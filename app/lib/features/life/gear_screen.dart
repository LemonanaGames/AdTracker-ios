import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../ui/asset_art.dart';
import '../../ui/requirement_view.dart';
import '../../ui/widgets.dart';

/// Gear shop: every item shows Cost → What changes (before/after numbers).
class GearScreen extends ConsumerWidget {
  const GearScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final engine = ref.watch(engineProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final gearNow = life.gearIds.fold<int>(0, (s, id) => s + (c.gearItem(id)?.qualityBonus ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(l.gearShop)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          Text(l.gearIntro(gearNow), style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: Space.m),
          for (final g in c.gear.where((g) => g.enabled))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Builder(
                builder: (context) {
                  final owned = life.gearIds.contains(g.id);
                  final unlocked = engine.rules.isMet(life, g.requirement);
                  final affordable = life.cashMinor >= g.costMinor;
                  return AppCard(
                    child: Row(
                      children: [
                        AssetArt(g.assetKey, size: 48),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.strings[g.nameKey], style: t.titleMedium),
                              Text(
                                owned
                                    ? l.gearOwnedEffect(g.qualityBonus)
                                    : l.gearBeforeAfter(gearNow, gearNow + g.qualityBonus),
                                style: t.bodySmall?.copyWith(color: owned ? AppColors.mint : AppColors.text),
                              ),
                              if (!owned && !unlocked)
                                Text(
                                  shortRequirement(l, c, engine.rules.check(life, g.requirement!)),
                                  style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                                )
                              else if (!owned && !affordable)
                                Text(
                                  l.needMore(Format.cash(g.costMinor - life.cashMinor)),
                                  style: t.bodySmall?.copyWith(color: AppColors.amber),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.s),
                        if (owned)
                          const StatusBadge(BadgeState.done)
                        else if (!unlocked)
                          const StatusBadge(BadgeState.locked)
                        else
                          FilledButton(
                            onPressed: affordable
                                ? () {
                                    if (ref.read(gameControllerProvider.notifier).buyGear(g.id) == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(l.bought(c.strings[g.nameKey]))));
                                    }
                                  }
                                : null,
                            child: Text(Format.cash(g.costMinor)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: Space.s),
          Text(l.moreGearLater, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
