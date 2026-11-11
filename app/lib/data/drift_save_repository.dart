import 'package:drift/drift.dart';

import '../domain/model/life_state.dart';
import '../domain/model/player_account.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/save/save_codec.dart';
import 'app_database.dart';

final class DriftSaveRepository implements SaveRepository {
  DriftSaveRepository(this._db, {int Function()? nowMs})
    : _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const _accountId = 'local';
  final AppDatabase _db;
  final int Function() _nowMs;

  @override
  Future<PlayerAccount?> loadAccount() async {
    final row = await (_db.select(_db.accounts)..where((t) => t.id.equals(_accountId))).getSingleOrNull();
    return row == null ? null : SaveCodec.decodeAccount(row.payload);
  }

  @override
  Future<void> saveAccount(PlayerAccount account) => _db
      .into(_db.accounts)
      .insertOnConflictUpdate(
        AccountsCompanion.insert(id: _accountId, payload: SaveCodec.encodeAccount(account), updatedAtMs: _nowMs()),
      );

  @override
  Future<LifeState?> loadLife(String lifeId) async {
    final row = await (_db.select(_db.lives)..where((t) => t.lifeId.equals(lifeId))).getSingleOrNull();
    return row == null ? null : SaveCodec.decodeLife(row.payload);
  }

  @override
  Future<void> saveLife(LifeState life) {
    final row = LivesCompanion.insert(
      lifeId: life.lifeId,
      revision: life.revision,
      status: life.status.name,
      payload: SaveCodec.encodeLife(life),
      updatedAtMs: _nowMs(),
    );
    // Never let an older revision overwrite a newer one.
    return _db
        .into(_db.lives)
        .insert(
          row,
          onConflict: DoUpdate((_) => row, where: (old) => old.revision.isSmallerOrEqualValue(life.revision)),
        );
  }

  @override
  Future<List<String>> lifeIds() async {
    final rows = await _db.select(_db.lives).get();
    return [for (final r in rows) r.lifeId];
  }
}
