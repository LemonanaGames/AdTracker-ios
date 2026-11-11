import 'package:flutter/material.dart';

/// "Creator-pop editorial" palette (GDD D3). Proposals: contrast still to be
/// validated with a formal audit in M6.
abstract final class AppColors {
  static const background = Color(0xFF10131F);
  static const surface = Color(0xFF1C2230);
  static const surfaceHigh = Color(0xFF252C3D);
  static const outline = Color(0xFF323A4E);
  static const text = Color(0xFFF7F8FA);
  static const textMuted = Color(0xFFA9B0C2);
  static const violet = Color(0xFF8F5BFF);
  static const coral = Color(0xFFFF6F78);
  static const mint = Color(0xFF54D6A1);
  static const amber = Color(0xFFFFB547);
  static const sky = Color(0xFF4FC3F7);

  static Color hex(String hex) => Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
}

/// Bundled OFL fonts (assets/fonts): a characterful grotesque for display,
/// Inter for reading.
abstract final class AppFonts {
  static const display = 'BricolageGrotesque';
  static const body = 'Inter';
}

/// 8pt spacing grid and radii.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const radius = 16.0;
  static const radiusSmall = 12.0;
  static const minTap = 44.0;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.violet, brightness: Brightness.dark).copyWith(
    primary: AppColors.violet,
    onPrimary: Colors.white,
    secondary: AppColors.coral,
    tertiary: AppColors.mint,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.outline,
    error: AppColors.coral,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    fontFamily: AppFonts.body,
  );
  final t = base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text);
  TextStyle? display(TextStyle? s, FontWeight w, [double spacing = -0.5]) =>
      s?.copyWith(fontFamily: AppFonts.display, fontWeight: w, letterSpacing: spacing, height: 1.05);
  final text = t.copyWith(
    displayLarge: display(t.displayLarge, FontWeight.w800, -1.5),
    displayMedium: display(t.displayMedium, FontWeight.w800, -1.2),
    displaySmall: display(t.displaySmall, FontWeight.w800, -1),
    headlineLarge: display(t.headlineLarge, FontWeight.w800),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: text.copyWith(
      headlineMedium: display(text.headlineMedium, FontWeight.w800),
      headlineSmall: display(text.headlineSmall, FontWeight.w800, -0.3),
      titleLarge: display(text.titleLarge, FontWeight.w700, -0.2),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.1),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        letterSpacing: -0.6,
        color: AppColors.text,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Space.radius))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.violet.withValues(alpha: 0.28),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(text.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(Space.minTap, 52),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Space.radius))),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(Space.minTap, 48),
        side: const BorderSide(color: AppColors.outline),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Space.radius))),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.violet.withValues(alpha: 0.35),
      side: const BorderSide(color: AppColors.outline),
      shape: const StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
    ),
  );
}
