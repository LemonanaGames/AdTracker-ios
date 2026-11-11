import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Procedural flat-illustration characters for avatars and NPCs.
///
/// Original vector drawings (no external art). Still listed as placeholders in
/// the asset manifest until approved final art replaces them.
enum HairStyle { bob, curly, bun, spiky, long, buzz }

final class CharacterLook {
  const CharacterLook({
    required this.bg,
    required this.skin,
    required this.hair,
    required this.style,
    required this.shirt,
    this.glasses = false,
    this.earrings = false,
    this.freckles = false,
  });
  final Color bg;
  final Color skin;
  final Color hair;
  final HairStyle style;
  final Color shirt;
  final bool glasses;
  final bool earrings;
  final bool freckles;
}

abstract final class CharacterLooks {
  static const all = <String, CharacterLook>{
    'avatar_1': CharacterLook(
      bg: Color(0xFF8F5BFF),
      skin: Color(0xFFF2C9A5),
      hair: Color(0xFF2B1B14),
      style: HairStyle.bob,
      shirt: Color(0xFFFF6F78),
    ),
    'avatar_2': CharacterLook(
      bg: Color(0xFFFF6F78),
      skin: Color(0xFF8D5A3B),
      hair: Color(0xFF15100D),
      style: HairStyle.curly,
      shirt: Color(0xFFFFB547),
      earrings: true,
    ),
    'avatar_3': CharacterLook(
      bg: Color(0xFF54D6A1),
      skin: Color(0xFFE8B48A),
      hair: Color(0xFFB4532A),
      style: HairStyle.spiky,
      shirt: Color(0xFF4FC3F7),
      freckles: true,
    ),
    'avatar_4': CharacterLook(
      bg: Color(0xFFFFB547),
      skin: Color(0xFFC68B62),
      hair: Color(0xFF3A2416),
      style: HairStyle.bun,
      shirt: Color(0xFF8F5BFF),
      glasses: true,
    ),
    'avatar_5': CharacterLook(
      bg: Color(0xFF4FC3F7),
      skin: Color(0xFFF6D7BF),
      hair: Color(0xFFE9C46A),
      style: HairStyle.long,
      shirt: Color(0xFF54D6A1),
    ),
    'avatar_6': CharacterLook(
      bg: Color(0xFFF7F8FA),
      skin: Color(0xFF5B3A29),
      hair: Color(0xFF0E0B09),
      style: HairStyle.buzz,
      shirt: Color(0xFF10131F),
      glasses: true,
    ),
    'npc_maya': CharacterLook(
      bg: Color(0xFF54D6A1),
      skin: Color(0xFFD9A17B),
      hair: Color(0xFF4A2A1A),
      style: HairStyle.long,
      shirt: Color(0xFFFFB547),
      earrings: true,
    ),
    'npc_kai': CharacterLook(
      bg: Color(0xFFFF6F78),
      skin: Color(0xFFF0C7A0),
      hair: Color(0xFF111111),
      style: HairStyle.spiky,
      shirt: Color(0xFF10131F),
    ),
    'npc_noor': CharacterLook(
      bg: Color(0xFF8F5BFF),
      skin: Color(0xFFB07A52),
      hair: Color(0xFF221510),
      style: HairStyle.bun,
      shirt: Color(0xFF4FC3F7),
      glasses: true,
    ),
  };
}

class CharacterAvatar extends StatelessWidget {
  const CharacterAvatar(this.look, {this.size = 44, this.circle = true, this.ring, super.key});
  final CharacterLook look;
  final double size;
  final bool circle;

  /// Optional "story ring" colour drawn around the avatar.
  final Gradient? ring;

  @override
  Widget build(BuildContext context) {
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(circle ? size : size * 0.28),
      child: CustomPaint(size: Size.square(size), painter: _CharacterPainter(look)),
    );
    if (ring == null) return avatar;
    return Container(
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: ring),
      child: Container(
        padding: EdgeInsets.all(size * 0.04),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10131F)),
        child: avatar,
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.l);
  final CharacterLook l;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final p = Paint()..isAntiAlias = true;
    Color darker(Color c, [double t = 0.25]) => Color.lerp(c, Colors.black, t)!;

    // Background with soft light.
    canvas.drawRect(
      Offset.zero & size,
      p
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [Color.lerp(l.bg, Colors.white, 0.25)!, l.bg],
        ).createShader(Offset.zero & size),
    );
    p.shader = null;

    final cx = s / 2;
    final headC = Offset(cx, s * 0.47);
    final headW = s * 0.36, headH = s * 0.42;

    // Long hair behind the head.
    p.color = l.hair;
    if (l.style == HairStyle.long) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, s * 0.58), width: s * 0.5, height: s * 0.62),
          Radius.circular(s * 0.2),
        ),
        p,
      );
    }
    if (l.style == HairStyle.bun) canvas.drawCircle(Offset(cx, s * 0.19), s * 0.1, p);

    // Shoulders / shirt.
    p.color = l.shirt;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.18, s * 0.78, s * 0.64, s * 0.4), Radius.circular(s * 0.22)),
      p,
    );
    // Neck.
    p.color = darker(l.skin, 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, s * 0.73), width: s * 0.14, height: s * 0.16),
        Radius.circular(s * 0.04),
      ),
      p,
    );
    // Ears + head.
    p.color = l.skin;
    canvas.drawCircle(Offset(cx - headW / 2, s * 0.5), s * 0.045, p);
    canvas.drawCircle(Offset(cx + headW / 2, s * 0.5), s * 0.045, p);
    canvas.drawOval(Rect.fromCenter(center: headC, width: headW, height: headH), p);

    if (l.earrings) {
      p.color = const Color(0xFFFFD166);
      canvas.drawCircle(Offset(cx - headW / 2, s * 0.56), s * 0.018, p);
      canvas.drawCircle(Offset(cx + headW / 2, s * 0.56), s * 0.018, p);
    }

    // Hair on top.
    p.color = l.hair;
    final top = Rect.fromCenter(center: Offset(cx, s * 0.36), width: headW * 1.08, height: headH * 0.62);
    switch (l.style) {
      case HairStyle.bob:
        canvas.drawArc(top.inflate(s * 0.02), math.pi, math.pi, true, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - headW * 0.58, s * 0.34, s * 0.09, s * 0.24),
            Radius.circular(s * 0.04),
          ),
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + headW * 0.58 - s * 0.09, s * 0.34, s * 0.09, s * 0.24),
            Radius.circular(s * 0.04),
          ),
          p,
        );
      case HairStyle.curly:
        for (var i = 0; i < 9; i++) {
          final a = math.pi + i * math.pi / 8;
          canvas.drawCircle(
            Offset(cx + math.cos(a) * headW * 0.52, s * 0.4 + math.sin(a) * headH * 0.45),
            s * 0.075,
            p,
          );
        }
      case HairStyle.bun:
      case HairStyle.long:
        canvas.drawArc(top, math.pi, math.pi, true, p);
      case HairStyle.spiky:
        final path = Path()..moveTo(cx - headW * 0.55, s * 0.4);
        for (var i = 0; i <= 5; i++) {
          final x = cx - headW * 0.55 + headW * 1.1 * i / 5;
          path
            ..lineTo(x - headW * 0.06, s * (0.2 + (i.isEven ? 0.0 : 0.05)))
            ..lineTo(x + headW * 0.05, s * 0.33);
        }
        path
          ..lineTo(cx + headW * 0.55, s * 0.4)
          ..close();
        canvas.drawPath(path, p);
      case HairStyle.buzz:
        canvas.drawArc(top.deflate(s * 0.01), math.pi, math.pi, true, p..color = l.hair.withValues(alpha: 0.85));
    }

    // Face.
    final eyeY = s * 0.49;
    p.color = const Color(0xFF1A1220);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - s * 0.07, eyeY), width: s * 0.04, height: s * 0.055), p);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + s * 0.07, eyeY), width: s * 0.04, height: s * 0.055), p);
    p
      ..color = const Color(0xFFFF8A8A).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - s * 0.11, s * 0.56), s * 0.03, p);
    canvas.drawCircle(Offset(cx + s * 0.11, s * 0.56), s * 0.03, p);
    if (l.freckles) {
      p.color = darker(l.skin, 0.35);
      for (final dx in [-0.12, -0.09, 0.09, 0.12]) {
        canvas.drawCircle(Offset(cx + s * dx, s * 0.535), s * 0.007, p);
      }
    }
    p
      ..color = const Color(0xFF1A1220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, s * 0.565), width: s * 0.11, height: s * 0.07),
      0.2,
      math.pi - 0.4,
      false,
      p,
    );
    if (l.glasses) {
      p
        ..strokeWidth = s * 0.014
        ..color = const Color(0xFF1A1220);
      canvas.drawCircle(Offset(cx - s * 0.07, eyeY), s * 0.045, p);
      canvas.drawCircle(Offset(cx + s * 0.07, eyeY), s * 0.045, p);
      canvas.drawLine(Offset(cx - s * 0.025, eyeY), Offset(cx + s * 0.025, eyeY), p);
    }
  }

  @override
  bool shouldRepaint(_CharacterPainter old) => old.l != l;
}
