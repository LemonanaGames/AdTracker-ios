import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:influencer_simulator/app/format.dart';

void main() {
  test('domain/ and core/ are pure Dart (no Flutter, Firebase or SDK imports)', () {
    final offenders = <String>[];
    for (final dir in ['lib/domain', 'lib/core']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        for (final line in f.readAsLinesSync()) {
          if (RegExp(r'''^import 'package:(flutter|firebase|drift|riverpod|flutter_riverpod|go_router)''')
              .hasMatch(line)) {
            offenders.add('${f.path}: $line');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no floating point money in the domain', () {
    for (final f in Directory('lib/domain').listSync(recursive: true).whereType<File>()) {
      final src = f.readAsStringSync();
      expect(
        RegExp(r'double\s+\w*(cash|Minor|price|revenue)', caseSensitive: false).hasMatch(src),
        isFalse,
        reason: f.path,
      );
    }
  });

  group('Format', () {
    test('cash', () {
      expect(Format.cash(0), r'$0');
      expect(Format.cash(6000), r'$60');
      expect(Format.cash(1250), r'$12.50');
      expect(Format.cash(123456789), r'$1,234,567');
      expect(Format.cash(-500), r'-$5');
    });
    test('counts', () {
      expect(Format.compact(950), '950');
      expect(Format.compact(8712), '8.7K');
      expect(Format.compact(1250000), '1.3M');
      expect(Format.count(12430), '12,430');
      expect(Format.bps(650), '6.5%');
      expect(Format.bps(41), '0.4%');
      expect(Format.delta(5), '+5');
      expect(Format.delta(-3), '-3');
    });
  });
}
