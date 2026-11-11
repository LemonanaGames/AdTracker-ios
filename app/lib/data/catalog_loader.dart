import 'package:flutter/services.dart' show AssetBundle;

import '../domain/content/asset_manifest.dart';
import '../domain/content/game_catalog.dart';

/// Loads bundled content. Bundled files are the local fallback that always
/// exists; Remote Config overrides (M4) will be validated before use.
abstract final class CatalogLoader {
  static const contentRoot = '../game_content/';
  static const assetManifestPath = 'assets/asset_manifest.json';

  static Future<GameCatalog> load(AssetBundle bundle) async {
    final sources = <String, String>{};
    for (final f in GameCatalog.files) {
      sources[f] = await bundle.loadString('$contentRoot$f');
    }
    return GameCatalog.fromSources(sources);
  }

  static Future<AssetManifest> loadAssets(AssetBundle bundle) async =>
      AssetManifest.parse(await bundle.loadString(assetManifestPath));
}
