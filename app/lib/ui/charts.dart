import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Tiny trend line with a soft fill and an end dot.
class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, this.color = AppColors.mint, this.height = 44, super.key});
  final List<int> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SparkPainter(values, color)),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min).toDouble();
    final maxV = values.reduce(math.max).toDouble();
    final span = maxV - minV == 0 ? 1 : maxV - minV;
    Offset at(int i) =>
        Offset(size.width * i / (values.length - 1), size.height - 4 - (values[i] - minV) / span * (size.height - 10));
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1), b = at(i);
      final mid = (a.dx + b.dx) / 2;
      line.cubicTo(mid, a.dy, mid, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final end = at(values.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawCircle(end, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}

/// Animated 0–100 arc gauge; colour moves from coral → amber → mint.
class QualityGauge extends StatelessWidget {
  const QualityGauge({required this.value, this.size = 120, super.key});
  final int value;
  final double size;

  static Color colorFor(int v) => v < 35
      ? AppColors.coral
      : v < 55
      ? Color.lerp(AppColors.coral, AppColors.amber, (v - 35) / 20)!
      : Color.lerp(AppColors.amber, AppColors.mint, ((v - 55) / 25).clamp(0, 1))!;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 600),
    curve: Curves.easeOutBack,
    builder: (context, v, _) => SizedBox(
      width: size,
      height: size * 0.62,
      child: CustomPaint(
        painter: _GaugePainter(v.clamp(0, 100) / 100, colorFor(v.round())),
        child: Align(
          alignment: const Alignment(0, 0.9),
          child: Text(
            '${v.round()}',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.32,
              height: 1,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.width / 2), radius: size.width / 2 - stroke / 2);
    final base = Paint()
      ..color = AppColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi * 0.95, math.pi * 1.1, false, base);
    canvas.drawArc(rect, math.pi * 0.95, math.pi * 1.1 * t, false, base..color = color);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.t != t || old.color != color;
}
