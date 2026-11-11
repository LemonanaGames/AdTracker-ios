import 'ids.dart';

/// A temporary, use-limited effect granted by a story choice
/// (e.g. "+20% trend on your next Loop post").
final class ActiveModifier {
  const ActiveModifier({
    required this.kind,
    required this.value,
    required this.usesLeft,
    required this.sourceId,
    this.network,
  });

  static const kindTrendBoostPermille = 'trendBoostPermille';
  static const kindQualityBonus = 'qualityBonus';

  final String kind;
  final int value;
  final int usesLeft;
  final String sourceId;
  final NetworkId? network;

  bool appliesTo(NetworkId id) => network == null || network == id;

  ActiveModifier consumeOne() =>
      ActiveModifier(kind: kind, value: value, usesLeft: usesLeft - 1, sourceId: sourceId, network: network);

  Map<String, Object?> toJson() => {
    'kind': kind,
    'value': value,
    'usesLeft': usesLeft,
    'sourceId': sourceId,
    'network': network?.name,
  };

  factory ActiveModifier.fromJson(Map<String, Object?> j) => ActiveModifier(
    kind: j['kind']! as String,
    value: j['value']! as int,
    usesLeft: j['usesLeft']! as int,
    sourceId: j['sourceId']! as String,
    network: j['network'] == null ? null : NetworkId.parse(j['network']! as String),
  );
}
