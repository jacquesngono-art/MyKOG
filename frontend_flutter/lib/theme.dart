import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette historique (accents partagés entre les thèmes + anciens noms
/// conservés pour compatibilité).
class MyKOGColors {
  // Gold Accent (Apple Music inspired) - identique en clair et en sombre
  static const accent = Color(0xFFd4af37);
  static const accentLight = Color(0xFFe6c758);

  // Success (Spotify green)
  static const success = Color(0xFF1db954);

  // Error
  static const error = Color(0xFFe22134);

  // Glass Effect (fond sombre translucide)
  static const glassEffect = Color(0x20FFFFFF);

  // ---- Anciens noms (palette sombre) conservés pour compatibilité ----
  static const primary = Color(0xFF000000);
  static const primaryDark = Color(0xFF000000);
  static const secondary = Color(0xFF1a1a1a);
  static const surface = Color(0xFF121212);
  static const textPrimary = Color(0xFFffffff);
  static const textSecondary = Color(0xFFb3b3b3);
  static const textTertiary = Color(0xFF808080);
}

/// Couleurs sémantiques qui s'adaptent automatiquement au thème clair/sombre.
///
/// Utilisation : `context.appColors.textPrimary`
class AppColors {
  final Color background; // fond principal (scaffold, barres)
  final Color surface; // cartes / surfaces élevées
  final Color surfaceVariant; // panneaux secondaires, champs
  final Color primary; // contraste fort (badges, éléments marqués)
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color border;
  final Color accent;
  final Color success;
  final Color error;
  final Color glass;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.border,
    required this.accent,
    required this.success,
    required this.error,
    required this.glass,
  });

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF2F2F4),
    primary: Color(0xFF3B82F6),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF5A5A5A),
    textTertiary: Color(0xFF8A8A8A),
    divider: Color(0xFFE5E5E7),
    border: Color(0xFFE0E0E2),
    accent: MyKOGColors.accent,
    success: MyKOGColors.success,
    error: Color(0xFFE22134),
    glass: Color(0x14FFFFFF),
  );

  static const dark = AppColors(
    background: Color(0xFF0A1424),
    surface: Color(0xFF0F1E38),
    surfaceVariant: Color(0xFF15294A),
    primary: Color(0xFF3B82F6),
    textPrimary: Color(0xFFF2F6FF),
    textSecondary: Color(0xFFB3C2E0),
    textTertiary: Color(0xFF8091B3),
    divider: Color(0xFF1E3252),
    border: Color(0xFF23395E),
    accent: MyKOGColors.accent,
    success: MyKOGColors.success,
    error: Color(0xFFFF5252),
    glass: MyKOGColors.glassEffect,
  );
}

/// Accès rapide aux couleurs dépendantes du thème depuis n'importe quel widget.
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).brightness == Brightness.dark
      ? AppColors.dark
      : AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 24.0;
  static const double headlineSmall = 22.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

TextTheme _buildTextTheme(AppColors c) {
  return TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.bold,
      color: c.textPrimary,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.bold,
      color: c.textPrimary,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.bold,
      color: c.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: c.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: c.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: c.textPrimary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: c.accent,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: c.accent,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: c.accent,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: c.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: c.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: c.textSecondary,
    ),
  );
}

ThemeData _baseTheme(AppColors c, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    cardColor: c.surface,
    dividerColor: c.divider,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: const Color(0xFFFFFFFF),
      secondary: c.accent,
      onSecondary: const Color(0xFF000000),
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceVariant,
      error: c.error,
      outline: c.border,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: c.textPrimary),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: FontSizes.titleLarge,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.background,
      selectedItemColor: c.accent,
      unselectedItemColor: c.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(color: c.textPrimary),
    dialogTheme: DialogThemeData(backgroundColor: c.surface),
    popupMenuTheme: PopupMenuThemeData(color: c.surface),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.border.withValues(alpha: 0.6)),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
    listTileTheme: ListTileThemeData(iconColor: c.textSecondary),
    textTheme: _buildTextTheme(c),
  );
}

ThemeData get lightTheme => _baseTheme(AppColors.light, Brightness.light);

ThemeData get darkTheme => _baseTheme(AppColors.dark, Brightness.dark);
