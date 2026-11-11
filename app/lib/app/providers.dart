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

/// Whether the 1-second foreground simulation ticker runs (off in some tests).
final tickerEnabledProvider = Provider<bool>((ref) => true);

final engineProvider = Provider<GameEngine>((ref) => GameEngine(ref.watch(catalogProvider)));

final gameControllerProvider = NotifierProvider<GameController, GameSession>(GameController.new);

/// Domain events for celebrations (snackbars) — analytics are logged in the controller.
final gameEventsProvider = StreamProvider<GameEvent>((ref) => ref.watch(gameControllerProvider.notifier).events);
