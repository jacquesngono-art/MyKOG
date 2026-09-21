import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration de l'API - Backend VPS
class ApiConfig {
  // URL du backend déployé sur le VPS (production)
  static const String _serverUrl = 'http://185.98.128.123:3001/mykog-api';

  // Mode unique
  static const String modeVps = 'vps';

  /// Obtenir l'URL de base de l'API
  static Future<String> getBaseUrl() async {
    return _serverUrl;
  }

  /// Obtenir l'URL de base (synchrone)
  static String getBaseUrlSync() {
    return _serverUrl;
  }

  /// Tester la connexion au backend VPS
  static Future<bool> testConnection({String? ip}) async {
    try {
      const url = '$_serverUrl/api/enseignements';
      debugPrint('🔍 Test connexion serveur vers: $url');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      client.idleTimeout = const Duration(seconds: 10);

      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final statusCode = response.statusCode;
      client.close();

      final isValid = statusCode == 200 || statusCode == 404;
      if (isValid) {
        debugPrint('✅ Connexion serveur OK: Status $statusCode');
      } else {
        debugPrint('⚠️ Connexion serveur: Status $statusCode');
      }
      return isValid;
    } catch (e) {
      debugPrint('❌ Connexion serveur échouée: $e');
      return false;
    }
  }

  /// Obtenir le mode de connexion actuel
  static String getCurrentMode() => modeVps;

  /// Obtenir l'IP/host actuel
  static Future<String> getCurrentIP() async {
    return '185.98.128.123';
  }

  /// Obtenir toutes les informations de connexion
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    final isConnected = await testConnection();

    return {
      'ip': '185.98.128.123',
      'port': 3001,
      'baseUrl': _serverUrl,
      'mode': modeVps,
      'isConnected': isConnected,
      'hasCustomIP': false,
    };
  }

  /// Initialiser l'API (VPS par défaut, rien à faire)
  static Future<void> initializeRenderOnly() async {
    debugPrint('🚀 API initialisée: $_serverUrl');
  }

  /// Compatibilité - setConnectionMode (no-op, toujours VPS)
  static Future<void> setConnectionMode(String mode) async {
    debugPrint('ℹ️ Mode fixe serveur: $_serverUrl');
  }

  /// Compatibilité - forceReset
  static Future<void> forceReset() async {
    debugPrint('🔄 Reset - serveur: $_serverUrl');
  }

  /// Compatibilité - forceRenderMode (redirige vers le serveur VPS)
  static Future<void> forceRenderMode() async {
    debugPrint('🚀 Mode serveur actif: $_serverUrl');
  }

  /// Compatibilité - testRenderConnection (redirige vers le serveur VPS)
  static Future<bool> testRenderConnection() async {
    return await testConnection();
  }
}