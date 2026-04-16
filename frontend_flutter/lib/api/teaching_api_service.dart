import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/teaching.dart';
import '../config/api_config.dart';

class TeachingApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Utiliser la configuration centralisée (async)
  static Future<String> get baseUrl async => '${await ApiConfig.getBaseUrl()}/api/enseignements';

  // Méthode pour récupérer tous les enseignements
  Future<List<Teaching>> getAllTeachings() async {
    try {
      final url = await baseUrl;
      final response = await http
          .get(Uri.parse(url))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Teaching.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load teachings: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception('Aucune connexion internet. Vérifiez votre connexion.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException: $e');
      throw Exception('La requête a expiré. Veuillez réessayer.');
    } catch (e) {
      debugPrint('Erreur getAllTeachings: $e');
      throw Exception('Erreur lors du chargement des enseignements: $e');
    }
  }

  // Méthode pour récupérer un enseignement par son ID
  Future<Teaching?> getTeachingById(String id) async {
    try {
      final response = await http
          .get(Uri.parse('${await baseUrl}/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Teaching.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load teaching: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getTeachingById: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getTeachingById: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur getTeachingById: $e');
      throw Exception('Erreur lors du chargement de l\'enseignement: $e');
    }
  }

  // Méthode pour récupérer les enseignements featured
  Future<List<Teaching>> getFeaturedTeachings() async {
    try {
      final allTeachings = await getAllTeachings();
      return allTeachings.where((t) => t.isFeatured).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des enseignements featured: $e');
    }
  }

  // Méthode pour récupérer les nouveaux enseignements
  Future<List<Teaching>> getNewTeachings() async {
    try {
      final allTeachings = await getAllTeachings();
      return allTeachings.where((t) => t.isNew).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des nouveaux enseignements: $e');
    }
  }

  // Méthode pour récupérer les enseignements populaires
  Future<List<Teaching>> getPopularTeachings({int limit = 10}) async {
    try {
      final allTeachings = await getAllTeachings();
      allTeachings.sort((a, b) => b.playCount.compareTo(a.playCount));
      return allTeachings.take(limit).toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des enseignements populaires: $e');
    }
  }

  // Méthode pour récupérer les enseignements par type de culte
  Future<List<Teaching>> getTeachingsByTypeCulte(String typeCulte) async {
    try {
      final allTeachings = await getAllTeachings();
      return allTeachings
          .where((t) =>
            (t.typeCulte?.toLowerCase() ?? '').contains(typeCulte.toLowerCase())
          )
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des enseignements par type: $e');
    }
  }

  // Méthode pour rechercher des enseignements
  Future<List<Teaching>> searchTeachings(String query) async {
    if (query.trim().isEmpty) return await getAllTeachings();

    try {
      final allTeachings = await getAllTeachings();
      final lowerQuery = query.toLowerCase();

      return allTeachings
          .where((t) =>
            t.title.toLowerCase().contains(lowerQuery) ||
            t.speaker.toLowerCase().contains(lowerQuery) ||
            (t.typeCulte?.toLowerCase() ?? '').contains(lowerQuery) ||
            (t.description?.toLowerCase() ?? '').contains(lowerQuery) ||
            t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
          )
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Méthode pour récupérer tous les types de culte disponibles
  Future<List<String>> getAvailableTypeCulte() async {
    try {
      final allTeachings = await getAllTeachings();
      final typeCulteSet = allTeachings
          .where((t) => t.typeCulte != null && t.typeCulte!.isNotEmpty)
          .map((t) => t.typeCulte!)
          .toSet()
          .toList();

      typeCulteSet.sort();
      return typeCulteSet;
    } catch (e) {
      throw Exception('Erreur lors du chargement des types de culte: $e');
    }
  }

  // Méthode pour incrémenter le compteur de lecture
  Future<bool> incrementPlayCount(String teachingId) async {
    try {
      // Note: Cette méthode nécessiterait un endpoint PUT dans le backend
      // Pour le moment, nous allons simplement simuler l'incrémentation
      // Le backend devrait avoir un endpoint: PUT /api/enseignements/:id/playcount
      // Incrémenter le compteur de lecture pour l\'enseignement: $teachingId
      return true;
    } catch (e) {
      // Erreur lors de l\'incrémentation du compteur: $e
      return false;
    }
  }

  // Méthode pour obtenir les enseignements par mois/année
  Future<List<Teaching>> getTeachingsByMonthYear(int mois, int annee) async {
    try {
      final allTeachings = await getAllTeachings();
      return allTeachings
          .where((t) =>
            (t.moisSafe == mois.toString()) &&
            (t.anneeSafe == annee.toString())
          )
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des enseignements par date: $e');
    }
  }

  // Méthode pour supprimer un enseignement
  Future<bool> deleteTeaching(String teachingId) async {
    try {
      final url = await baseUrl;
      final response = await http
          .delete(Uri.parse('$url/$teachingId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('✅ Enseignement supprimé avec succès: $teachingId');
        return true;
      } else {
        throw Exception('Failed to delete teaching: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException deleteTeaching: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException deleteTeaching: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur deleteTeaching: $e');
      throw Exception('Erreur lors de la suppression de l\'enseignement: $e');
    }
  }
}