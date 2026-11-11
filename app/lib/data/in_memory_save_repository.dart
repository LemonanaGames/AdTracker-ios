import '../domain/model/life_state.dart';
import '../domain/model/player_account.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/save/save_codec.dart';

/// Test/dev repository. Stores encoded envelopes so it exercises the codec.
final class InMemorySaveRepository implements SaveRepository {
  String? _account;
  final Map<String, String> _lives = {};
  final Map<String, int> _revisions = {};

  @override
  Future<PlayerAccount?> loadAccount() async => _account == null ? null : SaveCodec.decodeAccount(_account!);

  @override
  Future<void> saveAccount(PlayerAccount account) async => _account = SaveCodec.encodeAccount(account);

  @override
  Future<LifeState?> loadLife(String lifeId) async {
    final raw = _lives[lifeId];
    return raw == null ? null : SaveCodec.decodeLife(raw);
  }

  @override
  Future<void> saveLife(LifeState life) async {
    if ((_revisions[life.lifeId] ?? -1) > life.revision) return;
    _revisions[life.lifeId] = life.revision;
    _lives[life.lifeId] = SaveCodec.encodeLife(life);
  }

  @override
  Future<List<String>> lifeIds() async => _lives.keys.toList();
}
