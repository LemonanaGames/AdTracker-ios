import '../content/game_catalog.dart';

/// Creator Level from XP: level L needs base * (L-1) * L / 2 total XP
/// (100, 300, 600, 1000, ... with base 100).
abstract final class Progression {
  static int xpForLevel(EconomyConfig e, int level) => level <= 1 ? 0 : e.xpLevelBase * (level - 1) * level ~/ 2;

  static int levelForXp(EconomyConfig e, int xp) {
    var level = 1;
    while (level < e.maxLevel && xp >= xpForLevel(e, level + 1)) {
      level++;
    }
    return level;
  }

  /// (xp into current level, xp span of current level); span 0 at max level.
  static ({int into, int span}) levelProgress(EconomyConfig e, int xp) {
    final level = levelForXp(e, xp);
    if (level >= e.maxLevel) return (into: 0, span: 0);
    final start = xpForLevel(e, level);
    return (into: xp - start, span: xpForLevel(e, level + 1) - start);
  }
}
