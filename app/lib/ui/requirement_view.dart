import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/format.dart';
import '../app/l10n/app_localizations.dart';
import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/content/game_catalog.dart';
import '../domain/content/requirement.dart';
import '../domain/engine/requirement_evaluator.dart';
import '../domain/model/ids.dart';
import '../domain/model/life_state.dart';
import 'widgets.dart';

/// Plain-language text for one requirement leaf, with live numbers.
String describeRequirement(AppLocalizations l, GameCatalog c, RequirementCheck check) {
  final r = check.requirement;
  final s = c.strings;
  String net() => s[c.network(r.network!).nameKey];
  return switch (r.type) {
    RequirementType.always => l.reqAlways,
    RequirementType.anyOf => l.reqAnyOf,
    RequirementType.allOf => l.reqAllOf,
    RequirementType.followers => l.reqFollowers(Format.count(check.current), Format.count(check.target), net()),
    RequirementType.engagement => l.reqEngagement(net(), Format.bps(check.current), Format.bps(check.target)),
    RequirementType.totalFollowers => l.reqTotalFollowers(Format.count(check.current), Format.count(check.target)),
    RequirementType.creatorLevel => l.reqLevel(check.current, check.target),
    RequirementType.act => l.reqAct(s[c.economy.acts[check.target].nameKey]),
    RequirementType.gearOwned => l.reqGear(s[c.gearItem(r.gearId!)!.nameKey]),
    RequirementType.flag => l.reqFlag,
    RequirementType.trust => l.reqTrust(check.current, check.target),
    RequirementType.cash => l.reqCash(Format.cash(check.current), Format.cash(check.target)),
    RequirementType.postViews => l.reqPostViews(Format.count(check.target), Format.count(check.current)),
    RequirementType.stat => switch (r.stat) {
      'postsPublished' => l.reqPosts(check.current, check.target),
      'jobShifts' => l.reqShifts(check.current, check.target),
      'lifetimeClaimedMinor' => l.reqCollect,
      'tubecastPosts' => l.reqNetworkPosts(s[c.network(NetworkId.tubecast).nameKey], check.current, check.target),
      'vibePosts' => l.reqNetworkPosts(s[c.network(NetworkId.vibe).nameKey], check.current, check.target),
      _ => l.reqGeneric(check.current, check.target),
    },
  };
}

/// Short single-line summary for compact cards ("Level 3", "Reach Act I").
String shortRequirement(AppLocalizations l, GameCatalog c, RequirementCheck check) {
  final leaves = check.leafChecks.where((x) => !x.met).toList();
  if (leaves.isEmpty) return l.badgeReady;
  final best = leaves.reduce((a, b) => a.progressPermille >= b.progressPermille ? a : b);
  return describeRequirement(l, c, best);
}

/// Checklist with ✓/lock icons and progress bars (never colour-only).
class RequirementChecklist extends ConsumerWidget {
  const RequirementChecklist({required this.requirement, required this.life, super.key});
  final Requirement requirement;
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final check = RequirementEvaluator(c).check(life, requirement);
    return _node(context, c, check, 0);
  }

  Widget _node(BuildContext context, GameCatalog c, RequirementCheck check, int depth) {
    final l = context.l10n;
    final theme = Theme.of(context);
    if (check.children.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: depth * 12.0, bottom: 4),
            child: Text(
              describeRequirement(l, c, check),
              style: theme.textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
          for (final child in check.children) _node(context, c, child, depth + 1),
        ],
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(start: depth * 12.0, bottom: Space.s),
      child: Row(
        children: [
          Icon(
            check.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: check.met ? AppColors.mint : AppColors.textMuted,
            semanticLabel: check.met ? l.badgeDone : l.badgeLocked,
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeRequirement(l, c, check), style: theme.textTheme.bodyMedium),
                if (!check.met && check.target > 1) ...[
                  const SizedBox(height: 4),
                  ProgressBar(permille: check.progressPermille, height: 5),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
