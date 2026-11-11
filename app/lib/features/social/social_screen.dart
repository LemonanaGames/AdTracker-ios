import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/model/ids.dart';
import '../../ui/asset_art.dart';
import '../../ui/requirement_view.dart';
import '../../ui/widgets.dart';

/// Per-network dashboards. Networks are always shown separately.
class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({this.initialNetwork, super.key});
  final String? initialNetwork;

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  late NetworkId _network = _parse(widget.initialNetwork);

  static NetworkId _parse(String? raw) =>
      NetworkId.values.firstWhere((n) => n.name == raw, orElse: () => NetworkId.loop);

  @override
  void didUpdateWidget(SocialScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialNetwork != old.initialNetwork && widget.initialNetwork != null) {
      _network = _parse(widget.initialNetwork);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(catalogProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final def = c.network(_network);
    final state = life.network(_network);
    final color = AppColors.hex(def.colorHex);
    final posts = life.posts.where((p) => p.networkId == _network).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.tabSocial)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          Wrap(
            spacing: Space.s,
            children: [
              for (final id in NetworkId.values)
                ChoiceChip(
                  avatar: life.network(id).unlocked ? null : const Icon(Icons.lock_rounded, size: 16),
                  label: Text(c.strings[c.network(id).nameKey]),
                  selected: id == _network,
                  onSelected: (_) => setState(() => _network = id),
                ),
            ],
          ),
          const SizedBox(height: Space.m),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssetArt(def.assetKey, size: 40),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.strings[def.nameKey], style: t.titleLarge?.copyWith(color: color)),
                          Text(c.strings[def.taglineKey], style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.m),
                if (!state.unlocked) ...[
                  Text(l.unlockHow, style: t.titleSmall),
                  const SizedBox(height: Space.s),
                  RequirementChecklist(requirement: def.unlock, life: life),
                ] else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.3,
                    children: [
                      _Metric(label: l.followers, value: Format.count(state.followers), info: l.followersInfo),
                      _Metric(label: l.views7d, value: Format.count(state.last7dViews), info: l.views7dInfo),
                      _Metric(label: l.engagement, value: Format.bps(state.engagementRateBps), info: l.engagementInfo),
                      _Metric(label: l.earnedHere, value: Format.cash(state.revenueLifetimeMinor), info: l.earnedInfo),
                    ],
                  ),
              ],
            ),
          ),
          if (state.unlocked) ...[
            SectionHeader(l.posts),
            if (posts.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Text(l.noPostsYet, style: t.bodyLarge),
                    const SizedBox(height: Space.s),
                    FilledButton(onPressed: () => context.go(Routes.create), child: Text(l.createPost)),
                  ],
                ),
              ),
            for (final p in posts)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.go(Routes.post(p.postId)),
                  child: Row(
                    children: [
                      AssetArt(c.topic(p.topicId)!.assetKey, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.strings[c.topic(p.topicId)!.nameKey],
                              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              l.postLine(
                                Format.compact(p.views),
                                Format.compact(p.likes),
                                Format.compact(p.followersGained),
                              ),
                              style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(p.complete ? BadgeState.done : BadgeState.inProgress),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.info});
  final String label;
  final String value;
  final String info;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: t.titleLarge),
              Text(label, style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        InfoButton(title: label, body: info),
      ],
    );
  }
}
