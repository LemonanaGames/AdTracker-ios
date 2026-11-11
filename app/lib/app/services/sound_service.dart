import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Original synthesized UI sounds (tools/sfx_synth/make_sfx.py).
enum Sfx {
  tap('tap'),
  pop('pop'),
  coin('coin'),
  publish('publish'),
  levelUp('level_up'),
  unlock('unlock'),
  message('message'),
  error('error'),
  purchase('purchase');

  const Sfx(this.file);
  final String file;
}

abstract interface class SoundService {
  Future<void> init();
  void play(Sfx sfx);
}

final class NoopSoundService implements SoundService {
  const NoopSoundService();
  @override
  Future<void> init() async {}
  @override
  void play(Sfx sfx) {}
}

/// Low-latency players, two per effect so rapid repeats overlap. Uses the
/// "ambient" audio session on iOS: mixes with the player's music and
/// respects the silent switch.
final class AudioSoundService implements SoundService {
  final Map<Sfx, List<AudioPlayer>> _pool = {};
  final Map<Sfx, int> _next = {};
  bool _ready = false;

  @override
  Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContextConfig(respectSilence: true).build());
      for (final s in Sfx.values) {
        final players = <AudioPlayer>[];
        for (var i = 0; i < 2; i++) {
          final p = AudioPlayer(playerId: 'sfx_${s.file}_$i');
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setSource(AssetSource('sfx/${s.file}.wav'));
          players.add(p);
        }
        _pool[s] = players;
      }
      _ready = true;
    } on Object catch (e) {
      debugPrint('Sound disabled: $e'); // never let audio break the game
    }
  }

  @override
  void play(Sfx sfx) {
    if (!_ready) return;
    final players = _pool[sfx]!;
    final i = (_next[sfx] ?? 0) % players.length;
    _next[sfx] = i + 1;
    final p = players[i];
    unawaited(() async {
      try {
        await p.stop();
        await p.resume();
      } on Object catch (_) {}
    }());
  }
}
