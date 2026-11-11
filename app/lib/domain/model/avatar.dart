import 'ids.dart';

final class Avatar {
  const Avatar({
    required this.displayName,
    required this.handle,
    required this.nicheId,
    required this.presetId,
    this.persona = CreatorPersona.onCamera,
  });

  final String displayName;
  final String handle;
  final String nicheId;
  final String presetId;
  final CreatorPersona persona;

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'handle': handle,
    'nicheId': nicheId,
    'presetId': presetId,
    'persona': persona.name,
  };

  factory Avatar.fromJson(Map<String, Object?> j) => Avatar(
    displayName: j['displayName']! as String,
    handle: j['handle']! as String,
    nicheId: j['nicheId']! as String,
    presetId: j['presetId']! as String,
    persona: CreatorPersona.parse(j['persona'] as String? ?? 'onCamera'),
  );
}
