import 'package:flutter/material.dart';

import '../app/l10n/app_localizations.dart';
import '../app/theme.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Spring-like press feedback (100–180 ms). Static when Reduce Motion is on.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, this.onTap, super.key});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !context.reduceMotion;
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _down = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _down = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _down = false) : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.m),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Space.radius),
        side: BorderSide(color: borderColor ?? Colors.transparent, width: borderColor == null ? 0 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

/// Rolling number (450–850 ms). Jumps instantly with Reduce Motion.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({required this.value, required this.format, this.style, this.semanticsLabel, super.key});
  final int value;
  final String Function(int) format;
  final TextStyle? style;
  final String? semanticsLabel;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> {
  late int _from = widget.value;

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _from = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final text = Semantics(
      label: widget.semanticsLabel,
      value: widget.format(widget.value),
      excludeSemantics: true,
      child: const SizedBox.shrink(),
    );
    if (context.reduceMotion) {
      return Stack(
        children: [
          Text(widget.format(widget.value), style: widget.style),
          text,
        ],
      );
    }
    return Stack(
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey(widget.value),
          tween: Tween(begin: _from.toDouble(), end: widget.value.toDouble()),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Text(widget.format(v.round()), style: widget.style),
        ),
        text,
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.permille, this.color = AppColors.violet, this.height = 8, super.key});
  final int permille;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final value = (permille.clamp(0, 1000)) / 1000;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            color: color,
            backgroundColor: AppColors.surfaceHigh,
          ),
        ),
      ),
    );
  }
}

/// "?" explainer: plain-language definition in a bottom sheet.
class InfoButton extends StatelessWidget {
  const InfoButton({required this.title, required this.body, super.key});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.whatIsThis(title),
    constraints: const BoxConstraints(minWidth: Space.minTap, minHeight: Space.minTap),
    icon: const Icon(Icons.help_outline_rounded, size: 20, color: AppColors.textMuted),
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Space.s),
              Text(body, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: Space.l),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.gotIt)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

enum BadgeState { ready, locked, inProgress, done }

/// Status never relies on colour alone: icon + label.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.state, {this.label, super.key});
  final BadgeState state;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (icon, color, text) = switch (state) {
      BadgeState.ready => (Icons.bolt_rounded, AppColors.mint, l.badgeReady),
      BadgeState.locked => (Icons.lock_rounded, AppColors.textMuted, l.badgeLocked),
      BadgeState.inProgress => (Icons.timelapse_rounded, AppColors.amber, l.badgeInProgress),
      BadgeState.done => (Icons.check_circle_rounded, AppColors.mint, l.badgeDone),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label ?? text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: Space.l, bottom: Space.s),
    child: Row(
      children: [
        Expanded(
          child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Small labelled value with icon (cash, skill points, energy...).
class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.text,
    super.key,
  });
  final IconData icon;
  final String label;
  final Widget value;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: AppFonts.display, fontWeight: FontWeight.w800, fontSize: 16),
              child: FittedBox(fit: BoxFit.scaleDown, child: value),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One row of a breakdown: label, signed value, proportional bar.
class BreakdownRow extends StatelessWidget {
  const BreakdownRow({required this.label, required this.value, required this.max, this.color, super.key});
  final String label;
  final int value;
  final int max;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            flex: 5,
            child: ProgressBar(
              permille: max == 0 ? 0 : value.abs() * 1000 ~/ max,
              color: negative ? AppColors.coral : (color ?? AppColors.violet),
              height: 6,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              negative ? '$value' : '+$value',
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w700, color: negative ? AppColors.coral : AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}
