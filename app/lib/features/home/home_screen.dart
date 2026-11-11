import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/engine/progression.dart';
import '../../domain/model/ids.dart';
import '../../domain/model/life_state.dart';
import '../../ui/asset_art.dart';
import '../../ui/requirement_view.dart';
import '../../ui/views_chart.dart';
import '../../ui/widgets.dart';
import '../stories/story_sheet.dart';

/// Home: answers "what can I do next?" in 3 seconds (GDD D1/I5).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider);
    final life = session.life;
    if (life == null) return const SizedBox.shrink();
    final engine = ref.watch(engineProvider);
    final story = engine.pendingStory(life);
    final l = context.l10n;

    return Scaffold(
      // The primary action is pinned so it is always one tap away.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, Space.s),
        child: FilledButton.icon(
          onPressed: () => context.go(Routes.create),
          icon: const Icon(Icons.add_circle_rounded),
          label: Text(l.createPost),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, Space.xl),
          children: [
            _Header(life: life),
            const SizedBox(height: Space.m),
            if (session.awaySummary != null) ...[const _AwayCard(), const SizedBox(height: Space.m)],
            if (life.counter(Counters.postsPublished) == 0) ...[_IntroCard(), const SizedBox(height: Space.m)],
            if (life.pendingIncomeMinor > 0) ...[
              _CollectCard(amount: life.pendingIncomeMinor),
              const SizedBox(height: Space.m),
            ],
            if (story != null) ...[
              AppCard(
                borderColor: AppColors.violet,
                onTap: () => showStorySheet(context, story.id),
                child: Row(
                  children: [
                    const AssetArt('npc_maya', size: 48, circle: true),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.newStory,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.violet),
                          ),
                          Text(
                            ref.watch(catalogProvider).strings[story.titleKey],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
            ],
            _FollowersCard(life: life),
            const SizedBox(height: Space.m),
            _GoalCard(life: life),
            const SizedBox(height: Space.m),
            _NetworkRow(life: life),
            if (life.posts.isNotEmpty) ...[
              SectionHeader(
                l.latestPost,
                trailing: TextButton(onPressed: () => context.go(Routes.social), child: Text(l.seeAll)),
              ),
              _LatestPostCard(life: life),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final level = Progression.levelForXp(ref.watch(catalogProvider).economy, life.creatorXp);
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(Routes.life),
          child: AssetArt(life.avatar.presetId, size: 44, circle: true, semanticLabel: life.avatar.displayName),
        ),
        const SizedBox(width: Space.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(life.avatar.handle, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
              Text(
                l.levelShort(level),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        StatPill(icon: Icons.bolt_rounded, color: AppColors.amber, label: l.energy, value: Text('${life.energy}')),
        const SizedBox(width: 6),
        StatPill(
          icon: Icons.payments_rounded,
          color: AppColors.mint,
          label: l.cash,
          value: AnimatedCount(value: life.cashMinor, format: Format.cash),
        ),
        const SizedBox(width: 6),
        StatPill(
          icon: Icons.star_rounded,
          color: AppColors.violet,
          label: l.skillPoints,
          value: Text('${life.skillPoints}'),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssetArt('npc_maya', size: 44, circle: true),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.mayaName, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.mint)),
                const SizedBox(height: 2),
                Text(l.introMaya, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AwayCard extends ConsumerWidget {
  const _AwayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(gameControllerProvider).awaySummary!;
    final t = Theme.of(context).textTheme;
    return AppCard(
      borderColor: AppColors.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.awayTitle, style: t.titleMedium),
          const SizedBox(height: Space.s),
          Text(l.awayViews(Format.count(s.viewsGained))),
          Text(l.awayFollowers(Format.count(s.followersGained))),
          Text(l.awayIncome(Format.cash(s.incomeGainedMinor))),
          if (s.cappedRealMs > 0) ...[
            const SizedBox(height: Space.s),
            Text(
              l.awayCapped(ref.watch(catalogProvider).economy.freeOfflineHours),
              style: t.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: Space.s),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => ref.read(gameControllerProvider.notifier).dismissAwaySummary(),
              child: Text(l.gotIt),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectCard extends ConsumerWidget {
  const _CollectCard({required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AppCard(
      color: AppColors.mint.withValues(alpha: 0.12),
      borderColor: AppColors.mint.withValues(alpha: 0.6),
      child: Row(
        children: [
          const Icon(Icons.savings_rounded, color: AppColors.mint, size: 32),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.earningsReady, style: Theme.of(context).textTheme.labelMedium),
                AnimatedCount(value: amount, format: Format.cash, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.mint, foregroundColor: AppColors.background),
            onPressed: () {
              final got = ref.read(gameControllerProvider.notifier).collectIncome();
              if (got > 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.collected(Format.cash(got)))));
              }
            },
            child: Text(l.collect),
          ),
        ],
      ),
    );
  }
}

class _FollowersCard extends ConsumerWidget {
  const _FollowersCard({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final reach = ref.watch(engineProvider).estimatedUniqueReach(life);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.totalFollowersAcross, style: t.labelLarge?.copyWith(color: AppColors.textMuted)),
              ),
              InfoButton(title: l.totalFollowersAcross, body: l.totalFollowersInfo),
            ],
          ),
          AnimatedCount(
            value: life.totalFollowers,
            format: Format.count,
            style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            semanticsLabel: l.totalFollowersAcross,
          ),
          const SizedBox(height: 2),
          Text(l.uniqueReach(Format.count(reach)), style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = ref.watch(catalogProvider);
    final goal = ref.watch(engineProvider).currentGoal(life);
    final t = Theme.of(context).textTheme;
    if (goal == null) {
      return AppCard(child: Text(l.allGoalsDone, style: t.titleMedium));
    }
    return AppCard(
      onTap: () => context.go(goal.goal.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.coral, size: 18),
              const SizedBox(width: 6),
              Text(l.nextGoal, style: t.labelLarge?.copyWith(color: AppColors.coral)),
              const Spacer(),
              Text(l.go, style: t.labelLarge?.copyWith(color: AppColors.violet)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.violet),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.strings[goal.goal.titleKey], style: t.titleMedium),
          const SizedBox(height: Space.s),
          ProgressBar(permille: goal.check.progressPermille, color: AppColors.coral),
          const SizedBox(height: 4),
          Text(shortRequirement(l, c, goal.check), style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _NetworkRow extends ConsumerWidget {
  const _NetworkRow({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final rules = ref.watch(engineProvider).rules;
    return Row(
      children: [
        for (final (i, id) in NetworkId.values.indexed) ...[
          if (i > 0) const SizedBox(width: Space.s),
          Expanded(
            child: Builder(
              builder: (context) {
                final def = c.network(id);
                final state = life.network(id);
                final color = AppColors.hex(def.colorHex);
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.go(Routes.socialFor(id.name)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AssetArt(def.assetKey, size: 26),
                          const Spacer(),
                          if (!state.unlocked) const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: Space.s),
                      Text(c.strings[def.nameKey], style: t.labelLarge?.copyWith(color: color)),
                      if (state.unlocked) ...[
                        AnimatedCount(value: state.followers, format: Format.compact, style: t.titleLarge),
                        Text(
                          l.engagementShort(Format.bps(state.engagementRateBps)),
                          style: t.labelSmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ] else ...[
                        Text(l.badgeLocked, style: t.titleMedium?.copyWith(color: AppColors.textMuted)),
                        Text(
                          shortRequirement(l, c, rules.check(life, def.unlock)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.labelSmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestPostCard extends ConsumerWidget {
  const _LatestPostCard({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final l = context.l10n;
    final post = life.posts.last;
    final net = c.network(post.networkId);
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => context.go(Routes.post(post.postId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssetArt(c.topic(post.topicId)!.assetKey, size: 36),
              const SizedBox(width: Space.s),
              Expanded(child: Text(c.strings[c.topic(post.topicId)!.nameKey], style: t.titleMedium)),
              StatusBadge(post.complete ? BadgeState.done : BadgeState.inProgress),
            ],
          ),
          const SizedBox(height: Space.s),
          ViewsChart(
            post: post,
            network: net,
            nowSimMs: life.simTimeMs,
            color: AppColors.hex(net.colorHex),
            height: 90,
            semanticLabel: l.chartLabel,
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(
                child: _Mini(label: l.views, value: post.views),
              ),
              Expanded(
                child: _Mini(label: l.likes, value: post.likes),
              ),
              Expanded(
                child: _Mini(label: l.newFollowers, value: post.followersGained),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AnimatedCount(value: value, format: Format.compact, style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
    ],
  );
}
