import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/engine/game_event.dart';
import '../domain/model/ids.dart';
import '../ui/widgets.dart';
import 'format.dart';
import 'providers.dart';

/// Five labelled tabs (icon + text, never icon-only), each its own stack.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    ref.listen(gameEventsProvider, (_, next) {
      final event = next.value;
      if (event == null) return;
      final message = celebrationText(context, ref, event);
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
    });

    final life = ref.watch(gameControllerProvider.select((s) => s.life));
    final engine = ref.watch(engineProvider);
    final skillPoints = life?.skillPoints ?? 0;
    final storyPending = life != null && engine.pendingStory(life) != null;
    final pending = (life?.pendingIncomeMinor ?? 0) > 0;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: Badge(isLabelVisible: storyPending || pending, child: const Icon(Icons.home_outlined)),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline_rounded),
            selectedIcon: const Icon(Icons.add_circle_rounded),
            label: l.tabCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l.tabSocial,
          ),
          NavigationDestination(
            icon: const Icon(Icons.handshake_outlined),
            selectedIcon: const Icon(Icons.handshake_rounded),
            label: l.tabDeals,
          ),
          NavigationDestination(
            icon: Badge(isLabelVisible: skillPoints > 0, child: const Icon(Icons.person_outline_rounded)),
            selectedIcon: const Icon(Icons.person_rounded),
            label: l.tabLife,
          ),
        ],
      ),
    );
  }

  static String? celebrationText(BuildContext context, WidgetRef ref, GameEvent e) {
    final l = context.l10n;
    final c = ref.read(catalogProvider);
    String networkName(Object? id) => c.strings[c.network(NetworkId.parse(id! as String)).nameKey];
    return switch (e.name) {
      'level_up' => l.celebrateLevelUp(e.params['player_level']! as int),
      'network_unlocked' => l.celebrateUnlocked(networkName(e.params['network_id'])),
      'followers_milestone' => l.celebrateMilestone(
        Format.compact(e.params['milestone']! as int),
        networkName(e.params['network_id']),
      ),
      'story_act_complete' => l.celebrateAct(
        c.strings[c.economy.acts.firstWhere((a) => a.id == e.params['act']).nameKey],
      ),
      _ => null,
    };
  }
}
