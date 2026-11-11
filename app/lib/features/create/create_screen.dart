import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/game_controller.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/services/sound_service.dart';
import '../../app/theme.dart';
import '../../domain/content/game_catalog.dart';
import '../../domain/engine/game_event.dart';
import '../../domain/engine/post_simulation.dart';
import '../../domain/model/ids.dart';
import '../../domain/model/life_state.dart';
import '../../ui/asset_art.dart';
import '../../ui/charts.dart';
import '../../ui/chunky_button.dart';
import '../../ui/motion.dart';
import '../../ui/requirement_view.dart';
import '../../ui/widgets.dart';
import 'publish_result_sheet.dart';

/// Composer: Network → Topic → Hook → Gear → Preview → Publish (GDD I5).
/// Every number shown here comes from the same engine forecast.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  NetworkId _network = NetworkId.loop;
  String? _topicId;
  String? _hookId;

  @override
  void initState() {
    super.initState();
    ref.read(telemetryProvider).log('content_composer_open');
  }

  List<TopicDef> _topics(GameCatalog c, LifeState life) {
    final list = c.topics.where((t) => t.networks.contains(_network)).toList();
    // Own-niche topics first; the tutorial topic first of all on a new life.
    int rank(TopicDef t) => (t.tutorial ? 0 : 2) + (t.niches.contains(life.avatar.nicheId) ? 0 : 1);
    list.sort((a, b) => rank(a).compareTo(rank(b)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(catalogProvider);
    final engine = ref.watch(engineProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    if (!life.network(_network).unlocked) _network = NetworkId.loop;
    final net = c.network(_network);
    final topics = _topics(c, life);
    final topicId = topics.any((x) => x.id == _topicId) ? _topicId! : topics.first.id;
    final hooks = c.hooks;
    final hookId = _hookId != null && engine.rules.isMet(life, c.hook(_hookId!)!.requirement)
        ? _hookId!
        : hooks.firstWhere((h) => engine.rules.isMet(life, h.requirement)).id;
    final draft = PostDraft(networkId: _network, formatId: net.formats.first.id, topicId: topicId, hookId: hookId);
    final forecast = engine.forecast(life, draft);
    final error = engine.validateDraft(life, draft);
    final firstPost = life.counter(Counters.postsPublished) == 0;

    return Scaffold(
      appBar: AppBar(title: Text(l.createPost)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          SectionHeader(l.stepNetwork),
          Wrap(
            spacing: Space.s,
            children: [
              for (final id in NetworkId.values)
                ChoiceChip(
                  avatar: life.network(id).unlocked ? null : const Icon(Icons.lock_rounded, size: 16),
                  label: Text(c.strings[c.network(id).nameKey]),
                  selected: _network == id,
                  onSelected: life.network(id).unlocked ? (_) => setState(() => _network = id) : null,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(c.strings[net.taglineKey], style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
          SectionHeader(l.stepTopic),
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final topic = topics[i];
                return _TopicThumb(
                  topic: topic,
                  color: AppColors.hex(net.colorHex),
                  selected: topic.id == topicId,
                  highlight: firstPost && topic.tutorial,
                  ownNiche: topic.niches.contains(life.avatar.nicheId),
                  hot: PostSimulation.trendPermille(c, life, topic.id, _network) >= c.economy.trendHotFromPermille,
                  onTap: () {
                    ref.read(gameControllerProvider.notifier).feedback(Sfx.tap, Haptic.selection);
                    setState(() => _topicId = topic.id);
                  },
                );
              },
            ),
          ),
          SectionHeader(l.stepHook),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final h in hooks)
                Builder(
                  builder: (context) {
                    final ok = engine.rules.isMet(life, h.requirement);
                    return ChoiceChip(
                      avatar: ok ? null : const Icon(Icons.lock_rounded, size: 16),
                      label: Text(
                        ok
                            ? '${c.strings[h.nameKey]} +${h.qualityBonus}'
                            : '${c.strings[h.nameKey]} · ${shortRequirement(l, c, engine.rules.check(life, h.requirement!))}',
                      ),
                      selected: h.id == hookId,
                      onSelected: ok ? (_) => setState(() => _hookId = h.id) : null,
                    );
                  },
                ),
            ],
          ),
          SectionHeader(
            l.stepGear,
            trailing: TextButton(onPressed: () => context.go(Routes.gear), child: Text(l.upgradeGear)),
          ),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final g in c.gear.where((g) => life.gearIds.contains(g.id)))
                Chip(avatar: AssetArt(g.assetKey, size: 22), label: Text('${c.strings[g.nameKey]} +${g.qualityBonus}')),
            ],
          ),
          SectionHeader(l.stepPreview),
          _PreviewCard(forecast: forecast),
          const SizedBox(height: Space.m),
          if (error == GameError.insufficientEnergy)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Text(
                l.notEnoughEnergy(_secondsUntilEnergy(c, life, forecast.energyCost)),
                style: t.bodyMedium?.copyWith(color: AppColors.amber),
              ),
            ),
          ChunkyButton(
            label: l.publish,
            icon: Icons.send_rounded,
            color: AppColors.coral,
            sfx: null, // the publish event plays its own whoosh
            onPressed: error == null ? () => _publish(draft) : null,
          ),
        ],
      ),
    );
  }

  int _secondsUntilEnergy(GameCatalog c, LifeState life, int cost) {
    final e = c.economy;
    final needMilli = cost * 1000 - life.energyMilli;
    if (needMilli <= 0) return 0;
    final simMs = needMilli * 3600 ~/ e.energyRegenPerSimHour;
    return (simMs / 1000 / e.simSecondsPerRealSecond).ceil();
  }

  void _publish(PostDraft draft) {
    final r = ref.read(gameControllerProvider.notifier).publish(draft);
    if (!r.ok) return;
    showPublishResult(context, r.value!.postId);
  }
}

/// A topic as a vertical "video thumbnail" card.
class _TopicThumb extends ConsumerWidget {
  const _TopicThumb({
    required this.topic,
    required this.color,
    required this.selected,
    required this.highlight,
    required this.ownNiche,
    required this.hot,
    required this.onTap,
  });

  final TopicDef topic;
  final Color color;
  final bool selected;
  final bool highlight;
  final bool ownNiche;
  final bool hot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final l = context.l10n;
    final d = context.reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      selected: selected,
      button: true,
      label: c.strings[topic.nameKey],
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1 : 0.94,
          duration: d,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: d,
            width: 122,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.text : (highlight ? AppColors.coral : Colors.transparent),
                width: 3,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(color, AppColors.violet, 0.35)!, Color.lerp(color, AppColors.background, 0.55)!],
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Stack(
              children: [
                Center(child: Transform.rotate(angle: -0.08, child: AssetArt(topic.assetKey, size: 58))),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.75)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.strings[topic.nameKey],
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ownNiche ? l.yourNiche : l.offNiche,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: ownNiche ? AppColors.mint : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (highlight)
                  Positioned(top: 8, left: 6, child: Sticker(l.startHere, color: AppColors.coral))
                else if (hot)
                  Positioned(
                    top: 8,
                    left: 6,
                    child: Sticker(l.trending, color: AppColors.amber, icon: Icons.local_fire_department_rounded),
                  ),
                if (selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle_rounded, color: AppColors.text, size: 22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({required this.forecast});
  final PostForecast forecast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final life = ref.watch(gameControllerProvider).life!;
    final b = forecast.breakdown;
    final labels = {
      QualityPart.nicheFit: l.qNicheFit,
      QualityPart.gear: l.qGear,
      QualityPart.hook: l.qHook,
      QualityPart.skills: l.qSkills,
      QualityPart.storyBonus: l.qStory,
      QualityPart.stress: l.qStress,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QualityGauge(value: forecast.quality, size: 120),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.quality, style: t.labelLarge?.copyWith(color: AppColors.textMuted)),
                    Text(l.qualityOutOf, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      l.expectedViews(Format.count(forecast.typicalMinViews), Format.count(forecast.typicalMaxViews)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          for (final e in labels.entries)
            if ((b[e.key] ?? 0) != 0 || e.key == QualityPart.skills)
              BreakdownRow(label: e.value, value: b[e.key] ?? 0, max: 40),
          const Divider(height: Space.l),
          _Line(icon: Icons.local_fire_department_rounded, text: l.viralChance(forecast.viralChancePermille ~/ 10)),
          _Line(icon: Icons.bolt_rounded, text: l.energyCost(forecast.energyCost, life.energy)),
          _Line(icon: Icons.star_rounded, text: l.xpGain(forecast.xp)),
          const SizedBox(height: 4),
          Text(l.forecastNote, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: Space.s),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
