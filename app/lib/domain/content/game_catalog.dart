import 'dart:convert';

import '../model/ids.dart';
import 'requirement.dart';

typedef Json = Map<String, Object?>;

Json _obj(Object? raw) => (raw! as Map).cast<String, Object?>();
List<Json> _list(Object? raw) => [for (final e in (raw as List?) ?? const []) _obj(e)];
List<int> _ints(Object? raw) => [for (final e in (raw as List?) ?? const []) e as int];
List<String> _strings(Object? raw) => [for (final e in (raw as List?) ?? const []) e as String];

/// All versioned game content, parsed from `game_content/`. Pure data:
/// changing a JSON file changes behaviour without touching widget code.
final class GameCatalog {
  GameCatalog._({
    required this.economy,
    required this.networks,
    required this.niches,
    required this.topics,
    required this.hooks,
    required this.gear,
    required this.jobs,
    required this.skills,
    required this.goals,
    required this.characters,
    required this.events,
    required this.sponsorTiers,
    required this.strings,
  });

  /// Content files, relative to `game_content/`. The app bundles exactly these.
  static const files = <String>[
    'balance/economy.json',
    'balance/networks.json',
    'balance/content.json',
    'balance/equipment.json',
    'balance/jobs.json',
    'balance/skills.json',
    'balance/goals.json',
    'narrative/characters.json',
    'narrative/events.json',
    'deals/sponsor_tiers.json',
    'localization/en.json',
  ];

  /// Builds a catalog from raw file contents keyed by [files] entries.
  factory GameCatalog.fromSources(Map<String, String> sources) {
    Json file(String path) {
      final raw = sources[path];
      if (raw == null) throw FormatException('Missing content file $path');
      return _obj(jsonDecode(raw));
    }

    final economy = EconomyConfig.fromJson(file('balance/economy.json'));
    final content = file('balance/content.json');
    return GameCatalog._(
      economy: economy,
      networks: {for (final n in _list(file('balance/networks.json')['networks']).map(NetworkDef.fromJson)) n.id: n},
      niches: _list(content['niches']).map(NicheDef.fromJson).toList(),
      topics: _list(content['topics']).map(TopicDef.fromJson).toList(),
      hooks: _list(content['hooks']).map(HookDef.fromJson).toList(),
      gear: _list(file('balance/equipment.json')['gear']).map(GearDef.fromJson).toList(),
      jobs: _list(file('balance/jobs.json')['jobs']).map(JobDef.fromJson).toList(),
      skills: _list(file('balance/skills.json')['skills']).map(SkillDef.fromJson).toList(),
      goals: _list(file('balance/goals.json')['goals']).map(GoalDef.fromJson).toList(),
      characters: _list(file('narrative/characters.json')['characters']).map(CharacterDef.fromJson).toList(),
      events: _list(file('narrative/events.json')['events']).map(StoryEventDef.fromJson).toList(),
      sponsorTiers: _list(file('deals/sponsor_tiers.json')['tiers']).map(SponsorTierDef.fromJson).toList(),
      strings: ContentStrings({for (final e in file('localization/en.json').entries) e.key: e.value! as String}),
    );
  }

  final EconomyConfig economy;
  final Map<NetworkId, NetworkDef> networks;
  final List<NicheDef> niches;
  final List<TopicDef> topics;
  final List<HookDef> hooks;
  final List<GearDef> gear;
  final List<JobDef> jobs;
  final List<SkillDef> skills;
  final List<GoalDef> goals;
  final List<CharacterDef> characters;
  final List<StoryEventDef> events;
  final List<SponsorTierDef> sponsorTiers;
  final ContentStrings strings;

  String get contentVersion => economy.contentVersion;

  NetworkDef network(NetworkId id) => networks[id]!;
  TopicDef? topic(String id) => _find(topics, (t) => t.id == id);
  HookDef? hook(String id) => _find(hooks, (h) => h.id == id);
  GearDef? gearItem(String id) => _find(gear, (g) => g.id == id);
  JobDef? job(String id) => _find(jobs, (j) => j.id == id);
  SkillDef? skill(String id) => _find(skills, (s) => s.id == id);
  NicheDef? niche(String id) => _find(niches, (n) => n.id == id);
  CharacterDef? character(String id) => _find(characters, (c) => c.id == id);
  StoryEventDef? event(String id) => _find(events, (e) => e.id == id);

  /// Index of an act in progression order; -1 if unknown.
  int actIndex(String actId) => economy.acts.indexWhere((a) => a.id == actId);

  FormatDef? format(String formatId) {
    for (final n in networks.values) {
      for (final f in n.formats) {
        if (f.id == formatId) return f;
      }
    }
    return null;
  }

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }
}

/// Runtime lookup for content localization keys (UI chrome uses ARB files).
final class ContentStrings {
  const ContentStrings(this._map);
  final Map<String, String> _map;

  bool has(String key) => _map.containsKey(key);
  String operator [](String key) => _map[key] ?? key;
  Iterable<String> get keys => _map.keys;
}

final class EconomyConfig {
  const EconomyConfig({
    required this.contentVersion,
    required this.simSecondsPerRealSecond,
    required this.freeOfflineHours,
    required this.proOfflineHours,
    required this.minOfflineSummarySeconds,
    required this.startCashMinor,
    required this.startEnergy,
    required this.startTrust,
    required this.startIntegrity,
    required this.startSkillPoints,
    required this.startGearIds,
    required this.startHomeId,
    required this.energyMax,
    required this.energyRegenPerSimHour,
    required this.burnoutMax,
    required this.burnoutRecoveryPerSimHour,
    required this.burnoutQualityPenaltyDivisor,
    required this.xpLevelBase,
    required this.skillPointsPerLevel,
    required this.maxLevel,
    required this.publishBaseXp,
    required this.publishQualityPointsPerXp,
    required this.publishEnergyCost,
    required this.publishBurnoutGain,
    required this.nicheFitMatch,
    required this.nicheFitOff,
    required this.fatigueWindowSimHours,
    required this.fatiguePenaltyPermillePerPost,
    required this.fatigueMinFactorPermille,
    required this.viralMultipliersPermille,
    required this.viralWeights,
    required this.viralFromIndex,
    required this.trendMinPermille,
    required this.trendMaxPermille,
    required this.trendHotFromPermille,
    required this.uniqueReachOverlapPermille,
    required this.followerMilestones,
    required this.engagementWindowSimDays,
    required this.acts,
  });

  factory EconomyConfig.fromJson(Json j) {
    final time = _obj(j['time']);
    final start = _obj(j['start']);
    final energy = _obj(j['energy']);
    final burnout = _obj(j['burnout']);
    final prog = _obj(j['progression']);
    final publish = _obj(j['publish']);
    final fit = _obj(j['nicheFit']);
    final fatigue = _obj(j['audienceFatigue']);
    final viral = _obj(j['viral']);
    final trend = _obj(j['trend']);
    return EconomyConfig(
      contentVersion: j['contentVersion']! as String,
      simSecondsPerRealSecond: time['simSecondsPerRealSecond']! as int,
      freeOfflineHours: time['freeOfflineHours']! as int,
      proOfflineHours: time['proOfflineHours']! as int,
      minOfflineSummarySeconds: time['minOfflineSummarySeconds']! as int,
      startCashMinor: start['cashMinor']! as int,
      startEnergy: start['energy']! as int,
      startTrust: start['audienceTrust']! as int,
      startIntegrity: start['integrity']! as int,
      startSkillPoints: start['skillPoints']! as int,
      startGearIds: _strings(start['gearIds']),
      startHomeId: start['homeId']! as String,
      energyMax: energy['max']! as int,
      energyRegenPerSimHour: energy['regenPerSimHour']! as int,
      burnoutMax: burnout['max']! as int,
      burnoutRecoveryPerSimHour: burnout['recoveryPerSimHour']! as int,
      burnoutQualityPenaltyDivisor: burnout['qualityPenaltyDivisor']! as int,
      xpLevelBase: prog['xpLevelBase']! as int,
      skillPointsPerLevel: prog['skillPointsPerLevel']! as int,
      maxLevel: prog['maxLevel']! as int,
      publishBaseXp: publish['baseXp']! as int,
      publishQualityPointsPerXp: publish['qualityPointsPerXp']! as int,
      publishEnergyCost: publish['energyCost']! as int,
      publishBurnoutGain: publish['burnoutGain']! as int,
      nicheFitMatch: fit['match']! as int,
      nicheFitOff: fit['off']! as int,
      fatigueWindowSimHours: fatigue['windowSimHours']! as int,
      fatiguePenaltyPermillePerPost: fatigue['penaltyPermillePerActivePost']! as int,
      fatigueMinFactorPermille: fatigue['minFactorPermille']! as int,
      viralMultipliersPermille: _ints(viral['multipliersPermille']),
      viralWeights: _ints(viral['weights']),
      viralFromIndex: viral['viralFromIndex']! as int,
      trendMinPermille: trend['minPermille']! as int,
      trendMaxPermille: trend['maxPermille']! as int,
      trendHotFromPermille: trend['hotFromPermille']! as int,
      uniqueReachOverlapPermille: _obj(j['uniqueReach'])['overlapPermille']! as int,
      followerMilestones: _ints(j['followerMilestones']),
      engagementWindowSimDays: j['engagementWindowSimDays']! as int,
      acts: _list(j['acts']).map(ActDef.fromJson).toList(),
    );
  }

  final String contentVersion;
  final int simSecondsPerRealSecond;
  final int freeOfflineHours;
  final int proOfflineHours;
  final int minOfflineSummarySeconds;
  final int startCashMinor;
  final int startEnergy;
  final int startTrust;
  final int startIntegrity;
  final int startSkillPoints;
  final List<String> startGearIds;
  final String startHomeId;
  final int energyMax;
  final int energyRegenPerSimHour;
  final int burnoutMax;
  final int burnoutRecoveryPerSimHour;
  final int burnoutQualityPenaltyDivisor;
  final int xpLevelBase;
  final int skillPointsPerLevel;
  final int maxLevel;
  final int publishBaseXp;
  final int publishQualityPointsPerXp;
  final int publishEnergyCost;
  final int publishBurnoutGain;
  final int nicheFitMatch;
  final int nicheFitOff;
  final int fatigueWindowSimHours;
  final int fatiguePenaltyPermillePerPost;
  final int fatigueMinFactorPermille;
  final List<int> viralMultipliersPermille;
  final List<int> viralWeights;
  final int viralFromIndex;
  final int trendMinPermille;
  final int trendMaxPermille;
  final int trendHotFromPermille;
  final int uniqueReachOverlapPermille;
  final List<int> followerMilestones;
  final int engagementWindowSimDays;
  final List<ActDef> acts;
}

final class ActDef {
  const ActDef({required this.id, required this.nameKey, this.requirement});
  factory ActDef.fromJson(Json j) => ActDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    requirement: Requirement.maybe(j['requirement']),
  );
  final String id;
  final String nameKey;

  /// Null for the starting act.
  final Requirement? requirement;
}

final class FormatDef {
  const FormatDef({required this.id, required this.nameKey, required this.platformFitPermille, required this.tags});
  factory FormatDef.fromJson(Json j) => FormatDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    platformFitPermille: j['platformFitPermille']! as int,
    tags: _strings(j['tags']).toSet(),
  );
  final String id;
  final String nameKey;
  final int platformFitPermille;
  final Set<String> tags;
}

final class NetworkDef {
  const NetworkDef({
    required this.id,
    required this.nameKey,
    required this.taglineKey,
    required this.colorHex,
    required this.assetKey,
    required this.unlock,
    required this.baseReach,
    required this.reachPerFollowerPermille,
    required this.viewToFollowPpm,
    required this.rpmMinor,
    required this.crossReachPermille,
    required this.likeBps,
    required this.commentBps,
    required this.shareBps,
    required this.curve,
    required this.formats,
  });

  factory NetworkDef.fromJson(Json j) {
    final eng = _obj(j['engagement']);
    return NetworkDef(
      id: NetworkId.parse(j['id']! as String),
      nameKey: j['nameKey']! as String,
      taglineKey: j['taglineKey']! as String,
      colorHex: j['colorHex']! as String,
      assetKey: j['assetKey']! as String,
      unlock: Requirement.fromJson(_obj(j['unlock'])),
      baseReach: j['baseReach']! as int,
      reachPerFollowerPermille: j['reachPerFollowerPermille']! as int,
      viewToFollowPpm: j['viewToFollowPpm']! as int,
      rpmMinor: j['rpmMinor']! as int,
      crossReachPermille: j['crossReachPermille'] as int? ?? 0,
      likeBps: eng['likeBps']! as int,
      commentBps: eng['commentBps']! as int,
      shareBps: eng['shareBps']! as int,
      curve: [
        for (final p in (j['curve']! as List).cast<List<Object?>>()) (hour: p[0]! as int, permille: p[1]! as int),
      ],
      formats: _list(j['formats']).map(FormatDef.fromJson).toList(),
    );
  }

  final NetworkId id;
  final String nameKey;
  final String taglineKey;
  final String colorHex;
  final String assetKey;
  final Requirement unlock;
  final int baseReach;
  final int reachPerFollowerPermille;
  final int viewToFollowPpm;
  final int rpmMinor;

  /// Share of followers on *other* networks that adds to this network's
  /// baseline reach (cross-promotion). Reach only: never copies followers.
  final int crossReachPermille;
  final int likeBps;
  final int commentBps;
  final int shareBps;

  /// Cumulative share of views by simulated hour (permille, ends at 1000).
  final List<({int hour, int permille})> curve;
  final List<FormatDef> formats;

  int get curveEndHour => curve.last.hour;
}

final class NicheDef {
  const NicheDef({required this.id, required this.nameKey, required this.descKey, required this.assetKey});
  factory NicheDef.fromJson(Json j) => NicheDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    descKey: j['descKey']! as String,
    assetKey: j['assetKey']! as String,
  );
  final String id;
  final String nameKey;
  final String descKey;
  final String assetKey;
}

final class TopicDef {
  const TopicDef({
    required this.id,
    required this.nameKey,
    required this.niches,
    required this.networks,
    required this.tutorial,
    required this.assetKey,
  });
  factory TopicDef.fromJson(Json j) => TopicDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    niches: _strings(j['niches']).toSet(),
    networks: _strings(j['networks']).map(NetworkId.parse).toSet(),
    tutorial: j['tutorial'] as bool? ?? false,
    assetKey: j['assetKey']! as String,
  );
  final String id;
  final String nameKey;
  final Set<String> niches;
  final Set<NetworkId> networks;
  final bool tutorial;
  final String assetKey;
}

final class HookDef {
  const HookDef({
    required this.id,
    required this.nameKey,
    required this.qualityBonus,
    required this.commentBoostPermille,
    required this.assetKey,
    this.requirement,
  });
  factory HookDef.fromJson(Json j) => HookDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    qualityBonus: j['qualityBonus']! as int,
    commentBoostPermille: j['commentBoostPermille']! as int,
    assetKey: j['assetKey']! as String,
    requirement: Requirement.maybe(j['requirement']),
  );
  final String id;
  final String nameKey;
  final int qualityBonus;
  final int commentBoostPermille;
  final String assetKey;
  final Requirement? requirement;
}

final class GearDef {
  const GearDef({
    required this.id,
    required this.nameKey,
    required this.costMinor,
    required this.effects,
    required this.assetKey,
    required this.enabled,
    required this.starter,
    this.requirement,
  });
  factory GearDef.fromJson(Json j) => GearDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    costMinor: j['costMinor']! as int,
    effects: {for (final e in _obj(j['effects']).entries) e.key: e.value! as int},
    assetKey: j['assetKey']! as String,
    enabled: j['enabled'] as bool? ?? true,
    starter: j['starter'] as bool? ?? false,
    requirement: Requirement.maybe(j['requirement']),
  );
  final String id;
  final String nameKey;
  final int costMinor;

  /// e.g. {"quality": 2}. Only "quality" has gameplay effect in M1.
  final Map<String, int> effects;
  final String assetKey;

  /// Disabled items are hidden until their effect is implemented.
  final bool enabled;
  final bool starter;
  final Requirement? requirement;

  int get qualityBonus => effects['quality'] ?? 0;
}

final class JobDef {
  const JobDef({
    required this.id,
    required this.nameKey,
    required this.payMinor,
    required this.energyCost,
    required this.burnoutGain,
    required this.xp,
    required this.assetKey,
    this.requirement,
  });
  factory JobDef.fromJson(Json j) => JobDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    payMinor: j['payMinor']! as int,
    energyCost: j['energyCost']! as int,
    burnoutGain: j['burnoutGain']! as int,
    xp: j['xp']! as int,
    assetKey: j['assetKey']! as String,
    requirement: Requirement.maybe(j['requirement']),
  );
  final String id;
  final String nameKey;
  final int payMinor;
  final int energyCost;
  final int burnoutGain;
  final int xp;
  final String assetKey;
  final Requirement? requirement;
}

enum SkillEffectKind {
  qualityTenths,
  viewsPermille,
  reachPermille,
  none;

  static SkillEffectKind parse(String raw) =>
      SkillEffectKind.values.firstWhere((k) => k.name == raw, orElse: () => SkillEffectKind.none);
}

final class SkillDef {
  const SkillDef({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.maxRank,
    required this.effectKind,
    required this.perRank,
    required this.enabled,
    required this.assetKey,
    this.formatTag,
  });
  factory SkillDef.fromJson(Json j) {
    final effect = _obj(j['effect']);
    return SkillDef(
      id: j['id']! as String,
      nameKey: j['nameKey']! as String,
      descKey: j['descKey']! as String,
      maxRank: j['maxRank']! as int,
      effectKind: SkillEffectKind.parse(effect['kind']! as String),
      perRank: effect['perRank']! as int,
      formatTag: effect['formatTag'] as String?,
      enabled: j['enabled'] as bool? ?? true,
      assetKey: j['assetKey']! as String,
    );
  }
  final String id;
  final String nameKey;
  final String descKey;
  final int maxRank;
  final SkillEffectKind effectKind;
  final int perRank;

  /// When set, the effect only applies to formats carrying this tag.
  final String? formatTag;
  final bool enabled;
  final String assetKey;
}

final class GoalDef {
  const GoalDef({required this.id, required this.titleKey, required this.route, required this.requirement});
  factory GoalDef.fromJson(Json j) => GoalDef(
    id: j['id']! as String,
    titleKey: j['titleKey']! as String,
    route: j['route']! as String,
    requirement: Requirement.fromJson(_obj(j['requirement'])),
  );
  final String id;
  final String titleKey;
  final String route;
  final Requirement requirement;
}

final class CharacterDef {
  const CharacterDef({
    required this.id,
    required this.nameKey,
    required this.roleKey,
    required this.assetKey,
    required this.startRelationship,
  });
  factory CharacterDef.fromJson(Json j) => CharacterDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    roleKey: j['roleKey']! as String,
    assetKey: j['assetKey']! as String,
    startRelationship: j['startRelationship']! as int,
  );
  final String id;
  final String nameKey;
  final String roleKey;
  final String assetKey;
  final int startRelationship;
}

final class StoryEventDef {
  const StoryEventDef({
    required this.id,
    required this.act,
    required this.version,
    required this.oncePerLife,
    required this.titleKey,
    required this.sceneAssetKey,
    required this.trigger,
    required this.lines,
    required this.choices,
    required this.analyticsTags,
  });
  factory StoryEventDef.fromJson(Json j) => StoryEventDef(
    id: j['id']! as String,
    act: j['act']! as String,
    version: j['version']! as int,
    oncePerLife: j['oncePerLife']! as bool,
    titleKey: j['titleKey']! as String,
    sceneAssetKey: j['sceneAssetKey']! as String,
    trigger: Requirement.fromJson(_obj(j['trigger'])),
    lines: [for (final l in _list(j['lines'])) (speaker: l['speaker']! as String, textKey: l['textKey']! as String)],
    choices: _list(j['choices']).map(StoryChoiceDef.fromJson).toList(),
    analyticsTags: _strings(j['analyticsTags']),
  );
  final String id;
  final String act;
  final int version;
  final bool oncePerLife;
  final String titleKey;
  final String sceneAssetKey;
  final Requirement trigger;
  final List<({String speaker, String textKey})> lines;
  final List<StoryChoiceDef> choices;
  final List<String> analyticsTags;
}

final class StoryChoiceDef {
  const StoryChoiceDef({
    required this.id,
    required this.labelKey,
    required this.effects,
    required this.deferredFlags,
    this.requirement,
    this.nextEventId,
  });
  factory StoryChoiceDef.fromJson(Json j) => StoryChoiceDef(
    id: j['id']! as String,
    labelKey: j['labelKey']! as String,
    effects: ChoiceEffects.fromJson(_obj(j['effects'])),
    deferredFlags: _strings(j['deferredFlags']),
    requirement: Requirement.maybe(j['requirement']),
    nextEventId: j['nextEventId'] as String?,
  );
  final String id;
  final String labelKey;
  final ChoiceEffects effects;
  final List<String> deferredFlags;
  final Requirement? requirement;
  final String? nextEventId;
}

final class ModifierDef {
  const ModifierDef({required this.kind, required this.value, required this.uses, this.network});
  factory ModifierDef.fromJson(Json j) => ModifierDef(
    kind: j['kind']! as String,
    value: j['value']! as int,
    uses: j['uses']! as int,
    network: j['network'] == null ? null : NetworkId.parse(j['network']! as String),
  );
  final String kind;
  final int value;
  final int uses;
  final NetworkId? network;
}

/// Effects are applied verbatim and also drive the choice preview chips, so
/// the preview can never promise something the engine does not do.
final class ChoiceEffects {
  const ChoiceEffects({
    this.integrity = 0,
    this.audienceTrust = 0,
    this.cashMinor = 0,
    this.xp = 0,
    this.relationships = const {},
    this.modifiers = const [],
  });
  factory ChoiceEffects.fromJson(Json j) => ChoiceEffects(
    integrity: j['integrity'] as int? ?? 0,
    audienceTrust: j['audienceTrust'] as int? ?? 0,
    cashMinor: j['cashMinor'] as int? ?? 0,
    xp: j['xp'] as int? ?? 0,
    relationships: {
      for (final e in ((j['relationships'] as Map?) ?? const {}).entries) e.key as String: e.value as int,
    },
    modifiers: _list(j['modifiers']).map(ModifierDef.fromJson).toList(),
  );
  final int integrity;
  final int audienceTrust;
  final int cashMinor;
  final int xp;
  final Map<String, int> relationships;
  final List<ModifierDef> modifiers;
}

final class SponsorTierDef {
  const SponsorTierDef({
    required this.id,
    required this.nameKey,
    required this.network,
    required this.minFollowers,
    required this.min7dViews,
    required this.minEngagementBps,
    required this.rewardMinMinor,
    required this.rewardMaxMinor,
  });
  factory SponsorTierDef.fromJson(Json j) => SponsorTierDef(
    id: j['id']! as String,
    nameKey: j['nameKey']! as String,
    network: NetworkId.parse(j['network']! as String),
    minFollowers: j['minFollowers']! as int,
    min7dViews: j['min7dViews']! as int,
    minEngagementBps: j['minEngagementBps']! as int,
    rewardMinMinor: j['rewardMinMinor']! as int,
    rewardMaxMinor: j['rewardMaxMinor']! as int,
  );
  final String id;
  final String nameKey;
  final NetworkId network;
  final int minFollowers;
  final int min7dViews;
  final int minEngagementBps;
  final int rewardMinMinor;
  final int rewardMaxMinor;
}
