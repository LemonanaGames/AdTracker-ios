import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/game_controller.dart';
import '../app/providers.dart';
import '../app/services/sound_service.dart';
import '../app/theme.dart';

/// Tactile "game" button: a coloured face on a darker lip that squashes down
/// when pressed, with a click sound and haptic tick.
class ChunkyButton extends ConsumerStatefulWidget {
  const ChunkyButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = AppColors.violet,
    this.foreground = Colors.white,
    this.height = 56,
    this.expand = true,
    this.sfx = Sfx.tap,
    this.haptic = Haptic.light,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color foreground;
  final double height;
  final bool expand;

  /// Played on press (null = silent, e.g. when the action plays its own sound).
  final Sfx? sfx;
  final Haptic? haptic;

  @override
  ConsumerState<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends ConsumerState<ChunkyButton> {
  static const _lip = 5.0;
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  void _set(bool v) {
    if (_enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final face = _enabled ? widget.color : AppColors.surfaceHigh;
    final lip = _enabled ? Color.lerp(widget.color, Colors.black, 0.42)! : AppColors.outline;
    final fg = _enabled ? widget.foreground : AppColors.textMuted;
    final press = _down ? _lip - 1 : 0.0;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 80);

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 22), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: widget.height >= 52 ? 18 : 15,
              letterSpacing: -0.2,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: _enabled
            ? () {
                ref.read(gameControllerProvider.notifier).feedback(widget.sfx, widget.haptic);
                widget.onPressed!();
              }
            : null,
        child: Stack(
          children: [
            Positioned.fill(
              top: _lip,
              child: DecoratedBox(
                decoration: BoxDecoration(color: lip, borderRadius: BorderRadius.circular(Space.radius)),
              ),
            ),
            // The face is a normal child so the button sizes to its content
            // when it is not expanded (e.g. inside a Row).
            AnimatedPadding(
              duration: duration,
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: press, bottom: _lip - press),
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Space.radius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(face, Colors.white, _enabled ? 0.14 : 0)!, face],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: _enabled ? 0.18 : 0.04)),
                ),
                alignment: widget.expand ? Alignment.center : null,
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
