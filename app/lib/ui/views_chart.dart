import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/content/game_catalog.dart';
import '../domain/engine/post_simulation.dart';
import '../domain/model/content_post.dart';

/// Cumulative views of one post: solid up to "now", faint projection after.
/// Drawn from the same pure curve the engine credits from.
class ViewsChart extends StatelessWidget {
  const ViewsChart({
    required this.post,
    required this.network,
    required this.nowSimMs,
    required this.color,
    this.height = 120,
    this.semanticLabel,
    super.key,
  });

  final ContentPost post;
  final NetworkDef network;
  final int nowSimMs;
  final Color color;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: true,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (_, reveal, _) => CustomPaint(
          painter: _ChartPainter(
            network: network,
            elapsedMs: nowSimMs - post.publishedAtSimMs,
            color: color,
            reveal: reveal,
          ),
        ),
      ),
    ),
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.network, required this.elapsedMs, required this.color, required this.reveal});

  final NetworkDef network;
  final int elapsedMs;
  final Color color;
  final double reveal;

  static const _samples = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final endMs = network.curveEndHour * 3600 * 1000;
    Offset point(int i) {
      final t = endMs * i ~/ _samples;
      final y = PostSimulation.curvePermille(network, t) / 1000;
      return Offset(size.width * i / _samples, size.height - y * (size.height - 4) * reveal - 2);
    }

    final grid = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final nowIndex = (elapsedMs.clamp(0, endMs) * _samples / endMs).floor();
    final past = Path()..moveTo(0, size.height);
    final future = Path();
    for (var i = 0; i <= _samples; i++) {
      final p = point(i);
      if (i <= nowIndex) {
        past.lineTo(p.dx, p.dy);
      }
      if (i == nowIndex) future.moveTo(p.dx, p.dy);
      if (i > nowIndex) future.lineTo(p.dx, p.dy);
    }
    final nowPoint = point(nowIndex);
    final fill = Path.from(past)
      ..lineTo(nowPoint.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pastLine = Path()..moveTo(0, point(0).dy);
    for (var i = 1; i <= nowIndex; i++) {
      pastLine.lineTo(point(i).dx, point(i).dy);
    }
    canvas.drawPath(pastLine, line);
    canvas.drawPath(future, line..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(nowPoint, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.elapsedMs != elapsedMs || old.reveal != reveal || old.color != color || old.network != network;
}
