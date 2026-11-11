/// Local feature-flag defaults. Remote Config overrides arrive in M4; every
/// flag must keep a safe default here so the app works fully offline.
abstract final class FeatureFlags {
  static const Map<String, bool> defaults = {
    'faceless_strategy_enabled': false,
    'sponsors_enabled': false,
    'monetization_enabled': false,
    'cloud_sync_enabled': false,
    'media_import_enabled': false,
  };

  static bool isEnabled(String key, [Map<String, bool> overrides = const {}]) =>
      overrides[key] ?? defaults[key] ?? false;
}
