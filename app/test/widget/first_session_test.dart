import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/app/app.dart';
import 'package:influencer_simulator/app/bootstrap.dart';
import 'package:influencer_simulator/app/providers.dart';
import 'package:influencer_simulator/core/clock.dart';
import 'package:influencer_simulator/data/in_memory_save_repository.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/model/ids.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final assets = loadAssetManifest();
  final engine = GameEngine(catalog);

  Future<void> pumpApp(WidgetTester tester, InMemorySaveRepository repo, FakeClock clock) async {
    var n = 0;
    String newId() => 'id-${n++}';
    final session = await loadSession(repo: repo, engine: engine, clock: clock, newId: newId);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWithValue(catalog),
          assetManifestProvider.overrideWithValue(assets),
          saveRepositoryProvider.overrideWithValue(repo),
          initialSessionProvider.overrideWithValue(session),
          clockProvider.overrideWithValue(clock),
          idGeneratorProvider.overrideWithValue(newId),
          tickerEnabledProvider.overrideWithValue(false),
          ambientMotionProvider.overrideWithValue(false),
        ],
        child: const InfluencerSimApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> expectOnScreen(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    }
    expect(finder, findsOneWidget);
  }

  testWidgets('new player reaches their first published post, and it survives a restart', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = InMemorySaveRepository();
    final clock = FakeClock(t0);
    await pumpApp(tester, repo, clock);

    // Onboarding: welcome → name → niche → avatar.
    expect(find.text('Become the Creator Everyone Knows'), findsOneWidget);
    await tapText(tester, 'Start My Story');
    await tester.enterText(find.byType(TextField).first, 'Rae Sky');
    await tester.pumpAndSettle();
    expect(find.textContaining('@raesky'), findsOneWidget);
    await tapText(tester, 'Continue');
    await tapText(tester, 'Comedy');
    await tapText(tester, 'Continue');
    await tapText(tester, 'Looks Good');

    // Home: clear next step, no popups.
    expect(find.text('Publish your first post'), findsOneWidget);
    expect(find.text('Create Post'), findsOneWidget);
    expect(find.textContaining("Let's make yours"), findsOneWidget);

    // Create: first-challenge topic is preselected and highlighted; publish.
    await tapText(tester, 'Create Post');
    expect(find.text('START HERE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Publish'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('38'), findsWidgets, reason: 'first post quality 38/100');
    await tapText(tester, 'Publish');
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Published!'), findsOneWidget);
    expect(find.text('Followers are people who want to see your next post.'), findsOneWidget);
    await tapText(tester, 'Back home');
    await expectOnScreen(tester, 'Latest post');

    final saved = await repo.loadLife((await repo.loadAccount())!.activeLifeId!);
    expect(saved!.counter(Counters.postsPublished), 1);
    final followersAfterPublish = saved.network(NetworkId.loop).followers;

    // "Close" the app, come back 10 minutes later.
    await tester.pumpWidget(const SizedBox());
    clock.advance(const Duration(minutes: 10));
    await pumpApp(tester, repo, clock);

    expect(find.text('Become the Creator Everyone Knows'), findsNothing);
    expect(find.textContaining('@raesky'), findsOneWidget);
    expect(find.text('While you were away'), findsOneWidget);
    await expectOnScreen(tester, 'Latest post');
    final reloaded = await repo.loadLife(saved.lifeId);
    expect(reloaded!.network(NetworkId.loop).followers, greaterThanOrEqualTo(followersAfterPublish));
    expect(reloaded.posts.single.views, greaterThan(saved.posts.single.views));

    // The tip was marked as seen and is not shown again on the next post.
    expect((await repo.loadAccount())!.seenTips, contains('tip_followers'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('first gear purchase shows before/after and deducts cash', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo = InMemorySaveRepository();
    final clock = FakeClock(t0);
    final life = engine.newLife(lifeId: 'L1', lifeNumber: 1, avatar: testAvatar, nowMs: t0).copyWith(cashMinor: 15000);
    await repo.saveLife(life);
    await repo.saveAccount(
      (await loadSession(
        repo: repo,
        engine: engine,
        clock: clock,
        newId: () => 'acc',
      )).account.copyWith(activeLifeId: 'L1'),
    );
    await pumpApp(tester, repo, clock);

    await tapText(tester, 'Life');
    await tapText(tester, 'Gear');
    expect(find.text('Gear quality +8 → +10'), findsOneWidget);
    await tapText(tester, r'$120');
    expect(find.text('Desk Light is yours!'), findsOneWidget);
    expect((await repo.loadLife('L1'))!.cashMinor, 3000);

    await tester.pumpWidget(const SizedBox());
  });
}
