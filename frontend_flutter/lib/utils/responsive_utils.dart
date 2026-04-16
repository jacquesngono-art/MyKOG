import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveUtils {
  // Espacements responsive
  static double spacingTiny = 4.h;
  static double spacingSmall = 8.h;
  static double spacingMedium = 16.h;
  static double spacingLarge = 24.h;
  static double spacingExtraLarge = 32.h;

  // Padding responsive
  static double paddingSmall = 12.h;
  static double paddingMedium = 16.h;
  static double paddingLarge = 24.h;
  static double paddingExtraLarge = 32.h;

  // Rayons d'arrondi
  static double borderRadiusSmall = 8.h;
  static double borderRadiusMedium = 12.h;
  static double borderRadiusLarge = 16.h;
  static double borderRadiusExtraLarge = 24.h;
  static double borderRadiusRound = 999.h;

  // Hauteurs de widget
  static double heightAppBar = 56.h;
  static double heightBottomBar = 60.h;
  static double heightMiniPlayer = 72.h;
  static double heightButton = 48.h;

  // Largeurs de widget
  static double widthButton = 120.w;
  static double widthIcon = 24.w;
  static double widthAvatar = 40.w;
  static double widthAvatarLarge = 80.w;

  // Text sizes responsive
  static double textSizeXs = 10.sp;
  static double textSizeSm = 12.sp;
  static double textSizeMd = 14.sp;
  static double textSizeLg = 16.sp;
  static double textSizeXl = 18.sp;
  static double textSize2xl = 20.sp;
  static double textSize3xl = 24.sp;
  static double textSize4xl = 28.sp;
  static double textSize5xl = 32.sp;

  // Icon sizes
  static double iconSizeSm = 16.w;
  static double iconSizeMd = 24.w;
  static double iconSizeLg = 32.w;
  static double iconSizeXl = 48.w;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Breakpoints pour détecter la taille de l'écran
  static bool get isMobile => ScreenUtil().screenWidth <= 360;
  static bool get isSmallMobile => ScreenUtil().screenWidth <= 320;
  static bool get isTablet => ScreenUtil().screenWidth >= 768;
  static bool get isDesktop => ScreenUtil().screenWidth >= 1024;

  // Facteur de scaling pour les écrans très petits
  static double get scaleFactor {
    if (isSmallMobile) return 0.85;
    if (isMobile) return 0.9;
    if (isTablet) return 1.1;
    if (isDesktop) return 1.2;
    return 1.0;
  }

  // Méthodes utilitaires
  static EdgeInsetsGeometry paddingAll([double value = 16]) => EdgeInsets.all(value.h);
  static EdgeInsetsGeometry paddingSymmetric({double vertical = 16, double horizontal = 16}) =>
      EdgeInsets.symmetric(vertical: vertical.h, horizontal: horizontal.w);
  static EdgeInsetsGeometry paddingOnly({double left = 0, double top = 0, double right = 0, double bottom = 0}) =>
      EdgeInsets.only(left: left.w, top: top.h, right: right.w, bottom: bottom.h);
}