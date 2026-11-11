// Validates game_content/ + the asset manifest. Run from app/:
//   dart run tool/validate_content.dart
// Exit code 1 on any error (used by CI).
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:influencer_simulator/domain/content/asset_manifest.dart';
import 'package:influencer_simulator/domain/content/catalog_validator.dart';
import 'package:influencer_simulator/domain/content/game_catalog.dart';

void main() {
  final GameCatalog catalog;
  try {
    catalog = GameCatalog.fromSources({
      for (final f in GameCatalog.files) f: File('../game_content/$f').readAsStringSync(),
    });
  } on Object catch (e) {
    print('ERROR   could not parse content: $e');
    exit(1);
  }
  final assets = AssetManifest.parse(File('assets/asset_manifest.json').readAsStringSync());
  final report = CatalogValidator.validate(catalog, assetKeys: assets.entries.keys.toSet());
  if (report.errors.isNotEmpty || report.warnings.isNotEmpty) print(report);
  print(
    report.ok
        ? 'OK  content ${catalog.contentVersion}: ${report.warnings.length} warning(s)'
        : 'FAILED: ${report.errors.length} error(s)',
  );
  exit(report.ok ? 0 : 1);
}
