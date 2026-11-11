import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/data/catalog_loader.dart';
import 'package:influencer_simulator/domain/content/catalog_validator.dart';

/// Loads content through the real Flutter asset bundle (what the app does on
/// device), proving pubspec bundles every game_content file and the manifest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog + asset manifest load from the app bundle', () async {
    final catalog = await CatalogLoader.load(rootBundle);
    final assets = await CatalogLoader.loadAssets(rootBundle);
    expect(catalog.networks, hasLength(3));
    expect(CatalogValidator.validate(catalog, assetKeys: assets.entries.keys.toSet()).errors, isEmpty);
  });
}
