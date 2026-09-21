import 'package:MyKOG/services/hive_storage_service.dart';

class FirstLaunchService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyRegistrationCompleted = 'registration_completed';

  /// Vérifier si l'onboarding a été complété
  static Future<bool> isOnboardingCompleted() async {
    return HiveStorageService.getBool(_keyOnboardingCompleted);
  }

  /// Marquer l'onboarding comme complété
  static Future<void> setOnboardingCompleted() async {
    await HiveStorageService.storeBool(_keyOnboardingCompleted, true);
  }

  /// Vérifier si l'inscription a été complétée
  static Future<bool> isRegistrationCompleted() async {
    return HiveStorageService.getBool(_keyRegistrationCompleted);
  }

  /// Marquer l'inscription comme complétée
  static Future<void> setRegistrationCompleted() async {
    await HiveStorageService.storeBool(_keyRegistrationCompleted, true);
  }

  /// Réinitialiser tout (pour les tests ou déconnexion)
  static Future<void> reset() async {
    await HiveStorageService.delete(_keyOnboardingCompleted);
    await HiveStorageService.delete(_keyRegistrationCompleted);
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