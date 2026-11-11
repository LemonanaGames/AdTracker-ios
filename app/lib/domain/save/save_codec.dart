import 'dart:convert';

import '../model/life_state.dart';
import '../model/player_account.dart';

typedef Json = Map<String, Object?>;
typedef Migration = Json Function(Json payload);

final class SaveFormatException implements Exception {
  const SaveFormatException(this.message);
  final String message;
  @override
  String toString() => 'SaveFormatException: $message';
}

/// Versioned save envelope: `{"schemaVersion": n, "payload": {...}}`.
///
/// Migrations are pure `vN -> vN+1` payload transforms applied in order, so
/// any old save upgrades deterministically. A save from a *newer* app version
/// is rejected (never silently truncated).
abstract final class SaveCodec {
  static const lifeSchemaVersion = 1;
  static const accountSchemaVersion = 2;

  /// `fromVersion -> transform` for life payloads. Add entries, never edit.
  static final Map<int, Migration> lifeMigrations = {};
  static final Map<int, Migration> accountMigrations = {
    // v1 → v2: feedback + notification preferences (defaults: on / not asked).
    1: (p) => {...p, 'soundOn': true, 'hapticsOn': true, 'notificationsOptIn': null, 'sessionHours': <int>[]},
  };

  static String encodeLife(LifeState life) =>
      jsonEncode({'schemaVersion': lifeSchemaVersion, 'payload': life.toJson()});

  static LifeState decodeLife(String raw) =>
      LifeState.fromJson(upgrade(raw, current: lifeSchemaVersion, migrations: lifeMigrations));

  static String encodeAccount(PlayerAccount a) =>
      jsonEncode({'schemaVersion': accountSchemaVersion, 'payload': a.toJson()});

  static PlayerAccount decodeAccount(String raw) =>
      PlayerAccount.fromJson(upgrade(raw, current: accountSchemaVersion, migrations: accountMigrations));

  /// Parses an envelope and migrates its payload up to [current].
  static Json upgrade(String raw, {required int current, required Map<int, Migration> migrations}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw SaveFormatException('Corrupt save: ${e.message}');
    }
    if (decoded is! Map) throw const SaveFormatException('Save is not an object');
    final version = decoded['schemaVersion'];
    final payload = decoded['payload'];
    if (version is! int || payload is! Map) throw const SaveFormatException('Missing envelope fields');
    if (version > current) {
      throw SaveFormatException('Save schema v$version is newer than supported v$current');
    }
    var data = payload.cast<String, Object?>();
    for (var v = version; v < current; v++) {
      final step = migrations[v];
      if (step == null) throw SaveFormatException('No migration from v$v');
      data = step(data);
    }
    return data;
  }
}
