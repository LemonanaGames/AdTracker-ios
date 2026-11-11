import '../model/ids.dart';

/// Declarative gate shared by acts, unlocks, gear, hooks, jobs, goals and
/// story triggers (schema: game_content/schemas/requirement.schema.json).
final class Requirement {
  const Requirement._({
    required this.type,
    this.network,
    this.min,
    this.minAct,
    this.stat,
    this.gearId,
    this.flag,
    this.of = const [],
  });

  static const always = Requirement._(type: RequirementType.always);

  final RequirementType type;
  final NetworkId? network;

  /// Numeric threshold (followers, level, bps, cents, views, trust...).
  final int? min;
  final String? minAct;
  final String? stat;
  final String? gearId;
  final String? flag;
  final List<Requirement> of;

  factory Requirement.fromJson(Map<String, Object?> j) {
    final type = RequirementType.parse(j['type']! as String);
    return Requirement._(
      type: type,
      network: j['network'] == null ? null : NetworkId.parse(j['network']! as String),
      min: switch (type) {
        RequirementType.engagement => j['minBps']! as int,
        RequirementType.cash => j['minMinor']! as int,
        RequirementType.act => null,
        _ => j['min'] as int?,
      },
      minAct: type == RequirementType.act ? j['min']! as String : null,
      stat: j['stat'] as String?,
      gearId: j['gearId'] as String?,
      flag: j['flag'] as String?,
      of: [for (final raw in ((j['of'] as List?) ?? const []).cast<Map<String, Object?>>()) Requirement.fromJson(raw)],
    );
  }

  static Requirement? maybe(Object? raw) =>
      raw == null ? null : Requirement.fromJson((raw as Map).cast<String, Object?>());

  /// Every leaf (non-composite) requirement, depth first.
  Iterable<Requirement> get leaves sync* {
    if (type == RequirementType.anyOf || type == RequirementType.allOf) {
      for (final child in of) {
        yield* child.leaves;
      }
    } else {
      yield this;
    }
  }
}

enum RequirementType {
  always,
  followers,
  engagement,
  totalFollowers,
  creatorLevel,
  act,
  stat,
  gearOwned,
  flag,
  trust,
  cash,
  postViews,
  anyOf,
  allOf;

  static RequirementType parse(String raw) => RequirementType.values.firstWhere(
    (t) => t.name == raw,
    orElse: () => throw FormatException('Unknown requirement type "$raw"'),
  );
}

/// Result of evaluating a [Requirement] against a life, with progress data
/// the UI uses for "You need 2,300 more followers" style explanations.
final class RequirementCheck {
  const RequirementCheck({
    required this.requirement,
    required this.met,
    required this.current,
    required this.target,
    this.children = const [],
  });

  final Requirement requirement;
  final bool met;
  final int current;
  final int target;
  final List<RequirementCheck> children;

  /// 0..1000 progress. anyOf = best child, allOf = weakest child.
  int get progressPermille {
    if (met) return 1000;
    switch (requirement.type) {
      case RequirementType.anyOf:
        return children.fold(0, (best, c) => c.progressPermille > best ? c.progressPermille : best);
      case RequirementType.allOf:
        return children.fold(1000, (worst, c) => c.progressPermille < worst ? c.progressPermille : worst);
      default:
        if (target <= 0) return 0;
        return ((current.clamp(0, target) * 1000) ~/ target).clamp(0, 1000);
    }
  }

  /// Leaf checks (for checklists).
  Iterable<RequirementCheck> get leafChecks sync* {
    if (children.isEmpty) {
      yield this;
    } else {
      for (final c in children) {
        yield* c.leafChecks;
      }
    }
  }
}
