/// Stable identifiers shared by content, saves and analytics.
library;

/// The three simulated (fictional) networks. Values are persisted: never rename.
enum NetworkId {
  loop,
  tubecast,
  vibe;

  static NetworkId parse(String raw) =>
      NetworkId.values.firstWhere((n) => n.name == raw, orElse: () => throw FormatException('Unknown network "$raw"'));
}

enum LifeStatus {
  active,
  completed,
  archived;

  static LifeStatus parse(String raw) =>
      LifeStatus.values.firstWhere((s) => s.name == raw, orElse: () => LifeStatus.active);
}

/// Creator persona is cosmetic in the MVP (GDD B5): identical gameplay multipliers.
enum CreatorPersona {
  onCamera,
  faceless;

  static CreatorPersona parse(String raw) =>
      CreatorPersona.values.firstWhere((s) => s.name == raw, orElse: () => CreatorPersona.onCamera);
}

/// Counter keys stored in [LifeState.counters].
abstract final class Counters {
  static const postsPublished = 'postsPublished';
  static const jobShifts = 'jobShifts';
  static const lifetimeClaimedMinor = 'lifetimeClaimedMinor';
  static const lifetimeEarnedMinor = 'lifetimeEarnedMinor';

  static String postsOn(NetworkId id) => '${id.name}Posts';
}
