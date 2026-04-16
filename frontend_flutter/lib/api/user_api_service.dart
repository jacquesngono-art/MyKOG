import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config/api_config.dart';

class UserApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Utiliser la configuration centralisée
  static Future<String> get baseUrl async =>
      '${await ApiConfig.getBaseUrl()}/api/users';

  // Créer ou mettre à jour un utilisateur
  Future<User> createOrUpdateUser(User user) async {
    try {
      final url = await baseUrl;
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(user.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to save user');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception('Aucune connexion internet. Vérifiez votre connexion.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException: $e');
      throw Exception('La requête a expiré. Veuillez réessayer.');
    } catch (e) {
      debugPrint('Erreur createOrUpdateUser: $e');
      throw Exception('Erreur lors de la sauvegarde de l\'utilisateur: $e');
    }
  }

  // Récupérer un utilisateur par son ID
  Future<User?> getUserById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('${await baseUrl}/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getUserById: $e');
      return null;
    }
  }
}

