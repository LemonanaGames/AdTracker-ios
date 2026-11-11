import 'dart:convert';

/// Visual asset registry (app/assets/asset_manifest.json). Every content
/// `assetKey` must resolve here; M1 entries are all vector placeholders.
final class AssetManifest {
  const AssetManifest(this.entries);

  factory AssetManifest.parse(String raw) {
    final json = (jsonDecode(raw) as Map).cast<String, Object?>();
    final assets = (json['assets']! as Map).cast<String, Object?>();
    return AssetManifest({
      for (final e in assets.entries) e.key: AssetEntry.fromJson((e.value! as Map).cast<String, Object?>()),
    });
  }

  final Map<String, AssetEntry> entries;

  AssetEntry? operator [](String key) => entries[key];
}

final class AssetEntry {
  const AssetEntry({required this.status, required this.icon, required this.colorHex, this.file, this.initials});

  factory AssetEntry.fromJson(Map<String, Object?> j) => AssetEntry(
    status: j['status']! as String,
    icon: j['icon']! as String,
    colorHex: j['color']! as String,
    file: j['file'] as String?,
    initials: j['initials'] as String?,
  );

  /// "placeholder" or "final".
  final String status;
  final String icon;
  final String colorHex;
  final String? file;
  final String? initials;

  bool get isPlaceholder => status != 'final';
}
