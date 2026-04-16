import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:MyKOG/services/storage_service.dart';

/// Provider pour gérer le changement de langue
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  Locale _locale = const Locale('fr', 'FR'); // Français par défaut

  Locale get locale => _locale;

  /// Langues disponibles avec leurs noms
  static const Map<String, Map<String, String>> availableLanguages = {
    'fr': {
      'code': 'fr',
      'countryCode': 'FR',
      'name': 'Français',
      'nativeName': 'Français',
      'flag': '🇫🇷',
    },
    'en': {
      'code': 'en',
      'countryCode': 'US',
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
    },
    'de': {
      'code': 'de',
      'countryCode': 'DE',
      'name': 'German',
      'nativeName': 'Deutsch',
      'flag': '🇩🇪',
    },
    'es': {
      'code': 'es',
      'countryCode': 'ES',
      'name': 'Spanish',
      'nativeName': 'Español',
      'flag': '🇪🇸',
    },
  };

  LanguageProvider() {
    // Ne pas charger ici, attendre l'initialisation de StorageService
    _loadSavedLanguageSafely();
  }

  /// Charger la langue sauvegardée de manière sécurisée
  Future<void> _loadSavedLanguageSafely() async {
    try {
      final savedLanguage = StorageService.getString(_languageKey);
      if (savedLanguage != null && availableLanguages.containsKey(savedLanguage)) {
        final langData = availableLanguages[savedLanguage]!;
        _locale = Locale(langData['code']!, langData['countryCode']!);
        notifyListeners();
      }
    } catch (e) {
      // StorageService pas encore initialisé, utiliser la langue par défaut
      debugPrint('LanguageProvider: Utilisation langue par défaut (StorageService non init)');
    }
  }

  /// Changer la langue
  Future<void> changeLanguage(String languageCode) async {
    if (availableLanguages.containsKey(languageCode)) {
      final langData = availableLanguages[languageCode]!;
      _locale = Locale(langData['code']!, langData['countryCode']!);
      
      // Sauvegarder la préférence
      await StorageService.storeString(_languageKey, languageCode);
      
      notifyListeners();
    }
  }

  /// Obtenir le code de langue actuel
  String get currentLanguageCode => _locale.languageCode;

  /// Obtenir le nom de la langue actuelle
  String get currentLanguageName {
    return availableLanguages[currentLanguageCode]?['nativeName'] ?? 'Français';
  }

  /// Obtenir le drapeau de la langue actuelle
  String get currentLanguageFlag {
    return availableLanguages[currentLanguageCode]?['flag'] ?? '🇫🇷';
  }

  /// Vérifier si une langue est active
  bool isLanguageActive(String languageCode) {
    return currentLanguageCode == languageCode;
  }

  /// Obtenir toutes les langues disponibles
  List<Map<String, String>> getAllLanguages() {
    return availableLanguages.values.toList();
  }
}

