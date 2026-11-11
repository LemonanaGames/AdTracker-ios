import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/domain/engine/autoplayer.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/model/ids.dart';

import '../support/fixtures.dart';

/// Seeded autoplay over many lives: invariants must hold for every strategy,
/// and no free player may get stuck. (Full 10,000-life runs: tool/simulate_lives.dart.)
void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);

  test('30 seeded lives × 45 real minutes: no negatives, no stuck progression', () {
    for (var i = 0; i < 30; i++) {
      final strategy = AutoStrategy.values[i % AutoStrategy.values.length];
      final bot = AutoPlayer(engine, strategy: strategy);
      var life = newTestLife(engine, lifeId: 'bal-$i', niche: catalog.niches[i % 3].id);
      for (var sec = 1; sec <= 45 * 60; sec += 2) {
        life = bot.step(life, t0 + sec * 1000);
        expect(life.cashMinor, greaterThanOrEqualTo(0));
        expect(life.pendingIncomeMinor, greaterThanOrEqualTo(0));
        expect(life.energyMilli, inInclusiveRange(0, catalog.economy.energyMax * 1000));
        expect(life.burnoutMilli, inInclusiveRange(0, catalog.economy.burnoutMax * 1000));
      }
      for (final n in life.networks.values) {
        expect(n.followers, greaterThanOrEqualTo(0));
        expect(n.lifetimeViews, greaterThanOrEqualTo(0));
      }
      for (final p in life.posts) {
        expect(p.views, inInclusiveRange(0, p.expectedViews));
        expect(p.followersGained, greaterThanOrEqualTo(0));
      }
      // Pacing hypotheses for the first session (tune in soft launch).
      expect(life.gearIds, contains('gear_light_1'), reason: 'first gear within the first session');
      expect(life.network(NetworkId.loop).followers, greaterThanOrEqualTo(100), reason: 'strategy $strategy');
      expect(life.actId, isNot('prologue'), reason: 'Act I within 45 minutes');
      expect(life.completedEventIds, contains('V01'));
    }
  });
}
