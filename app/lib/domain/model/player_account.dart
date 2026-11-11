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
  });

  final String uid;
  final int createdAtMs;
  final String? activeLifeId;
  final int lifeCount;

  /// One-time coachmarks already shown (account-level so replays stay quiet).
  final Set<String> seenTips;

  /// Server-verified entitlements mirror (always empty until M5).
  final Set<String> entitlementIds;

  PlayerAccount copyWith({String? activeLifeId, int? lifeCount, Set<String>? seenTips}) => PlayerAccount(
    uid: uid,
    createdAtMs: createdAtMs,
    activeLifeId: activeLifeId ?? this.activeLifeId,
    lifeCount: lifeCount ?? this.lifeCount,
    seenTips: seenTips ?? this.seenTips,
    entitlementIds: entitlementIds,
  );

  Map<String, Object?> toJson() => {
    'uid': uid,
    'createdAtMs': createdAtMs,
    'activeLifeId': activeLifeId,
    'lifeCount': lifeCount,
    'seenTips': seenTips.toList()..sort(),
    'entitlementIds': entitlementIds.toList()..sort(),
  };

  factory PlayerAccount.fromJson(Map<String, Object?> j) => PlayerAccount(
    uid: j['uid']! as String,
    createdAtMs: j['createdAtMs']! as int,
    activeLifeId: j['activeLifeId'] as String?,
    lifeCount: j['lifeCount'] as int? ?? 0,
    seenTips: {...((j['seenTips'] as List?) ?? const []).cast<String>()},
    entitlementIds: {...((j['entitlementIds'] as List?) ?? const []).cast<String>()},
  );
}
