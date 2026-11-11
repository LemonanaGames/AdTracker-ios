import 'ids.dart';

/// One simulated publication. Everything needed to recompute its cumulative
/// stats is snapshotted at publish time, so crediting is a pure function of
/// elapsed sim time (idempotent, no double counting).
final class ContentPost {
  const ContentPost({
    required this.postId,
    required this.networkId,
    required this.formatId,
    required this.topicId,
    required this.hookId,
    required this.publishedAtSimMs,
    required this.qualityScore,
    required this.trendPermille,
    required this.viralTier,
    required this.viralPermille,
    required this.expectedViews,
    required this.followRatePpm,
    required this.likeBps,
    required this.commentBps,
    required this.shareBps,
    required this.rpmMinor,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.followersGained = 0,
    this.revenueMinor = 0,
    this.complete = false,
    this.qualityBreakdown = const {},
    this.mediaLocalKey,
  });

  final String postId;
  final NetworkId networkId;
  final String formatId;
  final String topicId;
  final String hookId;
  final int publishedAtSimMs;

  final int qualityScore;
  final int trendPermille;
  final int viralTier;
  final int viralPermille;
  final int expectedViews;
  final int followRatePpm;
  final int likeBps;
  final int commentBps;
  final int shareBps;
  final int rpmMinor;

  // Credited so far.
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int followersGained;
  final int revenueMinor;
  final bool complete;

  /// Component → points, for the "why is my quality X" breakdown.
  final Map<String, int> qualityBreakdown;

  /// Local-only media preview reference (never synced). Unused until M6.
  final String? mediaLocalKey;

  int get interactions => likes + comments + shares;

  ContentPost credited({
    required int views,
    required int likes,
    required int comments,
    required int shares,
    required int followersGained,
    required int revenueMinor,
    required bool complete,
  }) => ContentPost(
    postId: postId,
    networkId: networkId,
    formatId: formatId,
    topicId: topicId,
    hookId: hookId,
    publishedAtSimMs: publishedAtSimMs,
    qualityScore: qualityScore,
    trendPermille: trendPermille,
    viralTier: viralTier,
    viralPermille: viralPermille,
    expectedViews: expectedViews,
    followRatePpm: followRatePpm,
    likeBps: likeBps,
    commentBps: commentBps,
    shareBps: shareBps,
    rpmMinor: rpmMinor,
    views: views,
    likes: likes,
    comments: comments,
    shares: shares,
    followersGained: followersGained,
    revenueMinor: revenueMinor,
    complete: complete,
    qualityBreakdown: qualityBreakdown,
    mediaLocalKey: mediaLocalKey,
  );

  Map<String, Object?> toJson() => {
    'postId': postId,
    'networkId': networkId.name,
    'formatId': formatId,
    'topicId': topicId,
    'hookId': hookId,
    'publishedAtSimMs': publishedAtSimMs,
    'qualityScore': qualityScore,
    'trendPermille': trendPermille,
    'viralTier': viralTier,
    'viralPermille': viralPermille,
    'expectedViews': expectedViews,
    'followRatePpm': followRatePpm,
    'likeBps': likeBps,
    'commentBps': commentBps,
    'shareBps': shareBps,
    'rpmMinor': rpmMinor,
    'views': views,
    'likes': likes,
    'comments': comments,
    'shares': shares,
    'followersGained': followersGained,
    'revenueMinor': revenueMinor,
    'complete': complete,
    'qualityBreakdown': qualityBreakdown,
    'mediaLocalKey': mediaLocalKey,
  };

  factory ContentPost.fromJson(Map<String, Object?> j) => ContentPost(
    postId: j['postId']! as String,
    networkId: NetworkId.parse(j['networkId']! as String),
    formatId: j['formatId']! as String,
    topicId: j['topicId']! as String,
    hookId: j['hookId']! as String,
    publishedAtSimMs: j['publishedAtSimMs']! as int,
    qualityScore: j['qualityScore']! as int,
    trendPermille: j['trendPermille']! as int,
    viralTier: j['viralTier']! as int,
    viralPermille: j['viralPermille']! as int,
    expectedViews: j['expectedViews']! as int,
    followRatePpm: j['followRatePpm']! as int,
    likeBps: j['likeBps']! as int,
    commentBps: j['commentBps']! as int,
    shareBps: j['shareBps']! as int,
    rpmMinor: j['rpmMinor']! as int,
    views: j['views'] as int? ?? 0,
    likes: j['likes'] as int? ?? 0,
    comments: j['comments'] as int? ?? 0,
    shares: j['shares'] as int? ?? 0,
    followersGained: j['followersGained'] as int? ?? 0,
    revenueMinor: j['revenueMinor'] as int? ?? 0,
    complete: j['complete'] as bool? ?? false,
    qualityBreakdown: {
      for (final e in ((j['qualityBreakdown'] as Map?) ?? const {}).entries) e.key as String: e.value as int,
    },
    mediaLocalKey: j['mediaLocalKey'] as String?,
  );
}
