import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/providers/language_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';

/// Écran de sélection de langue
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: MyKOGColors.primaryDark,
        foregroundColor: MyKOGColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MyKOGColors.primaryDark,
              MyKOGColors.secondary,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: MyKOGColors.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: MyKOGColors.accent.withOpacity(0.2),
                  width: 1.w,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.language,
                    color: MyKOGColors.accent,
                    size: 48.w,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    l10n.language,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Select your preferred language',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(),

            SizedBox(height: 24.h),

            // Liste des langues
            ...LanguageProvider.availableLanguages.values.map((lang) {
              final languageCode = lang['code']!;
              final isSelected = languageProvider.isLanguageActive(languageCode);

              return _buildLanguageTile(
                context: context,
                flag: lang['flag']!,
                languageName: lang['nativeName']!,
                englishName: lang['name']!,
                languageCode: languageCode,
                isSelected: isSelected,
                onTap: () => _changeLanguage(context, languageCode),
              ).animate(
                delay: (LanguageProvider.availableLanguages.keys.toList().indexOf(languageCode) * 100).ms,
              ).fadeIn().slideX();
            }).toList(),

            SizedBox(height: 24.h),

            // Note d'information
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: MyKOGColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: MyKOGColors.accent.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: MyKOGColors.accent,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'The app will restart with the selected language. Your settings and downloads will be preserved.',
                      style: TextStyle(
                        color: MyKOGColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String languageName,
    required String englishName,
    required String languageCode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected 
            ? MyKOGColors.accent.withOpacity(0.15)
            : MyKOGColors.secondary,
              borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected 
              ? MyKOGColors.accent
              : MyKOGColors.accent.withOpacity(0.2),
          width: isSelected ? 2.w : 1.w,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: MyKOGColors.accent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        leading: Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            color: isSelected 
                ? MyKOGColors.accent.withOpacity(0.2)
                : MyKOGColors.primaryDark.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              flag,
              style: TextStyle(fontSize: 28.sp),
            ),
          ),
        ),
        title: Text(
          languageName,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isSelected ? MyKOGColors.accent : MyKOGColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          englishName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: MyKOGColors.textSecondary,
          ),
        ),
        trailing: isSelected
            ? Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: MyKOGColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20.sp,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: MyKOGColors.textSecondary,
                size: 16.sp,
              ),
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, String languageCode) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentCode = languageProvider.currentLanguageCode;

    if (currentCode != languageCode) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: MyKOGColors.accent),
                SizedBox(height: 16.h),
                Text(
                  'Changing language...',
                  style: TextStyle(color: MyKOGColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );

      // Changer la langue
      await languageProvider.changeLanguage(languageCode);

      // Attendre un peu pour l'effet visuel
      await Future.delayed(const Duration(milliseconds: 500));

      // Fermer le dialog et retourner
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le dialog
        Navigator.of(context).pop(); // Retourner à l'écran précédent
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${LanguageProvider.availableLanguages[languageCode]?['nativeName']}'),
            backgroundColor: MyKOGColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

