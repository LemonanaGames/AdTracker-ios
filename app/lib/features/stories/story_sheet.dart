import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/format.dart';
import '../../app/game_controller.dart';
import '../../app/l10n/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/services/sound_service.dart';
import '../../app/theme.dart';
import '../../domain/content/game_catalog.dart';
import '../../domain/model/modifier.dart';
import '../../ui/asset_art.dart';
import '../../ui/motion.dart';
import '../../ui/requirement_view.dart';
import '../../ui/widgets.dart';

Future<void> showStorySheet(BuildContext context, String eventId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StorySheet(eventId: eventId),
  );
}

/// Authored story event: short bubbles + choices whose preview chips are
/// generated from the exact effects the engine applies (no false promises).
class StorySheet extends ConsumerWidget {
  const StorySheet({required this.eventId, super.key});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final engine = ref.watch(engineProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final ev = c.event(eventId)!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          Center(child: AssetArt(ev.sceneAssetKey, size: 96)),
          const SizedBox(height: Space.m),
          Text(c.strings[ev.titleKey], style: t.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: Space.l),
          _ChatThread(lines: [for (final line in ev.lines) (speaker: line.speaker, text: c.strings[line.textKey])]),
          Stagger(index: ev.lines.length * 16, child: SectionHeader(l.whatDoYouDo)),
          for (final (ci, choice) in ev.choices.indexed)
            Stagger(
              index: ev.lines.length * 16 + 1 + ci * 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: Space.s),
                child: Builder(
                  builder: (context) {
                    final available = engine.isChoiceAvailable(life, choice);
                    return AppCard(
                      borderColor: available ? AppColors.outline : null,
                      onTap: available
                          ? () {
                              ref.read(gameControllerProvider.notifier).chooseStory(ev.id, choice.id);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.strings[choice.labelKey],
                                  style: t.titleMedium?.copyWith(color: available ? null : AppColors.textMuted),
                                ),
                              ),
                              if (!available) const StatusBadge(BadgeState.locked),
                            ],
                          ),
                          const SizedBox(height: Space.s),
                          Wrap(spacing: 6, runSpacing: 6, children: effectChips(l, c, choice.effects)),
                          if (!available && choice.requirement != null) ...[
                            const SizedBox(height: Space.s),
                            RequirementChecklist(requirement: choice.requirement!, life: life),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: Space.s),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.decideLater)),
        ],
      ),
    );
  }

  static List<Widget> effectChips(AppLocalizations l, GameCatalog c, ChoiceEffects fx) {
    Widget chip(String text, bool good) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (good ? AppColors.mint : AppColors.coral).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(good ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14),
          const SizedBox(width: 2),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );

    return [
      if (fx.audienceTrust != 0) chip(l.fxTrust(Format.delta(fx.audienceTrust)), fx.audienceTrust > 0),
      if (fx.integrity != 0) chip(l.fxIntegrity(Format.delta(fx.integrity)), fx.integrity > 0),
      if (fx.cashMinor != 0) chip(l.fxCash(Format.cash(fx.cashMinor)), fx.cashMinor > 0),
      if (fx.xp != 0) chip(l.fxXp(fx.xp), true),
      for (final e in fx.relationships.entries)
        chip(l.fxRelationship(c.strings[c.character(e.key)!.nameKey], Format.delta(e.value)), e.value > 0),
      for (final m in fx.modifiers)
        if (m.kind == ActiveModifier.kindTrendBoostPermille)
          chip(
            l.fxTrendBoost(m.value ~/ 10, m.network == null ? '' : c.strings[c.network(m.network!).nameKey], m.uses),
            true,
          )
        else if (m.kind == ActiveModifier.kindQualityBonus)
          chip(l.fxQualityBonus(m.value, m.uses), true),
    ];
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.speakerId, required this.text});
  final String speakerId;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final ch = c.character(speakerId)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssetArt(ch.assetKey, size: 40, circle: true),
          const SizedBox(width: Space.s),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(16),
                  bottomStart: Radius.circular(16),
                  bottomEnd: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.strings[ch.nameKey]} · ${c.strings[ch.roleKey]}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(text, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Messages arrive one by one after a short "typing…" beat (one controller,
/// no timers). With Reduce Motion everything is shown at once.
class _ChatThread extends ConsumerStatefulWidget {
  const _ChatThread({required this.lines});
  final List<({String speaker, String text})> lines;

  @override
  ConsumerState<_ChatThread> createState() => _ChatThreadState();
}

class _ChatThreadState extends ConsumerState<_ChatThread> with SingleTickerProviderStateMixin {
  static const _perLine = 850;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _perLine * widget.lines.length),
  );
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final shown = (_c.value * widget.lines.length + 0.0001).floor();
      if (shown != _shown) {
        setState(() => _shown = shown);
        ref.read(gameControllerProvider.notifier).feedback(Sfx.message, Haptic.light);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.value = 1;
      _shown = widget.lines.length;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < widget.lines.length; i++)
        if (i < _shown)
          Stagger(
            index: 0,
            child: _Bubble(speakerId: widget.lines[i].speaker, text: widget.lines[i].text),
          )
        else if (i == _shown)
          _Typing(speakerId: widget.lines[i].speaker),
    ],
  );
}

class _Typing extends ConsumerWidget {
  const _Typing({required this.speakerId});
  final String speakerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ch = ref.watch(catalogProvider).character(speakerId)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Row(
        children: [
          AssetArt(ch.assetKey, size: 40, circle: true),
          const SizedBox(width: Space.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                PulseDot(color: AppColors.textMuted, size: 6),
                PulseDot(color: AppColors.textMuted, size: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
