import '../../domain/content/game_catalog.dart';
import '../../domain/model/ids.dart';
import '../../domain/notifications/notification_planner.dart';
import '../format.dart';
import '../l10n/app_localizations.dart';
import 'notification_service.dart';

/// Turns planner output into localized OS notifications.
abstract final class NotificationCopy {
  static LocalNote build(AppLocalizations l, GameCatalog c, PlannedNotification n) {
    String network() => c.strings[c.network(NetworkId.parse(n.args['network']! as String)).nameKey];
    final (title, body) = switch (n.kind) {
      NotificationKind.postFinished => (
        l.notifPostTitle(c.strings[c.topic(n.args['topicId']! as String)!.nameKey]),
        l.notifPostBody(Format.count(n.args['views']! as int), Format.count(n.args['followers']! as int), network()),
      ),
      NotificationKind.milestone => (
        l.notifMilestoneTitle(Format.compact(n.args['milestone']! as int), network()),
        l.notifMilestoneBody,
      ),
      NotificationKind.canAffordGear => (
        l.notifGearTitle(c.strings[c.gearItem(n.args['gearId']! as String)!.nameKey]),
        l.notifGearBody,
      ),
      NotificationKind.energyFull => (l.notifEnergyTitle, l.notifEnergyBody),
      NotificationKind.storyWaiting => (l.notifStoryTitle(_speaker(c, n.args['eventId']! as String)), l.notifStoryBody),
      NotificationKind.awayCap => (l.notifAwayTitle(Format.cash(n.args['cashMinor']! as int)), l.notifAwayBody),
      NotificationKind.dailyReminder => (l.notifDailyTitle, l.notifDailyBody),
    };
    return LocalNote(id: n.kind.id, title: title, body: body, fireAtMs: n.fireAtMs);
  }

  static String _speaker(GameCatalog c, String eventId) {
    final ev = c.event(eventId);
    final speaker = ev == null || ev.lines.isEmpty ? null : c.character(ev.lines.first.speaker);
    return speaker == null ? c.strings['npc.maya.name'] : c.strings[speaker.nameKey];
  }
}
