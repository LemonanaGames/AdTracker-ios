// Renders key screens with real fonts to PNG for visual review (not part of
// the normal suite). Run from app/:
//   SHOT_DIR=/some/dir flutter test tool/screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/app/app.dart';
import 'package:influencer_simulator/app/game_session.dart';
import 'package:influencer_simulator/app/providers.dart';
import 'package:influencer_simulator/core/clock.dart';
import 'package:influencer_simulator/data/in_memory_save_repository.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';
import 'package:influencer_simulator/domain/model/life_state.dart';
import 'package:influencer_simulator/domain/model/player_account.dart';

import '../test/support/fixtures.dart';

Future<void> _loadFonts() async {
  const root = '/opt/flutter/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(Future.value(ByteData.sublistView(File('$root/Roboto-$w.ttf').readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$root/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  final catalog = loadCatalog();
  final assets = loadAssetManifest();
  final engine = GameEngine(catalog);
  final outDir = Platform.environment['SHOT_DIR'] ?? 'build/screenshots';
  final boundaryKey = GlobalKey();

  const draft = PostDraft(
    networkId: NetworkId.loop,
    formatId: 'loop_short',
    topicId: 'topic_first_challenge',
    hookId: 'hook_question',
  );

  LifeState progressedLife() {
    var life = newTestLife(engine).copyWith();
    life = engine.publish(life, draft).life;
    life = engine.advanceTo(life, t0 + 3 * 60 * 1000).life;
    life = engine.work(life, 'job_cafe').life;
    life = engine.buyGear(life, 'gear_light_1').life;
    life = engine.publish(life, draft).life;
    life = engine.advanceTo(life, t0 + 6 * 60 * 1000).life;
    return engine.publish(life, draft).life; // V01 pending, income pending
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(outDir).createSync(recursive: true);
      File('$outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<void> pump(WidgetTester tester, GameSession session) async {
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2;
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          key: UniqueKey(),
          overrides: [
            catalogProvider.overrideWithValue(catalog),
            assetManifestProvider.overrideWithValue(assets),
            saveRepositoryProvider.overrideWithValue(InMemorySaveRepository()),
            initialSessionProvider.overrideWithValue(session),
            clockProvider.overrideWithValue(FakeClock(t0 + 6 * 60 * 1000)),
            tickerEnabledProvider.overrideWithValue(false),
          ],
          child: const InfluencerSimApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUpAll(_loadFonts);

  testWidgets('screens', (tester) async {
    final life = progressedLife();
    final account = PlayerAccount(uid: 'u', createdAtMs: t0, activeLifeId: life.lifeId, lifeCount: 1);

    await pump(tester, GameSession(account: account));
    await shot(tester, '01_onboarding_welcome');

    await pump(tester, GameSession(account: account, life: life));
    await shot(tester, '02_home');

    await tester.tap(find.text('Create').last);
    await shot(tester, '03_create_top');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1400));
    await shot(tester, '04_create_preview');

    await tester.tap(find.text('Social').last);
    await shot(tester, '05_social');

    await tester.tap(find.text('Deals').last);
    await shot(tester, '06_deals');

    await tester.tap(find.text('Life').last);
    await shot(tester, '07_life');

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your Phone Is Blowing Up'));
    await shot(tester, '08_story');

    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });
}
