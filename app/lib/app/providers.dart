import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/telemetry.dart';
import '../domain/content/asset_manifest.dart';
import '../domain/content/game_catalog.dart';
import '../domain/engine/game_engine.dart';
import '../domain/engine/game_event.dart';
import '../domain/repositories/save_repository.dart';
import 'game_controller.dart';
import 'game_session.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';

/// Overridden in bootstrap (loaded before runApp) and in tests.
final catalogProvider = Provider<GameCatalog>((ref) => throw UnimplementedError('catalogProvider not overridden'));
final assetManifestProvider = Provider<AssetManifest>(
  (ref) => throw UnimplementedError('assetManifestProvider not overridden'),
);
final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => throw UnimplementedError('saveRepositoryProvider not overridden'),
);
final initialSessionProvider = Provider<GameSession>(
  (ref) => throw UnimplementedError('initialSessionProvider not overridden'),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());
final telemetryProvider = Provider<Telemetry>((ref) => DebugTelemetry());
final idGeneratorProvider = Provider<String Function()>(
  (ref) =>
      () => const Uuid().v4(),
);

final soundServiceProvider = Provider<SoundService>((ref) => const NoopSoundService());
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => NoopNotificationScheduler());

/// Local hour (0–23) of an epoch instant — injectable for deterministic tests.
final localHourProvider = Provider<int Function(int epochMs)>(
  (ref) =>
      (ms) => DateTime.fromMillisecondsSinceEpoch(ms).hour,
);

/// Continuous decorative motion (drifting gradients, pulses). Off in tests so
/// `pumpAndSettle` can settle; always off when the OS asks to reduce motion.
final ambientMotionProvider = Provider<bool>((ref) => true);

/// Whether the 1-second foreground simulation ticker runs (off in some tests).
final tickerEnabledProvider = Provider<bool>((ref) => true);

final engineProvider = Provider<GameEngine>((ref) => GameEngine(ref.watch(catalogProvider)));

final gameControllerProvider = NotifierProvider<GameController, GameSession>(GameController.new);

/// Domain events for celebrations (snackbars) — analytics are logged in the controller.
final gameEventsProvider = StreamProvider<GameEvent>((ref) => ref.watch(gameControllerProvider.notifier).events);
