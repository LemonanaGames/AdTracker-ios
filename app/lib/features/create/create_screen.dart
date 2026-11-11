import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/content/game_catalog.dart';
import '../../domain/engine/game_event.dart';
import '../../domain/engine/post_simulation.dart';
import '../../domain/model/ids.dart';
import '../../domain/model/life_state.dart';
import '../../ui/asset_art.dart';
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
          for (final topic in topics)
            _TopicTile(
              topic: topic,
              selected: topic.id == topicId,
              highlight: firstPost && topic.tutorial,
              ownNiche: topic.niches.contains(life.avatar.nicheId),
              hot: PostSimulation.trendPermille(c, life, topic.id, _network) >= c.economy.trendHotFromPermille,
              onTap: () => setState(() => _topicId = topic.id),
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
          FilledButton.icon(
            onPressed: error == null ? () => _publish(draft) : null,
            icon: const Icon(Icons.send_rounded),
            label: Text(l.publish),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
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

class _TopicTile extends ConsumerWidget {
  const _TopicTile({
    required this.topic,
    required this.selected,
    required this.highlight,
    required this.ownNiche,
    required this.hot,
    required this.onTap,
  });

  final TopicDef topic;
  final bool selected;
  final bool highlight;
  final bool ownNiche;
  final bool hot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Semantics(
        selected: selected,
        button: true,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderColor: selected ? AppColors.violet : (highlight ? AppColors.coral : null),
          onTap: onTap,
          child: Row(
            children: [
              AssetArt(topic.assetKey, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.strings[topic.nameKey], style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (highlight) _Tag(l.startHere, AppColors.coral),
                        _Tag(ownNiche ? l.yourNiche : l.offNiche, ownNiche ? AppColors.mint : AppColors.textMuted),
                        if (hot) _Tag(l.trending, AppColors.amber),
                      ],
                    ),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.violet),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
  );
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.quality, style: t.labelLarge?.copyWith(color: AppColors.textMuted)),
              const Spacer(),
              AnimatedCount(
                value: forecast.quality,
                format: (v) => '$v',
                style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(' / 100', style: t.titleMedium?.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: Space.s),
          for (final e in labels.entries)
            if ((b[e.key] ?? 0) != 0 || e.key == QualityPart.skills)
              BreakdownRow(label: e.value, value: b[e.key] ?? 0, max: 40),
          const Divider(height: Space.l),
          _Line(
            icon: Icons.visibility_rounded,
            text: l.expectedViews(Format.count(forecast.typicalMinViews), Format.count(forecast.typicalMaxViews)),
          ),
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
