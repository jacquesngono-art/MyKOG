import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:MyKOG/theme_responsive.dart';
import 'package:MyKOG/utils/responsive_utils.dart';

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final double? height;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? ResponsiveUtils.widthButton;
    final buttonHeight = height ?? ResponsiveUtils.heightButton;

    return SizedBox(
      width: ResponsiveUtils.isTablet || ResponsiveUtils.isDesktop
          ? buttonWidth * 1.2
          : buttonWidth,
      height: ResponsiveUtils.isTablet || ResponsiveUtils.isDesktop
          ? buttonHeight * 1.1
          : buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? MyKOGColors.accent : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : MyKOGColors.accent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: MyKOGColors.accent, width: 1.w),
          ),
          padding: ResponsiveUtils.paddingSymmetric(
            vertical: ResponsiveUtils.spacingSmall,
            horizontal: ResponsiveUtils.spacingMedium,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: ResponsiveUtils.iconSizeMd,
                height: ResponsiveUtils.iconSizeMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : MyKOGColors.accent,
                  ),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: ResponsiveUtils.textSizeMd * ResponsiveUtils.scaleFactor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}

class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final bool isPrimary;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? ResponsiveUtils.iconSizeMd;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
        child: Container(
          width: iconSize * (ResponsiveUtils.isTablet || ResponsiveUtils.isDesktop ? 1.2 : 1.0),
          height: iconSize * (ResponsiveUtils.isTablet || ResponsiveUtils.isDesktop ? 1.2 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
            color: isPrimary
                ? MyKOGColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: iconSize * ResponsiveUtils.scaleFactor,
            color: color ?? (isPrimary ? MyKOGColors.accent : MyKOGColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: (style?.fontSize ?? ResponsiveUtils.textSizeMd) * ResponsiveUtils.scaleFactor,
      ) ??
          GoogleFonts.inter(
            fontSize: ResponsiveUtils.textSizeMd * ResponsiveUtils.scaleFactor,
            fontWeight: FontWeight.normal,
            color: MyKOGColors.textPrimary,
          ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}