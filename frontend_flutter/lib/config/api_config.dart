import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration de l'API avec détection automatique de l'IP
class ApiConfig {
  // Clés de stockage
  static const String _ipKey = 'api_base_ip';
  static const String _connectionModeKey = 'connection_mode';

  // Modes de connexion
  static const String modeUsb = 'usb'; // Câble USB (adb reverse)
  static const String modeWifi = 'wifi'; // Même WiFi
  static const String modeHotspotPhone =
      'hotspot_phone'; // Hotspot téléphone → ordinateur
  static const String modeHotspotComputer =
      'hotspot_computer'; // Hotspot ordinateur → téléphone
  static const String modeRender = 'render'; // Backend hébergé sur Render

  // IPs par défaut selon le mode (seront détectées automatiquement)
  static const Map<String, String> defaultIPs = {
    modeUsb: 'localhost', // USB via adb reverse (localhost:3000)
    modeWifi: '192.168.1.195', // IP actuelle sur réseau WiFi
    modeHotspotPhone:
        '192.168.43.3', // IP de l'ordinateur quand connecté au hotspot du téléphone
    modeHotspotComputer:
        '192.168.137.1', // IP typique quand ordinateur crée hotspot
    modeRender: 'mykog-backend-api.onrender.com', // Backend sur Render
  };

  // Port du serveur
  static const int port = 3000;

  // Mode de connexion actuel (détection automatique USB/WiFi)
  static String _currentMode = modeUsb; // Par défaut USB si détecté, sinon WiFi

  // IP de base actuelle
  static String? _currentIP;

  /// Obtenir l'URL de base de l'API - Render ou Local (fallback)
  static Future<String> getBaseUrl() async {
    // Essayer Render d'abord
    const renderUrl = 'https://mykog-backend-api.onrender.com';
    
    // Test rapide de Render (timeout court)
    try {
      final renderWorks = await _testQuickConnection(renderUrl);
      if (renderWorks) {
        debugPrint('🌐 URL API (Render): $renderUrl');
        return renderUrl;
      }
    } catch (e) {
      debugPrint('⚠️ Render endormi, fallback local');
    }
    
    // Fallback vers localhost
    const localUrl = 'http://localhost:3000';
    debugPrint('🌐 URL API (Local fallback): $localUrl');
    return localUrl;
  }

  /// Test rapide de connexion (timeout très court)
  static Future<bool> _testQuickConnection(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      client.idleTimeout = const Duration(seconds: 3);
      
      final request = await client.getUrl(Uri.parse('$url/api/enseignements'))
          .timeout(const Duration(seconds: 3));
      final response = await request.close().timeout(const Duration(seconds: 3));
      client.close();
      
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
    }
  }

  /// Détecter automatiquement le mode de connexion (USB, WiFi ou Render)
  static Future<String> detectConnectionMode() async {
    try {
      // En premier, tester si Render est accessible
      final renderTest = await testRenderConnection();
      if (renderTest) {
        debugPrint('☁️ Mode Render détecté (backend en ligne fonctionne)');
        return modeRender;
      }

      // Tester d'abord si localhost fonctionne (USB avec adb reverse)
      final usbTest = await testConnection(ip: 'localhost');
      if (usbTest) {
        debugPrint('🔌 Mode USB détecté (localhost fonctionne)');
        return modeUsb;
      }

      // Si localhost ne fonctionne pas, essayer 127.0.0.1
      final localhostTest = await testConnection(ip: '127.0.0.1');
      if (localhostTest) {
        debugPrint('🔌 Mode USB détecté (127.0.0.1 fonctionne)');
        return modeUsb;
      }

      // Sinon, mode WiFi
      debugPrint('📶 Mode WiFi détecté (localhost non disponible)');
      return modeWifi;
    } catch (e) {
      debugPrint('⚠️ Erreur détection mode: $e, utilisation WiFi par défaut');
      return modeWifi;
    }
  }

  /// Obtenir l'IP actuelle - UNQUEMENT Render
  static Future<String> getCurrentIP() async {
    debugPrint('🔍 Configuration Render uniquement...');
    
    // TOUJOURS utiliser Render
    const renderIP = 'mykog-backend-api.onrender.com';
    _currentIP = renderIP;
    _currentMode = modeRender;
    
    debugPrint('☁️ Render forcé: $renderIP');
    return renderIP;
  }

  /// Définir l'IP manuellement
  static Future<void> setIP(String ip, {String? mode}) async {
    _currentIP = ip;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    if (mode != null) {
      _currentMode = mode;
      await prefs.setString(_connectionModeKey, mode);
    }
    debugPrint('✅ IP API mise à jour: $ip (mode: ${mode ?? _currentMode})');
  }

  /// Obtenir le mode de connexion actuel
  static String getCurrentMode() => _currentMode;

  /// Définir le mode de connexion
  static Future<void> setConnectionMode(String mode) async {
    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_connectionModeKey, mode);

    // Utiliser l'IP par défaut du mode si aucune IP n'est sauvegardée
    if (_currentIP == null || !await hasCustomIP()) {
      _currentIP = defaultIPs[mode] ?? defaultIPs[modeWifi]!;
      await setIP(_currentIP!, mode: mode);
    }

    debugPrint('✅ Mode de connexion mis à jour: $mode');
  }

  /// Vérifier si une IP personnalisée est sauvegardée
  static Future<bool> hasCustomIP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_ipKey);
  }

  /// Réinitialiser l'IP (utiliser la détection automatique)
  static Future<void> resetIP() async {
    _currentIP = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ipKey);
    await prefs.remove(_connectionModeKey);
    debugPrint('🔄 IP réinitialisée, utilisation de l\'IP par défaut');
  }

  /// Réinitialiser complètement le cache (force)
  static Future<void> forceReset() async {
    _currentIP = null;
    // Détecter automatiquement le mode
    _currentMode = await detectConnectionMode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ipKey);
    await prefs.remove(_connectionModeKey);
    // Utiliser la nouvelle IP par défaut selon le mode détecté
    _currentIP = defaultIPs[_currentMode] ?? defaultIPs[modeUsb]!;
    await prefs.setString(_ipKey, _currentIP!);
    await prefs.setString(_connectionModeKey, _currentMode);
    debugPrint(
        '🔄 Cache complètement réinitialisé, IP forcée: $_currentIP (mode: $_currentMode)');
  }

  /// Forcer le mode Render (toujours utilisé maintenant)
  static Future<void> forceRenderMode() async {
    _currentIP = 'mykog-backend-api.onrender.com';
    _currentMode = modeRender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _currentIP!);
    await prefs.setString(_connectionModeKey, _currentMode);
    debugPrint('☁️ Mode Render forcé (par défaut): mykog-backend-api.onrender.com');
  }

  /// Tester la connexion à l'API Render (HTTPS)
  static Future<bool> testRenderConnection() async {
    try {
      const url = 'https://mykog-backend-api.onrender.com/api/enseignements';
      debugPrint('🔍 Test connexion Render vers: $url');

      final client = HttpClient();
      client.connectionTimeout =
          const Duration(seconds: 10); // Timeout plus long pour Render
      client.idleTimeout = const Duration(seconds: 10);

      final request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      final response =
          await request.close().timeout(const Duration(seconds: 10));
      final statusCode = response.statusCode;
      client.close();

      // Accepter 200 (OK) ou 404 (route existe mais pas de données)
      final isValid = statusCode == 200 || statusCode == 404;
      if (isValid) {
        debugPrint('✅ Test connexion Render: Status: $statusCode');
      } else {
        debugPrint(
            '⚠️ Test connexion Render: Status: $statusCode (non valide)');
      }
      return isValid;
    } catch (e) {
      debugPrint('❌ Test connexion Render échoué: $e');
      return false;
    }
  }

  /// Tester la connexion à l'API locale (HTTP)
  static Future<bool> testConnection({String? ip}) async {
    try {
      final testIP = ip ?? await getCurrentIP();
      final url = 'http://$testIP:$port/api/enseignements';
      debugPrint('🔍 Test connexion vers: $url');

      final client = HttpClient();
      // Timeout plus court pour USB (localhost est rapide), plus long pour WiFi
      final timeout = (testIP == 'localhost' || testIP == '127.0.0.1')
          ? const Duration(seconds: 2)
          : const Duration(seconds: 5);
      client.connectionTimeout = timeout;
      client.idleTimeout = timeout;

      // Tester sur /api/enseignements pour être sûr que c'est le bon serveur
      final request = await client.getUrl(Uri.parse(url)).timeout(timeout);

      final response = await request.close().timeout(timeout);
      final statusCode = response.statusCode;
      client.close();

      // Accepter 200 (OK) ou 404 (route existe mais pas de données)
      final isValid = statusCode == 200 || statusCode == 404;
      if (isValid) {
        debugPrint('✅ Test connexion: $testIP:$port -> Status: $statusCode');
      } else {
        debugPrint(
            '⚠️ Test connexion: $testIP:$port -> Status: $statusCode (non valide)');
      }
      return isValid;
    } catch (e) {
      // Logger toutes les erreurs pour debug (y compris timeout)
      // Ne pas logger les erreurs de connexion pour localhost si c'est normal (pas d'adb reverse)
      if (ip == 'localhost' || ip == '127.0.0.1') {
        debugPrint(
            '⚠️ localhost non accessible (adb reverse non configuré?): $e');
      } else {
        debugPrint('❌ Test connexion échoué ($ip): $e');
      }
      return false;
    }
  }

  /// Détecter automatiquement l'IP (version simplifiée - seulement IPs prioritaires)
  static Future<String?> detectIP({String? forceMode}) async {
    debugPrint('🔍 Détection automatique de l\'IP (mode rapide)...');

    // Si un mode est forcé, l'utiliser directement
    if (forceMode != null) {
      _currentMode = forceMode;
    } else {
      final detectedMode = await detectConnectionMode();
      _currentMode = detectedMode;
    }

    if (_currentMode == modeRender) {
      // Mode Render : retourner directement l'URL de Render
      debugPrint(
          '✅ Mode Render: utilisation de mykog-backend-api.onrender.com');
      await setIP('mykog-backend-api.onrender.com', mode: modeRender);
      return 'mykog-backend-api.onrender.com';
    }

    if (_currentMode == modeUsb) {
      // Mode USB : tester seulement localhost et 127.0.0.1
      for (final ip in ['localhost', '127.0.0.1']) {
        if (await testConnection(ip: ip)) {
          debugPrint('✅ IP USB détectée: $ip');
          await setIP(ip, mode: modeUsb);
          return ip;
        }
      }
      return null;
    }

    // Mode WiFi : tester seulement les IPs prioritaires (pas de scan complet)
    final priorityIPs = [
      '192.168.1.195', // IP actuelle (priorité absolue)
      '192.168.1.1', // Gateway commune
      '192.168.0.1', // Gateway autre réseau
      '192.168.100.6', // Ancienne IP WiFi
      '192.168.43.145', // Ancienne IP WiFi
      '192.168.1.76', // IP mentionnée
      '192.168.43.1', // Hotspot téléphone (gateway)
    ];

    debugPrint('📋 Test de ${priorityIPs.length} IPs prioritaires...');

    for (final ip in priorityIPs) {
      if (await testConnection(ip: ip)) {
        debugPrint('✅ IP détectée: $ip');
        await setIP(ip, mode: _currentMode);
        return ip;
      }
    }

    debugPrint('⚠️ Aucune IP détectée dans les IPs prioritaires');
    return null;
  }

  /// Initialiser l'API pour utiliser Render uniquement
  static Future<void> initializeRenderOnly() async {
    debugPrint('🚀 Initialisation API Render uniquement...');
    await forceRenderMode();
    debugPrint('✅ API configurée pour Render uniquement');
  }

  /// Obtenir toutes les informations de connexion
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    final ip = await getCurrentIP();
    final isConnected = await testConnection();

    return {
      'ip': ip,
      'port': port,
      'baseUrl': await getBaseUrl(),
      'mode': _currentMode,
      'isConnected': isConnected,
      'hasCustomIP': await hasCustomIP(),
    };
  }
}
