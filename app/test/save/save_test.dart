import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/data/app_database.dart';
import 'package:influencer_simulator/data/drift_save_repository.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';
import 'package:influencer_simulator/domain/model/life_state.dart';
import 'package:influencer_simulator/domain/model/player_account.dart';
import 'package:influencer_simulator/domain/save/save_codec.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);

  LifeState playedLife() {
    var life = newTestLife(engine);
    const d = PostDraft(
      networkId: NetworkId.loop,
      formatId: 'loop_short',
      topicId: 'topic_first_challenge',
      hookId: 'hook_question',
    );
    life = engine.publish(life, d).life;
    life = engine.advanceTo(life, t0 + 5 * 60 * 1000).life;
    life = engine.work(life, 'job_cafe').life;
    life = engine.buyGear(life, 'gear_light_1').life;
    life = engine.claimIncome(life, 'c1').life;
    return engine.publish(life, d).life;
  }

  group('SaveCodec', () {
    test('life round-trips exactly through the versioned envelope', () {
      final life = playedLife();
      final encoded = SaveCodec.encodeLife(life);
      expect((jsonDecode(encoded) as Map)['schemaVersion'], SaveCodec.lifeSchemaVersion);
      final decoded = SaveCodec.decodeLife(encoded);
      expect(decoded.toJson(), life.toJson());
      // And the decoded life keeps simulating identically.
      expect(
        engine.advanceTo(decoded, t0 + 20 * 60 * 1000).life.toJson(),
        engine.advanceTo(life, t0 + 20 * 60 * 1000).life.toJson(),
      );
    });

    test('older schema versions migrate step by step', () {
      // Simulate a hypothetical v0 save that lacked `pendingIncomeMinor`
      // and stored cash in whole dollars.
      final life = playedLife();
      final v0 = life.toJson()
        ..remove('pendingIncomeMinor')
        ..['cashDollars'] = life.cashMinor ~/ 100
        ..remove('cashMinor');
      final raw = jsonEncode({'schemaVersion': 0, 'payload': v0});
      final migrated = SaveCodec.upgrade(
        raw,
        current: 1,
        migrations: {
          0: (p) =>
              {...p, 'cashMinor': (p['cashDollars']! as int) * 100, 'pendingIncomeMinor': 0}..remove('cashDollars'),
        },
      );
      final restored = LifeState.fromJson(migrated);
      expect(restored.cashMinor, life.cashMinor ~/ 100 * 100);
      expect(restored.pendingIncomeMinor, 0);
      expect(restored.posts.length, life.posts.length);
    });

    test('newer, corrupt or incomplete saves are rejected, never truncated', () {
      expect(
        () => SaveCodec.decodeLife(jsonEncode({'schemaVersion': 99, 'payload': <String, Object?>{}})),
        throwsA(isA<SaveFormatException>()),
      );
      expect(() => SaveCodec.decodeLife('{not json'), throwsA(isA<SaveFormatException>()));
      expect(() => SaveCodec.decodeLife('[]'), throwsA(isA<SaveFormatException>()));
      expect(
        () => SaveCodec.upgrade(
          jsonEncode({'schemaVersion': 0, 'payload': <String, Object?>{}}),
          current: 1,
          migrations: {},
        ),
        throwsA(isA<SaveFormatException>()),
      );
    });

    test('account round-trips', () {
      const a = PlayerAccount(
        uid: 'local-1',
        createdAtMs: 5,
        activeLifeId: 'L',
        lifeCount: 2,
        seenTips: {'tip_followers'},
      );
      final b = SaveCodec.decodeAccount(SaveCodec.encodeAccount(a));
      expect(b.toJson(), a.toJson());
    });
  });

  group('DriftSaveRepository (SQLite in memory)', () {
    late AppDatabase db;
    late DriftSaveRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftSaveRepository(db, nowMs: () => t0);
    });
    tearDown(() => db.close());

    test('save → load returns the same life and account', () async {
      final life = playedLife();
      await repo.saveLife(life);
      await repo.saveAccount(PlayerAccount(uid: 'u', createdAtMs: t0, activeLifeId: life.lifeId, lifeCount: 1));
      final loaded = await repo.loadLife(life.lifeId);
      expect(loaded!.toJson(), life.toJson());
      expect((await repo.loadAccount())!.activeLifeId, life.lifeId);
      expect(await repo.lifeIds(), [life.lifeId]);
    });

    test('a stale (older revision) write never overwrites a newer one', () async {
      final older = playedLife();
      final newer = engine.advanceTo(older, t0 + 60 * 60 * 1000).life;
      expect(newer.revision, greaterThan(older.revision));
      await repo.saveLife(newer);
      await repo.saveLife(older);
      expect((await repo.loadLife(older.lifeId))!.revision, newer.revision);
    });

    test('missing rows load as null', () async {
      expect(await repo.loadLife('nope'), isNull);
      expect(await repo.loadAccount(), isNull);
    });
  });
}
