import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration de l'API - Backend VPS
class ApiConfig {
  // URL du backend déployé sur le VPS (production)
  static const String _serverUrl = 'http://185.98.128.123:3001/mykog-api';

  // Modes de connexion
  static const String modeUsb = 'usb'; // Câble USB (adb reverse)
  static const String modeWifi = 'wifi'; // Même WiFi
  static const String modeHotspotPhone =
      'hotspot_phone'; // Hotspot téléphone → ordinateur
  static const String modeHotspotComputer =
      'hotspot_computer'; // Hotspot ordinateur → téléphone
  static const String modeVps = 'vps'; // Backend hébergé sur le VPS

  // IPs par défaut selon le mode (seront détectées automatiquement)
  static const Map<String, String> defaultIPs = {
    modeUsb: 'localhost', // USB via adb reverse (localhost:3000)
    modeWifi: '192.168.1.195', // IP actuelle sur réseau WiFi
    modeHotspotPhone:
        '192.168.43.3', // IP de l'ordinateur quand connecté au hotspot du téléphone
    modeHotspotComputer:
        '192.168.137.1', // IP typique quand ordinateur crée hotspot
    modeVps: 'vps123057.serveur-vps.net', // Backend sur VPS (mode cloud)
  };

  // Port du serveur
  static const int port = 3000;

  // Endpoint public du backend MyKOG hébergé sur le VPS (Nginx → PM2 mykog-api)
  static const String vpsBaseUrl =
      'https://vps123057.serveur-vps.net/mykog-api';
  static const String vpsHost = 'vps123057.serveur-vps.net';

  // Mode de connexion actuel (détection automatique USB/WiFi)
  static String _currentMode = modeUsb; // Par défaut USB si détecté, sinon WiFi

  // IP de base actuelle
  static String? _currentIP;

  /// Obtenir l'URL de base de l'API - VPS uniquement (fallback local USB/dev)
  static Future<String> getBaseUrl() async {
    // Endpoint VPS MyKOG (backend hébergé)
    try {
      final vpsWorks = await _testQuickConnection(vpsBaseUrl);
      if (vpsWorks) {
        debugPrint('🌐 URL API (VPS): $vpsBaseUrl');
        return vpsBaseUrl;
      }
    } catch (e) {
      debugPrint('⚠️ VPS injoignable, fallback local');
    }

    // Fallback vers localhost (USB / dev)
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

  /// Détecter automatiquement le mode de connexion (USB, WiFi ou VPS)
  static Future<String> detectConnectionMode() async {
    try {
      // En premier, tester si le backend VPS est accessible
      final vpsTest = await testVpsConnection();
      if (vpsTest) {
        debugPrint('☁️ Mode VPS détecté (backend en ligne fonctionne)');
        return modeVps;
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

  /// Obtenir l'IP actuelle - UNIQUEMENT le VPS
  static Future<String> getCurrentIP() async {
    debugPrint('🔍 Configuration VPS uniquement...');
    
    // TOUJOURS utiliser le VPS
    _currentIP = vpsHost;
    _currentMode = modeVps;
    
    debugPrint('☁️ VPS forcé: $vpsHost');
    return vpsHost;
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

  /// Forcer le mode cloud (backend VPS, toujours utilisé maintenant)
  static Future<void> forceVpsMode() async {
    _currentIP = vpsHost;
    _currentMode = modeVps;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _currentIP!);
    await prefs.setString(_connectionModeKey, _currentMode);
    debugPrint('☁️ Mode VPS forcé (par défaut): $vpsHost');
  }

  /// Tester la connexion à l'API VPS (HTTPS)
  static Future<bool> testVpsConnection() async {
    try {
      const url = '$vpsBaseUrl/api/enseignements';
      debugPrint('🔍 Test connexion VPS vers: $url');

      final client = HttpClient();
      client.connectionTimeout =
          const Duration(seconds: 10); // Timeout plus long pour le VPS
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
        debugPrint('✅ Test connexion VPS: Status: $statusCode');
      } else {
        debugPrint(
            '⚠️ Test connexion VPS: Status: $statusCode (non valide)');
      }
      return isValid;
    } catch (e) {
      debugPrint('❌ Test connexion VPS échoué: $e');
      return false;
    }
  }

  /// Obtenir le mode de connexion actuel
  static String getCurrentMode() => modeVps;

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

    if (_currentMode == modeVps) {
      // Mode cloud : retourner directement l'hôte du VPS
      debugPrint('✅ Mode VPS: utilisation de $vpsHost');
      await setIP(vpsHost, mode: modeVps);
      return vpsHost;
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

  /// Initialiser l'API pour utiliser le VPS uniquement
  static Future<void> initializeVpsOnly() async {
    debugPrint('🚀 Initialisation API VPS uniquement...');
    await forceVpsMode();
    debugPrint('✅ API configurée pour le VPS uniquement');
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