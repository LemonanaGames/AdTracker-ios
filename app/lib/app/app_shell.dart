import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/celebrations/celebration_overlay.dart';
import '../ui/widgets.dart';
import 'game_controller.dart';
import 'providers.dart';
import 'theme.dart';

/// Five labelled tabs (icon + text, never icon-only), each its own stack,
/// with Create raised in the middle as the primary action.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gameEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) reactToEvent(context, ref, event);
    });

    final life = ref.watch(gameControllerProvider.select((s) => s.life));
    final engine = ref.watch(engineProvider);
    final storyPending = life != null && engine.pendingStory(life) != null;
    final homeBadge = storyPending || (life?.pendingIncomeMinor ?? 0) > 0;
    final lifeBadge = (life?.skillPoints ?? 0) > 0;

    return Stack(
      children: [
        Scaffold(
          body: shell,
          extendBody: false,
          bottomNavigationBar: GameNavBar(
            index: shell.currentIndex,
            badges: {0: homeBadge, 4: lifeBadge},
            onSelect: (i) {
              ref.read(gameControllerProvider.notifier).feedback(null, Haptic.selection);
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
          ),
        ),
        const Positioned.fill(child: CelebrationOverlay()),
      ],
    );
  }
}

class GameNavBar extends StatelessWidget {
  const GameNavBar({required this.index, required this.onSelect, this.badges = const {}, super.key});
  final int index;
  final ValueChanged<int> onSelect;
  final Map<int, bool> badges;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      (Icons.home_rounded, l.tabHome),
      (Icons.add_rounded, l.tabCreate),
      (Icons.insights_rounded, l.tabSocial),
      (Icons.handshake_rounded, l.tabDeals),
      (Icons.person_rounded, l.tabLife),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (final (i, (icon, label)) in items.indexed)
                Expanded(
                  child: i == 1
                      ? _CreateItem(label: label, selected: index == 1, onTap: () => onSelect(1))
                      : _NavItem(
                          icon: icon,
                          label: label,
                          selected: index == i,
                          badge: badges[i] ?? false,
                          onTap: () => onSelect(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.badge,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.text : AppColors.textMuted;
    final d = context.reduceMotion ? Duration.zero : const Duration(milliseconds: 260);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.15 : 1,
              duration: d,
              curve: Curves.easeOutBack,
              child: Badge(
                isLabelVisible: badge,
                backgroundColor: AppColors.coral,
                smallSize: 9,
                child: Icon(icon, color: color, size: 25),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            AnimatedContainer(
              duration: d,
              margin: const EdgeInsets.only(top: 3),
              width: selected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(3)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateItem extends StatelessWidget {
  const _CreateItem({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.coral, AppColors.violet],
                ),
                border: Border.all(color: AppColors.background, width: 4),
                boxShadow: [
                  BoxShadow(color: AppColors.coral.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
