import 'package:flutter/foundation.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/api/live_api_service.dart';
import 'package:MyKOG/services/storage_service.dart';

class LiveStreamService {
  static final LiveApiService _apiService = LiveApiService();
  static List<LiveStream> _liveStreams = [];

  static Future<void> initializeSampleData() async {
    final now = DateTime.now();

    _liveStreams = [
      LiveStream(
        id: 'live1',
        title: 'Service du dimanche matin',
        description:
            'Rejoignez-nous pour notre culte hebdomadaire, rempli de louanges, denseignements et de partage.',
        pastor: 'Prophete Xavier',
        thumbnailUrl: 'assets/images/kog.png',
        streamUrl: 'https://example.com/stream/live1',
        status: LiveStreamStatus.live,
        startedAt: now.subtract(const Duration(minutes: 30)),
        viewerCount: 342,
        tags: ['worship', 'sunday service', 'live'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      LiveStream(
        id: 'live2',
        title: 'Mercredi etude biblique',
        description:
            'Plongez au cœur de la Parole de Dieu grâce à une étude biblique interactive et à des discussions.',
        pastor: 'Rev. Pasteur Grace',
        thumbnailUrl: 'assets/images/kog.png',
        streamUrl: 'https://example.com/stream/live2',
        status: LiveStreamStatus.scheduled,
        scheduledAt: now.add(const Duration(days: 2, hours: 19)),
        viewerCount: 0,
        tags: ['bible study', 'teaching', 'wednesday'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      LiveStream(
        id: 'live3',
        title: 'Youth Night Service',
        description:
            'Dynamic worship and relevant teaching designed for young adults and teens.',
        pastor: 'Pastor Michael',
        thumbnailUrl: 'assets/images/kog.png',
        streamUrl: 'https://example.com/stream/live3',
        status: LiveStreamStatus.scheduled,
        scheduledAt: now.add(const Duration(days: 5, hours: 18)),
        viewerCount: 0,
        tags: ['youth', 'worship', 'friday'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
    ];
  }

  /// Récupérer tous les live streams (avec fallback)
  static Future<List<LiveStream>> getAllLiveStreams() async {
    try {
      // Essayer l'API en premier
      final liveStreams = await _apiService.getAllLiveStreams();
      
      // Sauvegarder dans le cache local
      final liveStreamsJson = liveStreams.map((ls) => ls.toJson()).toList();
      await StorageService.storeJsonList('cached_live_streams', liveStreamsJson);
      
      return liveStreams;
    } catch (e) {
      debugPrint('Erreur API getAllLiveStreams, fallback vers cache: $e');
      
      // Fallback vers le cache local
      try {
        final cachedJson = StorageService.getJsonList('cached_live_streams');
        if (cachedJson.isNotEmpty) {
          return cachedJson.map((json) => LiveStream.fromJson(json)).toList();
        }
      } catch (e) {
        debugPrint('Erreur cache local: $e');
      }
      
      // Si tout échoue, retourner les données sample
      await initializeSampleData();
      return _liveStreams;
    }
  }

  /// Récupérer le live actif (le plus récent)
  static Future<LiveStream?> getActiveLive() async {
    try {
      return await _apiService.getActiveLive();
    } catch (e) {
      debugPrint('Erreur getActiveLive: $e');
      // Fallback: chercher dans tous les lives
      final all = await getAllLiveStreams();
      try {
        return all.firstWhere((stream) => stream.status == LiveStreamStatus.live);
      } catch (e) {
        return null;
      }
    }
  }

  /// Récupérer les live streams en direct
  static Future<List<LiveStream>> getLiveStreams() async {
    try {
      final liveStreams = await _apiService.getLiveNowStreams();
      return liveStreams;
    } catch (e) {
      debugPrint('Erreur getLiveStreams: $e');
      final all = await getAllLiveStreams();
      return all.where((stream) => stream.status == LiveStreamStatus.live).toList();
    }
  }

  /// Récupérer les live streams programmés
  static Future<List<LiveStream>> getScheduledStreams() async {
    try {
      final scheduledStreams = await _apiService.getScheduledStreams();
      return scheduledStreams;
    } catch (e) {
      debugPrint('Erreur getScheduledStreams: $e');
      final all = await getAllLiveStreams();
      return all
          .where((stream) => stream.status == LiveStreamStatus.scheduled)
          .toList()
        ..sort((a, b) => (a.scheduledAt ?? DateTime.now())
            .compareTo(b.scheduledAt ?? DateTime.now()));
    }
  }

  /// Récupérer un live stream par ID
  static Future<LiveStream?> getLiveStreamById(String id) async {
    try {
      return await _apiService.getLiveStreamById(id);
    } catch (e) {
      debugPrint('Erreur getLiveStreamById: $e');
      
      // Fallback vers cache
      final all = await getAllLiveStreams();
      try {
        return all.firstWhere((stream) => stream.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Rejoindre un live (incrémenter le compteur)
  static Future<int?> joinLive(String id) async {
    try {
      final result = await _apiService.joinLive(id);
      return result?['viewerCount'];
    } catch (e) {
      debugPrint('Erreur joinLive: $e');
      return null;
    }
  }

  /// Quitter un live (décrémenter le compteur)
  static Future<int?> leaveLive(String id) async {
    try {
      final result = await _apiService.leaveLive(id);
      return result?['viewerCount'];
    } catch (e) {
      debugPrint('Erreur leaveLive: $e');
      return null;
    }
  }

  /// Obtenir le nombre de viewers
  static Future<int?> getViewerCount(String id) async {
    try {
      final result = await _apiService.getViewerCount(id);
      return result?['viewerCount'];
    } catch (e) {
      debugPrint('Erreur getViewerCount: $e');
      return null;
    }
  }

  /// Vider le cache
  static void clearCache() {
    StorageService.remove('cached_live_streams');
    debugPrint('Cache LiveStreamService vidé');
  }
}
