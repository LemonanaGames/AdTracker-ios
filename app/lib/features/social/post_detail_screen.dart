import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/engine/post_simulation.dart';
import '../../ui/asset_art.dart';
import '../../ui/views_chart.dart';
import '../../ui/widgets.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({required this.postId, super.key});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final post = life.posts.where((p) => p.postId == postId).firstOrNull;
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.postMissing)),
      );
    }
    final net = c.network(post.networkId);
    final topic = c.topic(post.topicId)!;

    final labels = {
      QualityPart.nicheFit: l.qNicheFit,
      QualityPart.gear: l.qGear,
      QualityPart.hook: l.qHook,
      QualityPart.skills: l.qSkills,
      QualityPart.storyBonus: l.qStory,
      QualityPart.stress: l.qStress,
    };

    return Scaffold(
      appBar: AppBar(title: Text(c.strings[topic.nameKey])),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssetArt(net.assetKey, size: 28),
                    const SizedBox(width: Space.s),
                    Expanded(child: Text(c.strings[net.nameKey], style: t.titleMedium)),
                    StatusBadge(post.complete ? BadgeState.done : BadgeState.inProgress),
                  ],
                ),
                const SizedBox(height: Space.m),
                ViewsChart(
                  post: post,
                  network: net,
                  nowSimMs: life.simTimeMs,
                  color: AppColors.hex(net.colorHex),
                  height: 160,
                  semanticLabel: l.chartLabel,
                ),
                const SizedBox(height: Space.s),
                Text(l.chartCaption, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          AppCard(
            child: Column(
              children: [
                _Row(l.views, Format.count(post.views)),
                _Row(l.likes, Format.count(post.likes)),
                _Row(l.comments, Format.count(post.comments)),
                _Row(l.shares, Format.count(post.shares)),
                _Row(l.newFollowers, Format.count(post.followersGained)),
                _Row(l.earnedHere, Format.cash(post.revenueMinor)),
              ],
            ),
          ),
          SectionHeader(l.whyQuality(post.qualityScore)),
          AppCard(
            child: Column(
              children: [
                for (final e in labels.entries)
                  if ((post.qualityBreakdown[e.key] ?? 0) != 0)
                    BreakdownRow(label: e.value, value: post.qualityBreakdown[e.key]!, max: 40),
                const SizedBox(height: Space.s),
                Text(
                  post.viralTier >= c.economy.viralFromIndex ? l.luckViral : l.luckNormal,
                  style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
