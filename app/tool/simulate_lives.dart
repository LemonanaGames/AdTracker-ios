// Balance simulator: plays N seeded lives with the AutoPlayer and reports
// real-time pacing to key milestones. Run from app/:
//   dart run tool/simulate_lives.dart [lives=200] [minutes=180]
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:influencer_simulator/domain/content/game_catalog.dart';
import 'package:influencer_simulator/domain/engine/autoplayer.dart';
import 'package:influencer_simulator/domain/engine/game_engine.dart';
import 'package:influencer_simulator/domain/engine/progression.dart';
import 'package:influencer_simulator/domain/model/avatar.dart';
import 'package:influencer_simulator/domain/model/ids.dart';

void main(List<String> args) {
  final lives = args.isNotEmpty ? int.parse(args[0]) : 200;
  final minutes = args.length > 1 ? int.parse(args[1]) : 180;
  final catalog = GameCatalog.fromSources({
    for (final f in GameCatalog.files) f: File('../game_content/$f').readAsStringSync(),
  });
  final engine = GameEngine(catalog);
  final milestones = <String, List<double>>{};
  final finals = <String, List<int>>{'loop': [], 'tubecast': [], 'level': [], 'cash': []};

  for (var i = 0; i < lives; i++) {
    const t0 = 1800000000000;
    final niche = catalog.niches[i % catalog.niches.length].id;
    var life = engine.newLife(
      lifeId: 'sim-$i',
      lifeNumber: 1,
      avatar: Avatar(displayName: 'Sim', handle: '@sim', nicheId: niche, presetId: 'avatar_1'),
      nowMs: t0,
    );
    final bot = AutoPlayer(engine, strategy: AutoStrategy.values[i % AutoStrategy.values.length]);
    final hit = <String>{};
    void mark(String key, bool cond, int sec) {
      if (cond && hit.add(key)) milestones.putIfAbsent(key, () => []).add(sec / 60);
    }

    for (var sec = 1; sec <= minutes * 60; sec++) {
      life = bot.step(life, t0 + sec * 1000);
      if (life.cashMinor < 0 || life.pendingIncomeMinor < 0) throw StateError('negative money');
      mark('first light', life.gearIds.contains('gear_light_1'), sec);
      mark('loop 100', life.network(NetworkId.loop).followers >= 100, sec);
      mark('level 2', Progression.levelForXp(catalog.economy, life.creatorXp) >= 2, sec);
      mark('V01 story', life.completedEventIds.contains('V01'), sec);
      mark('act1 (TubeCast)', catalog.actIndex(life.actId) >= 1, sec);
      mark('loop 1k', life.network(NetworkId.loop).followers >= 1000, sec);
      mark('act2', catalog.actIndex(life.actId) >= 2, sec);
      mark('loop 10k', life.network(NetworkId.loop).followers >= 10000, sec);
    }
    finals['loop']!.add(life.network(NetworkId.loop).followers);
    finals['tubecast']!.add(life.network(NetworkId.tubecast).followers);
    finals['level']!.add(Progression.levelForXp(catalog.economy, life.creatorXp));
    finals['cash']!.add(life.cashMinor ~/ 100);
  }

  String pct(List<num> xs, double p) {
    final s = [...xs]..sort();
    return s[((s.length - 1) * p).round()].toStringAsFixed(1);
  }

  print('Lives: $lives, session length: $minutes real minutes (foreground, no offline).');
  print('milestone            reached   p10    median   p90   (real minutes)');
  for (final e in milestones.entries) {
    print(
      '${e.key.padRight(20)} ${'${e.value.length}/$lives'.padRight(9)} '
      '${pct(e.value, .1).padLeft(5)}  ${pct(e.value, .5).padLeft(6)}  ${pct(e.value, .9).padLeft(6)}',
    );
  }
  print('final after $minutes min: ');
  for (final e in finals.entries) {
    print('  ${e.key.padRight(9)} p10 ${pct(e.value, .1)}  median ${pct(e.value, .5)}  p90 ${pct(e.value, .9)}');
  }
}
