import '../../core/rng.dart';
import '../content/game_catalog.dart';
import '../model/content_post.dart';
import '../model/ids.dart';
import '../model/life_state.dart';
import '../model/modifier.dart';

/// What the player chose in the composer.
final class PostDraft {
  const PostDraft({required this.networkId, required this.formatId, required this.topicId, required this.hookId});
  final NetworkId networkId;
  final String formatId;
  final String topicId;
  final String hookId;
}

/// Quality components (points). Keys are stable for UI/analytics.
abstract final class QualityPart {
  static const nicheFit = 'nicheFit';
  static const gear = 'gear';
  static const hook = 'hook';
  static const skills = 'skills';
  static const storyBonus = 'storyBonus';
  static const stress = 'stress';
}

/// Pre-publish preview shown in the composer. Ranges, never a promise.
final class PostForecast {
  const PostForecast({
    required this.quality,
    required this.breakdown,
    required this.trendPermille,
    required this.isHot,
    required this.typicalMinViews,
    required this.typicalMaxViews,
    required this.viralChancePermille,
    required this.energyCost,
    required this.xp,
  });
  final int quality;
  final Map<String, int> breakdown;
  final int trendPermille;
  final bool isHot;
  final int typicalMinViews;
  final int typicalMaxViews;
  final int viralChancePermille;
  final int energyCost;
  final int xp;
}

/// Cumulative stats of a post at a given elapsed time.
typedef PostTotals = ({int views, int likes, int comments, int shares, int followers, int revenueMinor, bool complete});

/// Pure post math (GDD C4), all integer, seeded and reproducible.
abstract final class PostSimulation {
  static const _msPerHour = 3600 * 1000;

  // ---------------------------------------------------------------- quality

  static Map<String, int> qualityBreakdown(GameCatalog c, LifeState life, PostDraft d) {
    final e = c.economy;
    final topic = c.topic(d.topicId)!;
    final hook = c.hook(d.hookId)!;
    final format = c.format(d.formatId)!;

    final nicheFit = topic.niches.contains(life.avatar.nicheId) ? e.nicheFitMatch : e.nicheFitOff;
    var gear = 0;
    for (final id in life.gearIds) {
      gear += c.gearItem(id)?.qualityBonus ?? 0;
    }
    var skillTenths = 0;
    for (final s in c.skills) {
      if (!s.enabled || s.effectKind != SkillEffectKind.qualityTenths) continue;
      if (s.formatTag != null && !format.tags.contains(s.formatTag)) continue;
      skillTenths += life.skillRank(s.id) * s.perRank;
    }
    var story = 0;
    for (final m in life.modifiers) {
      if (m.kind == ActiveModifier.kindQualityBonus && m.usesLeft > 0 && m.appliesTo(d.networkId)) {
        story += m.value;
      }
    }
    final stress = life.burnout ~/ e.burnoutQualityPenaltyDivisor;
    return {
      QualityPart.nicheFit: nicheFit,
      QualityPart.gear: gear,
      QualityPart.hook: hook.qualityBonus,
      QualityPart.skills: skillTenths ~/ 10,
      QualityPart.storyBonus: story,
      QualityPart.stress: -stress,
    };
  }

  static int qualityFrom(Map<String, int> breakdown) => breakdown.values.fold<int>(0, (a, b) => a + b).clamp(0, 100);

  // ------------------------------------------------------------------ reach

  /// Trend heat for a topic on a network during the current sim day.
  static int trendPermille(GameCatalog c, LifeState life, String topicId, NetworkId network) {
    final day = life.simTimeMs ~/ (24 * _msPerHour);
    final rng = Rng(Seed.of([life.seed, 'trend', topicId, network.name, day, c.contentVersion]));
    return rng.intInRange(c.economy.trendMinPermille, c.economy.trendMaxPermille);
  }

  static int _trendWithModifiers(GameCatalog c, LifeState life, PostDraft d) {
    var trend = trendPermille(c, life, d.topicId, d.networkId);
    for (final m in life.modifiers) {
      if (m.kind == ActiveModifier.kindTrendBoostPermille && m.usesLeft > 0 && m.appliesTo(d.networkId)) {
        trend = trend * (1000 + m.value) ~/ 1000;
      }
    }
    return trend;
  }

  /// Fewer impressions when several recent posts compete on one network.
  static int fatiguePermille(GameCatalog c, LifeState life, NetworkId network) {
    final e = c.economy;
    final windowStart = life.simTimeMs - e.fatigueWindowSimHours * _msPerHour;
    final recent = life.posts.where((p) => p.networkId == network && p.publishedAtSimMs > windowStart).length;
    final factor = 1000 - recent * e.fatiguePenaltyPermillePerPost;
    return factor < e.fatigueMinFactorPermille ? e.fatigueMinFactorPermille : factor;
  }

  /// Expected views before the viral roll (viral multiplier = 1000‰).
  static int baseExpectedViews(GameCatalog c, LifeState life, PostDraft d, int quality) {
    final net = c.network(d.networkId);
    final format = c.format(d.formatId)!;
    final followers = life.network(d.networkId).followers;

    var reachBonus = 0;
    var viewsBonus = 0;
    for (final s in c.skills) {
      if (!s.enabled) continue;
      if (s.formatTag != null && !format.tags.contains(s.formatTag)) continue;
      final value = life.skillRank(s.id) * s.perRank;
      if (s.effectKind == SkillEffectKind.reachPermille) reachBonus += value;
      if (s.effectKind == SkillEffectKind.viewsPermille) viewsBonus += value;
    }

    final otherFollowers = life.totalFollowers - followers;
    var v =
        net.baseReach +
        followers * net.reachPerFollowerPermille ~/ 1000 +
        otherFollowers * net.crossReachPermille ~/ 1000;
    v = v * (1000 + reachBonus) ~/ 1000;
    v = v * (400 + quality * 10) ~/ 1000;
    v = v * format.platformFitPermille ~/ 1000;
    v = v * _trendWithModifiers(c, life, d) ~/ 1000;
    v = v * fatiguePermille(c, life, d.networkId) ~/ 1000;
    v = v * (1000 + viewsBonus) ~/ 1000;
    return v < 0 ? 0 : v;
  }

  static int xpFor(GameCatalog c, int quality) =>
      c.economy.publishBaseXp + quality ~/ c.economy.publishQualityPointsPerXp;

  static PostForecast forecast(GameCatalog c, LifeState life, PostDraft d) {
    final e = c.economy;
    final breakdown = qualityBreakdown(c, life, d);
    final quality = qualityFrom(breakdown);
    final base = baseExpectedViews(c, life, d, quality);
    final m = e.viralMultipliersPermille;
    final totalWeight = e.viralWeights.fold<int>(0, (a, b) => a + b);
    var viralWeight = 0;
    for (var i = e.viralFromIndex; i < e.viralWeights.length; i++) {
      viralWeight += e.viralWeights[i];
    }
    final trend = trendPermille(c, life, d.topicId, d.networkId);
    return PostForecast(
      quality: quality,
      breakdown: breakdown,
      trendPermille: trend,
      isHot: trend >= e.trendHotFromPermille,
      typicalMinViews: base * m[1] ~/ 1000,
      typicalMaxViews: base * m[2] ~/ 1000,
      viralChancePermille: totalWeight == 0 ? 0 : viralWeight * 1000 ~/ totalWeight,
      energyCost: e.publishEnergyCost,
      xp: xpFor(c, quality),
    );
  }

  // ------------------------------------------------------------ publication

  /// Creates the post with every coefficient snapshotted. Deterministic for
  /// (life seed, postId, contentVersion, state).
  static ContentPost plan(GameCatalog c, LifeState life, PostDraft d, String postId) {
    final e = c.economy;
    final net = c.network(d.networkId);
    final topic = c.topic(d.topicId)!;
    final hook = c.hook(d.hookId)!;
    final rng = Rng(Seed.of([life.seed, life.lifeId, postId, c.contentVersion]));

    final breakdown = qualityBreakdown(c, life, d);
    final quality = qualityFrom(breakdown);
    final base = baseExpectedViews(c, life, d, quality);
    final tier = rng.weightedIndex(e.viralWeights);
    final viral = e.viralMultipliersPermille[tier];
    final expected = base * viral ~/ 1000;

    final nicheAffinity = topic.niches.contains(life.avatar.nicheId) ? 1000 : 700;
    final trustFactor = 500 + life.audienceTrust * 5; // (0.5 + trust/200) in permille
    final followRate = net.viewToFollowPpm * trustFactor ~/ 1000 * nicheAffinity ~/ 1000;

    final qf = 600 + quality * 8; // engagement scales with quality
    int jitter() => rng.intInRange(850, 1150);
    final likeBps = net.likeBps * qf ~/ 1000 * jitter() ~/ 1000;
    final commentBps = net.commentBps * qf ~/ 1000 * hook.commentBoostPermille ~/ 1000 * jitter() ~/ 1000;
    final shareBps = net.shareBps * qf ~/ 1000 * (tier >= e.viralFromIndex ? 1500 : 1000) ~/ 1000 * jitter() ~/ 1000;

    return ContentPost(
      postId: postId,
      networkId: d.networkId,
      formatId: d.formatId,
      topicId: d.topicId,
      hookId: d.hookId,
      publishedAtSimMs: life.simTimeMs,
      qualityScore: quality,
      trendPermille: _trendWithModifiers(c, life, d),
      viralTier: tier,
      viralPermille: viral,
      expectedViews: expected,
      followRatePpm: followRate,
      likeBps: likeBps,
      commentBps: commentBps,
      shareBps: shareBps,
      rpmMinor: net.rpmMinor,
      qualityBreakdown: breakdown,
    );
  }

  /// Cumulative share of views (‰) after [elapsedMs], linear between points.
  static int curvePermille(NetworkDef net, int elapsedMs) {
    if (elapsedMs < 0) return 0;
    final curve = net.curve;
    for (var i = 1; i < curve.length; i++) {
      final a = curve[i - 1];
      final b = curve[i];
      final aMs = a.hour * _msPerHour;
      final bMs = b.hour * _msPerHour;
      if (elapsedMs <= bMs) {
        final span = bMs - aMs;
        if (span <= 0) return b.permille;
        return a.permille + (b.permille - a.permille) * (elapsedMs - aMs) ~/ span;
      }
    }
    return curve.last.permille;
  }

  /// Cumulative totals at [elapsedMs]: a pure function, so crediting the
  /// difference to what was already credited can never double count.
  static PostTotals totalsAt(GameCatalog c, ContentPost p, int elapsedMs) {
    final net = c.network(p.networkId);
    final share = curvePermille(net, elapsedMs);
    final views = p.expectedViews * share ~/ 1000;
    return (
      views: views,
      likes: views * p.likeBps ~/ 10000,
      comments: views * p.commentBps ~/ 10000,
      shares: views * p.shareBps ~/ 10000,
      followers: views * p.followRatePpm ~/ 1000000,
      revenueMinor: views * p.rpmMinor ~/ 1000,
      complete: elapsedMs >= net.curveEndHour * _msPerHour,
    );
  }
}
