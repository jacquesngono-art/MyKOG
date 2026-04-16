import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MyKOGColors.secondary.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MyKOGColors.accent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.language,
                    color: MyKOGColors.accent,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.language,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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

            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

            // Note d'information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MyKOGColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MyKOGColors.accent.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: MyKOGColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The app will restart with the selected language. Your settings and downloads will be preserved.',
                      style: TextStyle(
                        color: MyKOGColors.textSecondary,
                        fontSize: 13,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? MyKOGColors.accent.withOpacity(0.15)
            : MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? MyKOGColors.accent
              : MyKOGColors.accent.withOpacity(0.2),
          width: isSelected ? 2 : 1,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected 
                ? MyKOGColors.accent.withOpacity(0.2)
                : MyKOGColors.primaryDark.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              flag,
              style: const TextStyle(fontSize: 28),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MyKOGColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              )
            : Icon(
                Icons.arrow_forward_ios,
                color: MyKOGColors.textSecondary,
                size: 16,
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MyKOGColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: MyKOGColors.accent),
                const SizedBox(height: 16),
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

