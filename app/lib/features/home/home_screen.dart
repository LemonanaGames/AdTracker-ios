import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/engine/history.dart';
import '../../domain/engine/progression.dart';
import '../../domain/model/ids.dart';
import '../../domain/model/life_state.dart';
import '../../ui/asset_art.dart';
import '../../ui/characters.dart';
import '../../ui/charts.dart';
import '../../ui/chunky_button.dart';
import '../../ui/motion.dart';
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

    var i = 0;
    Widget item(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stagger(index: i++, child: child),
    );

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, Space.s),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background.withValues(alpha: 0), AppColors.background],
          ),
        ),
        child: ChunkyButton(
          label: l.createPost,
          icon: Icons.videocam_rounded,
          color: AppColors.coral,
          onPressed: () => context.go(Routes.create),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.m, Space.l),
          children: [
            item(_Header(life: life, storyPending: story != null)),
            if (session.awaySummary != null) item(const _AwayCard()),
            if (life.counter(Counters.postsPublished) == 0) item(const _IntroCard()),
            if (life.pendingIncomeMinor > 0) item(_CollectCard(amount: life.pendingIncomeMinor)),
            if (story != null)
              item(
                _StoryCard(
                  title: ref.watch(catalogProvider).strings[story.titleKey],
                  preview: ref.watch(catalogProvider).strings[story.lines.first.textKey],
                  speakerAsset: ref.watch(catalogProvider).character(story.lines.first.speaker)!.assetKey,
                  onTap: () => showStorySheet(context, story.id),
                ),
              ),
            item(_FollowersCard(life: life)),
            item(_GoalCard(life: life)),
            item(_NetworkRow(life: life)),
            if (life.posts.isNotEmpty) ...[
              SectionHeader(
                l.latestPost,
                trailing: TextButton(onPressed: () => context.go(Routes.social), child: Text(l.seeAll)),
              ),
              item(_LatestPostCard(life: life)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.life, required this.storyPending});
  final LifeState life;
  final bool storyPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final e = ref.watch(catalogProvider).economy;
    final level = Progression.levelForXp(e, life.creatorXp);
    final p = Progression.levelProgress(e, life.creatorXp);
    final look = CharacterLooks.all[life.avatar.presetId];
    final pills = Row(
      children: [
        Expanded(
          child: StatPill(
            icon: Icons.bolt_rounded,
            color: AppColors.amber,
            label: l.energy,
            value: Text('${life.energy}'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FloatingDelta(
            value: life.cashMinor,
            format: (d) => '+${Format.cash(d)}',
            child: StatPill(
              icon: Icons.payments_rounded,
              color: AppColors.mint,
              label: l.cash,
              value: AnimatedCount(value: life.cashMinor, format: Format.cash),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatPill(
            icon: Icons.star_rounded,
            color: AppColors.violet,
            label: l.skillPoints,
            value: Text('${life.skillPoints}'),
          ),
        ),
      ],
    );
    return Column(children: [_identity(context, l, level, p, look), const SizedBox(height: 12), pills]);
  }

  Widget _identity(BuildContext context, AppLocalizations l, int level, ({int into, int span}) p, CharacterLook? look) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(Routes.life),
          child: Semantics(
            label: life.avatar.displayName,
            image: true,
            child: look == null
                ? AssetArt(life.avatar.presetId, size: 46, circle: true)
                : CharacterAvatar(
                    look,
                    size: 46,
                    ring: const SweepGradient(
                      colors: [AppColors.coral, AppColors.amber, AppColors.violet, AppColors.coral],
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                life.avatar.handle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      l.levelShort(level),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ProgressBar(
                      permille: p.span == 0 ? 1000 : p.into * 1000 ~/ p.span,
                      height: 5,
                      color: AppColors.violet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _ChatBubble(speakerAsset: 'npc_maya', name: l.mayaName, text: l.introMaya);
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.speakerAsset, required this.name, required this.text});
  final String speakerAsset;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AssetArt(speakerAsset, size: 40, circle: true),
      const SizedBox(width: Space.s),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(18),
              topEnd: Radius.circular(18),
              bottomEnd: Radius.circular(18),
              bottomStart: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mint, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    ],
  );
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.title, required this.preview, required this.speakerAsset, required this.onTap});
  final String title;
  final String preview;
  final String speakerAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Space.radius),
          gradient: LinearGradient(
            colors: [AppColors.violet.withValues(alpha: 0.32), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PulseDot(color: AppColors.violet),
                Text(
                  context.l10n.newStory.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                    color: AppColors.violet,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppColors.violet),
              ],
            ),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.s),
            Row(
              children: [
                AssetArt(speakerAsset, size: 28, circle: true),
                const SizedBox(width: Space.s),
                Expanded(
                  child: Text(
                    '“$preview”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AwayCard extends ConsumerWidget {
  const _AwayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(gameControllerProvider).awaySummary!;
    final t = Theme.of(context).textTheme;
    Widget stat(String value, String label, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w800, fontSize: 22, color: color),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
    return AppCard(
      borderColor: AppColors.mint.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, color: AppColors.mint, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(l.awayTitle, style: t.titleMedium)),
            ],
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              stat('+${Format.compact(s.viewsGained)}', l.views, AppColors.text),
              stat('+${Format.compact(s.followersGained)}', l.followers, AppColors.mint),
              stat(Format.cash(s.incomeGainedMinor), l.earningsReady, AppColors.amber),
            ],
          ),
          // Kept for screen readers and tests: the full sentence.
          Offstage(child: Text(l.awayViews(Format.count(s.viewsGained)))),
          if (s.cappedRealMs > 0) ...[
            const SizedBox(height: Space.s),
            Text(
              l.awayCapped(ref.watch(catalogProvider).economy.freeOfflineHours),
              style: t.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
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

class _CollectCard extends ConsumerStatefulWidget {
  const _CollectCard({required this.amount});
  final int amount;

  @override
  ConsumerState<_CollectCard> createState() => _CollectCardState();
}

class _CollectCardState extends ConsumerState<_CollectCard> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final moving = ambientMotion(context, ref);
    if (moving && !_bob.isAnimating) _bob.repeat(reverse: true);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Space.radius),
        color: AppColors.mint.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _bob,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, -4 * Curves.easeInOut.transform(_bob.value)),
              child: Transform.rotate(angle: 0.08 * math.sin(_bob.value * math.pi), child: child),
            ),
            child: const _CoinStack(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.earningsReady, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                AnimatedCount(
                  value: widget.amount,
                  format: Format.cash,
                  style: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w800, fontSize: 26),
                ),
              ],
            ),
          ),
          ChunkyButton(
            label: l.collect,
            expand: false,
            height: 46,
            color: AppColors.mint,
            foreground: AppColors.background,
            sfx: null,
            onPressed: () => ref.read(gameControllerProvider.notifier).collectIncome(),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  const _CoinStack();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      children: [
        for (var i = 0; i < 3; i++)
          Positioned(
            left: 4 + i * 3.0,
            bottom: i * 7.0,
            child: Container(
              width: 30,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB57B16), width: 2),
              ),
            ),
          ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber,
              border: Border.all(color: const Color(0xFFB57B16), width: 2),
            ),
            alignment: Alignment.center,
            child: const Text(
              r'$',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF7A4E05)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FollowersCard extends ConsumerWidget {
  const _FollowersCard({required this.life});
  final LifeState life;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = ref.watch(catalogProvider);
    final reach = ref.watch(engineProvider).estimatedUniqueReach(life);
    final history = History.followers(c, life, windowSimMs: 24 * 3600 * 1000);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AmbientBlobs(
        colors: const [AppColors.coral, AppColors.violet, AppColors.sky],
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.totalFollowersAcross,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ),
                  InfoButton(title: l.totalFollowersAcross, body: l.totalFollowersInfo),
                ],
              ),
              FloatingDelta(
                value: life.totalFollowers,
                child: AnimatedCount(
                  value: life.totalFollowers,
                  format: Format.count,
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 54,
                    height: 1,
                  ),
                  semanticsLabel: l.totalFollowersAcross,
                ),
              ),
              const SizedBox(height: Space.s),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Sparkline(values: history, color: AppColors.mint, height: 40),
              ),
              const SizedBox(height: 6),
              Text(
                l.uniqueReach(Format.count(reach)),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
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
    if (goal == null) return AppCard(child: Text(l.allGoalsDone, style: t.titleMedium));
    return AppCard(
      onTap: () => context.go(goal.goal.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Sticker(l.nextGoal, color: AppColors.coral, icon: Icons.flag_rounded),
              const Spacer(),
              Text(l.go, style: t.labelLarge?.copyWith(color: AppColors.coral)),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.coral, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(c.strings[goal.goal.titleKey], style: t.titleLarge),
          const SizedBox(height: 10),
          ProgressBar(permille: goal.check.progressPermille, color: AppColors.coral, height: 10),
          const SizedBox(height: 6),
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
    final rules = ref.watch(engineProvider).rules;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, id) in NetworkId.values.indexed) ...[
            if (i > 0) const SizedBox(width: Space.s),
            Expanded(
              child: Builder(
                builder: (context) {
                  final def = c.network(id);
                  final state = life.network(id);
                  final color = AppColors.hex(def.colorHex);
                  return Pressable(
                    onTap: () => context.go(Routes.socialFor(id.name)),
                    child: GestureDetector(
                      onTap: () => context.go(Routes.socialFor(id.name)),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Space.radius),
                          border: Border.all(color: state.unlocked ? color.withValues(alpha: 0.5) : AppColors.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 6, color: state.unlocked ? color : AppColors.outline),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      AssetArt(def.assetKey, size: 24),
                                      const Spacer(),
                                      if (!state.unlocked)
                                        const Icon(Icons.lock_rounded, size: 15, color: AppColors.textMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    c.strings[def.nameKey],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: state.unlocked ? color : AppColors.textMuted,
                                    ),
                                  ),
                                  if (state.unlocked) ...[
                                    AnimatedCount(
                                      value: state.followers,
                                      format: Format.compact,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.display,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      l.engagementShort(Format.bps(state.engagementRateBps)),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ] else ...[
                                    Text(
                                      l.badgeLocked,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.display,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      shortRequirement(l, c, rules.check(life, def.unlock)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
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
    final color = AppColors.hex(net.colorHex);
    final topic = c.topic(post.topicId)!;
    return AppCard(
      onTap: () => context.go(Routes.post(post.postId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssetArt(topic.assetKey, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.strings[topic.nameKey], style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      c.strings[net.nameKey],
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (post.complete)
                const StatusBadge(BadgeState.done)
              else
                Row(
                  children: [
                    PulseDot(color: color, size: 7),
                    Text(
                      l.live,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1, color: color),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Space.s),
          ViewsChart(
            post: post,
            network: net,
            nowSimMs: life.simTimeMs,
            color: color,
            height: 90,
            semanticLabel: l.chartLabel,
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(
                child: _Mini(label: l.views, value: post.views, icon: Icons.visibility_rounded),
              ),
              Expanded(
                child: _Mini(label: l.likes, value: post.likes, icon: Icons.favorite_rounded),
              ),
              Expanded(
                child: _Mini(label: l.newFollowers, value: post.followersGained, icon: Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          AnimatedCount(
            value: value,
            format: Format.compact,
            style: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ],
  );
}
