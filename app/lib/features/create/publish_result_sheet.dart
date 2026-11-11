import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/rng.dart';
import '../../domain/engine/post_simulation.dart';
import '../../ui/chunky_button.dart';
import '../../ui/motion.dart';
import '../../ui/widgets.dart';

const tipFollowers = 'tip_followers';

Future<void> showPublishResult(BuildContext context, String postId) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => PublishResultSheet(postId: postId),
);

/// "Published!" moment: a short publishing beat, then live-updating counters
/// (they keep rolling as the foreground simulation credits the post).
class PublishResultSheet extends ConsumerStatefulWidget {
  const PublishResultSheet({required this.postId, super.key});
  final String postId;

  @override
  ConsumerState<PublishResultSheet> createState() => _PublishResultSheetState();
}

class _PublishResultSheetState extends ConsumerState<PublishResultSheet> {
  bool _revealed = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer(
      MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 200) : const Duration(milliseconds: 1100),
      () => mounted ? setState(() => _revealed = true) : null,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = ref.watch(catalogProvider);
    final session = ref.watch(gameControllerProvider);
    final post = session.life!.posts.firstWhere((p) => p.postId == widget.postId);
    final showTip = !session.account.seenTips.contains(tipFollowers);

    final askNotifications = session.account.notificationsOptIn == null;
    final comments = [
      for (var i = 0; i < 2; i++) 'comment.sample.${(Seed.of([post.postId]) + i * 2) % 5 + 1}',
    ];
    void close({required bool home}) {
      ref.read(gameControllerProvider.notifier).markTipSeen(tipFollowers);
      Navigator.pop(context);
      if (home) context.go(Routes.home);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: !_revealed
            ? const _Uploading()
            : Stack(
                children: [
                  Positioned.fill(child: ConfettiBurst(seed: Seed.of([post.postId]))),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stagger(
                        index: 0,
                        child: Column(
                          children: [
                            Text(l.published, style: t.displaySmall, textAlign: TextAlign.center),
                            if (post.viralTier >= c.economy.viralFromIndex) ...[
                              const SizedBox(height: 6),
                              Center(
                                child: Sticker(
                                  l.goingViral,
                                  color: AppColors.amber,
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.l),
                      Stagger(
                        index: 1,
                        child: Row(
                          children: [
                            _Stat(label: l.newFollowers, value: post.followersGained, color: AppColors.mint),
                            _Stat(label: l.views, value: post.views, color: AppColors.text),
                            _Stat(label: l.likes, value: post.likes, color: AppColors.coral),
                          ],
                        ),
                      ),
                      const SizedBox(height: Space.m),
                      for (final (i, key) in comments.indexed)
                        Stagger(
                          index: 2 + i * 2,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Align(
                              alignment: i.isEven ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: i.isEven ? AppColors.surfaceHigh : AppColors.violet.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text('“${c.strings[key]}”', style: t.bodyMedium),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: Space.s),
                      Text(
                        l.qualityAndXp(post.qualityScore, PostSimulation.xpFor(c, post.qualityScore)),
                        style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        l.keepsGrowing,
                        style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      if (showTip) ...[
                        const SizedBox(height: Space.m),
                        Stagger(
                          index: 6,
                          child: AppCard(
                            color: AppColors.violet.withValues(alpha: 0.16),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: AppColors.violet),
                                const SizedBox(width: Space.s),
                                Expanded(child: Text(l.tipFollowers)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (askNotifications) ...[
                        const SizedBox(height: Space.s),
                        Stagger(index: 7, child: const _NotifyOptIn()),
                      ],
                      const SizedBox(height: Space.l),
                      ChunkyButton(label: l.backHome, onPressed: () => close(home: true)),
                      const SizedBox(height: Space.s),
                      TextButton(onPressed: () => close(home: false), child: Text(l.makeAnother)),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Upload beat: a phone with a filling progress ring.
class _Uploading extends StatelessWidget {
  const _Uploading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          builder: (_, v, _) => SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: v,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: AppColors.coral,
                    backgroundColor: AppColors.surfaceHigh,
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -6 * v),
                  child: const Icon(Icons.cloud_upload_rounded, size: 40, color: AppColors.text),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.m),
        Text(context.l10n.publishing, style: Theme.of(context).textTheme.titleLarge),
      ],
    ),
  );
}

/// Contextual opt-in: asked once, right after the first post, with a clear promise.
class _NotifyOptIn extends ConsumerWidget {
  const _NotifyOptIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(Space.radius),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: AppColors.amber),
              const SizedBox(width: Space.s),
              Expanded(child: Text(l.notifyAskTitle, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.notifyAskBody, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: l.notifyYes,
                  height: 42,
                  color: AppColors.amber,
                  foreground: AppColors.background,
                  onPressed: () => ref.read(gameControllerProvider.notifier).setNotifications(true),
                ),
              ),
              const SizedBox(width: Space.s),
              TextButton(
                onPressed: () => ref.read(gameControllerProvider.notifier).setNotifications(false),
                child: Text(l.notifyNo),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedCount(
          value: value,
          format: Format.compact,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
          semanticsLabel: label,
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted)),
      ],
    ),
  );
}
