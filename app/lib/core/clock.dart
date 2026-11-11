/// Wall-clock abstraction so time-dependent logic is testable.
abstract interface class Clock {
  /// Milliseconds since the Unix epoch.
  int nowMs();
}

/// Real device clock.
final class SystemClock implements Clock {
  const SystemClock();
  @override
  int nowMs() => DateTime.now().millisecondsSinceEpoch;
}

/// Manually driven clock for tests and tools.
final class FakeClock implements Clock {
  FakeClock(this._now);
  int _now;
  @override
  int nowMs() => _now;
  void advance(Duration d) => _now += d.inMilliseconds;
  void set(int ms) => _now = ms;
}
