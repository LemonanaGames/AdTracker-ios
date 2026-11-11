import '../model/life_state.dart';
import '../model/player_account.dart';

/// Local persistence boundary. Drift/SQLite in the app, in-memory in tests.
/// Cloud sync (M4) wraps this; the local store stays authoritative offline.
abstract interface class SaveRepository {
  Future<PlayerAccount?> loadAccount();
  Future<void> saveAccount(PlayerAccount account);
  Future<LifeState?> loadLife(String lifeId);
  Future<void> saveLife(LifeState life);
  Future<List<String>> lifeIds();
}
