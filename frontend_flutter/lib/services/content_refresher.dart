import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:MyKOG/services/notification_service.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/calendar_service.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/services/connectivity_service.dart';
import 'package:MyKOG/services/live_stream_service.dart';
import 'package:MyKOG/providers/teaching_provider.dart';

/// Rafraîchit automatiquement le contenu de l'app, comme la version desktop :
/// 1. Rechargement immédiat à la réception d'une notification FCM
///    (nouvel enseignement, événement calendrier, etc.)
/// 2. Re-sync au retour de l'app au premier plan
///
/// Aucun polling périodique : le refresh se déclenche uniquement quand
/// un nouveau contenu est poussé (FCM) ou au retour au premier plan.
///
/// Les écrans qui chargent leurs données localement (CalendarScreen,
/// TextResumesScreen…) s'abonnent à ce ChangeNotifier via [version] :
/// quand elle change, ils rechargent silencieusement leurs données.
class ContentRefresher extends ChangeNotifier with WidgetsBindingObserver {
  static final ContentRefresher instance = ContentRefresher._();
  ContentRefresher._();

  int _version = 0;
  bool _started = false;
  bool _refreshing = false;

  TeachingProvider? _teachingProvider;

  /// Version du contenu : incrémentée à chaque rafraîchissement réussi.
  int get version => _version;

  bool get isStarted => _started;

  /// Démarrer l'écoute (à appeler après l'init des providers).
  /// [teachingProvider] sert à rafraîchir la liste des enseignements
  /// en mémoire (HomeScreen/BrowseScreen/TeachingsScreen suivent ce provider).
  void start(TeachingProvider teachingProvider) {
    if (_started) return;
    _started = true;
    _teachingProvider = teachingProvider;

    // 1) Push : recharger au moment où une notification arrive
    NotificationService().messageStream.listen(_onPushMessage);

    // 2) Re-sync quand l'app revient au premier plan
    WidgetsBinding.instance.addObserver(this);

    debugPrint('🚀 ContentRefresher démarré (refresh sur push FCM + reprise au premier plan)');
  }

  /// Recevoir une notification push en foreground.
  Future<void> _onPushMessage(RemoteMessage message) async {
    final type = message.data['type'] as String?;
    debugPrint('📬 Push reçu, refresh ciblé: type=$type');
    await refreshAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App au premier plan → refresh contenu');
      refreshAll();
    }
  }

  /// Rafraîchir tout le contenu (silencieux, sans spinner).
  Future<void> refreshAll() async {
    if (_refreshing) return;
    _refreshing = true;

    try {
      final connectivity = ConnectivityService();
      if (!connectivity.isConnected) {
        debugPrint('📴 Offline — refresh annulé');
        return;
      }

      // Enseignements : vider le cache statique puis re-fetch
      final provider = _teachingProvider;
      if (provider != null) {
        await provider.silentlyRefresh();
        debugPrint('🔄 Enseignements rafraîchis');
      }

      // Calendrier : recharger et mettre à jour le cache local
      try {
        final events = await CalendarService.getAllEvents();
        final eventIds = events.map((e) => e.id).toList();
        await BadgeService().checkNewCalendarEvents(eventIds);
      } catch (e) {
        debugPrint('⚠️ Refresh calendrier impossible: $e');
      }

      // Lives : recharger (statut live/scheduled modifié)
      try {
        LiveStreamService.clearCache();
        await LiveStreamService.getAllLiveStreams();
      } catch (e) {
        debugPrint('⚠️ Refresh lives impossible: $e');
      }

      // Badge "nouveaux enseignements" (Browse)
      try {
        final teachings = TeachingService.getAllCachedTeachings();
        final ids = teachings.map((t) => t.id).toList();
        final dates = {
          for (var t in teachings) t.id: t.publishedAt,
        };
        await BadgeService().checkNewTeachings(ids, dates);
      } catch (e) {
        debugPrint('⚠️ Refresh badges impossible: $e');
      }

      // Incrémenter la version pour les écrans abonnés
      _version++;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur ContentRefresher: $e');
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}