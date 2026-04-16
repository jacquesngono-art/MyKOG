import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyRegistrationCompleted = 'registration_completed';

  /// Vérifier si l'onboarding a été complété
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Marquer l'onboarding comme complété
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// Vérifier si l'inscription a été complétée
  static Future<bool> isRegistrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRegistrationCompleted) ?? false;
  }

  /// Marquer l'inscription comme complétée
  static Future<void> setRegistrationCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRegistrationCompleted, true);
  }

  /// Réinitialiser tout (pour les tests ou déconnexion)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyRegistrationCompleted);
  }

  /// Vérifier si l'utilisateur doit voir l'onboarding
  static Future<bool> shouldShowOnboarding() async {
    return !(await isOnboardingCompleted());
  }

  /// Vérifier si l'utilisateur doit voir l'inscription
  static Future<bool> shouldShowRegistration() async {
    final onboardingDone = await isOnboardingCompleted();
    final registrationDone = await isRegistrationCompleted();
    return onboardingDone && !registrationDone;
  }
}

