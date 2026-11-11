/// Deterministic, platform-independent pseudo-random numbers.
///
/// Uses 32-bit arithmetic only so results are identical on the Dart VM,
/// AOT (iOS/Android) and JS. Seeds come from [Seed.of] (FNV-1a over strings).
library;

/// FNV-1a 32-bit hashing used to derive seeds from stable string IDs.
abstract final class Seed {
  static const int _offset = 0x811C9DC5;
  static const int _prime = 0x01000193;

  /// Hashes [parts] joined with a separator that cannot appear in IDs.
  static int of(List<Object> parts) {
    var hash = _offset;
    final text = parts.join('\u0001');
    for (final unit in text.codeUnits) {
      hash ^= unit & 0xFF;
      hash = _mul32(hash, _prime);
      hash ^= (unit >> 8) & 0xFF;
      hash = _mul32(hash, _prime);
    }
    return hash;
  }

  static int _mul32(int a, int b) {
    final lo = (a & 0xFFFF) * b;
    final hi = ((a >>> 16) * b) & 0xFFFF;
    return (lo + (hi << 16)) & 0xFFFFFFFF;
  }
}

/// Mulberry32: tiny, fast, good-enough PRNG for gameplay rolls.
final class Rng {
  Rng(int seed) : _state = seed & 0xFFFFFFFF;

  int _state;

  /// Next unsigned 32-bit integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = Seed._mul32(t ^ (t >>> 15), t | 1);
    t ^= (t + Seed._mul32(t ^ (t >>> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >>> 14)) & 0xFFFFFFFF;
  }

  /// Uniform integer in [min, max] inclusive.
  int intInRange(int min, int max) {
    assert(max >= min, 'max must be >= min');
    final span = max - min + 1;
    return min + (nextUint32() % span);
  }

  /// Index picked proportionally to non-negative [weights].
  int weightedIndex(List<int> weights) {
    final total = weights.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return 0;
    var roll = nextUint32() % total;
    for (var i = 0; i < weights.length; i++) {
      if (roll < weights[i]) return i;
      roll -= weights[i];
    }
    return weights.length - 1;
  }
}
