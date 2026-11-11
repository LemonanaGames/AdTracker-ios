import 'package:intl/intl.dart';

/// All user-visible numbers go through here (never hand-roll strings).
abstract final class Format {
  static final _group = NumberFormat.decimalPattern('en_US');
  static final _compact = NumberFormat.compact(locale: 'en_US')..maximumFractionDigits = 1;

  /// In-game fictional cash. Cents only below $1,000 and only when non-zero.
  static String cash(int minor) {
    final negative = minor < 0;
    final abs = minor.abs();
    final dollars = abs ~/ 100;
    final cents = abs % 100;
    final whole = _group.format(dollars);
    final body = abs >= 100000 || cents == 0 ? '\$$whole' : '\$$whole.${cents.toString().padLeft(2, '0')}';
    return negative ? '-$body' : body;
  }

  /// 950 → "950", 8,712 → "8.7K", 1,250,000 → "1.3M".
  static String compact(int n) => n < 1000 ? '$n' : _compact.format(n);

  /// Exact count with grouping: 12,430.
  static String count(int n) => _group.format(n);

  /// Basis points as a percentage: 650 → "6.5%".
  static String bps(int bps) {
    final whole = bps ~/ 100;
    final tenth = (bps % 100) ~/ 10;
    return '$whole.$tenth%';
  }

  /// Signed delta: +12 / -3.
  static String delta(int n) => n >= 0 ? '+${count(n)}' : count(n);
}
