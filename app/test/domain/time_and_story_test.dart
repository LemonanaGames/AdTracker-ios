import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/core/rng.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/game_event.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);
  const draft = PostDraft(
    networkId: NetworkId.loop,
    formatId: 'loop_short',
    topicId: 'topic_first_challenge',
    hookId: 'hook_question',
  );
  const hourMs = 3600 * 1000;

  group('offline / clock', () {
    test('offline progress is capped at freeOfflineHours of real time', () {
      final life = newTestLife(engine);
      final r = engine.advanceTo(life, t0 + 48 * hourMs);
      final cap = catalog.economy.freeOfflineHours * hourMs;
      expect(r.value!.simDeltaMs, cap * catalog.economy.simSecondsPerRealSecond);
      expect(r.value!.cappedRealMs, 48 * hourMs - cap);
      expect(r.life.lastRealMs, t0 + 48 * hourMs, reason: 're-anchors so capped time is not re-credited later');
    });

    test('Pro allowance is longer (entitlement wiring comes in M5)', () {
      final r = engine.advanceTo(newTestLife(engine), t0 + 48 * hourMs, pro: true);
      expect(r.value!.cappedRealMs, 48 * hourMs - catalog.economy.proOfflineHours * hourMs);
    });

    test('clock rollback neither grants nor removes progress', () {
      var life = engine.publish(newTestLife(engine), draft).life;
      life = engine.advanceTo(life, t0 + 60 * 1000).life;
      final r = engine.advanceTo(life, t0 - 10 * hourMs);
      expect(r.value!.clockRolledBack, isTrue);
      expect(r.life.simTimeMs, life.simTimeMs);
      expect(r.life.posts.single.views, life.posts.single.views);
      expect(r.events.single.name, 'clock_rollback_detected');
      // After re-anchoring, normal time works again.
      final again = engine.advanceTo(r.life, t0 - 10 * hourMs + 1000);
      expect(again.life.simTimeMs, greaterThan(life.simTimeMs));
    });

    test('splitting time into many ticks equals one big step (no drift)', () {
      final base = engine.publish(newTestLife(engine), draft).life;
      var stepped = base;
      for (var i = 1; i <= 600; i++) {
        stepped = engine.advanceTo(stepped, t0 + i * 1000).life;
      }
      final once = engine.advanceTo(base, t0 + 600 * 1000).life;
      expect(stepped.energyMilli, once.energyMilli);
      expect(stepped.posts.single.views, once.posts.single.views);
      expect(stepped.network(NetworkId.loop).followers, once.network(NetworkId.loop).followers);
      expect(stepped.pendingIncomeMinor, once.pendingIncomeMinor);
    });

    test('long absence never fails anything or removes progress', () {
      var life = engine.publish(newTestLife(engine), draft).life;
      final followers = life.network(NetworkId.loop).followers;
      life = engine.advanceTo(life, t0 + 30 * 24 * hourMs).life;
      expect(life.network(NetworkId.loop).followers, greaterThanOrEqualTo(followers));
      expect(life.cashMinor, greaterThanOrEqualTo(0));
      expect(life.status, LifeStatus.active);
    });
  });

  group('curves', () {
    test('every network curve is monotonic and reaches 100%', () {
      for (final net in catalog.networks.values) {
        var last = -1;
        for (var ms = 0; ms <= net.curveEndHour * hourMs; ms += hourMs ~/ 4) {
          final v = PostSimulation.curvePermille(net, ms);
          expect(v, greaterThanOrEqualTo(last));
          last = v;
        }
        expect(PostSimulation.curvePermille(net, net.curveEndHour * hourMs), 1000);
        expect(PostSimulation.curvePermille(net, -5), 0);
      }
    });

    test('Loop front-loads views more than TubeCast (GDD C4 shapes)', () {
      final loop = catalog.network(NetworkId.loop);
      final tube = catalog.network(NetworkId.tubecast);
      expect(PostSimulation.curvePermille(loop, 2 * hourMs), 500);
      expect(PostSimulation.curvePermille(tube, 2 * hourMs), 200);
    });
  });

  group('story V01 stub', () {
    test('triggers after 2 posts and a 500-view post, once per life', () {
      var life = newTestLife(engine);
      expect(engine.pendingStory(life), isNull);
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 10 * 60 * 1000).life;
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 20 * 60 * 1000).life;
      expect(life.posts.any((p) => p.views >= 500), isTrue);
      expect(engine.pendingStory(life)?.id, 'V01');

      final r = engine.chooseStory(life, 'V01', 'make_it_yours');
      expect(r.ok, isTrue);
      expect(r.life.audienceTrust, life.audienceTrust + 5);
      expect(r.life.flags, containsAll(['signature_series_unlocked', 'choice:V01:make_it_yours']));
      expect(r.life.modifiers.single.usesLeft, 3);
      expect(engine.pendingStory(r.life), isNull);
      expect(engine.chooseStory(r.life, 'V01', 'ride_trend').error, GameError.alreadyCompleted);

      // The quality bonus is real, previewed, and consumed one post at a time.
      final before = engine.forecast(life, draft).quality;
      expect(engine.forecast(r.life, draft).quality, before + 3);
      final after = engine.publish(r.life, draft).life;
      expect(after.modifiers.single.usesLeft, 2);
    });

    test('a choice that costs cash is locked when the player cannot afford it', () {
      var life = newTestLife(engine);
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 10 * 60 * 1000).life;
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 20 * 60 * 1000).life.copyWith(cashMinor: 5000);
      expect(engine.chooseStory(life, 'V01', 'ask_maya').error, GameError.requirementsNotMet);
      final ok = engine.chooseStory(life.copyWith(cashMinor: 20000), 'V01', 'ask_maya');
      expect(ok.life.cashMinor, 10000);
      expect(ok.life.relationships['maya'], 68);
    });

    test('ride_trend boosts the next Loop post trend by 20%', () {
      var life = newTestLife(engine);
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 10 * 60 * 1000).life;
      life = engine.publish(life, draft).life;
      life = engine.advanceTo(life, t0 + 20 * 60 * 1000).life;
      final boosted = engine.chooseStory(life, 'V01', 'ride_trend').life;
      final normal = PostSimulation.trendPermille(catalog, boosted, draft.topicId, NetworkId.loop);
      final post = engine.publish(boosted, draft).value!;
      expect(post.trendPermille, normal * 1200 ~/ 1000);
      expect(engine.publish(boosted, draft).life.modifiers, isEmpty);
    });
  });

  group('rng', () {
    test('seed hashing and sequence are stable across runs/platforms', () {
      expect(Seed.of(['life', 'abc']), Seed.of(['life', 'abc']));
      expect(Seed.of(['a', 'bc']), isNot(Seed.of(['ab', 'c'])));
      final a = Rng(42);
      final b = Rng(42);
      final seqA = [for (var i = 0; i < 5; i++) a.nextUint32()];
      final seqB = [for (var i = 0; i < 5; i++) b.nextUint32()];
      expect(seqA, seqB);
      for (final v in seqA) {
        expect(v, inInclusiveRange(0, 0xFFFFFFFF));
      }
    });

    test('weighted index roughly follows weights', () {
      final rng = Rng(7);
      final counts = List.filled(5, 0);
      for (var i = 0; i < 20000; i++) {
        counts[rng.weightedIndex(catalog.economy.viralWeights)]++;
      }
      expect(counts[1], greaterThan(counts[0]));
      expect(counts[4], lessThan(counts[3]));
      expect(counts[1] / 20000, closeTo(0.45, 0.03));
    });
  });
}
