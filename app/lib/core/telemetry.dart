/// Analytics boundary. Event names/params follow docs/analytics_taxonomy.md.
///
/// M1 ships only [DebugTelemetry] / [NoopTelemetry]. Firebase Analytics and
/// Singular adapters are added in M4 once their configs are verified; nothing
/// is sent off-device before then.
abstract interface class Telemetry {
  void log(String name, [Map<String, Object> params = const {}]);
}

final class NoopTelemetry implements Telemetry {
  const NoopTelemetry();
  @override
  void log(String name, [Map<String, Object> params = const {}]) {}
}

/// Keeps the last events in memory (debug screen / tests). Never leaves device.
final class DebugTelemetry implements Telemetry {
  DebugTelemetry({this.capacity = 200});
  final int capacity;
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  void log(String name, [Map<String, Object> params = const {}]) {
    events.add((name: name, params: params));
    if (events.length > capacity) events.removeAt(0);
  }
}
