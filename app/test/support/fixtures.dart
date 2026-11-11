import 'dart:io';

import 'package:influencer_simulator/domain/content/asset_manifest.dart';
import 'package:influencer_simulator/domain/content/game_catalog.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/model/avatar.dart';
import 'package:influencer_simulator/domain/model/life_state.dart';

/// Loads the real game_content/ from disk (tests run with cwd = app/).
GameCatalog loadCatalog() {
  final root = Directory('../game_content');
  return GameCatalog.fromSources({for (final f in GameCatalog.files) f: File('${root.path}/$f').readAsStringSync()});
}

AssetManifest loadAssetManifest() => AssetManifest.parse(File('assets/asset_manifest.json').readAsStringSync());

const t0 = 1_800_000_000_000; // fixed wall clock for tests

const testAvatar = Avatar(displayName: 'Test', handle: '@test', nicheId: 'comedy', presetId: 'avatar_1');

LifeState newTestLife(GameEngine engine, {String lifeId = 'life-test-1', String niche = 'comedy'}) => engine.newLife(
  lifeId: lifeId,
  lifeNumber: 1,
  avatar: Avatar(displayName: 'Test', handle: '@test', nicheId: niche, presetId: 'avatar_1'),
  nowMs: t0,
);
