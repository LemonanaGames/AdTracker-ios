import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/providers.dart';
import 'app/services/notification_service.dart';
import 'app/services/sound_service.dart';
import 'core/clock.dart';
import 'data/app_database.dart';
import 'data/catalog_loader.dart';
import 'data/drift_save_repository.dart';
import 'data/prefs_save_repository.dart';
import 'domain/engine/game_engine.dart';
import 'domain/repositories/save_repository.dart';

/// Startup (GDD F5, M1 subset): local DB + bundled content, then Home.
/// Firebase, consent, RevenueCat, Singular and AdMob are added in M4/M5;
/// none are initialised or contacted in this build.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final catalog = await CatalogLoader.load(rootBundle);
  final assets = await CatalogLoader.loadAssets(rootBundle);
  // Devices: SQLite. Web preview: browser storage (same save format).
  final SaveRepository repo = kIsWeb
      ? PrefsSaveRepository(await SharedPreferences.getInstance())
      : DriftSaveRepository(AppDatabase.open());
  const clock = SystemClock();
  String newId() => const Uuid().v4();

  final sound = AudioSoundService();
  await sound.init();
  // Local notifications only on devices; the web preview cannot schedule.
  final NotificationScheduler notifications = kIsWeb ? NoopNotificationScheduler() : LocalNotificationScheduler();
  await notifications.init();

  final session = await loadSession(repo: repo, engine: GameEngine(catalog), clock: clock, newId: newId);

  runApp(
    ProviderScope(
      overrides: [
        catalogProvider.overrideWithValue(catalog),
        assetManifestProvider.overrideWithValue(assets),
        saveRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(session),
        soundServiceProvider.overrideWithValue(sound),
        notificationSchedulerProvider.overrideWithValue(notifications),
      ],
      child: const InfluencerSimApp(),
    ),
  );
}
