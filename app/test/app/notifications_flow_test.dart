import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/app/game_session.dart';
import 'package:influencer_simulator/app/providers.dart';
import 'package:influencer_simulator/app/services/notification_service.dart';
import 'package:influencer_simulator/core/clock.dart';
import 'package:influencer_simulator/data/in_memory_save_repository.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/post_simulation.dart';
import 'package:influencer_simulator/domain/model/ids.dart';
import 'package:influencer_simulator/domain/model/player_account.dart';

import '../support/fixtures.dart';

void main() {
  final catalog = loadCatalog();
  final engine = GameEngine(catalog);

  ProviderContainer container(NoopNotificationScheduler scheduler, {bool? optIn}) {
    final life = engine
        .publish(
          newTestLife(engine),
          const PostDraft(
            networkId: NetworkId.loop,
            formatId: 'loop_short',
            topicId: 'topic_first_challenge',
            hookId: 'hook_question',
          ),
        )
        .life;
    final c = ProviderContainer(
      overrides: [
        catalogProvider.overrideWithValue(catalog),
        assetManifestProvider.overrideWithValue(loadAssetManifest()),
        saveRepositoryProvider.overrideWithValue(InMemorySaveRepository()),
        initialSessionProvider.overrideWithValue(
          GameSession(
            account: PlayerAccount(uid: 'u', createdAtMs: t0, activeLifeId: life.lifeId, notificationsOptIn: optIn),
            life: life,
          ),
        ),
        clockProvider.overrideWithValue(FakeClock(t0)),
        notificationSchedulerProvider.overrideWithValue(scheduler),
        tickerEnabledProvider.overrideWithValue(false),
        localHourProvider.overrideWithValue((ms) => ((ms - t0) ~/ 3600000 + 12) % 24),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('opted-in player gets real, localized reminders when leaving; returning cancels them', () async {
    final scheduler = NoopNotificationScheduler();
    final c = container(scheduler);
    final game = c.read(gameControllerProvider.notifier);
    await pumpEventQueue();

    expect(await game.setNotifications(true), isTrue);
    expect(c.read(gameControllerProvider).account.notificationsOptIn, isTrue);

    game.onAppPaused();
    await pumpEventQueue();
    expect(scheduler.scheduled, isNotEmpty);
    expect(scheduler.scheduled.length, lessThanOrEqualTo(3));
    final post = scheduler.scheduled.firstWhere((n) => n.title.contains('First Challenge'));
    expect(post.body, contains('views'));
    expect(post.body, contains('Loop'));

    game.onAppResumed();
    await pumpEventQueue();
    expect(scheduler.scheduled, isEmpty);
  });

  test('players who said no never get anything scheduled', () async {
    final scheduler = NoopNotificationScheduler();
    final c = container(scheduler, optIn: false);
    await pumpEventQueue();
    c.read(gameControllerProvider.notifier).onAppPaused();
    await pumpEventQueue();
    expect(scheduler.scheduled, isEmpty);
  });

  test('session hours are learned for the daily reminder', () async {
    final c = container(NoopNotificationScheduler());
    c.read(gameControllerProvider);
    await pumpEventQueue();
    expect(c.read(gameControllerProvider).account.sessionHours, [12]);
  });
}
