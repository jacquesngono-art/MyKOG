import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/live_stream.dart';
import '../models/live_comment.dart';
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

  /// Obtenir un token LiveKit pour rejoindre une room en tant que viewer
  Future<Map<String, dynamic>?> getViewerToken(String id, {String? userId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${await baseUrl}/$id/token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'userId': userId}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('🎫 Token LiveKit obtenu pour le live $id');
        return data;
      } else {
        debugPrint('❌ Erreur getViewerToken: ${response.statusCode}');
        return null;
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getViewerToken: $e');
      return null;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getViewerToken: $e');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur getViewerToken: $e');
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

  /// Obtenir un token viewer LiveKit pour rejoindre un live
  /// Retourne: { id, token, url, roomName, identity }
  Future<Map<String, dynamic>> getViewerToken(String liveId,
      {String? userId}) async {
    try {
      final response = await http
          .post(
            Uri.parse('${await baseUrl}/$liveId/token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              if (userId != null) 'userId': userId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getViewerToken: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getViewerToken: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur getViewerToken: $e');
      rethrow;
    }
  }

  /// Obtenir un token publisher LiveKit pour diffuser (OBS / app desktop)
  /// Retourne: { id, url, roomName, whipUrl, streamKey, ingressId }
  /// ou { id, token, url, roomName, whipUrl } en fallback WebRTC
  Future<Map<String, dynamic>> getPublisherToken(String liveId) async {
    try {
      final response = await http
          .post(
            Uri.parse('${await baseUrl}/$liveId/publisher-token'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getPublisherToken: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getPublisherToken: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur getPublisherToken: $e');
      rethrow;
    }
  }

  /// Obtenir les informations du serveur de streaming
  /// Retourne: { livekitUrl, whipUrl, defaultStreamKey }
  Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final response = await http
          .get(Uri.parse('${await baseUrl}/server-info'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception(_extractError(response));
      }
    } on SocketException catch (e) {
      debugPrint('SocketException getServerInfo: $e');
      throw Exception('Aucune connexion internet.');
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException getServerInfo: $e');
      throw Exception('La requête a expiré.');
    } catch (e) {
      debugPrint('Erreur getServerInfo: $e');
      rethrow;
    }
  }

  /// Récupérer les commentaires d'un live (arbre imbriqué)
  Future<List<LiveComment>> getComments(String liveId) async {
    try {
      final response = await http
          .get(Uri.parse('${await baseUrl}/$liveId/comments'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['comments'] ?? [];
        return list
            .map((c) => LiveComment.fromJson(Map<String, dynamic>.from(c)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur getComments: $e');
      return [];
    }
  }

  /// Poster un commentaire (ou une réponse si parentId fourni)
  Future<LiveComment?> postComment(
    String liveId, {
    required String content,
    String? author,
    String? userId,
    String? avatar,
    String? parentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${await baseUrl}/$liveId/comments'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'content': content,
              if (author != null) 'author': author,
              if (userId != null) 'userId': userId,
              if (avatar != null) 'avatar': avatar,
              if (parentId != null) 'parentId': parentId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return LiveComment.fromJson(
            Map<String, dynamic>.from(data['comment']));
      }
      throw Exception(_extractError(response));
    } catch (e) {
      debugPrint('Erreur postComment: $e');
      rethrow;
    }
  }

  /// Voter sur un commentaire (+1 ou -1)
  Future<int?> voteComment(String liveId, String commentId, int delta) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${await baseUrl}/$liveId/comments/$commentId/vote'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'delta': delta}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['votes'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur voteComment: $e');
      return null;
    }
  }

  /// Modifier un commentaire
  Future<LiveComment?> updateComment(
      String liveId, String commentId, String content) async {
    try {
      final response = await http
          .put(
            Uri.parse('${await baseUrl}/$liveId/comments/$commentId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'content': content}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LiveComment.fromJson(
            Map<String, dynamic>.from(data['comment']));
      }
      return null;
    } catch (e) {
      debugPrint('Erreur updateComment: $e');
      return null;
    }
  }

  /// Supprimer un commentaire (et ses réponses)
  Future<bool> deleteComment(String liveId, String commentId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${await baseUrl}/$liveId/comments/$commentId'),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur deleteComment: $e');
      return false;
    }
  }

  /// Extraire le message d'erreur d'une réponse HTTP
  String _extractError(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {
      // Ignorer les erreurs de parsing
    }
    return 'Erreur HTTP ${response.statusCode}';
  }
}
