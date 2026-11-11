import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/domain/content/catalog_validator.dart';
import 'package:influencer_simulator/domain/content/game_catalog.dart';
import 'package:influencer_simulator/ui/asset_art.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final assets = loadAssetManifest();

  test('game_content validates with no errors', () {
    final report = CatalogValidator.validate(catalog, assetKeys: assets.entries.keys.toSet());
    expect(report.errors, isEmpty, reason: report.toString());
  });

  test('every manifest icon resolves to a bundled vector icon', () {
    for (final e in assets.entries.entries) {
      expect(AssetArt.icons.containsKey(e.value.icon), isTrue, reason: '${e.key} → ${e.value.icon}');
    }
  });

  test('avatar presets and fixed UI asset keys exist in the manifest', () {
    for (final k in [
      for (var i = 1; i <= 6; i++) 'avatar_$i',
      'scene_bedroom',
      'npc_maya',
      'gear_light',
      'skill_creativity',
      'home_shared_room',
    ]) {
      expect(assets[k], isNotNull, reason: k);
    }
  });

  test('every content file listed in GameCatalog.files is bundled in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final f in GameCatalog.files) {
      final dir = f.substring(0, f.lastIndexOf('/') + 1);
      expect(pubspec, contains('../game_content/$dir'), reason: f);
    }
  });

  test('validator catches broken content (sanity check of the checker)', () {
    final broken = GameCatalog.fromSources({
      for (final f in GameCatalog.files) f: File('../game_content/$f').readAsStringSync(),
      'balance/goals.json':
          '{"goals":[{"id":"g","titleKey":"missing.key","route":"home",'
          '"requirement":{"type":"gearOwned","gearId":"nope"}}]}',
    });
    final report = CatalogValidator.validate(broken);
    expect(report.errors.join('\n'), allOf(contains('missing.key'), contains('nope'), contains('route')));
  });
}
