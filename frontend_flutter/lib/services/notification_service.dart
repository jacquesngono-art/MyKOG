import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:MyKOG/api/notification_api_service.dart';
import 'package:MyKOG/services/user_service.dart';
import 'package:MyKOG/services/navigation_service.dart';

/// Handler pour les notifications en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase si nécessaire (important pour iOS)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase déjà initialisé, continuer
  }

  debugPrint('📬 Notification reçue en arrière-plan: ${message.messageId}');
  debugPrint('📬 Titre: ${message.notification?.title}');
  debugPrint('📬 Corps: ${message.notification?.body}');
  debugPrint('📬 Données: ${message.data}');
  debugPrint('📬 Type: ${message.data['type']}');

  // Les notifications en background sont automatiquement affichées par le système
  // On peut ici faire des traitements supplémentaires si nécessaire
  // Par exemple : mettre à jour le cache local, synchroniser des données, etc.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  // Stream pour les notifications en foreground
  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageController.stream;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Demander la permission pour les notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissions de notification accordées');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permissions de notification provisoires');
      } else {
        debugPrint('❌ Permissions de notification refusées');
        return;
      }

      // Configurer les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 Token FCM: $_fcmToken');

      // Enregistrer le token dans Firebase (avec retry si nécessaire)
      if (_fcmToken != null) {
        // Essayer immédiatement
        await _saveTokenToBackend(_fcmToken!);
        
        // Réessayer après 3 secondes au cas où l'utilisateur n'est pas encore initialisé
        Future.delayed(const Duration(seconds: 3), () async {
          if (_fcmToken != null) {
            debugPrint('🔄 Nouvelle tentative d\'enregistrement du token...');
            await _saveTokenToBackend(_fcmToken!);
          }
        });
      }

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Nouveau token FCM: $newToken');
        _fcmToken = newToken;
        _saveTokenToBackend(newToken);
      });

      // Configurer le handler pour les notifications en arrière-plan
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Écouter les notifications en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📬 Notification reçue en foreground: ${message.messageId}');
        _handleForegroundMessage(message);
        _messageController.add(message);
      });

      // Gérer les notifications qui ouvrent l'app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📬 Notification ouverte: ${message.messageId}');
        _handleNotificationTap(message);
      });

      // Vérifier si l'app a été ouverte depuis une notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📬 App ouverte depuis notification: ${initialMessage.messageId}');
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('✅ NotificationService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation NotificationService: $e');
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    // Configuration Android avec logo KOG
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/kog_launch');

    // Configuration iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
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
        debugPrint('📬 Notification locale tapée: ${response.payload}');
      },
    );

    // Créer le canal de notification Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mykog_notifications',
      'MyKOG Notifications',
      description: 'Notifications pour les nouvelles publications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Afficher une notification locale
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    // Configuration Android avec logo de l'application
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mykog_notifications',
      'MyKOG Notifications',
      channelDescription: 'Notifications pour les nouvelles publications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/kog_launch', // Logo KOG de l'application (petite icône - Android convertira automatiquement)
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/kog_launch'), // Grande icône KOG colorée pour les notifications étendues
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // L'icône iOS sera automatiquement utilisée depuis les assets de l'app
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Gérer les notifications en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    // Afficher une notification locale
    showLocalNotification(
      title: message.notification?.title ?? 'MyKOG',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      imageUrl: message.notification?.android?.imageUrl,
    );
  }

  /// Gérer le tap sur une notification
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    if (type != null) {
      debugPrint('📬 Navigation depuis notification: type=$type, id=$id');
      
      // Utiliser le service de navigation
      NavigationService().navigateFromNotification(
        type: type,
        id: id,
        data: data,
      );
    } else {
      debugPrint('⚠️ Notification sans type, navigation vers l\'accueil');
      NavigationService().navigateTo('/home');
    }
  }

  /// Enregistrer le token FCM dans le backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      var user = await UserService.getCurrentUser();
      
      // Si l'utilisateur n'existe pas encore, initialiser un utilisateur par défaut
      if (user == null) {
        await UserService.initializeDefaultUser();
        user = await UserService.getCurrentUser();
      }
      
      if (user != null) {
        // Enregistrer le token via l'API
        final notificationApi = NotificationApiService();
        await notificationApi.registerToken(user.id, token);
        debugPrint('✅ Token FCM enregistré pour l\'utilisateur: ${user.id}');
      } else {
        // Utiliser un ID par défaut si aucun utilisateur n'est disponible
        debugPrint('⚠️ Aucun utilisateur disponible, utilisation de l\'ID par défaut');
        final notificationApi = NotificationApiService();
        await notificationApi.registerToken('default-user', token);
        debugPrint('✅ Token FCM enregistré avec l\'ID par défaut');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur enregistrement token: $e');
      debugPrint('⚠️ Stack trace: ${StackTrace.current}');
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Abonné au topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur abonnement topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur désabonnement topic: $e');
    }
  }

  /// S'abonner aux topics par défaut
  Future<void> subscribeToDefaultTopics() async {
    await subscribeToTopic('all'); // Tous les utilisateurs
    await subscribeToTopic('notifications'); // Notifications générales
  }

  void dispose() {
    _messageController.close();
  }
}

