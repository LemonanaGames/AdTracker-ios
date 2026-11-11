import '../../core/rng.dart';
import '../content/game_catalog.dart';
import '../content/requirement.dart';
import '../model/avatar.dart';
import '../model/content_post.dart';
import '../model/ids.dart';
import '../model/life_state.dart';
import '../model/modifier.dart';
import '../model/network_state.dart';
import 'game_event.dart';
import 'post_simulation.dart';
import 'progression.dart';
import 'requirement_evaluator.dart';

/// Outcome of a command. On error [life] is the *unchanged* input instance.
final class CommandResult<T> {
  const CommandResult(this.life, {this.events = const [], this.error, this.value});
  final LifeState life;
  final List<GameEvent> events;
  final GameError? error;
  final T? value;
  bool get ok => error == null;
}

/// What happened while time advanced (used for the "while you were away" sheet).
final class AdvanceSummary {
  const AdvanceSummary({
    required this.realDeltaMs,
    required this.simDeltaMs,
    required this.cappedRealMs,
    required this.viewsGained,
    required this.followersGained,
    required this.incomeGainedMinor,
    required this.clockRolledBack,
  });
  final int realDeltaMs;
  final int simDeltaMs;

  /// Real time that was NOT simulated because it exceeded the offline cap.
  final int cappedRealMs;
  final int viewsGained;
  final int followersGained;
  final int incomeGainedMinor;
  final bool clockRolledBack;
}

/// The single entry point for every state change in a life. Pure: no I/O,
/// no wall clock (time is passed in), deterministic for equal inputs.
final class GameEngine {
  GameEngine(this.catalog) : rules = RequirementEvaluator(catalog);

  final GameCatalog catalog;
  final RequirementEvaluator rules;

  static const _msPerHour = 3600 * 1000;
  static const _claimDedupeWindow = 32;

  EconomyConfig get _e => catalog.economy;

  int creatorLevel(LifeState life) => Progression.levelForXp(_e, life.creatorXp);

  // ------------------------------------------------------------ new life

  LifeState newLife({required String lifeId, required int lifeNumber, required Avatar avatar, required int nowMs}) {
    final seed = Seed.of(['life', lifeId]);
    final networks = <NetworkId, NetworkState>{
      for (final id in NetworkId.values) id: NetworkState(networkId: id, unlocked: false),
    };
    var life = LifeState(
      lifeId: lifeId,
      lifeNumber: lifeNumber,
      seed: seed,
      status: LifeStatus.active,
      actId: _e.acts.first.id,
      avatar: avatar,
      creatorXp: 0,
      cashMinor: _e.startCashMinor,
      pendingIncomeMinor: 0,
      skillPoints: _e.startSkillPoints,
      skills: {for (final s in catalog.skills) s.id: 0},
      networks: networks,
      posts: const [],
      nextPostSerial: 1,
      gearIds: {..._e.startGearIds},
      homeId: _e.startHomeId,
      energyMilli: _e.startEnergy * 1000,
      burnoutMilli: 0,
      audienceTrust: _e.startTrust,
      integrity: _e.startIntegrity,
      relationships: {for (final ch in catalog.characters) ch.id: ch.startRelationship},
      flags: const {},
      modifiers: const [],
      completedEventIds: const {},
      counters: const {},
      recentClaimIds: const [],
      simTimeMs: 0,
      lastRealMs: nowMs,
      createdAtMs: nowMs,
      contentVersion: catalog.contentVersion,
      revision: 0,
    );
    life = _postProcess(life, []);
    return life;
  }

  // ------------------------------------------------------------- time

  /// Advances simulated time to wall-clock [nowMs].
  ///
  /// Real time is converted with `simSecondsPerRealSecond` and capped at the
  /// offline allowance. A backwards clock never removes progress and never
  /// grants any: it simply re-anchors.
  CommandResult<AdvanceSummary> advanceTo(LifeState life, int nowMs, {bool pro = false}) {
    final realDelta = nowMs - life.lastRealMs;
    if (realDelta <= 0) {
      final rolledBack = realDelta < 0;
      final next = rolledBack ? life.copyWith(lastRealMs: nowMs) : life;
      return CommandResult(
        next,
        events: rolledBack
            ? [
                GameEvent('clock_rollback_detected', {'delta_ms': realDelta}),
              ]
            : const [],
        value: AdvanceSummary(
          realDeltaMs: realDelta,
          simDeltaMs: 0,
          cappedRealMs: 0,
          viewsGained: 0,
          followersGained: 0,
          incomeGainedMinor: 0,
          clockRolledBack: rolledBack,
        ),
      );
    }
    final capMs = (pro ? _e.proOfflineHours : _e.freeOfflineHours) * _msPerHour;
    final simulatedReal = realDelta > capMs ? capMs : realDelta;
    final simDelta = simulatedReal * _e.simSecondsPerRealSecond;

    final events = <GameEvent>[];
    final viewsBefore = _totalViews(life);
    final followersBefore = life.totalFollowers;
    final pendingBefore = life.pendingIncomeMinor;

    var next = _advanceSim(life, simDelta);
    next = _postProcess(
      next.copyWith(lastRealMs: nowMs, revision: life.revision + 1),
      events,
      before: life,
    );

    return CommandResult(
      next,
      events: events,
      value: AdvanceSummary(
        realDeltaMs: realDelta,
        simDeltaMs: simDelta,
        cappedRealMs: realDelta - simulatedReal,
        viewsGained: _totalViews(next) - viewsBefore,
        followersGained: next.totalFollowers - followersBefore,
        incomeGainedMinor: next.pendingIncomeMinor - pendingBefore,
        clockRolledBack: false,
      ),
    );
  }

  static int _totalViews(LifeState l) => l.networks.values.fold(0, (s, n) => s + n.lifetimeViews);

  LifeState _advanceSim(LifeState life, int simDeltaMs) {
    final from = life.simTimeMs;
    final to = from + simDeltaMs;
    // Exact regeneration (no rounding drift): difference of floors.
    int regen(int perHour) => (to * perHour ~/ 3600) - (from * perHour ~/ 3600);

    final energy = (life.energyMilli + regen(_e.energyRegenPerSimHour)).clamp(0, _e.energyMax * 1000);
    final burnout = (life.burnoutMilli - regen(_e.burnoutRecoveryPerSimHour)).clamp(0, _e.burnoutMax * 1000);
    return _creditPosts(life.copyWith(simTimeMs: to, energyMilli: energy, burnoutMilli: burnout));
  }

  /// Credits every post up to the current sim time (difference to already
  /// credited totals) and refreshes per-network aggregates.
  LifeState _creditPosts(LifeState life) {
    final networks = {...life.networks};
    var pending = life.pendingIncomeMinor;
    var earned = life.counter(Counters.lifetimeEarnedMinor);
    final posts = <ContentPost>[];

    for (final p in life.posts) {
      if (p.complete) {
        posts.add(p);
        continue;
      }
      final t = PostSimulation.totalsAt(catalog, p, life.simTimeMs - p.publishedAtSimMs);
      // Monotonic guard: never take anything back.
      final dv = _nonNeg(t.views - p.views);
      final dl = _nonNeg(t.likes - p.likes);
      final dc = _nonNeg(t.comments - p.comments);
      final ds = _nonNeg(t.shares - p.shares);
      final df = _nonNeg(t.followers - p.followersGained);
      final dr = _nonNeg(t.revenueMinor - p.revenueMinor);
      posts.add(
        p.credited(
          views: p.views + dv,
          likes: p.likes + dl,
          comments: p.comments + dc,
          shares: p.shares + ds,
          followersGained: p.followersGained + df,
          revenueMinor: p.revenueMinor + dr,
          complete: t.complete,
        ),
      );
      final n = networks[p.networkId]!;
      networks[p.networkId] = n.copyWith(
        followers: n.followers + df,
        lifetimeFollowersGained: n.lifetimeFollowersGained + df,
        lifetimeViews: n.lifetimeViews + dv,
        lifetimeLikes: n.lifetimeLikes + dl,
        lifetimeComments: n.lifetimeComments + dc,
        lifetimeShares: n.lifetimeShares + ds,
        revenueLifetimeMinor: n.revenueLifetimeMinor + dr,
      );
      pending += dr;
      earned += dr;
    }

    // Rolling engagement window: (likes+comments+shares) / views of posts
    // published within the window. Formula is shown in the UI tooltip.
    final windowStart = life.simTimeMs - _e.engagementWindowSimDays * 24 * _msPerHour;
    for (final id in NetworkId.values) {
      var views = 0;
      var interactions = 0;
      for (final p in posts) {
        if (p.networkId != id || p.publishedAtSimMs < windowStart) continue;
        views += p.views;
        interactions += p.interactions;
      }
      networks[id] = networks[id]!.copyWith(
        last7dViews: views,
        engagementRateBps: views == 0 ? 0 : interactions * 10000 ~/ views,
      );
    }

    return life.copyWith(
      networks: networks,
      posts: posts,
      pendingIncomeMinor: pending,
      counters: {...life.counters, Counters.lifetimeEarnedMinor: earned},
    );
  }

  static int _nonNeg(int v) => v < 0 ? 0 : v;

  /// Unlocks, act changes and milestone events after any state change.
  ///
  /// [before] is the state at the start of the command (for milestone edges).
  LifeState _postProcess(LifeState life, List<GameEvent> events, {LifeState? before}) {
    final origin = before ?? life;
    var next = life;

    // Acts advance in order, one step per satisfied requirement.
    var actIdx = catalog.actIndex(next.actId);
    while (actIdx + 1 < _e.acts.length) {
      final candidate = _e.acts[actIdx + 1];
      if (!rules.isMet(next, candidate.requirement)) break;
      actIdx++;
      next = next.copyWith(actId: candidate.id);
      events.add(GameEvent('story_act_complete', {'act': candidate.id}));
    }

    // Network unlocks.
    final networks = {...next.networks};
    var changed = false;
    for (final def in catalog.networks.values) {
      final state = networks[def.id]!;
      if (!state.unlocked && rules.isMet(next, def.unlock)) {
        networks[def.id] = state.copyWith(unlocked: true, unlockedAtSimMs: next.simTimeMs);
        changed = true;
        events.add(GameEvent('network_unlocked', {'network_id': def.id.name}));
      }
    }
    if (changed) next = next.copyWith(networks: networks);

    // Follower milestones (per network; derived from before/after values).
    for (final id in NetworkId.values) {
      final before = origin.networks[id]!.followers;
      final after = next.networks[id]!.followers;
      for (final m in _e.followerMilestones) {
        if (before < m && after >= m) {
          events.add(GameEvent('followers_milestone', {'network_id': id.name, 'milestone': m}));
        }
      }
    }
    return next;
  }

  LifeState _grantXp(LifeState life, int xp, List<GameEvent> events) {
    if (xp <= 0) return life;
    final before = creatorLevel(life);
    final next = life.copyWith(creatorXp: life.creatorXp + xp);
    final after = creatorLevel(next);
    if (after <= before) return next;
    events.add(GameEvent('level_up', {'player_level': after}));
    return next.copyWith(skillPoints: next.skillPoints + (after - before) * _e.skillPointsPerLevel);
  }

  LifeState _bump(LifeState l) => l.copyWith(revision: l.revision + 1);

  // ---------------------------------------------------------- commands

  PostForecast forecast(LifeState life, PostDraft draft) => PostSimulation.forecast(catalog, life, draft);

  GameError? validateDraft(LifeState life, PostDraft d) {
    final net = catalog.networks[d.networkId];
    final topic = catalog.topic(d.topicId);
    final hook = catalog.hook(d.hookId);
    if (net == null || topic == null || hook == null) return GameError.notFound;
    if (!net.formats.any((f) => f.id == d.formatId)) return GameError.invalidInput;
    if (!topic.networks.contains(d.networkId)) return GameError.invalidInput;
    if (!life.network(d.networkId).unlocked) return GameError.locked;
    if (!rules.isMet(life, hook.requirement)) return GameError.locked;
    if (life.energy < _e.publishEnergyCost) return GameError.insufficientEnergy;
    return null;
  }

  CommandResult<ContentPost> publish(LifeState life, PostDraft d) {
    final error = validateDraft(life, d);
    if (error != null) return CommandResult(life, error: error);

    final events = <GameEvent>[];
    final postId = 'post_${life.nextPostSerial.toString().padLeft(6, '0')}';
    final post = PostSimulation.plan(catalog, life, d, postId);

    // Consume one use of every modifier that affected this post.
    final modifiers = <ActiveModifier>[
      for (final m in life.modifiers)
        if (m.usesLeft > 0 && m.appliesTo(d.networkId)) m.consumeOne() else m,
    ]..removeWhere((m) => m.usesLeft <= 0);

    final postsKey = Counters.postsOn(d.networkId);
    var next = life.copyWith(
      posts: [...life.posts, post],
      nextPostSerial: life.nextPostSerial + 1,
      energyMilli: life.energyMilli - _e.publishEnergyCost * 1000,
      burnoutMilli: (life.burnoutMilli + _e.publishBurnoutGain * 1000).clamp(0, _e.burnoutMax * 1000),
      modifiers: modifiers,
      counters: {
        ...life.counters,
        Counters.postsPublished: life.counter(Counters.postsPublished) + 1,
        postsKey: life.counter(postsKey) + 1,
      },
    );
    next = _creditPosts(next); // first-impressions burst at elapsed 0
    next = _grantXp(next, PostSimulation.xpFor(catalog, post.qualityScore), events);
    events.insert(
      0,
      GameEvent('post_published', {
        'network_id': d.networkId.name,
        'content_format': d.formatId,
        'topic_id': d.topicId,
        'quality': post.qualityScore,
        'viral_tier': post.viralTier,
      }),
    );
    next = _postProcess(_bump(next), events, before: life);
    final credited = next.posts.last;
    return CommandResult(next, events: events, value: credited);
  }

  /// Moves pending post income into cash. Idempotent per [claimId]; a second
  /// claim (same id, or nothing pending) grants 0.
  CommandResult<int> claimIncome(LifeState life, String claimId) {
    if (life.recentClaimIds.contains(claimId)) {
      return CommandResult(life, error: GameError.alreadyClaimed, value: 0);
    }
    final amount = life.pendingIncomeMinor;
    if (amount <= 0) return CommandResult(life, value: 0);
    final ids = [...life.recentClaimIds, claimId];
    final next = _bump(
      life.copyWith(
        cashMinor: life.cashMinor + amount,
        pendingIncomeMinor: 0,
        recentClaimIds: ids.length > _claimDedupeWindow ? ids.sublist(ids.length - _claimDedupeWindow) : ids,
        counters: {
          ...life.counters,
          Counters.lifetimeClaimedMinor: life.counter(Counters.lifetimeClaimedMinor) + amount,
        },
      ),
    );
    return CommandResult(
      next,
      events: [
        GameEvent('offline_claimed', {'amount_minor': amount}),
      ],
      value: amount,
    );
  }

  CommandResult<void> buyGear(LifeState life, String gearId) {
    final gear = catalog.gearItem(gearId);
    if (gear == null) return CommandResult(life, error: GameError.notFound);
    if (!gear.enabled) return CommandResult(life, error: GameError.disabled);
    if (life.gearIds.contains(gearId)) return CommandResult(life, error: GameError.alreadyOwned);
    if (!rules.isMet(life, gear.requirement)) return CommandResult(life, error: GameError.locked);
    if (life.cashMinor < gear.costMinor) return CommandResult(life, error: GameError.insufficientCash);
    final next = _bump(life.copyWith(cashMinor: life.cashMinor - gear.costMinor, gearIds: {...life.gearIds, gearId}));
    return CommandResult(
      next,
      events: [
        GameEvent('gear_purchased', {'gear_id': gearId, 'cost_minor': gear.costMinor}),
      ],
    );
  }

  CommandResult<int> work(LifeState life, String jobId) {
    final job = catalog.job(jobId);
    if (job == null) return CommandResult(life, error: GameError.notFound);
    if (!rules.isMet(life, job.requirement)) return CommandResult(life, error: GameError.locked);
    if (life.energy < job.energyCost) return CommandResult(life, error: GameError.insufficientEnergy);
    final events = <GameEvent>[
      GameEvent('job_shift_completed', {'job_id': jobId, 'pay_minor': job.payMinor}),
    ];
    var next = life.copyWith(
      cashMinor: life.cashMinor + job.payMinor,
      energyMilli: life.energyMilli - job.energyCost * 1000,
      burnoutMilli: (life.burnoutMilli + job.burnoutGain * 1000).clamp(0, _e.burnoutMax * 1000),
      counters: {...life.counters, Counters.jobShifts: life.counter(Counters.jobShifts) + 1},
    );
    next = _grantXp(next, job.xp, events);
    next = _postProcess(_bump(next), events, before: life);
    return CommandResult(next, events: events, value: job.payMinor);
  }

  CommandResult<void> spendSkillPoint(LifeState life, String skillId) {
    final skill = catalog.skill(skillId);
    if (skill == null) return CommandResult(life, error: GameError.notFound);
    if (!skill.enabled) return CommandResult(life, error: GameError.disabled);
    if (life.skillPoints < 1) return CommandResult(life, error: GameError.insufficientSkillPoints);
    final rank = life.skillRank(skillId);
    if (rank >= skill.maxRank) return CommandResult(life, error: GameError.maxRank);
    final next = _bump(life.copyWith(skillPoints: life.skillPoints - 1, skills: {...life.skills, skillId: rank + 1}));
    return CommandResult(
      next,
      events: [
        GameEvent('skill_spent', {'skill_id': skillId, 'rank': rank + 1}),
      ],
    );
  }

  // ------------------------------------------------------------- story

  /// First story event whose trigger is met and that has not been played.
  StoryEventDef? pendingStory(LifeState life) {
    for (final ev in catalog.events) {
      if (ev.oncePerLife && life.completedEventIds.contains(ev.id)) continue;
      if (rules.isMet(life, ev.trigger)) return ev;
    }
    return null;
  }

  bool isChoiceAvailable(LifeState life, StoryChoiceDef choice) => rules.isMet(life, choice.requirement);

  CommandResult<void> chooseStory(LifeState life, String eventId, String choiceId) {
    final ev = catalog.event(eventId);
    if (ev == null) return CommandResult(life, error: GameError.notFound);
    if (ev.oncePerLife && life.completedEventIds.contains(eventId)) {
      return CommandResult(life, error: GameError.alreadyCompleted);
    }
    if (!rules.isMet(life, ev.trigger)) return CommandResult(life, error: GameError.requirementsNotMet);
    StoryChoiceDef? choice;
    for (final c in ev.choices) {
      if (c.id == choiceId) choice = c;
    }
    if (choice == null) return CommandResult(life, error: GameError.notFound);
    if (!isChoiceAvailable(life, choice)) return CommandResult(life, error: GameError.requirementsNotMet);

    final fx = choice.effects;
    final events = <GameEvent>[
      GameEvent('story_choice_made', {'event_id': eventId, 'choice_id': choiceId, 'act': life.actId}),
    ];
    final relationships = {...life.relationships};
    fx.relationships.forEach((npc, delta) {
      relationships[npc] = ((relationships[npc] ?? 0) + delta).clamp(0, 100);
      events.add(GameEvent('relationship_changed', {'npc_id': npc, 'delta': delta}));
    });
    var next = life.copyWith(
      integrity: (life.integrity + fx.integrity).clamp(0, 100),
      audienceTrust: (life.audienceTrust + fx.audienceTrust).clamp(0, 100),
      cashMinor: life.cashMinor + fx.cashMinor < 0 ? 0 : life.cashMinor + fx.cashMinor,
      relationships: relationships,
      modifiers: [
        ...life.modifiers,
        for (final m in fx.modifiers)
          ActiveModifier(
            kind: m.kind,
            value: m.value,
            usesLeft: m.uses,
            sourceId: '$eventId:$choiceId',
            network: m.network,
          ),
      ],
      flags: {...life.flags, ...choice.deferredFlags, 'choice:$eventId:$choiceId'},
      completedEventIds: {...life.completedEventIds, eventId},
    );
    next = _grantXp(next, fx.xp, events);
    next = _postProcess(_bump(next), events, before: life);
    return CommandResult(next, events: events);
  }

  // ------------------------------------------------------ projections

  /// The single "what should I do next" goal, with progress.
  ({GoalDef goal, RequirementCheck check})? currentGoal(LifeState life) {
    for (final g in catalog.goals) {
      final check = rules.check(life, g.requirement);
      if (!check.met) return (goal: g, check: check);
    }
    return null;
  }

  /// Modeled estimate, NOT verified unique humans: largest network plus a
  /// non-overlapping share of the others.
  int estimatedUniqueReach(LifeState life) {
    final counts = [for (final n in life.networks.values) n.followers]..sort();
    if (counts.isEmpty) return 0;
    final largest = counts.last;
    final rest = counts.fold<int>(0, (a, b) => a + b) - largest;
    return largest + rest * (1000 - _e.uniqueReachOverlapPermille) ~/ 1000;
  }
}
