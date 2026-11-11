import '../content/game_catalog.dart';
import '../engine/game_engine.dart';
import '../engine/post_simulation.dart';
import '../model/ids.dart';
import '../model/life_state.dart';

/// What a reminder is about. Values are persisted as notification ids — append only.
enum NotificationKind {
  postFinished,
  milestone,
  canAffordGear,
  energyFull,
  storyWaiting,
  awayCap,
  dailyReminder;

  /// Stable platform notification id (one pending notification per kind).
  int get id => 1000 + index;
}

/// One local notification to schedule. Text is localized by the app from
/// [kind] + [args]; the planner only decides *what* and *when*.
final class PlannedNotification {
  const PlannedNotification({required this.kind, required this.fireAtMs, this.args = const {}});
  final NotificationKind kind;
  final int fireAtMs;
  final Map<String, Object> args;

  @override
  String toString() => 'PlannedNotification(${kind.name} @$fireAtMs $args)';
}

/// Anti-spam rules. Defaults are design hypotheses (tune with retention data).
final class NotificationPolicy {
  const NotificationPolicy({
    this.quietStartHour = 22,
    this.quietEndHour = 9,
    this.minGap = const Duration(minutes: 45),
    this.maxPerAbsence = 3,
    this.sampleStep = const Duration(minutes: 5),
    this.minLead = const Duration(minutes: 10),
    this.defaultReminderHour = 19,
  });

  final int quietStartHour;
  final int quietEndHour;
  final Duration minGap;
  final int maxPerAbsence;
  final Duration sampleStep;

  /// Nothing fires sooner than this after leaving (the player just saw it).
  final Duration minLead;
  final int defaultReminderHour;

  bool isQuiet(int hour) => quietStartHour > quietEndHour
      ? hour >= quietStartHour || hour < quietEndHour
      : hour >= quietStartHour && hour < quietEndHour;
}

/// "Smart" reminders, planned when the player leaves the app.
///
/// The planner projects the life forward with the *real* engine (pure and
/// deterministic), so every message describes something that will actually
/// have happened by the time it fires — "Your Outfit Check video hit 1,240
/// views", not a generic "come back!". Honest rules:
/// - never more than [NotificationPolicy.maxPerAbsence] per absence, spaced
///   by [NotificationPolicy.minGap], shifted out of quiet hours;
/// - nothing is promised beyond the offline accrual cap;
/// - no guilt or loss framing: absence never hurts a life (GDD C4).
abstract final class NotificationPlanner {
  static const _hourMs = 3600 * 1000;

  /// Higher first: what the player most likely cares about.
  static const priority = [
    NotificationKind.postFinished,
    NotificationKind.milestone,
    NotificationKind.canAffordGear,
    NotificationKind.storyWaiting,
    NotificationKind.energyFull,
    NotificationKind.awayCap,
    NotificationKind.dailyReminder,
  ];

  static List<PlannedNotification> plan({
    required GameEngine engine,
    required LifeState life,
    required int nowMs,
    required int Function(int epochMs) localHourOf,
    List<int> sessionHours = const [],
    bool pro = false,
    NotificationPolicy policy = const NotificationPolicy(),
  }) {
    final c = engine.catalog;
    final e = c.economy;
    final capMs = (pro ? e.proOfflineHours : e.freeOfflineHours) * _hourMs;
    final start = engine.advanceTo(life, nowMs, pro: pro).life; // catch up first
    final candidates = <PlannedNotification>[];

    // 1. Latest post finishes growing — exact numbers, it is deterministic.
    final growing = start.posts.where((p) => !p.complete).toList();
    if (growing.isNotEmpty) {
      final post = growing.last;
      final net = c.network(post.networkId);
      final endSim = post.publishedAtSimMs + net.curveEndHour * _hourMs;
      final realMs = (endSim - start.simTimeMs) ~/ e.simSecondsPerRealSecond;
      if (realMs <= capMs) {
        final totals = PostSimulation.totalsAt(c, post, endSim - post.publishedAtSimMs);
        candidates.add(
          PlannedNotification(
            kind: NotificationKind.postFinished,
            fireAtMs: nowMs + realMs,
            args: {
              'topicId': post.topicId,
              'network': post.networkId.name,
              'views': totals.views,
              'followers': totals.followers,
            },
          ),
        );
      }
    }

    // 2–4. Sample the future for threshold crossings.
    final nextGear = _nextGear(engine, start);
    final milestones = {for (final id in NetworkId.values) id: _nextMilestone(e, start.network(id).followers)};
    int? energyAt, gearAt, milestoneAt;
    Map<String, Object>? milestoneArgs;
    final stepMs = policy.sampleStep.inMilliseconds;
    for (var t = stepMs; t <= capMs; t += stepMs) {
      final f = engine.advanceTo(start, nowMs + t, pro: pro).life;
      if (energyAt == null && start.energy < e.energyMax && f.energy >= e.energyMax) energyAt = t;
      if (gearAt == null && nextGear != null && f.cashMinor + f.pendingIncomeMinor >= nextGear.costMinor) {
        gearAt = t;
      }
      if (milestoneAt == null) {
        for (final id in NetworkId.values) {
          final m = milestones[id];
          if (m != null && f.network(id).followers >= m) {
            milestoneAt = t;
            milestoneArgs = {'network': id.name, 'milestone': m};
            break;
          }
        }
      }
      if (energyAt != null && gearAt != null && milestoneAt != null) break;
    }
    if (milestoneAt != null) {
      candidates.add(
        PlannedNotification(kind: NotificationKind.milestone, fireAtMs: nowMs + milestoneAt, args: milestoneArgs!),
      );
    }
    if (gearAt != null) {
      candidates.add(
        PlannedNotification(
          kind: NotificationKind.canAffordGear,
          fireAtMs: nowMs + gearAt,
          args: {'gearId': nextGear!.id},
        ),
      );
    }
    if (energyAt != null) {
      candidates.add(PlannedNotification(kind: NotificationKind.energyFull, fireAtMs: nowMs + energyAt));
    }

    // 5. A story beat is waiting (nudge once, a little later).
    final story = engine.pendingStory(start);
    if (story != null) {
      candidates.add(
        PlannedNotification(
          kind: NotificationKind.storyWaiting,
          fireAtMs: nowMs + 2 * _hourMs,
          args: {'eventId': story.id},
        ),
      );
    }

    // 6. Offline accrual reached its cap: earnings are waiting (positive framing).
    final atCap = engine.advanceTo(start, nowMs + capMs, pro: pro).life;
    if (atCap.pendingIncomeMinor > 0) {
      candidates.add(
        PlannedNotification(
          kind: NotificationKind.awayCap,
          fireAtMs: nowMs + capMs,
          args: {'cashMinor': atCap.pendingIncomeMinor},
        ),
      );
    }

    // 7. One daily reminder at the hour this player usually plays.
    final hour = _preferredHour(sessionHours, policy.defaultReminderHour);
    var daily = nowMs + 20 * _hourMs;
    for (var i = 0; i < 24 * 4 && localHourOf(daily) != hour; i++) {
      daily += _hourMs ~/ 4;
    }
    candidates.add(PlannedNotification(kind: NotificationKind.dailyReminder, fireAtMs: daily));

    return _applyPolicy(candidates, nowMs, localHourOf, policy);
  }

  static List<PlannedNotification> _applyPolicy(
    List<PlannedNotification> candidates,
    int nowMs,
    int Function(int) localHourOf,
    NotificationPolicy policy,
  ) {
    final shifted = [
      for (final n in candidates)
        PlannedNotification(
          kind: n.kind,
          fireAtMs: _outOfQuiet(_atLeast(n.fireAtMs, nowMs, policy), localHourOf, policy),
          args: n.args,
        ),
    ];
    shifted.sort((a, b) => priority.indexOf(a.kind).compareTo(priority.indexOf(b.kind)));
    final accepted = <PlannedNotification>[];
    final gap = policy.minGap.inMilliseconds;
    for (final n in shifted) {
      if (accepted.length >= policy.maxPerAbsence) break;
      if (accepted.any((a) => (a.fireAtMs - n.fireAtMs).abs() < gap)) continue;
      accepted.add(n);
    }
    accepted.sort((a, b) => a.fireAtMs.compareTo(b.fireAtMs));
    return accepted;
  }

  static int _atLeast(int fireAtMs, int nowMs, NotificationPolicy p) {
    final min = nowMs + p.minLead.inMilliseconds;
    return fireAtMs < min ? min : fireAtMs;
  }

  /// Moves a time out of quiet hours to the first 15-minute slot after them.
  static int _outOfQuiet(int ms, int Function(int) localHourOf, NotificationPolicy p) {
    var t = ms;
    for (var i = 0; i < 24 * 4 && p.isQuiet(localHourOf(t)); i++) {
      t += _hourMs ~/ 4;
    }
    return t;
  }

  static int _preferredHour(List<int> hours, int fallback) {
    if (hours.isEmpty) return fallback;
    final sorted = [...hours]..sort();
    return sorted[sorted.length ~/ 2];
  }

  static int? _nextMilestone(EconomyConfig e, int followers) {
    for (final m in e.followerMilestones) {
      if (m > followers) return m;
    }
    return null;
  }

  static GearDef? _nextGear(GameEngine engine, LifeState l) {
    GearDef? best;
    for (final g in engine.catalog.gear) {
      if (!g.enabled || l.gearIds.contains(g.id) || !engine.rules.isMet(l, g.requirement)) continue;
      if (g.costMinor <= l.cashMinor) continue; // already affordable: not news
      if (best == null || g.costMinor < best.costMinor) best = g;
    }
    return best;
  }
}
