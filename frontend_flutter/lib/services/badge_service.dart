import 'package:flutter/foundation.dart';
import 'package:MyKOG/services/hive_storage_service.dart';

class BadgeService extends ChangeNotifier {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  static const String _keySeenTeachings = 'seen_teachings_ids';
  static const String _keySeenCalendarEvents = 'seen_calendar_events_ids';

  Set<String> _seenTeachingIds = {};
  Set<String> _seenCalendarEventIds = {};
  bool _hasNewTeachings = false;
  bool _hasNewCalendarEvents = false;

  bool get hasNewTeachings => _hasNewTeachings;
  bool get hasNewCalendarEvents => _hasNewCalendarEvents;

  /// Initialiser le service
  Future<void> initialize() async {
    try {
      // Charger les IDs déjà vus (stockés sous forme de liste JSON en Hive)
      _seenTeachingIds = _loadIdList(_keySeenTeachings);
      _seenCalendarEventIds = _loadIdList(_keySeenCalendarEvents);

      debugPrint('✅ BadgeService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation BadgeService: $e');
    }
  }

  static Set<String> _loadIdList(String key) {
    final value = HiveStorageService.get(key);
    if (value is List) {
      return value.map((e) => e.toString()).toSet();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(',').where((e) => e.isNotEmpty).toSet();
    }
    return {};
  }

  static Future<void> _saveIdList(String key, Set<String> ids) async {
    await HiveStorageService.storeString(key, ids.join(','));
  }

  /// Vérifier s'il y a de nouveaux enseignements (publiés dans les 2 derniers jours)
  Future<void> checkNewTeachings(List<String> currentTeachingIds, Map<String, DateTime> teachingPublishedDates) async {
    try {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      
      // Trouver les nouveaux enseignements publiés dans les 2 derniers jours
      final newTeachings = currentTeachingIds.where((id) {
        // Vérifier si l'enseignement n'a pas été vu
        if (_seenTeachingIds.contains(id)) {
          return false;
        }
        
        // Vérifier si l'enseignement a été publié dans les 2 derniers jours
        final publishedDate = teachingPublishedDates[id];
        if (publishedDate == null) {
          return false;
        }
        
        return publishedDate.isAfter(twoDaysAgo);
      }).toList();

      final hadNewTeachings = _hasNewTeachings;
      _hasNewTeachings = newTeachings.isNotEmpty;
      
      // Notifier seulement si l'état a changé
      if (hadNewTeachings != _hasNewTeachings) {
        notifyListeners();
      }
      
      if (newTeachings.isNotEmpty) {
        debugPrint('📚 ${newTeachings.length} nouveau(x) enseignement(s) détecté(s) (publiés dans les 2 derniers jours)');
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification nouveaux enseignements: $e');
    }
  }
  
  /// Vérifier si un enseignement est "nouveau" (publié dans les 2 derniers jours)
  bool isTeachingNew(String teachingId, DateTime publishedDate) {
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    
    // Vérifier si l'enseignement n'a pas été vu ET a été publié dans les 2 derniers jours
    return !_seenTeachingIds.contains(teachingId) && publishedDate.isAfter(twoDaysAgo);
  }

  /// Vérifier s'il y a de nouveaux événements calendrier
  Future<void> checkNewCalendarEvents(List<String> currentEventIds) async {
    try {
      // Trouver les nouveaux événements
      final newEvents = currentEventIds
          .where((id) => !_seenCalendarEventIds.contains(id))
          .toList();

      final hadNewEvents = _hasNewCalendarEvents;
      _hasNewCalendarEvents = newEvents.isNotEmpty;
      
      // Notifier seulement si l'état a changé
      if (hadNewEvents != _hasNewCalendarEvents) {
        notifyListeners();
      }
      
      if (newEvents.isNotEmpty) {
        debugPrint('📅 ${newEvents.length} nouveau(x) événement(s) calendrier détecté(s)');
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification nouveaux événements: $e');
    }
  }

  /// Marquer les enseignements comme vus (quand on clique sur l'icône Browse)
  Future<void> markTeachingsAsSeen(List<String> teachingIds) async {
    try {
      // Ajouter les IDs aux enseignements vus
      _seenTeachingIds.addAll(teachingIds);

      // Sauvegarder
      await _saveIdList(_keySeenTeachings, _seenTeachingIds);

      // Mettre à jour le badge
      _hasNewTeachings = false;
      notifyListeners();

      debugPrint('✅ Enseignements marqués comme vus');
    } catch (e) {
      debugPrint('❌ Erreur marquage enseignements: $e');
    }
  }

  /// Marquer les événements calendrier comme vus (quand on clique sur l'icône Calendar)
  Future<void> markCalendarEventsAsSeen(List<String> eventIds) async {
    try {
      // Ajouter les IDs aux événements vus
      _seenCalendarEventIds.addAll(eventIds);

      // Sauvegarder
      await _saveIdList(_keySeenCalendarEvents, _seenCalendarEventIds);

      // Mettre à jour le badge
      _hasNewCalendarEvents = false;
      notifyListeners();

      debugPrint('✅ Événements calendrier marqués comme vus');
    } catch (e) {
      debugPrint('❌ Erreur marquage événements: $e');
    }
  }

  /// Réinitialiser tous les badges (optionnel, pour tests)
  Future<void> resetAllBadges() async {
    try {
      await HiveStorageService.delete(_keySeenTeachings);
      await HiveStorageService.delete(_keySeenCalendarEvents);

      _seenTeachingIds.clear();
      _seenCalendarEventIds.clear();
      _hasNewTeachings = false;
      _hasNewCalendarEvents = false;

      notifyListeners();
      debugPrint('✅ Tous les badges réinitialisés');
    } catch (e) {
      debugPrint('❌ Erreur réinitialisation badges: $e');
    }
  }
}

