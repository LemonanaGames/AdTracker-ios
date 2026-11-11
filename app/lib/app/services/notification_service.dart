import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A fully localized notification ready for the OS.
final class LocalNote {
  const LocalNote({required this.id, required this.title, required this.body, required this.fireAtMs});
  final int id;
  final String title;
  final String body;
  final int fireAtMs;
}

/// Platform boundary for local notifications (no push server involved).
abstract interface class NotificationScheduler {
  Future<void> init();

  /// Shows the OS permission prompt. Returns whether notifications are allowed.
  Future<bool> requestPermission();

  /// Cancels everything pending and schedules [notes].
  Future<void> replaceAll(List<LocalNote> notes);
  Future<void> cancelAll();
}

/// Tests, web preview and anything without a scheduler.
final class NoopNotificationScheduler implements NotificationScheduler {
  NoopNotificationScheduler();
  final List<LocalNote> scheduled = [];
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<LocalNote> notes) async => scheduled
    ..clear()
    ..addAll(notes);
  @override
  Future<void> cancelAll() async => scheduled.clear();
}

final class LocalNotificationScheduler implements NotificationScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'game_updates',
      'Game updates',
      channelDescription: 'When your posts finish, you hit a milestone or something is ready.',
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Never ask at launch; we ask in context after the first post.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } on Object catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  @override
  Future<void> replaceAll(List<LocalNote> notes) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final n in notes) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, n.fireAtMs),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
