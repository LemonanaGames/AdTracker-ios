import '../model/ids.dart';
import 'game_catalog.dart';
import 'requirement.dart';

final class ValidationReport {
  const ValidationReport(this.errors, this.warnings);
  final List<String> errors;
  final List<String> warnings;
  bool get ok => errors.isEmpty;

  @override
  String toString() => [...errors.map((e) => 'ERROR   $e'), ...warnings.map((w) => 'WARNING $w')].join('\n');
}

/// Cross-reference checks that JSON Schema cannot express. Run in tests and
/// via `dart run tool/validate_content.dart`.
final class CatalogValidator {
  static const knownStats = {'postsPublished', 'jobShifts', 'lifetimeClaimedMinor', 'tubecastPosts', 'vibePosts'};

  static ValidationReport validate(GameCatalog c, {Set<String>? assetKeys}) {
    final errors = <String>[];
    final warnings = <String>[];

    void key(String where, String k) {
      if (!c.strings.has(k)) errors.add('$where: missing localization key "$k"');
    }

    void asset(String where, String k) {
      if (assetKeys != null && !assetKeys.contains(k)) errors.add('$where: unknown assetKey "$k"');
    }

    void unique(String what, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) errors.add('$what: duplicate id "$id"');
      }
    }

    final actIds = c.economy.acts.map((a) => a.id).toSet();
    final gearIds = c.gear.map((g) => g.id).toSet();

    void req(String where, Requirement? r) {
      if (r == null) return;
      switch (r.type) {
        case RequirementType.anyOf:
        case RequirementType.allOf:
          if (r.of.isEmpty) errors.add('$where: empty ${r.type.name}');
          for (final child in r.of) {
            req(where, child);
          }
        case RequirementType.act:
          if (!actIds.contains(r.minAct)) errors.add('$where: unknown act "${r.minAct}"');
        case RequirementType.gearOwned:
          if (!gearIds.contains(r.gearId)) errors.add('$where: unknown gear "${r.gearId}"');
        case RequirementType.stat:
          if (!knownStats.contains(r.stat)) errors.add('$where: unknown stat "${r.stat}"');
        case RequirementType.followers:
        case RequirementType.engagement:
          if (r.network == null) errors.add('$where: ${r.type.name} needs a network');
        default:
          break;
      }
    }

    // Economy
    final e = c.economy;
    if (e.viralMultipliersPermille.length != e.viralWeights.length) {
      errors.add('economy.viral: multipliers and weights differ in length');
    }
    if (e.viralFromIndex >= e.viralWeights.length) errors.add('economy.viral: viralFromIndex out of range');
    if (e.viralWeights.any((w) => w < 0)) errors.add('economy.viral: negative weight');
    if (e.trendMinPermille > e.trendMaxPermille) errors.add('economy.trend: min > max');
    if (e.simSecondsPerRealSecond <= 0) errors.add('economy.time: simSecondsPerRealSecond must be > 0');
    if (e.acts.isEmpty || e.acts.first.requirement != null) {
      errors.add('economy.acts: first act must exist and have no requirement');
    }
    unique('acts', e.acts.map((a) => a.id));
    for (final a in e.acts) {
      key('act ${a.id}', a.nameKey);
      req('act ${a.id}', a.requirement);
    }
    for (final g in e.startGearIds) {
      if (!gearIds.contains(g)) errors.add('economy.start: unknown gear "$g"');
    }

    // Networks
    for (final id in NetworkId.values) {
      if (!c.networks.containsKey(id)) errors.add('networks: missing "${id.name}"');
    }
    for (final n in c.networks.values) {
      final w = 'network ${n.id.name}';
      key(w, n.nameKey);
      key(w, n.taglineKey);
      asset(w, n.assetKey);
      req(w, n.unlock);
      if (n.curve.isEmpty || n.curve.first.hour != 0) errors.add('$w: curve must start at hour 0');
      for (var i = 1; i < n.curve.length; i++) {
        if (n.curve[i].hour <= n.curve[i - 1].hour) errors.add('$w: curve hours must increase');
        if (n.curve[i].permille < n.curve[i - 1].permille) errors.add('$w: curve must not decrease');
      }
      if (n.curve.isNotEmpty && n.curve.last.permille != 1000) errors.add('$w: curve must end at 1000');
      if (n.formats.isEmpty) errors.add('$w: needs at least one format');
      for (final f in n.formats) {
        key('$w format ${f.id}', f.nameKey);
      }
    }
    unique('formats', c.networks.values.expand((n) => n.formats).map((f) => f.id));

    // Niches, topics, hooks
    final nicheIds = c.niches.map((n) => n.id).toSet();
    unique('niches', c.niches.map((n) => n.id));
    for (final n in c.niches) {
      key('niche ${n.id}', n.nameKey);
      key('niche ${n.id}', n.descKey);
      asset('niche ${n.id}', n.assetKey);
      if (!c.topics.any((t) => t.niches.contains(n.id) && t.networks.contains(NetworkId.loop))) {
        errors.add('niche ${n.id}: has no Loop topic (first post would be impossible)');
      }
    }
    unique('topics', c.topics.map((t) => t.id));
    for (final t in c.topics) {
      key('topic ${t.id}', t.nameKey);
      asset('topic ${t.id}', t.assetKey);
      for (final n in t.niches) {
        if (!nicheIds.contains(n)) errors.add('topic ${t.id}: unknown niche "$n"');
      }
      if (t.networks.isEmpty) errors.add('topic ${t.id}: no networks');
    }
    unique('hooks', c.hooks.map((h) => h.id));
    if (!c.hooks.any((h) => h.requirement == null)) errors.add('hooks: at least one hook must be always available');
    for (final h in c.hooks) {
      key('hook ${h.id}', h.nameKey);
      asset('hook ${h.id}', h.assetKey);
      req('hook ${h.id}', h.requirement);
    }

    // Gear, jobs, skills
    unique('gear', c.gear.map((g) => g.id));
    for (final g in c.gear) {
      key('gear ${g.id}', g.nameKey);
      asset('gear ${g.id}', g.assetKey);
      req('gear ${g.id}', g.requirement);
      if (g.costMinor < 0) errors.add('gear ${g.id}: negative cost');
      if (g.enabled && g.effects.keys.any((k) => k != 'quality')) {
        warnings.add('gear ${g.id}: enabled with an effect M1 does not simulate (${g.effects.keys})');
      }
    }
    unique('jobs', c.jobs.map((j) => j.id));
    if (!c.jobs.any((j) => j.requirement == null)) errors.add('jobs: at least one job must be always available');
    for (final j in c.jobs) {
      key('job ${j.id}', j.nameKey);
      asset('job ${j.id}', j.assetKey);
      req('job ${j.id}', j.requirement);
      if (j.payMinor <= 0 || j.energyCost <= 0) errors.add('job ${j.id}: pay and energy cost must be > 0');
    }
    unique('skills', c.skills.map((s) => s.id));
    for (final s in c.skills) {
      key('skill ${s.id}', s.nameKey);
      key('skill ${s.id}', s.descKey);
      asset('skill ${s.id}', s.assetKey);
    }

    // Goals
    unique('goals', c.goals.map((g) => g.id));
    for (final g in c.goals) {
      key('goal ${g.id}', g.titleKey);
      req('goal ${g.id}', g.requirement);
      if (!g.route.startsWith('/')) errors.add('goal ${g.id}: route must start with "/"');
    }

    // Narrative
    final npcIds = c.characters.map((ch) => ch.id).toSet();
    unique('characters', c.characters.map((ch) => ch.id));
    for (final ch in c.characters) {
      key('character ${ch.id}', ch.nameKey);
      key('character ${ch.id}', ch.roleKey);
      asset('character ${ch.id}', ch.assetKey);
    }
    final eventIds = c.events.map((ev) => ev.id).toSet();
    unique('events', c.events.map((ev) => ev.id));
    for (final ev in c.events) {
      final w = 'event ${ev.id}';
      key(w, ev.titleKey);
      asset(w, ev.sceneAssetKey);
      req(w, ev.trigger);
      if (!actIds.contains(ev.act)) errors.add('$w: unknown act "${ev.act}"');
      for (final l in ev.lines) {
        key(w, l.textKey);
        if (!npcIds.contains(l.speaker)) errors.add('$w: unknown speaker "${l.speaker}"');
      }
      if (ev.choices.length < 2) errors.add('$w: needs at least 2 choices (no false choices)');
      unique('$w choices', ev.choices.map((ch) => ch.id));
      if (!ev.choices.any((ch) => ch.requirement == null)) {
        errors.add('$w: at least one choice must have no requirement (no dead ends)');
      }
      for (final ch in ev.choices) {
        key('$w choice ${ch.id}', ch.labelKey);
        req('$w choice ${ch.id}', ch.requirement);
        for (final npc in ch.effects.relationships.keys) {
          if (!npcIds.contains(npc)) errors.add('$w choice ${ch.id}: unknown npc "$npc"');
        }
        if (ch.nextEventId != null && !eventIds.contains(ch.nextEventId)) {
          warnings.add('$w choice ${ch.id}: callback event "${ch.nextEventId}" not authored yet');
        }
      }
    }

    // Deals preview
    unique('sponsorTiers', c.sponsorTiers.map((t) => t.id));
    for (final t in c.sponsorTiers) {
      key('sponsor tier ${t.id}', t.nameKey);
      if (t.rewardMinMinor > t.rewardMaxMinor) errors.add('sponsor tier ${t.id}: min reward > max');
    }

    return ValidationReport(errors, warnings);
  }
}
