import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../core/telemetry.dart';
import '../domain/engine/game_engine.dart';
import '../domain/engine/game_event.dart';
import '../domain/engine/post_simulation.dart';
import '../domain/model/avatar.dart';
import '../domain/model/content_post.dart';
import '../domain/model/ids.dart';
import '../domain/model/life_state.dart';
import '../domain/repositories/save_repository.dart';
import 'game_session.dart';
import 'providers.dart';

/// Thin application layer: forwards commands to the pure [GameEngine],
/// persists results, logs telemetry and drives the foreground clock.
/// No game rules live here.
class GameController extends Notifier<GameSession> {
  static const _saveEvery = Duration(seconds: 10);

  Timer? _ticker;
  int _lastSaveAtMs = 0;
  final _events = StreamController<GameEvent>.broadcast();

  Stream<GameEvent> get events => _events.stream;

  GameEngine get _engine => ref.read(engineProvider);
  SaveRepository get _repo => ref.read(saveRepositoryProvider);
  Clock get _clock => ref.read(clockProvider);
  Telemetry get _telemetry => ref.read(telemetryProvider);

  @override
  GameSession build() {
    ref.onDispose(() {
      _ticker?.cancel();
      unawaited(_events.close());
    });
    if (ref.read(tickerEnabledProvider)) _startTicker();
    return ref.read(initialSessionProvider);
  }

  // ------------------------------------------------------------ clock

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Advances the simulation to "now". Called every second in foreground.
  void tick() {
    final life = state.life;
    if (life == null) return;
    final r = _engine.advanceTo(life, _clock.nowMs());
    if (identical(r.life, life)) return;
    _commit(r.life, r.events, persist: false);
    if (_clock.nowMs() - _lastSaveAtMs >= _saveEvery.inMilliseconds) _save();
  }

  void onAppPaused() {
    _ticker?.cancel();
    tick();
    _save();
  }

  void onAppResumed() {
    final life = state.life;
    if (life != null) {
      final r = _engine.advanceTo(life, _clock.nowMs());
      final summary = r.value!;
      final minMs = ref.read(catalogProvider).economy.minOfflineSummarySeconds * 1000;
      final meaningful = summary.realDeltaMs >= minMs && (summary.viewsGained > 0 || summary.incomeGainedMinor > 0);
      state = state.copyWith(life: r.life, awaySummary: meaningful ? summary : null);
      _emit(r.events);
      _save();
    }
    if (ref.read(tickerEnabledProvider)) _startTicker();
  }

  // --------------------------------------------------------- commands

  Future<void> startLife({
    required String displayName,
    required String handle,
    required String nicheId,
    required String presetId,
    CreatorPersona persona = CreatorPersona.onCamera,
  }) async {
    final account = state.account;
    final life = _engine.newLife(
      lifeId: ref.read(idGeneratorProvider)(),
      lifeNumber: account.lifeCount + 1,
      avatar: Avatar(displayName: displayName, handle: handle, nicheId: nicheId, presetId: presetId, persona: persona),
      nowMs: _clock.nowMs(),
    );
    final nextAccount = account.copyWith(activeLifeId: life.lifeId, lifeCount: account.lifeCount + 1);
    await _repo.saveLife(life);
    await _repo.saveAccount(nextAccount);
    state = GameSession(account: nextAccount, life: life);
    _telemetry.log('new_life_started', {'niche_id': nicheId, 'persona': persona.name});
    _telemetry.log('tutorial_complete', {'step': 'avatar'});
  }

  CommandResult<ContentPost> publish(PostDraft draft) {
    final r = _engine.publish(state.life!, draft);
    if (r.ok) _commit(r.life, r.events);
    return r;
  }

  /// Returns the amount collected (0 if nothing pending).
  int collectIncome() {
    final r = _engine.claimIncome(state.life!, ref.read(idGeneratorProvider)());
    if (r.ok && (r.value ?? 0) > 0) _commit(r.life, r.events);
    return r.value ?? 0;
  }

  GameError? buyGear(String gearId) => _run(_engine.buyGear(state.life!, gearId));
  GameError? work(String jobId) => _run(_engine.work(state.life!, jobId));
  GameError? spendSkillPoint(String skillId) => _run(_engine.spendSkillPoint(state.life!, skillId));
  GameError? chooseStory(String eventId, String choiceId) => _run(_engine.chooseStory(state.life!, eventId, choiceId));

  void dismissAwaySummary() => state = state.copyWith(clearAway: true);

  void markTipSeen(String tipId) {
    if (state.account.seenTips.contains(tipId)) return;
    final account = state.account.copyWith(seenTips: {...state.account.seenTips, tipId});
    state = state.copyWith(account: account);
    unawaited(_repo.saveAccount(account).catchError(_onSaveError));
  }

  // ---------------------------------------------------------- helpers

  GameError? _run(CommandResult<Object?> r) {
    if (r.ok) _commit(r.life, r.events);
    return r.error;
  }

  void _commit(LifeState life, List<GameEvent> events, {bool persist = true}) {
    state = state.copyWith(life: life);
    _emit(events);
    if (persist) _save();
  }

  void _emit(List<GameEvent> events) {
    for (final e in events) {
      _telemetry.log(e.name, e.params);
      if (!_events.isClosed) _events.add(e);
    }
  }

  void _save() {
    final life = state.life;
    if (life == null) return;
    _lastSaveAtMs = _clock.nowMs();
    unawaited(_repo.saveLife(life).catchError(_onSaveError));
  }

  void _onSaveError(Object e) {
    debugPrint('Save failed: $e');
    _telemetry.log('save_failed', {'error': e.runtimeType.toString()});
  }
}
