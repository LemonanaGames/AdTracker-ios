import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/model/ids.dart';
import '../../ui/asset_art.dart';
import '../../ui/widgets.dart';

/// First-session beats 1–4 (GDD I4): welcome → name → niche → avatar.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const presets = ['avatar_1', 'avatar_2', 'avatar_3', 'avatar_4', 'avatar_5', 'avatar_6'];
  final _name = TextEditingController();
  final _handle = TextEditingController();
  final _random = Random();
  int _step = 0;
  String? _niche;
  String _preset = presets.first;
  CreatorPersona _persona = CreatorPersona.onCamera;
  bool _handleEdited = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.read(telemetryProvider).log('tutorial_start');
  }

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  String _suggestHandle(String name) {
    final base = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final stem = base.isEmpty ? 'creator' : (base.length > 14 ? base.substring(0, 14) : base);
    return '@$stem${10 + _random.nextInt(89)}';
  }

  void _next() {
    ref.read(telemetryProvider).log('tutorial_step', {'step': _step + 1});
    setState(() => _step++);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    var handle = _handle.text.trim();
    if (!handle.startsWith('@')) handle = '@$handle';
    await ref
        .read(gameControllerProvider.notifier)
        .startLife(
          displayName: _name.text.trim(),
          handle: handle,
          nicheId: _niche!,
          presetId: _preset,
          persona: _persona,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loadError = ref.watch(gameControllerProvider.select((s) => s.loadError));
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (loadError != null)
              MaterialBanner(content: Text(context.l10n.saveLoadError), actions: const [SizedBox.shrink()]),
            if (_step > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  tooltip: context.l10n.back,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _step--),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(_step), child: _stepBody(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) => switch (_step) {
    0 => _welcome(context),
    1 => _nameStep(context),
    2 => _nicheStep(context),
    _ => _avatarStep(context),
  };

  Widget _page({required List<Widget> children, required Widget action}) => Padding(
    padding: const EdgeInsets.all(Space.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: ListView(children: children)),
        const SizedBox(height: Space.m),
        action,
      ],
    ),
  );

  Widget _welcome(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return _page(
      children: [
        const SizedBox(height: Space.xl),
        const Center(child: AssetArt('scene_bedroom', size: 160)),
        const SizedBox(height: Space.xl),
        Text(l.welcomeTitle, style: t.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: Space.m),
        Text(
          l.welcomeBody,
          style: t.bodyLarge?.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
      action: FilledButton(onPressed: _next, child: Text(l.startMyStory)),
    );
  }

  Widget _nameStep(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return _page(
      children: [
        Text(l.nameTitle, style: t.headlineSmall),
        const SizedBox(height: Space.l),
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l.nameLabel, border: const OutlineInputBorder()),
          onChanged: (v) => setState(() {
            if (!_handleEdited) _handle.text = _suggestHandle(v);
          }),
        ),
        const SizedBox(height: Space.s),
        TextField(
          controller: _handle,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: l.handleLabel,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: l.shuffleHandle,
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: () => setState(() {
                _handleEdited = false;
                _handle.text = _suggestHandle(_name.text);
              }),
            ),
          ),
          onChanged: (_) => setState(() => _handleEdited = true),
        ),
      ],
      action: FilledButton(
        onPressed: _name.text.trim().isEmpty || _handle.text.trim().length < 2 ? null : _next,
        child: Text(l.continueLabel),
      ),
    );
  }

  Widget _nicheStep(BuildContext context) {
    final l = context.l10n;
    final c = ref.watch(catalogProvider);
    final t = Theme.of(context).textTheme;
    return _page(
      children: [
        Text(l.nicheTitle, style: t.headlineSmall),
        const SizedBox(height: Space.s),
        Text(l.nicheBody, style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: Space.l),
        for (final n in c.niches)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Semantics(
              selected: _niche == n.id,
              button: true,
              child: AppCard(
                borderColor: _niche == n.id ? AppColors.violet : null,
                onTap: () => setState(() => _niche = n.id),
                child: Row(
                  children: [
                    AssetArt(n.assetKey, size: 52),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.strings[n.nameKey], style: t.titleMedium),
                          Text(c.strings[n.descKey], style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    if (_niche == n.id) const Icon(Icons.check_circle_rounded, color: AppColors.violet),
                  ],
                ),
              ),
            ),
          ),
      ],
      action: FilledButton(onPressed: _niche == null ? null : _next, child: Text(l.continueLabel)),
    );
  }

  Widget _avatarStep(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return _page(
      children: [
        Text(l.avatarTitle, style: t.headlineSmall),
        const SizedBox(height: Space.l),
        Wrap(
          spacing: Space.m,
          runSpacing: Space.m,
          alignment: WrapAlignment.center,
          children: [
            for (final (i, p) in presets.indexed)
              Semantics(
                selected: _preset == p,
                button: true,
                label: l.avatarOption(i + 1),
                child: GestureDetector(
                  onTap: () => setState(() => _preset = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _preset == p ? AppColors.violet : Colors.transparent, width: 3),
                    ),
                    child: AssetArt(p, size: 84, circle: true),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.l),
        Text(l.personaTitle, style: t.titleMedium),
        const SizedBox(height: Space.s),
        SegmentedButton<CreatorPersona>(
          segments: [
            ButtonSegment(value: CreatorPersona.onCamera, label: Text(l.personaOnCamera)),
            ButtonSegment(value: CreatorPersona.faceless, label: Text(l.personaFaceless)),
          ],
          selected: {_persona},
          onSelectionChanged: (s) => setState(() => _persona = s.first),
        ),
        const SizedBox(height: Space.s),
        Text(l.personaNote, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
      ],
      action: FilledButton(onPressed: _busy ? null : _finish, child: Text(l.looksGood)),
    );
  }
}
