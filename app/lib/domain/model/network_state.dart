import 'ids.dart';

/// Per-network persisted metrics. Networks never share followers implicitly.
final class NetworkState {
  const NetworkState({
    required this.networkId,
    required this.unlocked,
    this.unlockedAtSimMs,
    this.followers = 0,
    this.lifetimeFollowersGained = 0,
    this.lifetimeViews = 0,
    this.lifetimeLikes = 0,
    this.lifetimeComments = 0,
    this.lifetimeShares = 0,
    this.revenueLifetimeMinor = 0,
    this.last7dViews = 0,
    this.engagementRateBps = 0,
  });

  final NetworkId networkId;
  final bool unlocked;
  final int? unlockedAtSimMs;
  final int followers;
  final int lifetimeFollowersGained;
  final int lifetimeViews;
  final int lifetimeLikes;
  final int lifetimeComments;
  final int lifetimeShares;
  final int revenueLifetimeMinor;

  /// Cached projection over the rolling engagement window (recomputed on tick).
  final int last7dViews;

  /// (likes + comments + shares) / views over the rolling window, in basis points.
  final int engagementRateBps;

  NetworkState copyWith({
    bool? unlocked,
    int? unlockedAtSimMs,
    int? followers,
    int? lifetimeFollowersGained,
    int? lifetimeViews,
    int? lifetimeLikes,
    int? lifetimeComments,
    int? lifetimeShares,
    int? revenueLifetimeMinor,
    int? last7dViews,
    int? engagementRateBps,
  }) => NetworkState(
    networkId: networkId,
    unlocked: unlocked ?? this.unlocked,
    unlockedAtSimMs: unlockedAtSimMs ?? this.unlockedAtSimMs,
    followers: followers ?? this.followers,
    lifetimeFollowersGained: lifetimeFollowersGained ?? this.lifetimeFollowersGained,
    lifetimeViews: lifetimeViews ?? this.lifetimeViews,
    lifetimeLikes: lifetimeLikes ?? this.lifetimeLikes,
    lifetimeComments: lifetimeComments ?? this.lifetimeComments,
    lifetimeShares: lifetimeShares ?? this.lifetimeShares,
    revenueLifetimeMinor: revenueLifetimeMinor ?? this.revenueLifetimeMinor,
    last7dViews: last7dViews ?? this.last7dViews,
    engagementRateBps: engagementRateBps ?? this.engagementRateBps,
  );

  Map<String, Object?> toJson() => {
    'networkId': networkId.name,
    'unlocked': unlocked,
    'unlockedAtSimMs': unlockedAtSimMs,
    'followers': followers,
    'lifetimeFollowersGained': lifetimeFollowersGained,
    'lifetimeViews': lifetimeViews,
    'lifetimeLikes': lifetimeLikes,
    'lifetimeComments': lifetimeComments,
    'lifetimeShares': lifetimeShares,
    'revenueLifetimeMinor': revenueLifetimeMinor,
    'last7dViews': last7dViews,
    'engagementRateBps': engagementRateBps,
  };

  factory NetworkState.fromJson(Map<String, Object?> j) => NetworkState(
    networkId: NetworkId.parse(j['networkId']! as String),
    unlocked: j['unlocked']! as bool,
    unlockedAtSimMs: j['unlockedAtSimMs'] as int?,
    followers: j['followers'] as int? ?? 0,
    lifetimeFollowersGained: j['lifetimeFollowersGained'] as int? ?? 0,
    lifetimeViews: j['lifetimeViews'] as int? ?? 0,
    lifetimeLikes: j['lifetimeLikes'] as int? ?? 0,
    lifetimeComments: j['lifetimeComments'] as int? ?? 0,
    lifetimeShares: j['lifetimeShares'] as int? ?? 0,
    revenueLifetimeMinor: j['revenueLifetimeMinor'] as int? ?? 0,
    last7dViews: j['last7dViews'] as int? ?? 0,
    engagementRateBps: j['engagementRateBps'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) => other is NetworkState && _mapEquals(toJson(), other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);
}

bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}
