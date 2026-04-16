import 'package:flutter/material.dart';
import 'package:MyKOG/screens/calendar_screen.dart';
import 'package:MyKOG/screens/teachings_screen.dart';
import 'package:MyKOG/screens/live_screen.dart';

/// Service global pour gérer la navigation depuis les notifications
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Naviguer vers un écran spécifique
  Future<void> navigateTo(String route, {Map<String, dynamic>? arguments}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('⚠️ NavigationService: Context is null');
      return;
    }

    try {
      switch (route) {
        case '/calendar':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          );
          break;
        case '/teaching':
          // Naviguer vers l'écran des enseignements
          // Si un ID est fourni, on pourrait ouvrir directement l'enseignement
          if (arguments?['id'] != null) {
            // TODO: Implémenter la navigation vers un enseignement spécifique
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeachingsScreen()),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeachingsScreen()),
            );
          }
          break;
        case '/live':
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LiveScreen()),
          );
          break;
        case '/home':
          // Retourner à l'écran d'accueil
          Navigator.of(context).popUntil((route) => route.isFirst);
          break;
        default:
          debugPrint('⚠️ Route inconnue: $route');
      }
    } catch (e) {
      debugPrint('❌ Erreur navigation: $e');
    }
  }

  /// Naviguer selon le type de notification
  Future<void> navigateFromNotification({
    required String type,
    String? id,
    Map<String, dynamic>? data,
  }) async {
    switch (type) {
      case 'calendar':
        await navigateTo('/calendar', arguments: {'id': id});
        break;
      case 'teaching':
        await navigateTo('/teaching', arguments: {'id': id, ...?data});
        break;
      case 'live':
        await navigateTo('/live', arguments: {'id': id, ...?data});
        break;
      case 'annonce':
        // Les annonces peuvent être affichées sur l'écran d'accueil
        await navigateTo('/home');
        break;
      default:
        debugPrint('⚠️ Type de notification inconnu: $type');
    }
  }
}

