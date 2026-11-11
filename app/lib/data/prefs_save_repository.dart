import 'package:shared_preferences/shared_preferences.dart';

import '../domain/model/life_state.dart';
import '../domain/model/player_account.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/save/save_codec.dart';

/// Key-value save store used by the **web preview** build (browser local
/// storage). Devices use [DriftSaveRepository] (SQLite). Same envelope format.
final class PrefsSaveRepository implements SaveRepository {
  PrefsSaveRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _account = 'save.account';
  static String _life(String id) => 'save.life.$id';
  static String _rev(String id) => 'save.rev.$id';

  @override
  Future<PlayerAccount?> loadAccount() async {
    final raw = _prefs.getString(_account);
    return raw == null ? null : SaveCodec.decodeAccount(raw);
  }

  @override
  Future<void> saveAccount(PlayerAccount account) => _prefs.setString(_account, SaveCodec.encodeAccount(account));

  @override
  Future<LifeState?> loadLife(String lifeId) async {
    final raw = _prefs.getString(_life(lifeId));
    return raw == null ? null : SaveCodec.decodeLife(raw);
  }

  @override
  Future<void> saveLife(LifeState life) async {
    if ((_prefs.getInt(_rev(life.lifeId)) ?? -1) > life.revision) return;
    await _prefs.setString(_life(life.lifeId), SaveCodec.encodeLife(life));
    await _prefs.setInt(_rev(life.lifeId), life.revision);
  }

  @override
  Future<List<String>> lifeIds() async => [
    for (final k in _prefs.getKeys())
      if (k.startsWith('save.life.')) k.substring('save.life.'.length),
  ];
}
