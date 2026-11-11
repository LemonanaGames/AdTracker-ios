import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/game_controller.dart';
import '../../app/providers.dart';
import '../../app/services/sound_service.dart';
import '../../app/theme.dart';
import '../../domain/engine/game_event.dart';
import '../../domain/model/ids.dart';
import '../../ui/chunky_button.dart';
import '../../ui/motion.dart';
import '../../ui/widgets.dart';

final class Celebration {
  const Celebration({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.seed,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int seed;
}

/// FIFO of big moments; one is shown at a time so they never stack.
class CelebrationQueue extends Notifier<List<Celebration>> {
  @override
  List<Celebration> build() => const [];
  void add(Celebration c) => state = [...state, c];
  void dismiss() => state = state.isEmpty ? state : state.sublist(1);
}

final celebrationQueueProvider = NotifierProvider<CelebrationQueue, List<Celebration>>(CelebrationQueue.new);

/// Maps domain events to sound, haptics and (for big moments) celebrations.
/// The single place where "game juice" is decided.
void reactToEvent(BuildContext context, WidgetRef ref, GameEvent e) {
  final l = context.l10n;
  final c = ref.read(catalogProvider);
  final game = ref.read(gameControllerProvider.notifier);
  final queue = ref.read(celebrationQueueProvider.notifier);
  String networkName(Object? id) => c.strings[c.network(NetworkId.parse(id! as String)).nameKey];
  final seed = DateTime.now().microsecond;

  switch (e.name) {
    case 'level_up':
      game.feedback(Sfx.levelUp, Haptic.heavy);
      queue.add(
        Celebration(
          title: l.celebrateLevelTitle(e.params['player_level']! as int),
          subtitle: l.celebrateLevelBody,
          icon: Icons.star_rounded,
          color: AppColors.violet,
          seed: seed,
        ),
      );
    case 'network_unlocked':
      game.feedback(Sfx.unlock, Haptic.heavy);
      queue.add(
        Celebration(
          title: l.celebrateUnlockTitle(networkName(e.params['network_id'])),
          subtitle: c.strings[c.network(NetworkId.parse(e.params['network_id']! as String)).taglineKey],
          icon: Icons.lock_open_rounded,
          color: AppColors.hex(c.network(NetworkId.parse(e.params['network_id']! as String)).colorHex),
          seed: seed,
        ),
      );
    case 'followers_milestone':
      game.feedback(Sfx.levelUp, Haptic.medium);
      queue.add(
        Celebration(
          title: l.celebrateMilestone(
            Format.compact(e.params['milestone']! as int),
            networkName(e.params['network_id']),
          ),
          subtitle: l.celebrateMilestoneBody,
          icon: Icons.groups_rounded,
          color: AppColors.mint,
          seed: seed,
        ),
      );
    case 'story_act_complete':
      game.feedback(Sfx.unlock, Haptic.medium);
      queue.add(
        Celebration(
          title: c.strings[c.economy.acts.firstWhere((a) => a.id == e.params['act']).nameKey],
          subtitle: l.celebrateActBody,
          icon: Icons.auto_stories_rounded,
          color: AppColors.amber,
          seed: seed,
        ),
      );
    case 'post_published':
      game.feedback(Sfx.publish, Haptic.medium);
    case 'offline_claimed':
    case 'job_shift_completed':
      game.feedback(Sfx.coin, Haptic.light);
    case 'gear_purchased':
      game.feedback(Sfx.purchase, Haptic.medium);
    case 'skill_spent':
      game.feedback(Sfx.pop, Haptic.selection);
    case 'story_choice_made':
      game.feedback(Sfx.message, Haptic.light);
  }
}

class CelebrationOverlay extends ConsumerWidget {
  const CelebrationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(celebrationQueueProvider);
    return AnimatedSwitcher(
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      child: queue.isEmpty
          ? const SizedBox.shrink(key: ValueKey('none'))
          : _CelebrationView(
              key: ValueKey(queue.first),
              celebration: queue.first,
              remaining: queue.length - 1,
              onDone: () => ref.read(celebrationQueueProvider.notifier).dismiss(),
            ),
    );
  }
}

class _CelebrationView extends ConsumerStatefulWidget {
  const _CelebrationView({required this.celebration, required this.remaining, required this.onDone, super.key});
  final Celebration celebration;
  final int remaining;
  final VoidCallback onDone;

  @override
  ConsumerState<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends ConsumerState<_CelebrationView> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 12));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _in.value = 1;
    } else if (_in.value == 0) {
      _in.forward();
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.celebration;
    final l = context.l10n;
    final moving = ambientMotion(context, ref);
    if (moving && !_rays.isAnimating) _rays.repeat();
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: const SizedBox.expand()),
          ),
          Positioned.fill(child: ConfettiBurst(seed: c.seed)),
          Center(
            child: AnimatedBuilder(
              animation: _in,
              builder: (_, child) => Transform.scale(
                scale: 0.6 + 0.4 * Curves.elasticOut.transform(_in.value),
                child: Opacity(opacity: _in.value.clamp(0, 1), child: child),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _rays,
                            builder: (_, _) => Transform.rotate(
                              angle: _rays.value * 2 * math.pi,
                              child: CustomPaint(size: const Size.square(190), painter: _RaysPainter(c.color)),
                            ),
                          ),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color.lerp(c.color, Colors.white, 0.3)!, c.color],
                              ),
                              boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.6), blurRadius: 30)],
                            ),
                            child: Icon(c.icon, size: 56, color: AppColors.background),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.m),
                    Text(c.title, textAlign: TextAlign.center, style: t.displaySmall?.copyWith(fontSize: 34)),
                    const SizedBox(height: Space.s),
                    Text(
                      c.subtitle,
                      textAlign: TextAlign.center,
                      style: t.bodyLarge?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: Space.l),
                    SizedBox(
                      width: 220,
                      child: ChunkyButton(
                        label: widget.remaining > 0 ? l.celebrateNext : l.celebrateNice,
                        color: c.color,
                        foreground: AppColors.background,
                        onPressed: widget.onDone,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: size.width / 2));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * size.width, c.dy + math.sin(a - 0.12) * size.width)
        ..lineTo(c.dx + math.cos(a + 0.12) * size.width, c.dy + math.sin(a + 0.12) * size.width)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
