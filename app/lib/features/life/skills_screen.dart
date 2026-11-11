import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/content/game_catalog.dart';
import '../../ui/asset_art.dart';
import '../../ui/widgets.dart';

/// Six skills, one clear effect each, always with a Before → After preview.
class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  static String effectText(AppLocalizations l, SkillDef s, int rank) {
    final v = rank * s.perRank;
    return switch (s.effectKind) {
      SkillEffectKind.qualityTenths => l.skillQuality('${v ~/ 10}.${v % 10}'),
      SkillEffectKind.viewsPermille => l.skillLongViews('${v ~/ 10}.${v % 10}'),
      SkillEffectKind.reachPermille => l.skillReach('${v ~/ 10}.${v % 10}'),
      SkillEffectKind.none => l.skillNotYet,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.skills)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          AppCard(
            color: AppColors.violet.withValues(alpha: 0.12),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.violet, size: 32),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.skillPointsCount(life.skillPoints), style: t.titleMedium),
                      Text(l.skillPointsHow, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          for (final s in c.skills)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Builder(
                builder: (context) {
                  final rank = life.skillRank(s.id);
                  final maxed = rank >= s.maxRank;
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AssetArt(s.assetKey, size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.strings[s.nameKey], style: t.titleMedium),
                                  Text(
                                    l.rankOf(rank, s.maxRank),
                                    style: t.labelMedium?.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (!s.enabled)
                              StatusBadge(BadgeState.locked, label: l.soon)
                            else if (maxed)
                              const StatusBadge(BadgeState.done)
                            else
                              FilledButton.tonal(
                                onPressed: life.skillPoints > 0
                                    ? () => ref.read(gameControllerProvider.notifier).spendSkillPoint(s.id)
                                    : null,
                                child: Text(l.plusOne),
                              ),
                          ],
                        ),
                        const SizedBox(height: Space.s),
                        Text(c.strings[s.descKey], style: t.bodyMedium),
                        if (s.enabled) ...[
                          const SizedBox(height: 4),
                          Text(
                            maxed
                                ? effectText(l, s, rank)
                                : l.beforeAfter(effectText(l, s, rank), effectText(l, s, rank + 1)),
                            style: t.bodySmall?.copyWith(color: AppColors.mint, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
