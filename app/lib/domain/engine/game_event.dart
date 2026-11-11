/// Domain event emitted by the engine; the app maps these 1:1 to analytics
/// names from docs/analytics_taxonomy.md and to UI celebrations.
final class GameEvent {
  const GameEvent(this.name, [this.params = const {}]);
  final String name;
  final Map<String, Object> params;

  @override
  String toString() => 'GameEvent($name, $params)';
}

enum GameError {
  locked,
  notFound,
  disabled,
  insufficientCash,
  insufficientEnergy,
  insufficientSkillPoints,
  alreadyOwned,
  maxRank,
  alreadyCompleted,
  alreadyClaimed,
  requirementsNotMet,
  invalidInput,
}
