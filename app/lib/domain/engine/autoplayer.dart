import '../content/game_catalog.dart';
import '../model/ids.dart';
import '../model/life_state.dart';
import 'game_engine.dart';
import 'post_simulation.dart';

/// Scripted player used by balance tests and `tool/simulate_lives.dart`.
/// It never pays (there is no purchase path in the domain at all).
final class AutoPlayer {
  AutoPlayer(this.engine, {this.minRealSecondsBetweenPosts = 20, this.strategy = AutoStrategy.balanced});

  final GameEngine engine;
  final int minRealSecondsBetweenPosts;
  final AutoStrategy strategy;
  int _lastPostRealMs = -1 << 40;
  int _claims = 0;

  GameCatalog get _c => engine.catalog;

  /// Performs at most one meaningful action at wall-clock [nowMs].
  LifeState step(LifeState life, int nowMs) {
    var l = engine.advanceTo(life, nowMs).life;

    final story = engine.pendingStory(l);
    if (story != null) {
      final choices = [
        for (final c in story.choices)
          if (engine.isChoiceAvailable(l, c)) c,
      ];
      final pick = strategy == AutoStrategy.trend ? choices.first : choices[choices.length > 1 ? 1 : 0];
      return engine.chooseStory(l, story.id, pick.id).life;
    }
    if (l.pendingIncomeMinor > 0) {
      l = engine.claimIncome(l, 'auto-${_claims++}').life;
    }
    if (l.skillPoints > 0) {
      for (final id in strategy.skillOrder) {
        final r = engine.spendSkillPoint(l, id);
        if (r.ok) return r.life;
      }
    }
    final gear = _nextGear(l);
    if (gear != null && l.cashMinor >= gear.costMinor) {
      return engine.buyGear(l, gear.id).life;
    }

    final canPost = nowMs - _lastPostRealMs >= minRealSecondsBetweenPosts * 1000;
    if (canPost) {
      final draft = bestDraft(l);
      if (draft != null && engine.validateDraft(l, draft) == null) {
        _lastPostRealMs = nowMs;
        return engine.publish(l, draft).life;
      }
    }
    // Work only when saving for gear and energy would remain for a post.
    if (gear != null && l.cashMinor < gear.costMinor) {
      for (final job in _c.jobs.reversed) {
        if (l.energy - job.energyCost >= _c.economy.publishEnergyCost) {
          final r = engine.work(l, job.id);
          if (r.ok) return r.life;
        }
      }
    }
    return l;
  }

  GearDef? _nextGear(LifeState l) {
    GearDef? best;
    for (final g in _c.gear) {
      if (!g.enabled || l.gearIds.contains(g.id) || !engine.rules.isMet(l, g.requirement)) continue;
      if (best == null || g.costMinor < best.costMinor) best = g;
    }
    return best;
  }

  /// Highest-forecast draft across unlocked networks (rotates when allowed).
  PostDraft? bestDraft(LifeState l) {
    PostDraft? best;
    var bestScore = -1;
    for (final net in _c.networks.values) {
      if (!l.network(net.id).unlocked) continue;
      if (strategy == AutoStrategy.singleNetwork && net.id != NetworkId.loop) continue;
      for (final topic in _c.topics) {
        if (!topic.networks.contains(net.id)) continue;
        for (final hook in _c.hooks) {
          if (!engine.rules.isMet(l, hook.requirement)) continue;
          final d = PostDraft(networkId: net.id, formatId: net.formats.first.id, topicId: topic.id, hookId: hook.id);
          final f = engine.forecast(l, d);
          // Values followers and income (a player saving for gear wants both).
          final score = f.typicalMaxViews * (net.viewToFollowPpm ~/ 1000 + net.rpmMinor ~/ 20);
          if (score > bestScore) {
            bestScore = score;
            best = d;
          }
        }
      }
    }
    return best;
  }
}

enum AutoStrategy {
  balanced(['editing', 'creativity', 'marketing', 'on_camera', 'storytelling']),
  trend(['marketing', 'creativity', 'editing', 'on_camera', 'storytelling']),
  singleNetwork(['on_camera', 'editing', 'creativity', 'marketing', 'storytelling']);

  const AutoStrategy(this.skillOrder);
  final List<String> skillOrder;
}
