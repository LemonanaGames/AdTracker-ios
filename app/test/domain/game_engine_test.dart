import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/game_event.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';
import 'package:influencer_simulator/domain/model/life_state.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);

  const loopDraft = PostDraft(
    networkId: NetworkId.loop,
    formatId: 'loop_short',
    topicId: 'topic_first_challenge',
    hookId: 'hook_question',
  );

  LifeState later(LifeState life, Duration real) => engine.advanceTo(life, life.lastRealMs + real.inMilliseconds).life;

  group('new life', () {
    test('starts with only Loop unlocked, starter gear and config cash', () {
      final life = newTestLife(engine);
      expect(life.network(NetworkId.loop).unlocked, isTrue);
      expect(life.network(NetworkId.tubecast).unlocked, isFalse);
      expect(life.network(NetworkId.vibe).unlocked, isFalse);
      expect(life.gearIds, {'gear_phone_1'});
      expect(life.cashMinor, catalog.economy.startCashMinor);
      expect(life.actId, 'prologue');
    });
  });

  group('determinism', () {
    test('same seed + same inputs → identical post output', () {
      final a = engine.publish(newTestLife(engine), loopDraft);
      final b = engine.publish(newTestLife(engine), loopDraft);
      expect(a.value!.toJson(), b.value!.toJson());
      final a2 = later(a.life, const Duration(minutes: 20));
      final b2 = later(b.life, const Duration(minutes: 20));
      expect(a2.toJson(), b2.toJson());
    });

    test('different life seeds can roll different outcomes', () {
      final outcomes = {
        for (var i = 0; i < 30; i++)
          engine.publish(newTestLife(engine, lifeId: 'seed-$i'), loopDraft).value!.expectedViews,
      };
      expect(outcomes.length, greaterThan(1));
    });
  });

  group('publishing', () {
    test('first post: guided values, immediate burst, XP and energy cost', () {
      final life = newTestLife(engine);
      final forecast = engine.forecast(life, loopDraft);
      expect(forecast.quality, 38, reason: 'GDD I4: first post editing score 38/100');
      final r = engine.publish(life, loopDraft);
      expect(r.ok, isTrue);
      final post = r.value!;
      expect(post.views, greaterThan(0), reason: 'first impressions are credited at publish');
      expect(r.life.energy, life.energy - catalog.economy.publishEnergyCost);
      expect(r.life.creatorXp, PostSimulation.xpFor(catalog, 38));
      expect(r.life.counter(Counters.postsPublished), 1);
      expect(r.events.first.name, 'post_published');
    });

    test('credits incrementally and never more than the curve total', () {
      var life = engine.publish(newTestLife(engine), loopDraft).life;
      final expected = life.posts.single.expectedViews;
      var lastViews = life.posts.single.views;
      for (var i = 0; i < 40; i++) {
        life = later(life, const Duration(minutes: 1));
        final views = life.posts.single.views;
        expect(views, greaterThanOrEqualTo(lastViews));
        lastViews = views;
      }
      expect(life.posts.single.complete, isTrue);
      expect(life.posts.single.views, expected);
      expect(life.network(NetworkId.loop).followers, life.posts.single.followersGained);
    });

    test('rejects locked networks, unknown topics and missing energy without mutation', () {
      final life = newTestLife(engine);
      final locked = engine.publish(
        life,
        const PostDraft(
          networkId: NetworkId.tubecast,
          formatId: 'tubecast_long',
          topicId: 'topic_reaction',
          hookId: 'hook_question',
        ),
      );
      expect(locked.error, GameError.locked);
      expect(identical(locked.life, life), isTrue);

      final unknown = engine.publish(
        life,
        const PostDraft(networkId: NetworkId.loop, formatId: 'loop_short', topicId: 'nope', hookId: 'hook_question'),
      );
      expect(unknown.error, GameError.notFound);

      final tired = life.copyWith(energyMilli: 1000);
      expect(engine.publish(tired, loopDraft).error, GameError.insufficientEnergy);
    });

    test('locked hook is rejected until its level requirement is met', () {
      final life = newTestLife(engine);
      final r = engine.publish(
        life,
        const PostDraft(
          networkId: NetworkId.loop,
          formatId: 'loop_short',
          topicId: 'topic_prank_fail',
          hookId: 'hook_reveal',
        ),
      );
      expect(r.error, GameError.locked);
    });
  });

  group('platform independence', () {
    test('publishing on Loop never changes TubeCast or Vibe', () {
      var life = newTestLife(engine);
      final before = {
        for (final id in [NetworkId.tubecast, NetworkId.vibe]) id: life.network(id).toJson(),
      };
      for (var i = 0; i < 5; i++) {
        life = engine.publish(life, loopDraft).life;
        life = later(life, const Duration(minutes: 5));
      }
      expect(life.network(NetworkId.loop).followers, greaterThan(0));
      for (final id in [NetworkId.tubecast, NetworkId.vibe]) {
        final now = life.network(id).toJson()
          ..remove('unlocked')
          ..remove('unlockedAtSimMs');
        final then = before[id]!
          ..remove('unlocked')
          ..remove('unlockedAtSimMs');
        expect(now, then, reason: '$id must be unaffected by Loop posts');
      }
    });

    test('cross-promotion adds reach only — never followers — to another network', () {
      var life = newTestLife(engine);
      final tubecast = const PostDraft(
        networkId: NetworkId.tubecast,
        formatId: 'tubecast_long',
        topicId: 'topic_reaction',
        hookId: 'hook_question',
      );
      life = life.copyWith(
        creatorXp: 300, // level 3 → Act I → TubeCast unlocked on next post-process
        networks: {...life.networks, NetworkId.loop: life.network(NetworkId.loop).copyWith(followers: 5000)},
      );
      life = later(life, const Duration(seconds: 1));
      expect(life.network(NetworkId.tubecast).unlocked, isTrue);
      expect(life.network(NetworkId.tubecast).followers, 0);
      final withCross = engine.forecast(life, tubecast).typicalMaxViews;
      final noCross = engine
          .forecast(
            life.copyWith(
              networks: {...life.networks, NetworkId.loop: life.network(NetworkId.loop).copyWith(followers: 0)},
            ),
            tubecast,
          )
          .typicalMaxViews;
      expect(withCross, greaterThan(noCross));
    });
  });

  group('income', () {
    test('claiming twice → second claim grants 0', () {
      var life = engine.publish(newTestLife(engine), loopDraft).life;
      life = later(life, const Duration(minutes: 30));
      expect(life.pendingIncomeMinor, greaterThan(0));
      final cashBefore = life.cashMinor;

      final first = engine.claimIncome(life, 'claim-1');
      expect(first.value, life.pendingIncomeMinor);
      expect(first.life.cashMinor, cashBefore + life.pendingIncomeMinor);
      expect(first.life.pendingIncomeMinor, 0);

      final again = engine.claimIncome(first.life, 'claim-2');
      expect(again.value, 0);
      expect(again.life.cashMinor, first.life.cashMinor);

      final replay = engine.claimIncome(first.life, 'claim-1');
      expect(replay.value, 0);
      expect(replay.error, GameError.alreadyClaimed);
      expect(identical(replay.life, first.life), isTrue);
    });
  });

  group('gear', () {
    test('insufficient cash fails without any state mutation', () {
      final life = newTestLife(engine).copyWith(cashMinor: 11999);
      final snapshot = life.toJson();
      final r = engine.buyGear(life, 'gear_light_1');
      expect(r.error, GameError.insufficientCash);
      expect(identical(r.life, life), isTrue);
      expect(r.life.toJson(), snapshot);
    });

    test('purchase deducts cost once and raises post quality by the shown amount', () {
      final life = newTestLife(engine).copyWith(cashMinor: 20000);
      final before = engine.forecast(life, loopDraft).quality;
      final r = engine.buyGear(life, 'gear_light_1');
      expect(r.ok, isTrue);
      expect(r.life.cashMinor, 8000);
      expect(engine.forecast(r.life, loopDraft).quality, before + catalog.gearItem('gear_light_1')!.qualityBonus);
      expect(engine.buyGear(r.life, 'gear_light_1').error, GameError.alreadyOwned);
    });

    test('locked and disabled items cannot be bought', () {
      final rich = newTestLife(engine).copyWith(cashMinor: 100000000);
      expect(engine.buyGear(rich, 'gear_camera_1').error, GameError.locked);
      expect(engine.buyGear(rich, 'gear_editor_1').error, GameError.disabled);
    });
  });

  group('jobs, levels and skills', () {
    test('cafe shift pays, costs energy and counts', () {
      final life = newTestLife(engine);
      final r = engine.work(life, 'job_cafe');
      expect(r.life.cashMinor, life.cashMinor + 6000);
      expect(r.life.energy, life.energy - 10);
      expect(r.life.counter(Counters.jobShifts), 1);
      expect(engine.work(life, 'job_freelance_edit').error, GameError.locked);
    });

    test('level up grants a skill point; spending shows in quality', () {
      var life = newTestLife(engine).copyWith(creatorXp: 95);
      life = engine.work(life, 'job_cafe').life; // +2 xp → 97
      life = engine.publish(life, loopDraft).life; // crosses 100
      expect(engine.creatorLevel(life), 2);
      expect(life.skillPoints, 1);
      final before = engine.forecast(life, loopDraft).quality;
      final spent = engine.spendSkillPoint(life, 'editing');
      expect(spent.life.skillPoints, 0);
      expect(spent.life.skillRank('editing'), 1);
      expect(engine.forecast(spent.life, loopDraft).quality, before + 1); // 1.5 → floor 1
      expect(engine.spendSkillPoint(spent.life, 'editing').error, GameError.insufficientSkillPoints);
      expect(engine.spendSkillPoint(life, 'negotiation').error, GameError.disabled);
    });
  });

  group('acts and unlocks', () {
    test('Creator Level 3 opens Act I and unlocks TubeCast', () {
      var life = newTestLife(engine).copyWith(creatorXp: 290);
      final r = engine.publish(life, loopDraft);
      life = r.life;
      expect(life.actId, 'act1');
      expect(life.network(NetworkId.tubecast).unlocked, isTrue);
      expect(r.events.map((e) => e.name), containsAll(['story_act_complete', 'network_unlocked']));
    });

    test('next goal starts at the first post and moves on', () {
      var life = newTestLife(engine);
      expect(engine.currentGoal(life)!.goal.id, 'goal_first_post');
      life = engine.publish(life, loopDraft).life;
      expect(engine.currentGoal(life)!.goal.id, 'goal_collect');
    });

    test('unique reach is a modeled estimate below the plain sum', () {
      final life = newTestLife(engine);
      final l2 = life.copyWith(
        networks: {
          ...life.networks,
          NetworkId.loop: life.network(NetworkId.loop).copyWith(followers: 1000),
          NetworkId.tubecast: life.network(NetworkId.tubecast).copyWith(followers: 400),
        },
      );
      expect(l2.totalFollowers, 1400);
      expect(engine.estimatedUniqueReach(l2), 1000 + 400 * 350 ~/ 1000);
    });
  });
}
