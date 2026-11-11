import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/format.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../domain/engine/game_event.dart';
import '../../domain/engine/progression.dart';
import '../../ui/asset_art.dart';
import '../../ui/chunky_button.dart';
import '../../ui/requirement_view.dart';
import '../../ui/widgets.dart';

class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(catalogProvider);
    final engine = ref.watch(engineProvider);
    final life = ref.watch(gameControllerProvider).life!;
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final level = Progression.levelForXp(c.economy, life.creatorXp);
    final progress = Progression.levelProgress(c.economy, life.creatorXp);
    final act = c.economy.acts.firstWhere((a) => a.id == life.actId);

    return Scaffold(
      appBar: AppBar(title: Text(l.tabLife)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.m, 0, Space.m, Space.xl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AssetArt(life.avatar.presetId, size: 64, circle: true, semanticLabel: life.avatar.displayName),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(life.avatar.displayName, style: t.titleLarge),
                          Text(
                            '${life.avatar.handle} · ${c.strings[c.niche(life.avatar.nicheId)!.nameKey]}',
                            style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                          Text(c.strings[act.nameKey], style: t.labelMedium?.copyWith(color: AppColors.violet)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Expanded(child: Text(l.levelShort(level), style: t.titleMedium)),
                    if (progress.span > 0)
                      Text(
                        l.xpProgress(progress.into, progress.span),
                        style: t.labelMedium?.copyWith(color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ProgressBar(permille: progress.span == 0 ? 1000 : progress.into * 1000 ~/ progress.span),
              ],
            ),
          ),
          SectionHeader(l.wellbeing),
          AppCard(
            child: Column(
              children: [
                _Meter(
                  label: l.energy,
                  value: life.energy,
                  color: AppColors.amber,
                  info: l.energyInfo(c.economy.energyRegenPerSimHour),
                ),
                _Meter(label: l.stress, value: life.burnout, color: AppColors.coral, info: l.stressInfo),
                _Meter(label: l.trust, value: life.audienceTrust, color: AppColors.mint, info: l.trustInfo),
                _Meter(label: l.integrity, value: life.integrity, color: AppColors.sky, info: l.integrityInfo),
              ],
            ),
          ),
          SectionHeader(l.jobs),
          for (final job in c.jobs)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Builder(
                builder: (context) {
                  final unlocked = engine.rules.isMet(life, job.requirement);
                  final enoughEnergy = life.energy >= job.energyCost;
                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        AssetArt(job.assetKey, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.strings[job.nameKey], style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                unlocked
                                    ? l.jobLine(Format.cash(job.payMinor), job.energyCost)
                                    : shortRequirement(l, c, engine.rules.check(life, job.requirement!)),
                                style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (!unlocked)
                          const StatusBadge(BadgeState.locked)
                        else
                          ChunkyButton(
                            label: enoughEnergy ? l.work : l.tooTiredShort,
                            expand: false,
                            height: 40,
                            sfx: null,
                            color: AppColors.amber,
                            foreground: AppColors.background,
                            onPressed: enoughEnergy
                                ? () {
                                    final err = ref.read(gameControllerProvider.notifier).work(job.id);
                                    if (err == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(l.earned(Format.cash(job.payMinor)))));
                                    } else if (err == GameError.insufficientEnergy) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.tooTired)));
                                    }
                                  }
                                : null,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          SectionHeader(l.growth),
          AppCard(
            onTap: () => context.go(Routes.gear),
            child: Row(
              children: [
                const AssetArt('gear_light', size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(l.gearShop, style: t.titleMedium)),
                Text(l.ownedCount(life.gearIds.length), style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: Space.s),
          AppCard(
            onTap: () => context.go(Routes.skills),
            child: Row(
              children: [
                const AssetArt('skill_creativity', size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(l.skills, style: t.titleMedium)),
                if (life.skillPoints > 0) StatusBadge(BadgeState.ready, label: l.pointsToSpend(life.skillPoints)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          SectionHeader(l.homeSection),
          AppCard(
            child: Row(
              children: [
                AssetArt(life.homeId, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.homeSharedRoom, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(l.homesLater, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(l.settings),
          const _SettingsCard(),
          SectionHeader(l.about),
          Text(l.aboutLine(c.contentVersion), style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(l.privacyLine, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.color, required this.info});
  final String label;
  final int value;
  final Color color;
  final String info;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 84, child: Text(label)),
      Expanded(
        child: ProgressBar(permille: value * 10, color: color),
      ),
      SizedBox(
        width: 40,
        child: Text(
          '$value',
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      InfoButton(title: label, body: info),
    ],
  );
}

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final a = ref.watch(gameControllerProvider.select((s) => s.account));
    final game = ref.read(gameControllerProvider.notifier);
    Widget row(IconData icon, String title, String? subtitle, bool value, ValueChanged<bool> onChanged) =>
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.mint,
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.m),
          secondary: Icon(icon, color: AppColors.textMuted),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        );
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          row(Icons.volume_up_rounded, l.settingSound, null, a.soundOn, game.setSound),
          row(Icons.vibration_rounded, l.settingHaptics, null, a.hapticsOn, game.setHaptics),
          row(
            Icons.notifications_rounded,
            l.settingNotifications,
            l.settingNotificationsBody,
            a.notificationsOptIn ?? false,
            (v) async {
              final granted = await game.setNotifications(v);
              if (v && !granted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.notifyDenied)));
              }
            },
          ),
        ],
      ),
    );
  }
}
