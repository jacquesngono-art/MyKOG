import 'package:MyKOG/models/calendar_event.dart';
import 'package:MyKOG/api/calendar_api_service.dart';
import 'package:MyKOG/services/storage_service.dart';
import 'package:MyKOG/services/alarm_service.dart';

class CalendarService {
  static final CalendarApiService _apiService = CalendarApiService();
  static List<CalendarEvent>? _cachedEvents;

  // Clé de stockage
  static const String _eventsKey = 'calendar_events';

  // Récupérer tous les événements
  static Future<List<CalendarEvent>> getAllEvents() async {
    try {
      // Essayer de récupérer depuis l'API
      final events = await _apiService.getAllEvents();
      _cachedEvents = events;
      // Sauvegarder en cache local
      await _saveEventsToCache(events);
      return events;
    } catch (e) {
      // En cas d'erreur, utiliser le cache local
      final cachedEvents = await _loadEventsFromCache();
      if (cachedEvents.isNotEmpty) {
        return cachedEvents;
      }
      rethrow;
    }
  }

  // Récupérer les événements pour une année spécifique
  static Future<List<CalendarEvent>> getEventsByYear(int year) async {
    try {
      final events = await _apiService.getEventsByYear(year);
      return events;
    } catch (e) {
      // Fallback: filtrer depuis le cache
      final allEvents = await getAllEvents();
      return allEvents
          .where((event) => event.startDate.year == year)
          .toList();
    }
  }

  // Récupérer un événement par ID
  static Future<CalendarEvent?> getEventById(String id) async {
    try {
      return await _apiService.getEventById(id);
    } catch (e) {
      // Fallback: chercher dans le cache
      final events = await getAllEvents();
      try {
        return events.firstWhere((event) => event.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Créer un événement (admin uniquement)
  static Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final createdEvent = await _apiService.createEvent(event);
      // Mettre à jour le cache
      _cachedEvents?.add(createdEvent);
      await _saveEventsToCache(_cachedEvents ?? []);
      
      // Synchroniser l'alarme si activée
      if (createdEvent.hasAlarm) {
        try {
          await AlarmService().scheduleAlarm(createdEvent);
        } catch (e) {
          // Ne pas bloquer la création si l'alarme échoue
          print('Erreur planification alarme: $e');
        }
      }
      
      return createdEvent;
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour un événement (admin uniquement)
  static Future<CalendarEvent> updateEvent(
      String id, CalendarEvent event) async {
    try {
      final updatedEvent = await _apiService.updateEvent(id, event);
      // Mettre à jour le cache
      if (_cachedEvents != null) {
        final index =
            _cachedEvents!.indexWhere((e) => e.id == id);
        if (index != -1) {
          _cachedEvents![index] = updatedEvent;
          await _saveEventsToCache(_cachedEvents!);
        }
      }
      
      // Mettre à jour l'alarme
      try {
        await AlarmService().updateAlarm(updatedEvent);
      } catch (e) {
        // Ne pas bloquer la mise à jour si l'alarme échoue
        print('Erreur mise à jour alarme: $e');
      }
      
      return updatedEvent;
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un événement (admin uniquement)
  static Future<void> deleteEvent(String id) async {
    try {
      await _apiService.deleteEvent(id);
      // Mettre à jour le cache
      _cachedEvents?.removeWhere((event) => event.id == id);
      await _saveEventsToCache(_cachedEvents ?? []);
      
      // Annuler l'alarme associée
      try {
        await AlarmService().cancelAlarm(id);
      } catch (e) {
        print('Erreur annulation alarme: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sauvegarder les événements en cache
  static Future<void> _saveEventsToCache(List<CalendarEvent> events) async {
    final eventsJson = events.map((e) => e.toJson()).toList();
    await StorageService.storeJsonList(_eventsKey, eventsJson);
  }

  // Charger les événements depuis le cache
  static Future<List<CalendarEvent>> _loadEventsFromCache() async {
    try {
      final eventsJson = StorageService.getJsonList(_eventsKey);
      return eventsJson
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Obtenir les événements pour un mois spécifique
  static Future<List<CalendarEvent>> getEventsByMonth(
      int year, int month) async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) {
      return event.startDate.year == year && event.startDate.month == month;
    }).toList();
  }

  // Obtenir les événements pour une date spécifique
  static Future<List<CalendarEvent>> getEventsByDate(DateTime date) async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) {
      return event.startDate.year == date.year &&
          event.startDate.month == date.month &&
          event.startDate.day == date.day;
    }).toList();
  }

  // Obtenir les événements à venir
  static Future<List<CalendarEvent>> getUpcomingEvents() async {
    final allEvents = await getAllEvents();
    final now = DateTime.now();
    return allEvents
        .where((event) => event.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}

