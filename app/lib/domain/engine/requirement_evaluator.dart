import '../content/game_catalog.dart';
import '../content/requirement.dart';
import '../model/ids.dart';
import '../model/life_state.dart';
import 'progression.dart';

/// Evaluates [Requirement]s against a [LifeState]. Pure and side-effect free.
final class RequirementEvaluator {
  const RequirementEvaluator(this.catalog);
  final GameCatalog catalog;

  bool isMet(LifeState life, Requirement? r) => r == null || check(life, r).met;

  RequirementCheck check(LifeState life, Requirement r) {
    switch (r.type) {
      case RequirementType.always:
        return RequirementCheck(requirement: r, met: true, current: 1, target: 1);
      case RequirementType.anyOf:
      case RequirementType.allOf:
        final children = [for (final c in r.of) check(life, c)];
        final met = r.type == RequirementType.anyOf ? children.any((c) => c.met) : children.every((c) => c.met);
        return RequirementCheck(requirement: r, met: met, current: 0, target: 0, children: children);
      case RequirementType.act:
        final current = catalog.actIndex(life.actId);
        final target = catalog.actIndex(r.minAct!);
        return _leaf(r, current, target);
      case RequirementType.followers:
        return _leaf(r, life.networks[r.network]?.followers ?? 0, r.min!);
      case RequirementType.engagement:
        return _leaf(r, life.networks[r.network]?.engagementRateBps ?? 0, r.min!);
      case RequirementType.totalFollowers:
        return _leaf(r, life.totalFollowers, r.min!);
      case RequirementType.creatorLevel:
        return _leaf(r, Progression.levelForXp(catalog.economy, life.creatorXp), r.min!);
      case RequirementType.stat:
        return _leaf(r, _stat(life, r.stat!), r.min!);
      case RequirementType.gearOwned:
        final owned = life.gearIds.contains(r.gearId);
        return _leaf(r, owned ? 1 : 0, 1);
      case RequirementType.flag:
        return _leaf(r, life.flags.contains(r.flag) ? 1 : 0, 1);
      case RequirementType.trust:
        return _leaf(r, life.audienceTrust, r.min!);
      case RequirementType.cash:
        return _leaf(r, life.cashMinor, r.min!);
      case RequirementType.postViews:
        final best = life.posts.fold<int>(0, (m, p) => p.views > m ? p.views : m);
        return _leaf(r, best, r.min!);
    }
  }

  static RequirementCheck _leaf(Requirement r, int current, int target) =>
      RequirementCheck(requirement: r, met: current >= target, current: current, target: target);

  static int _stat(LifeState life, String stat) => switch (stat) {
    'tubecastPosts' => life.counter(Counters.postsOn(NetworkId.tubecast)),
    'vibePosts' => life.counter(Counters.postsOn(NetworkId.vibe)),
    _ => life.counter(stat),
  };
}
