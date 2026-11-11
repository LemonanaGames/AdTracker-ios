import '../content/game_catalog.dart';
import '../model/ids.dart';
import '../model/life_state.dart';
import 'post_simulation.dart';

/// Exact past series reconstructed from the pure post curves (nothing extra
/// is stored): followers at time t = Σ followers each post had credited at t.
abstract final class History {
  /// [points] samples of followers over the last [windowSimMs] of sim time,
  /// oldest first. When [network] is null, all networks are summed.
  static List<int> followers(
    GameCatalog c,
    LifeState life, {
    required int windowSimMs,
    int points = 24,
    NetworkId? network,
  }) {
    final end = life.simTimeMs;
    final start = end - windowSimMs < 0 ? 0 : end - windowSimMs;
    final out = <int>[];
    for (var i = 0; i < points; i++) {
      final t = points == 1 ? end : start + (end - start) * i ~/ (points - 1);
      var sum = 0;
      for (final p in life.posts) {
        if (network != null && p.networkId != network) continue;
        if (p.publishedAtSimMs > t) continue;
        final at = PostSimulation.totalsAt(c, p, t - p.publishedAtSimMs).followers;
        sum += at < p.followersGained ? at : p.followersGained;
      }
      out.add(sum);
    }
    return out;
  }
}
