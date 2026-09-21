import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/api/teaching_api_service.dart';
import 'package:MyKOG/services/hive_storage_service.dart';
import 'package:MyKOG/services/download_service.dart';

class TeachingService {
  static final TeachingApiService _apiService = TeachingApiService();
  static List<Teaching>? _cachedTeachings;

  // Méthode pour initialiser les données de démarrage (fallback)
  static Future<void> initializeSampleData() async {
    final existingTeachings = await getAllTeachings();
    if (existingTeachings.isEmpty) {
      // Si aucune donnée n'est disponible, utiliser les données minimales de démarrage
      await _storeSampleTeachings();
    }
  }

  // Méthode pour stocker des données minimales en cas d'absence totale
  static Future<void> _storeSampleTeachings() async {
    final teachingsJson = _getMinimalSampleData().map((t) => t.toJson()).toList();
    await HiveStorageService.storeJsonList('teachings', teachingsJson);
  }

  // Données minimales de démarrage (pour le premier démarrage)
  static List<Teaching> _getMinimalSampleData() {
    return [
      Teaching(
        id: 'startup-1',
        title: 'Bienvenue sur MyKOG',
        speaker: 'Équipe MyKOG',
        description: 'Bienvenue sur notre plateforme d\'enseignements chrétiens.',
        category: 'Accueil',
        duration: const Duration(minutes: 5, seconds: 0),
        audioUrl: 'https://actions.google.com/sounds/v1/alarms/digital_alarm_clock.ogg',
        artworkUrl: 'assets/images/kog.png',
        tags: ['bienvenue', 'démarrage'],
        playCount: 0,
        rating: 5.0,
        isNew: true,
        isFeatured: true,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        mois: DateTime.now().month.toString(),
        annee: DateTime.now().year.toString(),
        typeCulte: 'Culte de Louange',
      ),
    ];
  }

  // Récupérer les IDs des enseignements téléchargés localement
  static List<String> _getDownloadedIds() {
    try {
      return DownloadService.getDownloadedTeachingIds();
    } catch (_) {
      return [];
    }
  }

  // Récupérer les enseignements téléchargés qui ne sont plus sur le serveur
  static List<Teaching> _getOrphanedDownloadedTeachings(List<Teaching> serverTeachings) {
    try {
      final downloadedIds = _getDownloadedIds();
      if (downloadedIds.isEmpty) return [];

      final serverIds = serverTeachings.map((t) => t.id).toSet();
      final orphanedIds = downloadedIds.where((id) => !serverIds.contains(id)).toList();
      if (orphanedIds.isEmpty) return [];

      final cachedJson = HiveStorageService.getJsonList('teachings');
      final cachedTeachings = cachedJson.map((json) => Teaching.fromJson(json)).toList();

      return cachedTeachings.where((t) => orphanedIds.contains(t.id)).toList();
    } catch (_) {
      return [];
    }
  }

  // Récupérer tous les enseignements (avec cache et fallback)
  static Future<List<Teaching>> getAllTeachings() async {
    try {
      // Essayer d'abord l'API
      if (_cachedTeachings == null) {
        final teachings = await _apiService.getAllTeachings();

        // Préserver les enseignements téléchargés qui ont été supprimés du serveur
        final orphaned = _getOrphanedDownloadedTeachings(teachings);
        final merged = [...teachings, ...orphaned];

        _cachedTeachings = merged;
        // Persister dans Hive pour le mode offline
        final teachingsJson = merged.map((t) => t.toJson()).toList();
        await HiveStorageService.storeJsonList('teachings', teachingsJson);
        return merged;
      }
      return _cachedTeachings!;
    } catch (e) {
      // Erreur API, tentative fallback stockage local: $e

      // En cas d'erreur API, essayer le stockage local
      try {
        final teachingsJson =
            HiveStorageService.getJsonList('teachings');
        if (teachingsJson.isNotEmpty) {
          _cachedTeachings = teachingsJson.map((json) => Teaching.fromJson(json)).toList();
          return _cachedTeachings!;
        }
      } catch (e) {
        // Erreur stockage local: $e
      }

      // Si tout échoue, retourner les données minimales
      return _getMinimalSampleData();
    }
  }

  // Récupérer un enseignement par ID
  static Future<Teaching?> getTeachingById(String id) async {
    try {
      // Essayer l'API en premier
      final teaching = await _apiService.getTeachingById(id);
      if (teaching != null) {
        return teaching;
      }

      // Fallback vers le cache local
      final teachings = await getAllTeachings();
      return teachings.firstWhere((t) => t.id == id, orElse: () => Teaching.empty());
    } catch (e) {
      // Ne pas logger les erreurs réseau comme des erreurs critiques
      // Elles sont gérées par le fallback vers le cache local
      return null;
    }
  }

  // Récupérer les enseignements featured
  static Future<List<Teaching>> getFeaturedTeachings() async {
    try {
      final teachings = await getAllTeachings();
      return teachings.where((t) => t.isFeatured).toList();
    } catch (e) {
      print('Erreur getFeaturedTeachings: $e');
      return [];
    }
  }

  // Récupérer les nouveaux enseignements
  static Future<List<Teaching>> getNewTeachings() async {
    try {
      final teachings = await getAllTeachings();
      return teachings.where((t) => t.isNew).toList();
    } catch (e) {
      print('Erreur getNewTeachings: $e');
      return [];
    }
  }

  // Récupérer les enseignements populaires
  static Future<List<Teaching>> getPopularTeachings({int limit = 10}) async {
    try {
      final teachings = await getAllTeachings();
      final teachingsWithSort = List<Teaching>.from(teachings);
      teachingsWithSort.sort((a, b) => b.playCount.compareTo(a.playCount));
      return teachingsWithSort.take(limit).toList();
    } catch (e) {
      print('Erreur getPopularTeachings: $e');
      return [];
    }
  }

  // Récupérer les enseignements par type de culte (serveur + fallback local)
  static Future<List<Teaching>> getTeachingsByTypeCulte(String typeCulte) async {
    try {
      return await _apiService.getTeachingsByTypeCulte(typeCulte);
    } catch (e) {
      print('Erreur API getTeachingsByTypeCulte, fallback local: $e');
      try {
        final teachings = await getAllTeachings();
        return teachings
            .where((t) => (t.typeCulte?.toLowerCase() ?? '').contains(typeCulte.toLowerCase()))
            .toList();
      } catch (e2) {
        print('Erreur getTeachingsByTypeCulte: $e2');
        return [];
      }
    }
  }

  // Rechercher des enseignements
  static Future<List<Teaching>> searchTeachings(String query) async {
    if (query.trim().isEmpty) return await getAllTeachings();

    try {
      final teachings = await getAllTeachings();
      final lowerQuery = query.toLowerCase();

      return teachings
          .where((t) =>
            t.title.toLowerCase().contains(lowerQuery) ||
            t.speaker.toLowerCase().contains(lowerQuery) ||
            (t.typeCulte?.toLowerCase() ?? '').contains(lowerQuery) ||
            (t.description?.toLowerCase() ?? '').contains(lowerQuery) ||
            t.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      print('Erreur searchTeachings: $e');
      return [];
    }
  }

  // Récupérer les catégories (pour compatibilité)
  static Future<List<String>> getCategories() async {
    try {
      // Pour l'instant, retourner les types de culte comme catégories
      return await getTypeCulteOptions();
    } catch (e) {
      return ['Culte de Louange', 'Culte de Prière', 'Culte d\'Enseignement'];
    }
  }

  // Récupérer les enseignements recommandés
  static Future<List<Teaching>> getRecommendedTeachings() async {
    try {
      final teachings = await getAllTeachings();

      // Logique simple de recommandation: featured + nouveaux + populaires
      final recommended = <Teaching>{};

      // Ajouter les enseignements featured
      recommended.addAll(teachings.where((t) => t.isFeatured));

      // Ajouter les nouveaux enseignements
      recommended.addAll(teachings.where((t) => t.isNew));

      // Ajouter les enseignements les plus joués
      final popular = teachings..sort((a, b) => b.playCount.compareTo(a.playCount));
      recommended.addAll(popular.take(5));

      return recommended.toList();
    } catch (e) {
      print('Erreur getRecommendedTeachings: $e');
      return [];
    }
  }

  // Récupérer les types de culte disponibles
  static Future<List<String>> getTypeCulteOptions() async {
    try {
      final teachings = await getAllTeachings();
      final typeCulteSet = teachings
          .where((t) => t.typeCulte != null && t.typeCulte!.isNotEmpty)
          .map((t) => t.typeCulte!)
          .toSet()
          .toList();

      typeCulteSet.sort();
      return typeCulteSet;
    } catch (e) {
      print('Erreur getTypeCulteOptions: $e');
      // Retourner quelques options par défaut
      return [
        'Culte de Louange',
        'Culte de Prière',
        'Culte d\'Enseignement',
        'Culte d\'Adoration',
        'Étude Biblique'
      ];
    }
  }

  // Récupérer enseignements par mois/année (serveur + fallback local)
  static Future<List<Teaching>> getTeachingsByMonthYear(int mois, int annee) async {
    try {
      return await _apiService.getTeachingsByMonthYear(mois, annee);
    } catch (e) {
      print('Erreur API getTeachingsByMonthYear, fallback local: $e');
      try {
        final teachings = await getAllTeachings();
        return teachings
            .where((t) => t.moisSafe == mois.toString() && t.anneeSafe == annee.toString())
            .toList();
      } catch (e2) {
        print('Erreur getTeachingsByMonthYear: $e2');
        return [];
      }
    }
  }

  // Incrémenter le compteur de lecture
  static Future<void> incrementPlayCount(String teachingId) async {
    try {
      await _apiService.incrementPlayCount(teachingId);

      // Mettre à jour le cache local si disponible
      if (_cachedTeachings != null) {
        final index = _cachedTeachings!.indexWhere((t) => t.id == teachingId);
        if (index != -1) {
          final teaching = _cachedTeachings![index];
          _cachedTeachings![index] = teaching.copyWith(
            playCount: teaching.playCount + 1,
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      print('Erreur incrementPlayCount: $e');
    }
  }

  // Ajouter un enseignement (pour la persistance locale)
  static Future<void> addTeaching(Teaching teaching) async {
    try {
      final teachings = await getAllTeachings();
      teachings.add(teaching);

      final teachingsJson = teachings.map((t) => t.toJson()).toList();
      await HiveStorageService.storeJsonList('teachings', teachingsJson);

      // Mettre à jour le cache
      _cachedTeachings = teachings;
    } catch (e) {
      print('Erreur addTeaching: $e');
    }
  }

  // Mettre à jour un enseignement
  static Future<void> updateTeaching(Teaching teaching) async {
    try {
      final teachings = await getAllTeachings();
      final index = teachings.indexWhere((t) => t.id == teaching.id);

      if (index != -1) {
        teachings[index] = teaching.copyWith(updatedAt: DateTime.now());

        final teachingsJson = teachings.map((t) => t.toJson()).toList();
        await HiveStorageService.storeJsonList('teachings', teachingsJson);

        // Mettre à jour le cache
        _cachedTeachings = teachings;
      }
    } catch (e) {
      print('Erreur updateTeaching: $e');
    }
  }

  // Supprimer un enseignement
  static Future<bool> deleteTeaching(String teachingId) async {
    try {
      // Supprimer via l'API
      final success = await _apiService.deleteTeaching(teachingId);
      
      if (success) {
        // Mettre à jour le cache local
        if (_cachedTeachings != null) {
          _cachedTeachings!.removeWhere((t) => t.id == teachingId);
        }

        // Mettre à jour le stockage local
        final teachings = await getAllTeachings();
        teachings.removeWhere((t) => t.id == teachingId);
        final teachingsJson = teachings.map((t) => t.toJson()).toList();
        await HiveStorageService.storeJsonList('teachings', teachingsJson);

        return true;
      }
      return false;
    } catch (e) {
      print('Erreur deleteTeaching: $e');
      // En cas d'erreur API, supprimer quand même localement pour le cache
      if (_cachedTeachings != null) {
        _cachedTeachings!.removeWhere((t) => t.id == teachingId);
      }
      return false;
    }
  }

  // Vider le cache (utile pour rafraîchir)
static void clearCache() {
    _cachedTeachings = null;
  }

  /// Retourner la liste actuellement en cache (sans aucun appel réseau).
  /// Vide si le cache n'a pas encore été rempli.
  static List<Teaching> getAllCachedTeachings() {
    return _cachedTeachings ?? [];
  }

  // Méthode pour obtenir des stats sur le cache
  static String getCacheStats() {
    final teachingsCount = _cachedTeachings?.length ?? 0;
    return 'Cache: ${teachingsCount} enseignements';
  }

  // Obtenir statistiques
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final teachings = await getAllTeachings();
      return {
        'totalTeachings': teachings.length,
        'featuredCount': teachings.where((t) => t.isFeatured).length,
        'newCount': teachings.where((t) => t.isNew).length,
        'totalPlayCount': teachings.fold(0, (sum, t) => sum + t.playCount),
        'averageRating': teachings.isEmpty
            ? 0
            : teachings.fold(0.0, (sum, t) => sum + t.rating) / teachings.length,
        'availableTypeCulte': teachings
            .where((t) => t.typeCulte != null && t.typeCulte!.isNotEmpty)
            .map((t) => t.typeCulte!)
            .toSet()
            .length,
      };
    } catch (e) {
      print('Erreur getStatistics: $e');
      return {
        'totalTeachings': 0,
        'featuredCount': 0,
        'newCount': 0,
        'totalPlayCount': 0,
        'averageRating': 0.0,
        'availableTypeCulte': 0,
      };
    }
  }
}