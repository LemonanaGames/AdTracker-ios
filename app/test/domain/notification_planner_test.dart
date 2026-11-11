import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/history.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';
import 'package:influencer_simulator/domain/model/life_state.dart';
import 'package:influencer_simulator/domain/notifications/notification_planner.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);
  const hour = 3600 * 1000;
  const draft = PostDraft(
    networkId: NetworkId.loop,
    formatId: 'loop_short',
    topicId: 'topic_first_challenge',
    hookId: 'hook_question',
  );

  // t0 is "noon" in this fake local clock; UTC-like hours for determinism.
  int localHour(int ms) => ((ms - t0) ~/ hour + 12) % 24;

  LifeState justPosted() => engine.publish(newTestLife(engine), draft).life;

  List<PlannedNotification> plan(LifeState life, {int now = t0, List<int> hours = const []}) =>
      NotificationPlanner.plan(engine: engine, life: life, nowMs: now, localHourOf: localHour, sessionHours: hours);

  test('describes real outcomes: the post-finished numbers match the engine', () {
    final life = justPosted();
    final n = plan(life).firstWhere((n) => n.kind == NotificationKind.postFinished);
    final later = engine.advanceTo(life, n.fireAtMs).life;
    expect(later.posts.single.complete, isTrue);
    expect(n.args['views'], later.posts.single.views);
    expect(n.args['followers'], later.posts.single.followersGained);
  });

  test('never more than 3 per absence, spaced ≥ 45 minutes, sorted, after a lead time', () {
    final planned = plan(justPosted());
    expect(planned.length, inInclusiveRange(1, 3));
    for (var i = 0; i < planned.length; i++) {
      expect(planned[i].fireAtMs, greaterThanOrEqualTo(t0 + 10 * 60 * 1000));
      if (i > 0) {
        expect(planned[i].fireAtMs - planned[i - 1].fireAtMs, greaterThanOrEqualTo(45 * 60 * 1000));
      }
    }
  });

  test('nothing fires in quiet hours (22:00–09:00 local)', () {
    // Leave the app at 21:30 local.
    final now = t0 + 9 * hour + 30 * 60 * 1000;
    final life = engine.advanceTo(justPosted(), now).life;
    for (final n in plan(life, now: now)) {
      final h = localHour(n.fireAtMs);
      expect(h >= 9 && h < 22, isTrue, reason: '$n at $h:00');
    }
  });

  test('daily reminder uses the hour this player usually plays', () {
    final fresh = newTestLife(engine); // no posts: only reminder-type notes
    final planned = plan(fresh, hours: [20, 20, 21, 20]);
    final daily = planned.firstWhere((n) => n.kind == NotificationKind.dailyReminder);
    expect(localHour(daily.fireAtMs), 20);
    expect(daily.fireAtMs - t0, greaterThanOrEqualTo(20 * hour));
  });

  test('can-afford-gear only when it will really be affordable within the offline cap', () {
    var life = justPosted();
    for (var i = 0; i < 4; i++) {
      life = engine.advanceTo(life, life.lastRealMs + 3 * 60 * 1000).life;
      life = engine.publish(life, draft).life;
    }
    final n = plan(life, now: life.lastRealMs).where((n) => n.kind == NotificationKind.canAffordGear);
    for (final x in n) {
      final f = engine.advanceTo(life, x.fireAtMs).life;
      final cost = catalog.gearItem(x.args['gearId']! as String)!.costMinor;
      expect(f.cashMinor + f.pendingIncomeMinor, greaterThanOrEqualTo(cost));
    }
  });

  test('deterministic for equal inputs', () {
    final life = justPosted();
    expect(plan(life).toString(), plan(life).toString());
  });

  test('follower history ends at the current total and never decreases', () {
    var life = justPosted();
    life = engine.advanceTo(life, t0 + 20 * 60 * 1000).life;
    life = engine.publish(life, draft).life;
    life = engine.advanceTo(life, t0 + 40 * 60 * 1000).life;
    final series = History.followers(catalog, life, windowSimMs: 24 * hour);
    expect(series.last, life.totalFollowers);
    for (var i = 1; i < series.length; i++) {
      expect(series[i], greaterThanOrEqualTo(series[i - 1]));
    }
  });
}
