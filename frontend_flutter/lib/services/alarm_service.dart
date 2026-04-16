import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:MyKOG/models/calendar_event.dart';
import 'package:MyKOG/api/calendar_api_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialiser le service d'alarme
  Future<void> initialize() async {
    try {
      // Initialiser timezone
      tz.initializeTimeZones();
      
      // Configuration Android pour les alarmes
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@drawable/kog_launch');

      // Configuration iOS
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 Alarme déclenchée: ${response.payload}');
        },
      );

      // Créer le canal de notification pour les alarmes avec son d'alarme système
      // Note: Le son d'alarme système sera utilisé automatiquement avec Importance.max
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'mykog_alarms',
        'MyKOG Alarmes',
        description: 'Alarmes pour les événements du calendrier',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // Le son d'alarme système sera utilisé automatiquement
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alarmChannel);

      debugPrint('✅ AlarmService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation AlarmService: $e');
    }
  }

  /// Planifier une alarme pour un événement
  Future<void> scheduleAlarm(CalendarEvent event) async {
    debugPrint('🔔 Tentative de planification alarme pour: ${event.title}');
    debugPrint('   - hasAlarm: ${event.hasAlarm}');
    debugPrint('   - alarmDaysBefore: ${event.alarmDaysBefore}');
    debugPrint('   - alarmHoursBefore: ${event.alarmHoursBefore}');
    debugPrint('   - alarmMinutesBefore: ${event.alarmMinutesBefore}');
    
    if (!event.hasAlarm || event.alarmTriggerTime == null) {
      debugPrint('⚠️ Événement sans alarme ou date de déclenchement invalide');
      debugPrint('   - alarmTriggerTime: ${event.alarmTriggerTime}');
      return;
    }

    final triggerTime = event.alarmTriggerTime!;
    final now = DateTime.now();

    debugPrint('   - Date événement: ${event.startDate}');
    debugPrint('   - Date déclenchement calculée: $triggerTime');
    debugPrint('   - Maintenant: $now');
    debugPrint('   - Différence: ${triggerTime.difference(now).inMinutes} minutes');

    // Vérifier que l'alarme est dans le futur
    if (triggerTime.isBefore(now)) {
      debugPrint('⚠️ L\'alarme est dans le passé, elle ne sera pas planifiée');
      debugPrint('   - Différence: ${now.difference(triggerTime).inMinutes} minutes dans le passé');
      return;
    }

    try {
      // Configuration Android pour l'alarme avec son d'alarme système
      // Utiliser l'URI du son d'alarme système Android (en tant que String)
      const alarmSoundUri = 'content://settings/system/alarm_alert';
      
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mykog_alarms',
        'MyKOG Alarmes',
        channelDescription: 'Alarmes pour les événements du calendrier',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/kog_launch',
        largeIcon: const DrawableResourceAndroidBitmap('@drawable/kog_launch'),
        sound: UriAndroidNotificationSound(alarmSoundUri), // Son d'alarme système Android
        fullScreenIntent: true, // Afficher l'alarme même si l'écran est verrouillé (Android 10+)
        category: AndroidNotificationCategory.alarm, // Catégorie alarme pour Android
        ongoing: true, // Alarme continue jusqu'à action de l'utilisateur
        autoCancel: false, // Ne pas annuler automatiquement - l'utilisateur doit agir
        enableLights: true, // Activer la LED
        ledColor: const Color(0xFFFF0000), // LED rouge pour l'alarme
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm.caf', // Son d'alarme système iOS
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Planifier l'alarme avec une date précise
      final location = tz.getLocation('Europe/Paris'); // Ajuster selon votre fuseau horaire
      final scheduledDate = tz.TZDateTime.from(triggerTime, location);
      
      debugPrint('🔔 Planification alarme:');
      debugPrint('   - Événement: ${event.title}');
      debugPrint('   - Date événement: ${event.startDate}');
      debugPrint('   - Date déclenchement: $triggerTime');
      debugPrint('   - Date planifiée (TZ): $scheduledDate');
      debugPrint('   - Maintenant: ${DateTime.now()}');
      
      await _localNotifications.zonedSchedule(
        event.id.hashCode, // ID unique pour l'alarme
        '📅 ${event.title}',
        event.description ?? 'L\'événement commence bientôt !',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: event.id,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('✅ Alarme planifiée avec succès pour ${event.title} à ${triggerTime.toString()}');
    } catch (e) {
      debugPrint('❌ Erreur planification alarme: $e');
    }
  }

  /// Annuler une alarme
  Future<void> cancelAlarm(String eventId) async {
    try {
      await _localNotifications.cancel(eventId.hashCode);
      debugPrint('✅ Alarme annulée pour l\'événement: $eventId');
    } catch (e) {
      debugPrint('❌ Erreur annulation alarme: $e');
    }
  }

  /// Mettre à jour une alarme
  Future<void> updateAlarm(CalendarEvent event) async {
    // Annuler l'ancienne alarme
    await cancelAlarm(event.id);
    
    // Planifier la nouvelle alarme si elle est activée
    if (event.hasAlarm) {
      await scheduleAlarm(event);
    }
  }

  /// Synchroniser toutes les alarmes depuis les événements
  Future<void> syncAlarms() async {
    try {
      final calendarApi = CalendarApiService();
      final events = await calendarApi.getAllEvents();
      
      // Planifier les alarmes pour tous les événements avec alarme activée
      for (final event in events) {
        if (event.hasAlarm && event.isUpcoming()) {
          await scheduleAlarm(event);
        }
      }
      
      debugPrint('✅ Synchronisation des alarmes terminée');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation alarmes: $e');
    }
  }

  /// Annuler toutes les alarmes
  Future<void> cancelAllAlarms() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ Toutes les alarmes ont été annulées');
    } catch (e) {
      debugPrint('❌ Erreur annulation de toutes les alarmes: $e');
    }
  }
}

