import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NotificationApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Utiliser la configuration centralisée
  static Future<String> get baseUrl async =>
      '${await ApiConfig.getBaseUrl()}/api/notifications';

  // Enregistrer le token FCM d'un utilisateur
  Future<void> registerToken(String userId, String fcmToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('${await baseUrl}/tokens'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'fcmToken': fcmToken,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to register token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur registerToken: $e');
      // Ne pas throw pour ne pas bloquer l'app
    }
  }

  // Supprimer le token FCM d'un utilisateur
  Future<void> unregisterToken(String userId, String fcmToken) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${await baseUrl}/tokens'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'fcmToken': fcmToken,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to unregister token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur unregisterToken: $e');
    }
  }
}

