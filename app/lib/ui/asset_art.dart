import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import 'characters.dart';

/// Resolves a content `assetKey` through the asset manifest. In M1 every
/// entry is a vector placeholder (tinted icon tile); final art will set
/// `status: final` + `file` and render the image instead, no code changes.
class AssetArt extends ConsumerWidget {
  const AssetArt(this.assetKey, {this.size = 44, this.circle = false, this.semanticLabel, super.key});

  final String assetKey;
  final double size;
  final bool circle;
  final String? semanticLabel;

  /// Fixed map so icon fonts tree-shake correctly. Tested against the manifest.
  static const icons = <String, IconData>{
    'loop': Icons.all_inclusive_rounded,
    'play': Icons.play_circle_fill_rounded,
    'camera': Icons.photo_camera_rounded,
    'comedy': Icons.theater_comedy_rounded,
    'gaming': Icons.sports_esports_rounded,
    'lifestyle': Icons.local_florist_rounded,
    'flag': Icons.flag_rounded,
    'reaction': Icons.emoji_emotions_rounded,
    'desk': Icons.desk_rounded,
    'food': Icons.ramen_dining_rounded,
    'question': Icons.question_mark_rounded,
    'timer': Icons.timer_rounded,
    'sparkle': Icons.auto_awesome_rounded,
    'movie': Icons.movie_creation_rounded,
    'phone': Icons.smartphone_rounded,
    'light': Icons.light_rounded,
    'mic': Icons.mic_rounded,
    'edit': Icons.movie_edit,
    'laptop': Icons.laptop_mac_rounded,
    'studio': Icons.videocam_rounded,
    'coffee': Icons.coffee_rounded,
    'bike': Icons.pedal_bike_rounded,
    'idea': Icons.lightbulb_rounded,
    'face': Icons.face_rounded,
    'book': Icons.menu_book_rounded,
    'handshake': Icons.handshake_rounded,
    'megaphone': Icons.campaign_rounded,
    'person': Icons.person_rounded,
    'bed': Icons.bed_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final look = CharacterLooks.all[assetKey];
    if (look != null) {
      return Semantics(
        label: semanticLabel,
        image: semanticLabel != null,
        excludeSemantics: true,
        child: CharacterAvatar(look, size: size, circle: circle),
      );
    }
    final entry = ref.watch(assetManifestProvider)[assetKey];
    final color = entry == null ? AppColors.textMuted : AppColors.hex(entry.colorHex);
    final icon = icons[entry?.icon] ?? Icons.image_not_supported_rounded;
    final radius = circle ? size / 2 : size * 0.3;
    // Sticker-style tile: solid colour, light top-left sheen, dark glyph.
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, 0.28)!, color, Color.lerp(color, Colors.black, 0.18)!],
            stops: const [0, 0.55, 1],
          ),
          boxShadow: [BoxShadow(color: Color.lerp(color, Colors.black, 0.55)!, offset: Offset(0, size * 0.06))],
        ),
        alignment: Alignment.center,
        child: entry?.initials != null
            ? Text(
                entry!.initials!,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: size * 0.46,
                  fontWeight: FontWeight.w800,
                  color: AppColors.background,
                ),
              )
            : Icon(icon, size: size * 0.54, color: AppColors.background.withValues(alpha: 0.85)),
      ),
    );
  }
}
