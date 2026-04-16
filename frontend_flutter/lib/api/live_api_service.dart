import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/live_stream.dart';
import '../config/api_config.dart';

class LiveApiService {
  static const Duration _timeout = Duration(seconds: 30);

  // Utiliser la configuration centralisée (async)
  static Future<String> get baseUrl async =>
      '${await ApiConfig.getBaseUrl()}/api/lives';

  /// Récupérer tous les live streams
  Future<List<LiveStream>> getAllLiveStreams() async {
    try {
      final url = await baseUrl;
      final response = await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LiveStream.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load live streams: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getAllLiveStreams: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getAllLiveStreams: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur getAllLiveStreams: $e');
      throw Exception('Erreur lors du chargement des lives: $e');
    }
  }

  /// Récupérer un live stream par ID
  Future<LiveStream?> getLiveStreamById(String id) async {
    try {
      final response =
          await http.get(Uri.parse('${await baseUrl}/$id')).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return LiveStream.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load live stream: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur getLiveStreamById: $e');
      return null;
    }
  }

  /// Récupérer le live actif (le plus récent avec status = 'live')
  Future<LiveStream?> getActiveLive() async {
    try {
      final url = await baseUrl;
      final response =
          await http.get(Uri.parse('$url/active')).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return LiveStream.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('ℹ️ Aucun live actif');
        return null;
      } else {
        throw Exception('Failed to load active live: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getActiveLive: $e');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getActiveLive: $e');
      return null;
    } catch (e) {
      debugPrint('Erreur getActiveLive: $e');
      return null;
    }
  }

  /// Récupérer les live streams actuellement en direct
  Future<List<LiveStream>> getLiveNowStreams() async {
    try {
      final allStreams = await getAllLiveStreams();
      return allStreams
          .where((stream) => stream.status == LiveStreamStatus.live)
          .toList();
    } catch (e) {
      debugPrint('Erreur getLiveNowStreams: $e');
      return [];
    }
  }

  /// Récupérer les live streams programmés
  Future<List<LiveStream>> getScheduledStreams() async {
    try {
      final allStreams = await getAllLiveStreams();
      final scheduled = allStreams
          .where((stream) => stream.status == LiveStreamStatus.scheduled)
          .toList();

      // Trier par date de programmation
      scheduled.sort((a, b) {
        if (a.scheduledAt == null) return 1;
        if (b.scheduledAt == null) return -1;
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      });

      return scheduled;
    } catch (e) {
      debugPrint('Erreur getScheduledStreams: $e');
      return [];
    }
  }

  /// Rejoindre un live (incrémenter le compteur de viewers)
  Future<Map<String, dynamic>?> joinLive(String id) async {
    try {
      final response = await http
          .post(Uri.parse('${await baseUrl}/$id/join'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('✅ Rejoint le live: ${data['viewerCount']} viewers');
        return data;
      } else {
        throw Exception('Failed to join live: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur joinLive: $e');
      return null;
    }
  }

  /// Quitter un live (décrémenter le compteur de viewers)
  Future<Map<String, dynamic>?> leaveLive(String id) async {
    try {
      final response = await http
          .post(Uri.parse('${await baseUrl}/$id/leave'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('👋 Quitté le live: ${data['viewerCount']} viewers');
        return data;
      } else {
        throw Exception('Failed to leave live: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur leaveLive: $e');
      return null;
    }
  }

  /// Obtenir le nombre de viewers en temps réel
  Future<Map<String, dynamic>?> getViewerCount(String id) async {
    try {
      final response = await http
          .get(Uri.parse('${await baseUrl}/$id/viewers'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Erreur getViewerCount: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'un live
  Future<bool> updateLiveStatus(String id, String status) async {
    try {
      final response = await http
          .put(
            Uri.parse('${await baseUrl}/$id/status'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': status}),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur updateLiveStatus: $e');
      return false;
    }
  }
}
