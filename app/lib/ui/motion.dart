import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';

/// True when decorative, continuous motion may run.
bool ambientMotion(BuildContext context, WidgetRef ref) =>
    ref.watch(ambientMotionProvider) && !MediaQuery.disableAnimationsOf(context);

/// Entrance: fade + rise, delayed by [index] (no timers — the delay is part of
/// one controller's interval, so nothing is left pending on dispose).
class Stagger extends StatefulWidget {
  const Stagger({required this.index, required this.child, this.step = 55, this.offset = 18, super.key});
  final int index;
  final Widget child;
  final int step;
  final double offset;

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = widget.index * widget.step;
    final total = delay + 420;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
    ),
  );
}

/// Shows a floating "+N" above [child] every time [value] goes up.
class FloatingDelta extends StatefulWidget {
  const FloatingDelta({
    required this.value,
    required this.child,
    this.format,
    this.color = AppColors.mint,
    this.onIncrease,
    super.key,
  });
  final int value;
  final Widget child;
  final String Function(int delta)? format;
  final Color color;
  final VoidCallback? onIncrease;

  @override
  State<FloatingDelta> createState() => _FloatingDeltaState();
}

class _FloatingDeltaState extends State<FloatingDelta> with TickerProviderStateMixin {
  final _items = <({int delta, AnimationController c})>[];

  @override
  void didUpdateWidget(FloatingDelta old) {
    super.didUpdateWidget(old);
    final delta = widget.value - old.value;
    if (delta <= 0 || MediaQuery.disableAnimationsOf(context)) return;
    widget.onIncrease?.call();
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    final item = (delta: delta, c: c);
    setState(() => _items.add(item));
    c.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _items.remove(item));
      c.dispose();
    });
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    fit: StackFit.passthrough,
    children: [
      widget.child,
      for (final i in _items)
        PositionedDirectional(
          end: -6,
          top: -4,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: i.c,
              builder: (_, _) {
                final t = Curves.easeOutCubic.transform(i.c.value);
                return Opacity(
                  opacity: (1 - i.c.value).clamp(0, 1) * (i.c.value < 0.1 ? i.c.value * 10 : 1),
                  child: Transform.translate(
                    offset: Offset(0, -28 * t),
                    child: Transform.scale(
                      scale: 0.8 + 0.4 * Curves.elasticOut.transform(math.min(1, i.c.value * 2)),
                      child: Text(
                        widget.format?.call(i.delta) ?? '+${i.delta}',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: widget.color,
                          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    ],
  );
}

/// One-shot confetti burst from the top centre (paper strips + dots).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({this.seed = 1, this.count = 70, super.key});
  final int seed;
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final List<_Particle> _parts;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed);
    const colors = [AppColors.coral, AppColors.mint, AppColors.amber, AppColors.sky, AppColors.violet, AppColors.text];
    _parts = [
      for (var i = 0; i < widget.count; i++)
        _Particle(
          angle: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.1,
          speed: 380 + r.nextDouble() * 520,
          spin: (r.nextDouble() - 0.5) * 14,
          color: colors[r.nextInt(colors.length)],
          strip: r.nextBool(),
          size: 5 + r.nextDouble() * 6,
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context) && !_c.isAnimating && _c.value == 0) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(painter: _ConfettiPainter(_parts, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.color,
    required this.strip,
    required this.size,
  });
  final double angle;
  final double speed;
  final double spin;
  final Color color;
  final bool strip;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts, this.t);
  final List<_Particle> parts;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.32);
    final secs = t * 1.9;
    final paint = Paint();
    for (final p in parts) {
      final dx = math.cos(p.angle) * p.speed * secs * 0.75;
      final dy = math.sin(p.angle) * p.speed * secs + 520 * secs * secs; // gravity
      final pos = origin + Offset(dx, dy);
      paint.color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.spin * secs);
      if (p.strip) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size * 0.6, height: p.size * 1.8),
            const Radius.circular(1.5),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/// Slowly drifting colour blobs (a living background for hero cards).
class AmbientBlobs extends ConsumerStatefulWidget {
  const AmbientBlobs({required this.colors, this.child, super.key});
  final List<Color> colors;
  final Widget? child;

  @override
  ConsumerState<AmbientBlobs> createState() => _AmbientBlobsState();
}

class _AmbientBlobsState extends ConsumerState<AmbientBlobs> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moving = ambientMotion(context, ref);
    if (moving && !_c.isAnimating) _c.repeat();
    if (!moving && _c.isAnimating) _c.stop();
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => CustomPaint(painter: _BlobPainter(widget.colors, _c.value), child: child),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.colors, this.t);
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t * 2 * math.pi;
    for (var i = 0; i < colors.length; i++) {
      final phase = a + i * 2.1;
      final center = Offset(
        size.width * (0.2 + 0.6 * (0.5 + 0.5 * math.sin(phase * (i.isEven ? 1 : -1)))),
        size.height * (0.25 + 0.5 * (0.5 + 0.5 * math.cos(phase * 0.8))),
      );
      final r = size.shortestSide * (0.75 + 0.15 * math.sin(phase * 1.3));
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [colors[i].withValues(alpha: 0.42), colors[i].withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t || old.colors != colors;
}

/// Pulsing "live" dot for things that are still growing.
class PulseDot extends ConsumerStatefulWidget {
  const PulseDot({this.color = AppColors.coral, this.size = 8, super.key});
  final Color color;
  final double size;

  @override
  ConsumerState<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends ConsumerState<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moving = ambientMotion(context, ref);
    if (moving && !_c.isAnimating) _c.repeat();
    if (!moving && _c.isAnimating) _c.stop();
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            if (moving)
              Container(
                width: s * (1 + 1.4 * _c.value),
                height: s * (1 + 1.4 * _c.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.45 * (1 - _c.value)),
                ),
              ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tilted label, like a sticker slapped on a card.
class Sticker extends StatelessWidget {
  const Sticker(this.text, {this.color = AppColors.amber, this.angle = -0.06, this.icon, super.key});
  final String text;
  final Color color;
  final double angle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), offset: const Offset(1, 2), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: AppColors.background), const SizedBox(width: 3)],
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppColors.background,
            ),
          ),
        ],
      ),
    ),
  );
}
