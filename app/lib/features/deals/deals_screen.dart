import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/content/game_catalog.dart';
import '../../domain/model/life_state.dart';
import '../../ui/asset_art.dart';
import '../../ui/widgets.dart';

/// M1: sponsor offers are not implemented yet. This tab honestly says so and
/// previews what brands will check, using the live per-network stats.
class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final seed = c.sponsorTiers.first;

    return Scaffold(
      appBar: AppBar(title: Text(l.tabDeals)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          AppCard(
            color: AppColors.violet.withValues(alpha: 0.12),
            child: Row(
              children: [
                const Icon(Icons.construction_rounded, color: AppColors.violet),
                const SizedBox(width: Space.m),
                Expanded(child: Text(l.dealsComingSoon, style: t.bodyLarge)),
              ],
            ),
          ),
          SectionHeader(l.dealsWhatBrandsCheck),
          _TierCard(tier: seed, life: life, catalog: c),
          SectionHeader(l.dealsLaterTiers),
          for (final tier in c.sponsorTiers.skip(1))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    AssetArt(c.network(tier.network).assetKey, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.strings[tier.nameKey], style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            l.tierLine(Format.compact(tier.minFollowers), c.strings[c.network(tier.network).nameKey]),
                            style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const StatusBadge(BadgeState.locked),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.life, required this.catalog});
  final SponsorTierDef tier;
  final LifeState life;
  final GameCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final n = life.network(tier.network);
    final name = catalog.strings[catalog.network(tier.network).nameKey];
    final rows = [
      (l.followersOn(name), n.followers, tier.minFollowers, Format.count),
      (l.views7dOn(name), n.last7dViews, tier.min7dViews, Format.count),
      (l.engagementOn(name), n.engagementRateBps, tier.minEngagementBps, Format.bps),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.tierTitle(catalog.strings[tier.nameKey], name), style: t.titleMedium),
          Text(
            l.tierReward(Format.cash(tier.rewardMinMinor), Format.cash(tier.rewardMaxMinor)),
            style: t.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: Space.m),
          for (final (label, current, target, fmt) in rows) ...[
            Row(
              children: [
                Icon(
                  current >= target ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: current >= target ? AppColors.mint : AppColors.textMuted,
                ),
                const SizedBox(width: Space.s),
                Expanded(child: Text(label)),
                Text('${fmt(current)} / ${fmt(target)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            ProgressBar(permille: target == 0 ? 1000 : current * 1000 ~/ target, height: 5),
            const SizedBox(height: Space.s),
          ],
          if (!n.unlocked) Text(l.networkLockedNote(name), style: t.bodySmall?.copyWith(color: AppColors.amber)),
        ],
      ),
    );
  }
}
