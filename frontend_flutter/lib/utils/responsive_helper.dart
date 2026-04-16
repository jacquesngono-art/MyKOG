import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helper pour la responsivité de l'application
class ResponsiveHelper {
  /// Obtenir la largeur responsive
  static double width(double width) => width.w;
  
  /// Obtenir la hauteur responsive
  static double height(double height) => height.h;
  
  /// Obtenir la taille de police responsive
  static double fontSize(double size) => size.sp;
  
  /// Obtenir le rayon responsive
  static double radius(double radius) => radius.r;
  
  /// Obtenir l'espacement horizontal responsive
  static double horizontalSpacing(double spacing) => spacing.w;
  
  /// Obtenir l'espacement vertical responsive
  static double verticalSpacing(double spacing) => spacing.h;
  
  /// Obtenir le padding responsive
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all.w);
    }
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0).h,
      bottom: (bottom ?? vertical ?? 0).h,
      left: (left ?? horizontal ?? 0).w,
      right: (right ?? horizontal ?? 0).w,
    );
  }
  
  /// Obtenir le margin responsive
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all.w);
    }
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0).h,
      bottom: (bottom ?? vertical ?? 0).h,
      left: (left ?? horizontal ?? 0).w,
      right: (right ?? horizontal ?? 0).w,
    );
  }
  
  /// Obtenir le SizedBox responsive
  static SizedBox spacing({
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width?.w,
      height: height?.h,
    );
  }
  
  /// Vérifier si l'écran est petit (< 360px)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  /// Vérifier si l'écran est moyen (360-414px)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 414;
  }
  
  /// Vérifier si l'écran est grand (>= 414px)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 414;
  }
  
  /// Obtenir le nombre de colonnes selon la taille d'écran
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 2;
    if (width < 414) return 2;
    return 3;
  }
}

