import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/theme.dart';

class ModernListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? leadingText;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Widget? leadingWidget;
  final List<Widget>? badges;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool showArrow;

  const ModernListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingText,
    this.leadingIcon,
    this.trailingIcon,
    this.leadingWidget,
    this.badges,
    this.onTap,
    this.accentColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? MyKOGColors.accent;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Leading section
                _buildLeadingSection(color),
                SizedBox(width: 16.w),
                
                // Content section
                Expanded(
                  child: _buildContentSection(theme, color),
                ),
                
                // Trailing section
                _buildTrailingSection(color),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (title.length * 5).ms)
        .slideX(begin: 0.05, curve: Curves.easeOutCubic)
        .fadeIn(curve: Curves.easeOutCubic);
  }

  Widget _buildLeadingSection(Color color) {
    if (leadingWidget != null) {
      return leadingWidget!;
    }
    
    if (leadingIcon != null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Icon(
          leadingIcon,
          color: color,
          size: 24.w,
        ),
      );
    }
    
    if (leadingText != null) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Center(
          child: Text(
            leadingText!,
            style: TextStyle(
              color: color,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildContentSection(ThemeData theme, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with badges
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: MyKOGColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badges != null) ...badges!,
          ],
        ),
        
        // Subtitle
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyKOGColors.textSecondary,
              fontSize: 13.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailingSection(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailingIcon != null)
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              trailingIcon,
              color: color,
              size: 20.w,
            ),
          ),
        
        if (showArrow) ...[
          if (trailingIcon != null) SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: MyKOGColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.6),
              size: 20.w,
            ),
          ),
        ],
      ],
    );
  }
}

// Widget spécialisé pour les éléments avec icône circulaire
class ModernIconListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showArrow;

  const ModernIconListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernListTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      accentColor: iconColor,
      onTap: onTap,
      trailing: trailing,
      showArrow: showArrow,
    );
  }
}

// Widget spécialisé pour les éléments avec texte en badge
class ModernBadgeListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ModernBadgeListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.badgeText,
    this.badgeColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ModernListTile(
      title: title,
      subtitle: subtitle,
      leadingText: badgeText,
      accentColor: badgeColor,
      onTap: onTap,
      trailing: trailing,
    );
  }
}
