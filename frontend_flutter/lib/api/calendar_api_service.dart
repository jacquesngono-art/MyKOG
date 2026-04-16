import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/calendar_event.dart';
import '../config/api_config.dart';

class CalendarApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Utiliser la configuration centralisée
  static Future<String> get baseUrl async =>
      '${await ApiConfig.getBaseUrl()}/api/calendar';

  // Récupérer tous les événements
  Future<List<CalendarEvent>> getAllEvents() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception('Aucune connexion internet. Vérifiez votre connexion.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException: $e');
      throw Exception('La requête a expiré. Veuillez réessayer.');
    } catch (e) {
      debugPrint('Erreur getAllEvents: $e');
      throw Exception('Erreur lors du chargement des événements: $e');
    }
  }

  // Récupérer les événements pour une année spécifique
  Future<List<CalendarEvent>> getEventsByYear(int year) async {
    try {
      final url = '${await baseUrl}/year/$year';
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getEventsByYear: $e');
      throw Exception('Erreur lors du chargement des événements: $e');
    }
  }

  // Récupérer un événement par son ID
  Future<CalendarEvent?> getEventById(String id) async {
    try {
      final response =
          await http.get(Uri.parse('${await baseUrl}/$id')).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CalendarEvent.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getEventById: $e');
      return null;
    }
  }

  // Créer un événement (admin uniquement)
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final response = await http
          .post(
            Uri.parse(await baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(event.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CalendarEvent.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to create event');
      }
    } catch (e) {
      debugPrint('Erreur createEvent: $e');
      throw Exception('Erreur lors de la création de l\'événement: $e');
    }
  }

  // Mettre à jour un événement (admin uniquement)
  Future<CalendarEvent> updateEvent(String id, CalendarEvent event) async {
    try {
      final response = await http
          .put(
            Uri.parse('${await baseUrl}/$id'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(event.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return CalendarEvent.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update event');
      }
    } catch (e) {
      debugPrint('Erreur updateEvent: $e');
      throw Exception('Erreur lors de la mise à jour de l\'événement: $e');
    }
  }

  // Supprimer un événement (admin uniquement)
  Future<void> deleteEvent(String id) async {
    try {
      final response = await http
          .delete(Uri.parse('${await baseUrl}/$id'))
          .timeout(_timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete event');
      }
    } catch (e) {
      debugPrint('Erreur deleteEvent: $e');
      throw Exception('Erreur lors de la suppression de l\'événement: $e');
    }
  }
}

