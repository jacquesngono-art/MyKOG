import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyKOGColors {
  // Primary Dark (Spotify inspired)
  static const primary = Color(0xFF000000);
  static const primaryDark = Color(0xFF000000);
  static const secondary = Color(0xFF1a1a1a);
  static const surface = Color(0xFF121212);
  
  // Gold Accent (Apple Music inspired)  
  static const accent = Color(0xFFd4af37);
  static const accentLight = Color(0xFFe6c758);
  
  // Text Colors
  static const textPrimary = Color(0xFFffffff);
  static const textSecondary = Color(0xFFb3b3b3);
  static const textTertiary = Color(0xFF808080);
  
  // Success (Spotify green)
  static const success = Color(0xFF1db954);
  
  // Glass Effect
  static const glassEffect = Color(0x20FFFFFF);
  
  // Error
  static const error = Color(0xFFe22134);
}

class LightModeColors {
  static const lightPrimary = Color(0xFF000000);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFf5f5f5);
  static const lightOnPrimaryContainer = Color(0xFF000000);
  static const lightSecondary = Color(0xFF1a1a1a);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightTertiary = Color(0xFFd4af37);
  static const lightOnTertiary = Color(0xFF000000);
  static const lightError = Color(0xFFe22134);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFffebee);
  static const lightOnErrorContainer = Color(0xFFe22134);
  static const lightInversePrimary = Color(0xFFd4af37);
  static const lightShadow = Color(0xFF000000);
  static const lightSurface = Color(0xFFffffff);
  static const lightOnSurface = Color(0xFF000000);
  static const lightAppBarBackground = Color(0xFFffffff);
}

class DarkModeColors {
  static const darkPrimary = Color(0xFFd4af37);
  static const darkOnPrimary = Color(0xFF000000);
  static const darkPrimaryContainer = Color(0xFF1a1a1a);
  static const darkOnPrimaryContainer = Color(0xFFffffff);
  static const darkSecondary = Color(0xFF1a1a1a);
  static const darkOnSecondary = Color(0xFFffffff);
  static const darkTertiary = Color(0xFFd4af37);
  static const darkOnTertiary = Color(0xFF000000);
  static const darkError = Color(0xFFff5252);
  static const darkOnError = Color(0xFF000000);
  static const darkErrorContainer = Color(0xFF1a1a1a);
  static const darkOnErrorContainer = Color(0xFFff5252);
  static const darkInversePrimary = Color(0xFF000000);
  static const darkShadow = Color(0xFF000000);
  static const darkSurface = Color(0xFF121212);
  static const darkOnSurface = Color(0xFFffffff);
  static const darkAppBarBackground = Color(0xFF000000);
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

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    inversePrimary: LightModeColors.lightInversePrimary,
    shadow: LightModeColors.lightShadow,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.lightAppBarBackground,
    foregroundColor: LightModeColors.lightOnPrimaryContainer,
    elevation: 0,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.bold,
      color: LightModeColors.lightOnSurface,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.bold,
      color: LightModeColors.lightOnSurface,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.bold,
      color: LightModeColors.lightOnSurface,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: LightModeColors.lightOnSurface,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
      color: LightModeColors.lightOnSurface,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightOnSurface,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightTertiary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightTertiary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: LightModeColors.lightTertiary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: LightModeColors.lightOnSurface,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: MyKOGColors.textSecondary,
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    inversePrimary: DarkModeColors.darkInversePrimary,
    shadow: DarkModeColors.darkShadow,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: MyKOGColors.primaryDark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.darkAppBarBackground,
    foregroundColor: DarkModeColors.darkOnPrimaryContainer,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: MyKOGColors.primaryDark,
    selectedItemColor: MyKOGColors.accent,
    unselectedItemColor: MyKOGColors.textSecondary,
    type: BottomNavigationBarType.fixed,
  ),
  textTheme: TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.bold,
      color: MyKOGColors.textPrimary,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.bold,
      color: MyKOGColors.textPrimary,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w600,
      color: MyKOGColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.poppins(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.bold,
      color: MyKOGColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
      color: MyKOGColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.bold,
      color: MyKOGColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
      color: MyKOGColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
      color: MyKOGColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
      color: MyKOGColors.textPrimary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      color: MyKOGColors.accent,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      color: MyKOGColors.accent,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      color: MyKOGColors.accent,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.normal,
      color: MyKOGColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.normal,
      color: MyKOGColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.normal,
      color: MyKOGColors.textSecondary,
    ),
  ),
);
