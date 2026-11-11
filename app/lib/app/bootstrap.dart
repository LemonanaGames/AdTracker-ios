import '../core/clock.dart';
import '../domain/engine/game_engine.dart';
import '../domain/model/life_state.dart';
import '../domain/model/player_account.dart';
import '../domain/repositories/save_repository.dart';
import '../domain/save/save_codec.dart';
import 'game_session.dart';

/// Loads (or creates) the local account and active life, then catches the
/// simulation up to now (capped offline progress). Runs before the first frame.
Future<GameSession> loadSession({
  required SaveRepository repo,
  required GameEngine engine,
  required Clock clock,
  required String Function() newId,
}) async {
  var account = await repo.loadAccount();
  if (account == null) {
    account = PlayerAccount(uid: 'local-${newId()}', createdAtMs: clock.nowMs());
    await repo.saveAccount(account);
  }

  final lifeId = account.activeLifeId;
  if (lifeId == null) return GameSession(account: account);

  LifeState? life;
  try {
    life = await repo.loadLife(lifeId);
  } on SaveFormatException catch (e) {
    // Never overwrite an unreadable save; the player can start fresh and the
    // old row stays on disk for recovery.
    return GameSession(account: account, loadError: e.message);
  }
  if (life == null) return GameSession(account: account);

  final r = engine.advanceTo(life, clock.nowMs());
  final summary = r.value!;
  final minMs = engine.catalog.economy.minOfflineSummarySeconds * 1000;
  final meaningful = summary.realDeltaMs >= minMs && (summary.viewsGained > 0 || summary.incomeGainedMinor > 0);
  await repo.saveLife(r.life);
  return GameSession(account: account, life: r.life, awaySummary: meaningful ? summary : null);
}
