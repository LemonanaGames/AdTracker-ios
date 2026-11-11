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
    final commentKey = 'comment.sample.${Seed.of([post.postId]) % 5 + 1}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: !_revealed
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.publishing, style: t.titleLarge),
                    const SizedBox(height: Space.m),
                    const LinearProgressIndicator(),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.celebration_rounded, size: 48, color: AppColors.coral),
                  const SizedBox(height: Space.s),
                  Text(l.published, style: t.headlineMedium, textAlign: TextAlign.center),
                  if (post.viralTier >= c.economy.viralFromIndex)
                    Text(
                      l.goingViral,
                      style: t.titleMedium?.copyWith(color: AppColors.amber),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: Space.l),
                  Row(
                    children: [
                      _Stat(label: l.newFollowers, value: post.followersGained, color: AppColors.mint),
                      _Stat(label: l.views, value: post.views, color: AppColors.text),
                      _Stat(label: l.likes, value: post.likes, color: AppColors.coral),
                    ],
                  ),
                  const SizedBox(height: Space.m),
                  AppCard(
                    color: AppColors.surfaceHigh,
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: Space.s),
                        Expanded(child: Text('“${c.strings[commentKey]}”', style: t.bodyLarge)),
                      ],
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
                    AppCard(
                      color: AppColors.violet.withValues(alpha: 0.16),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: AppColors.violet),
                          const SizedBox(width: Space.s),
                          Expanded(child: Text(l.tipFollowers)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.l),
                  FilledButton(
                    onPressed: () {
                      ref.read(gameControllerProvider.notifier).markTipSeen(tipFollowers);
                      Navigator.pop(context);
                      context.go(Routes.home);
                    },
                    child: Text(l.backHome),
                  ),
                  const SizedBox(height: Space.s),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(gameControllerProvider.notifier).markTipSeen(tipFollowers);
                      Navigator.pop(context);
                    },
                    child: Text(l.makeAnother),
                  ),
                ],
              ),
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
