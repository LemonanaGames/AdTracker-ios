import 'avatar.dart';
import 'content_post.dart';
import 'ids.dart';
import 'modifier.dart';
import 'network_state.dart';

/// Complete state of one life. Immutable; the engine returns new instances.
///
/// Money is integer minor units (cents). Energy/burnout are stored in milli-
/// points so fractional regeneration is never lost to rounding.
final class LifeState {
  const LifeState({
    required this.lifeId,
    required this.lifeNumber,
    required this.seed,
    required this.status,
    required this.actId,
    required this.avatar,
    required this.creatorXp,
    required this.cashMinor,
    required this.pendingIncomeMinor,
    required this.skillPoints,
    required this.skills,
    required this.networks,
    required this.posts,
    required this.nextPostSerial,
    required this.gearIds,
    required this.homeId,
    required this.energyMilli,
    required this.burnoutMilli,
    required this.audienceTrust,
    required this.integrity,
    required this.relationships,
    required this.flags,
    required this.modifiers,
    required this.completedEventIds,
    required this.counters,
    required this.recentClaimIds,
    required this.simTimeMs,
    required this.lastRealMs,
    required this.createdAtMs,
    required this.contentVersion,
    required this.revision,
  });

  final String lifeId;
  final int lifeNumber;
  final int seed;
  final LifeStatus status;
  final String actId;
  final Avatar avatar;
  final int creatorXp;
  final int cashMinor;

  /// Earned post revenue waiting to be collected (claim moves it to cash).
  final int pendingIncomeMinor;
  final int skillPoints;
  final Map<String, int> skills;
  final Map<NetworkId, NetworkState> networks;
  final List<ContentPost> posts;
  final int nextPostSerial;
  final Set<String> gearIds;
  final String homeId;
  final int energyMilli;
  final int burnoutMilli;
  final int audienceTrust;
  final int integrity;
  final Map<String, int> relationships;
  final Set<String> flags;
  final List<ActiveModifier> modifiers;
  final Set<String> completedEventIds;
  final Map<String, int> counters;

  /// Most recent claim/grant IDs (dedupe window for idempotent grants).
  final List<String> recentClaimIds;

  /// Simulated game time since the life started.
  final int simTimeMs;

  /// Last wall-clock instant the simulation was advanced to.
  final int lastRealMs;
  final int createdAtMs;
  final String contentVersion;

  /// Incremented on every accepted state change (sync/conflict detection).
  final int revision;

  int get energy => energyMilli ~/ 1000;
  int get burnout => burnoutMilli ~/ 1000;
  int counter(String key) => counters[key] ?? 0;
  NetworkState network(NetworkId id) => networks[id]!;
  int skillRank(String id) => skills[id] ?? 0;

  int get totalFollowers => networks.values.fold(0, (sum, n) => sum + n.followers);

  LifeState copyWith({
    LifeStatus? status,
    String? actId,
    int? creatorXp,
    int? cashMinor,
    int? pendingIncomeMinor,
    int? skillPoints,
    Map<String, int>? skills,
    Map<NetworkId, NetworkState>? networks,
    List<ContentPost>? posts,
    int? nextPostSerial,
    Set<String>? gearIds,
    String? homeId,
    int? energyMilli,
    int? burnoutMilli,
    int? audienceTrust,
    int? integrity,
    Map<String, int>? relationships,
    Set<String>? flags,
    List<ActiveModifier>? modifiers,
    Set<String>? completedEventIds,
    Map<String, int>? counters,
    List<String>? recentClaimIds,
    int? simTimeMs,
    int? lastRealMs,
    int? revision,
  }) => LifeState(
    lifeId: lifeId,
    lifeNumber: lifeNumber,
    seed: seed,
    status: status ?? this.status,
    actId: actId ?? this.actId,
    avatar: avatar,
    creatorXp: creatorXp ?? this.creatorXp,
    cashMinor: cashMinor ?? this.cashMinor,
    pendingIncomeMinor: pendingIncomeMinor ?? this.pendingIncomeMinor,
    skillPoints: skillPoints ?? this.skillPoints,
    skills: skills ?? this.skills,
    networks: networks ?? this.networks,
    posts: posts ?? this.posts,
    nextPostSerial: nextPostSerial ?? this.nextPostSerial,
    gearIds: gearIds ?? this.gearIds,
    homeId: homeId ?? this.homeId,
    energyMilli: energyMilli ?? this.energyMilli,
    burnoutMilli: burnoutMilli ?? this.burnoutMilli,
    audienceTrust: audienceTrust ?? this.audienceTrust,
    integrity: integrity ?? this.integrity,
    relationships: relationships ?? this.relationships,
    flags: flags ?? this.flags,
    modifiers: modifiers ?? this.modifiers,
    completedEventIds: completedEventIds ?? this.completedEventIds,
    counters: counters ?? this.counters,
    recentClaimIds: recentClaimIds ?? this.recentClaimIds,
    simTimeMs: simTimeMs ?? this.simTimeMs,
    lastRealMs: lastRealMs ?? this.lastRealMs,
    createdAtMs: createdAtMs,
    contentVersion: contentVersion,
    revision: revision ?? this.revision,
  );

  Map<String, Object?> toJson() => {
    'lifeId': lifeId,
    'lifeNumber': lifeNumber,
    'seed': seed,
    'status': status.name,
    'actId': actId,
    'avatar': avatar.toJson(),
    'creatorXp': creatorXp,
    'cashMinor': cashMinor,
    'pendingIncomeMinor': pendingIncomeMinor,
    'skillPoints': skillPoints,
    'skills': _sorted(skills),
    'networks': [
      for (final id in NetworkId.values)
        if (networks[id] != null) networks[id]!.toJson(),
    ],
    'posts': [for (final p in posts) p.toJson()],
    'nextPostSerial': nextPostSerial,
    'gearIds': gearIds.toList()..sort(),
    'homeId': homeId,
    'energyMilli': energyMilli,
    'burnoutMilli': burnoutMilli,
    'audienceTrust': audienceTrust,
    'integrity': integrity,
    'relationships': _sorted(relationships),
    'flags': flags.toList()..sort(),
    'modifiers': [for (final m in modifiers) m.toJson()],
    'completedEventIds': completedEventIds.toList()..sort(),
    'counters': _sorted(counters),
    'recentClaimIds': recentClaimIds,
    'simTimeMs': simTimeMs,
    'lastRealMs': lastRealMs,
    'createdAtMs': createdAtMs,
    'contentVersion': contentVersion,
    'revision': revision,
  };

  factory LifeState.fromJson(Map<String, Object?> j) {
    final networks = <NetworkId, NetworkState>{
      for (final raw in (j['networks']! as List).cast<Map<String, Object?>>())
        NetworkId.parse(raw['networkId']! as String): NetworkState.fromJson(raw),
    };
    return LifeState(
      lifeId: j['lifeId']! as String,
      lifeNumber: j['lifeNumber']! as int,
      seed: j['seed']! as int,
      status: LifeStatus.parse(j['status']! as String),
      actId: j['actId']! as String,
      avatar: Avatar.fromJson((j['avatar']! as Map).cast<String, Object?>()),
      creatorXp: j['creatorXp']! as int,
      cashMinor: j['cashMinor']! as int,
      pendingIncomeMinor: j['pendingIncomeMinor'] as int? ?? 0,
      skillPoints: j['skillPoints']! as int,
      skills: _intMap(j['skills']),
      networks: networks,
      posts: [for (final raw in (j['posts']! as List).cast<Map<String, Object?>>()) ContentPost.fromJson(raw)],
      nextPostSerial: j['nextPostSerial']! as int,
      gearIds: {...(j['gearIds']! as List).cast<String>()},
      homeId: j['homeId']! as String,
      energyMilli: j['energyMilli']! as int,
      burnoutMilli: j['burnoutMilli']! as int,
      audienceTrust: j['audienceTrust']! as int,
      integrity: j['integrity']! as int,
      relationships: _intMap(j['relationships']),
      flags: {...((j['flags'] as List?) ?? const []).cast<String>()},
      modifiers: [
        for (final raw in ((j['modifiers'] as List?) ?? const []).cast<Map<String, Object?>>())
          ActiveModifier.fromJson(raw),
      ],
      completedEventIds: {...((j['completedEventIds'] as List?) ?? const []).cast<String>()},
      counters: _intMap(j['counters']),
      recentClaimIds: [...((j['recentClaimIds'] as List?) ?? const []).cast<String>()],
      simTimeMs: j['simTimeMs']! as int,
      lastRealMs: j['lastRealMs']! as int,
      createdAtMs: j['createdAtMs']! as int,
      contentVersion: j['contentVersion']! as String,
      revision: j['revision']! as int,
    );
  }
}

Map<String, int> _intMap(Object? raw) => {
  for (final e in ((raw as Map?) ?? const {}).entries) e.key as String: e.value as int,
};

Map<String, int> _sorted(Map<String, int> m) => {for (final k in (m.keys.toList()..sort())) k: m[k]!};
