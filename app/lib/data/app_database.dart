import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Account row (single local account, id "local" until M4 auth).
class Accounts extends Table {
  TextColumn get id => text()();

  /// SaveCodec envelope (JSON with its own schemaVersion).
  TextColumn get payload => text()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One row per life. The payload is a versioned SaveCodec envelope; the
/// revision column guards against stale out-of-order writes.
class Lives extends Table {
  TextColumn get lifeId => text()();
  IntColumn get revision => integer()();
  TextColumn get status => text()();
  TextColumn get payload => text()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {lifeId};
}

@DriftDatabase(tables: [Accounts, Lives])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// On-device database in the app's documents directory (local only; it is
  /// not uploaded anywhere — cloud sync is a separate M4 service).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'influencer_simulator'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());
}
