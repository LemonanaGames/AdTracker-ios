import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/providers.dart';
import 'core/clock.dart';
import 'data/app_database.dart';
import 'data/catalog_loader.dart';
import 'data/drift_save_repository.dart';
import 'domain/engine/game_engine.dart';

/// Startup (GDD F5, M1 subset): local DB + bundled content, then Home.
/// Firebase, consent, RevenueCat, Singular and AdMob are added in M4/M5;
/// none are initialised or contacted in this build.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final catalog = await CatalogLoader.load(rootBundle);
  final assets = await CatalogLoader.loadAssets(rootBundle);
  final repo = DriftSaveRepository(AppDatabase.open());
  const clock = SystemClock();
  String newId() => const Uuid().v4();

  final session = await loadSession(repo: repo, engine: GameEngine(catalog), clock: clock, newId: newId);

  runApp(
    ProviderScope(
      overrides: [
        catalogProvider.overrideWithValue(catalog),
        assetManifestProvider.overrideWithValue(assets),
        saveRepositoryProvider.overrideWithValue(repo),
        initialSessionProvider.overrideWithValue(session),
      ],
      child: const InfluencerSimApp(),
    ),
  );
}
