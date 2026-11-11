import '../domain/engine/game_engine.dart';
import '../domain/model/life_state.dart';
import '../domain/model/player_account.dart';

/// Read-only projection the UI watches.
final class GameSession {
  const GameSession({required this.account, this.life, this.awaySummary, this.loadError});

  final PlayerAccount account;
  final LifeState? life;

  /// Shown once after returning from a meaningful absence.
  final AdvanceSummary? awaySummary;

  /// Set when an existing save could not be read (it is left untouched).
  final String? loadError;

  bool get hasLife => life != null;

  GameSession copyWith({
    PlayerAccount? account,
    LifeState? life,
    AdvanceSummary? awaySummary,
    bool clearAway = false,
    bool clearError = false,
  }) => GameSession(
    account: account ?? this.account,
    life: life ?? this.life,
    awaySummary: clearAway ? null : (awaySummary ?? this.awaySummary),
    loadError: clearError ? null : loadError,
  );
}
