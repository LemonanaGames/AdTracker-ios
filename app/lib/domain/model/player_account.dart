/// Account-level state (survives new lives). In M1 the uid is a local UUID;
/// M4 links it to Firebase Anonymous Auth / Sign in with Apple.
final class PlayerAccount {
  const PlayerAccount({
    required this.uid,
    required this.createdAtMs,
    this.activeLifeId,
    this.lifeCount = 0,
    this.seenTips = const {},
    this.entitlementIds = const {},
    this.soundOn = true,
    this.hapticsOn = true,
    this.notificationsOptIn,
    this.sessionHours = const [],
  });

  final String uid;
  final int createdAtMs;
  final String? activeLifeId;
  final int lifeCount;

  /// One-time coachmarks already shown (account-level so replays stay quiet).
  final Set<String> seenTips;

  /// Server-verified entitlements mirror (always empty until M5).
  final Set<String> entitlementIds;

  final bool soundOn;
  final bool hapticsOn;

  /// null = never asked; true/false = the player's explicit answer.
  final bool? notificationsOptIn;

  /// Local hours (0–23) of the most recent session starts (max 7). Used to
  /// time the single daily reminder to when this player actually plays.
  final List<int> sessionHours;

  PlayerAccount copyWith({
    String? activeLifeId,
    int? lifeCount,
    Set<String>? seenTips,
    bool? soundOn,
    bool? hapticsOn,
    bool? notificationsOptIn,
    List<int>? sessionHours,
  }) => PlayerAccount(
    uid: uid,
    createdAtMs: createdAtMs,
    activeLifeId: activeLifeId ?? this.activeLifeId,
    lifeCount: lifeCount ?? this.lifeCount,
    seenTips: seenTips ?? this.seenTips,
    entitlementIds: entitlementIds,
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    notificationsOptIn: notificationsOptIn ?? this.notificationsOptIn,
    sessionHours: sessionHours ?? this.sessionHours,
  );

  /// Records a session start hour, keeping the last 7.
  PlayerAccount withSessionHour(int hour) {
    final hours = [...sessionHours, hour];
    return copyWith(sessionHours: hours.length > 7 ? hours.sublist(hours.length - 7) : hours);
  }

  Map<String, Object?> toJson() => {
    'uid': uid,
    'createdAtMs': createdAtMs,
    'activeLifeId': activeLifeId,
    'lifeCount': lifeCount,
    'seenTips': seenTips.toList()..sort(),
    'entitlementIds': entitlementIds.toList()..sort(),
    'soundOn': soundOn,
    'hapticsOn': hapticsOn,
    'notificationsOptIn': notificationsOptIn,
    'sessionHours': sessionHours,
  };

  factory PlayerAccount.fromJson(Map<String, Object?> j) => PlayerAccount(
    uid: j['uid']! as String,
    createdAtMs: j['createdAtMs']! as int,
    activeLifeId: j['activeLifeId'] as String?,
    lifeCount: j['lifeCount'] as int? ?? 0,
    seenTips: {...((j['seenTips'] as List?) ?? const []).cast<String>()},
    entitlementIds: {...((j['entitlementIds'] as List?) ?? const []).cast<String>()},
    soundOn: j['soundOn']! as bool,
    hapticsOn: j['hapticsOn']! as bool,
    notificationsOptIn: j['notificationsOptIn'] as bool?,
    sessionHours: [...((j['sessionHours'] as List?) ?? const []).cast<int>()],
  );
}
