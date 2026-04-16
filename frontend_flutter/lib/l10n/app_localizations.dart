import 'package:flutter/material.dart';

/// Classe de gestion des traductions
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // Français
    Locale('en', 'US'), // Anglais
    Locale('de', 'DE'), // Allemand
    Locale('es', 'ES'), // Espagnol
  ];

  // Map des traductions
  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': _frenchTranslations,
    'en': _englishTranslations,
    'de': _germanTranslations,
    'es': _spanishTranslations,
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Helper methods pour accès direct
  String get appName => translate('app_name');
  String get home => translate('home');
  String get browse => translate('browse');
  String get library => translate('library');
  String get live => translate('live');
  String get profile => translate('profile');

  // Home Screen
  String get goodMorning => translate('good_morning');
  String get goodAfternoon => translate('good_afternoon');
  String get goodEvening => translate('good_evening');
  String get verseOfTheDay => translate('verse_of_the_day');
  String get myFavorites => translate('my_favorites');
  String get recentlyPlayed => translate('recently_played');
  String get newReleases => translate('new_releases');

  // Browse Screen
  String get categories => translate('categories');
  String get popular => translate('popular');
  String get recommended => translate('recommended');

  // Library Screen
  String get allTeachings => translate('all_teachings');
  String get downloads => translate('downloads');
  String get culteDImpact => translate('culte_d_impact');
  String get culteProphetique => translate('culte_prophetique');
  String get culteDEnseignement => translate('culte_d_enseignement');
  String get searchTeachings => translate('search_teachings');
  String get noTeachingsFound => translate('no_teachings_found');

  // Audio Player
  String get nowPlaying => translate('now_playing');
  String get playbackSpeed => translate('playback_speed');
  String get addToQueue => translate('add_to_queue');
  String get addToFavorites => translate('add_to_favorites');
  String get removeFromFavorites => translate('remove_from_favorites');
  String get share => translate('share');
  String get download => translate('download');
  String get deleteDownload => translate('delete_download');

  // Profile Screen
  String get settings => translate('settings');
  String get language => translate('language');
  String get notifications => translate('notifications');
  String get manageDownloads => translate('manage_downloads');
  String get aboutApp => translate('about_app');
  String get signOut => translate('sign_out');
  String get darkMode => translate('dark_mode');

  // Downloads
  String get downloading => translate('downloading');
  String get downloaded => translate('downloaded');
  String get downloadComplete => translate('download_complete');
  String get downloadFailed => translate('download_failed');
  String get deleteDownloadConfirm => translate('delete_download_confirm');
  String get deleteAllDownloads => translate('delete_all_downloads');
  String get storageUsed => translate('storage_used');

  // Common
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get delete => translate('delete');
  String get save => translate('save');
  String get search => translate('search');
  String get filter => translate('filter');
  String get refresh => translate('refresh');
  String get retry => translate('retry');
  String get error => translate('error');
  String get success => translate('success');
  String get loading => translate('loading');
  String get noDataAvailable => translate('no_data_available');

  // Messages
  String get addedToFavorites => translate('added_to_favorites');
  String get removedFromFavorites => translate('removed_from_favorites');
  String get addedToQueue => translate('added_to_queue');
  String get noInternetConnection => translate('no_internet_connection');
  String get requestTimeout => translate('request_timeout');

  // Additional strings
  String get downloadDeleted => translate('download_deleted');
  String get shareComingSoon => translate('share_coming_soon');
  String get noDownloadsYet => translate('no_downloads_yet');
  String get downloadToListenOffline => translate('download_to_listen_offline');
  String get startListening => translate('start_listening');
  String get recentTeachingsAppearHere =>
      translate('recent_teachings_appear_here');
  String get noLiveStreamsNow => translate('no_live_streams_now');
  String get checkBackLater => translate('check_back_later');
  String get liveNow => translate('live_now');
  String get scheduled => translate('scheduled');
  String get liveServices => translate('live_services');
  String get watchInRealTime => translate('watch_in_real_time');
  String get all => translate('all');
  String get madeForYou => translate('made_for_you');
  String get popularThisWeek => translate('popular_this_week');
  String get discover => translate('discover');
  String get exploreTeachings => translate('explore_teachings');
  String get browseByCategory => translate('browse_by_category');
  String get closePlayer => translate('close_player');
  String get stopPlaybackConfirm => translate('stop_playback_confirm');
  String get filterByYear => translate('filter_by_year');
  String get filterByMonth => translate('filter_by_month');
}

// Délégué pour les localisations
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'de', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ========================================
// TRADUCTIONS FRANÇAIS
// ========================================
const Map<String, String> _frenchTranslations = {
  // App
  'app_name': 'MyKOG',

  // Navigation
  'home': 'Accueil',
  'browse': 'Explorer',
  'library': 'Bibliothèque',
  'live': 'En direct',
  'profile': 'Profil',

  // Home Screen
  'good_morning': 'Bonjour',
  'good_afternoon': 'Bon après-midi',
  'good_evening': 'Bonsoir',
  'verse_of_the_day': 'Verset du jour',
  'my_favorites': 'Mes Favoris',
  'recently_played': 'Récemment écouté',
  'new_releases': 'Nouveautés',

  // Browse Screen
  'categories': 'Catégories',
  'popular': 'Populaires',
  'recommended': 'Recommandés',

  // Library Screen
  'all_teachings': 'Tous',
  'downloads': 'Téléchargés',
  'culte_d_impact': 'Culte d\'Impact',
  'culte_prophetique': 'Culte Prophétique',
  'culte_d_enseignement': 'Culte d\'Enseignement',
  'search_teachings': 'Rechercher enseignements, orateurs...',
  'no_teachings_found': 'Aucun enseignement trouvé',

  // Audio Player
  'now_playing': 'En cours de lecture',
  'playback_speed': 'Vitesse de lecture',
  'add_to_queue': 'Ajouter à la file',
  'add_to_favorites': 'Ajouter aux favoris',
  'remove_from_favorites': 'Retirer des favoris',
  'share': 'Partager',
  'download': 'Télécharger',
  'delete_download': 'Supprimer le téléchargement',

  // Profile Screen
  'settings': 'Paramètres',
  'language': 'Langue',
  'notifications': 'Notifications',
  'manage_downloads': 'Gérer les téléchargements',
  'about_app': 'À propos',
  'sign_out': 'Déconnexion',
  'dark_mode': 'Mode sombre',

  // Downloads
  'downloading': 'Téléchargement en cours...',
  'downloaded': 'Téléchargé',
  'download_complete': 'Téléchargement terminé',
  'download_failed': 'Échec du téléchargement',
  'delete_download_confirm': 'Voulez-vous supprimer ce téléchargement ?',
  'delete_all_downloads': 'Supprimer tous les téléchargements',
  'storage_used': 'Espace utilisé',

  // Common
  'cancel': 'Annuler',
  'confirm': 'Confirmer',
  'delete': 'Supprimer',
  'save': 'Enregistrer',
  'search': 'Rechercher',
  'filter': 'Filtrer',
  'refresh': 'Actualiser',
  'retry': 'Réessayer',
  'error': 'Erreur',
  'success': 'Succès',
  'loading': 'Chargement...',
  'no_data_available': 'Aucune donnée disponible',

  // Messages
  'added_to_favorites': 'Ajouté aux favoris',
  'removed_from_favorites': 'Retiré des favoris',
  'added_to_queue': 'Ajouté à la file',
  'no_internet_connection': 'Aucune connexion internet',
  'request_timeout': 'Délai d\'attente dépassé',
  'download_deleted': 'Téléchargement supprimé',
  'share_coming_soon': 'Fonctionnalité de partage bientôt disponible',
  'no_downloads_yet': 'Aucun téléchargement',
  'download_to_listen_offline':
      'Téléchargez des enseignements pour les écouter hors ligne',
  'start_listening': 'Commencez à écouter',
  'recent_teachings_appear_here': 'Vos enseignements récents apparaîtront ici',
  'no_live_streams_now': 'Aucun live en ce moment',
  'check_back_later': 'Revenez plus tard ou consultez les services programmés',
  'live_now': 'En direct',
  'scheduled': 'Programmé',
  'liveServices': 'Services en direct',
  'watch_in_real_time': 'Regarder les services en temps réel',
  'all': 'Tous',
  'confirm_delete_all_downloads':
      'Êtes-vous sûr de vouloir supprimer tous les téléchargements ? Cette action est irréversible.',
  'all_downloads_deleted': 'Tous les téléchargements ont été supprimés',
  'try_adjusting_search': 'Essayez d\'ajuster vos termes de recherche',
  'made_for_you': 'Pour Vous',
  'popular_this_week': 'Populaires Cette Semaine',
  'discover': 'Découvrir',
  'explore_teachings':
      'Explorer les enseignements et trouver votre inspiration',
  'browse_by_category': 'Parcourir par Catégorie',
  'close_player': 'Fermer le lecteur',
  'stop_playback_confirm': 'Voulez-vous arrêter la lecture ?',
  'filter_by_year': 'Filtrer par année',
  'filter_by_month': 'Filtrer par mois',
};

// ========================================
// TRADUCTIONS ANGLAIS
// ========================================
const Map<String, String> _englishTranslations = {
  // App
  'app_name': 'MyKOG',

  // Navigation
  'home': 'Home',
  'browse': 'Browse',
  'library': 'Library',
  'live': 'Live',
  'profile': 'Profile',

  // Home Screen
  'good_morning': 'Good Morning',
  'good_afternoon': 'Good Afternoon',
  'good_evening': 'Good Evening',
  'verse_of_the_day': 'Verse of the Day',
  'my_favorites': 'My Favorites',
  'recently_played': 'Recently Played',
  'new_releases': 'New Releases',

  // Browse Screen
  'categories': 'Categories',
  'popular': 'Popular',
  'recommended': 'Recommended',

  // Library Screen
  'all_teachings': 'All',
  'downloads': 'Downloads',
  'culte_d_impact': 'Impact Service',
  'culte_prophetique': 'Prophetic Service',
  'culte_d_enseignement': 'Teaching Service',
  'search_teachings': 'Search teachings, speakers...',
  'no_teachings_found': 'No teachings found',

  // Audio Player
  'now_playing': 'Now Playing',
  'playback_speed': 'Playback Speed',
  'add_to_queue': 'Add to Queue',
  'add_to_favorites': 'Add to Favorites',
  'remove_from_favorites': 'Remove from Favorites',
  'share': 'Share',
  'download': 'Download',
  'delete_download': 'Delete Download',

  // Profile Screen
  'settings': 'Settings',
  'language': 'Language',
  'notifications': 'Notifications',
  'manage_downloads': 'Manage Downloads',
  'about_app': 'About',
  'sign_out': 'Sign Out',
  'dark_mode': 'Dark Mode',

  // Downloads
  'downloading': 'Downloading...',
  'downloaded': 'Downloaded',
  'download_complete': 'Download complete',
  'download_failed': 'Download failed',
  'delete_download_confirm': 'Do you want to delete this download?',
  'delete_all_downloads': 'Delete all downloads',
  'storage_used': 'Storage used',

  // Common
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'delete': 'Delete',
  'save': 'Save',
  'search': 'Search',
  'filter': 'Filter',
  'refresh': 'Refresh',
  'retry': 'Retry',
  'error': 'Error',
  'success': 'Success',
  'loading': 'Loading...',
  'no_data_available': 'No data available',

  // Messages
  'added_to_favorites': 'Added to favorites',
  'removed_from_favorites': 'Removed from favorites',
  'added_to_queue': 'Added to queue',
  'no_internet_connection': 'No internet connection',
  'request_timeout': 'Request timeout',
  'download_deleted': 'Download deleted',
  'share_coming_soon': 'Share functionality coming soon',
  'no_downloads_yet': 'No downloads yet',
  'download_to_listen_offline': 'Download teachings to listen offline',
  'start_listening': 'Start listening',
  'recent_teachings_appear_here': 'Your recent teachings will appear here',
  'no_live_streams_now': 'No live streams at the moment',
  'check_back_later': 'Check back later or view scheduled services',
  'live_now': 'Live Now',
  'scheduled': 'Scheduled',
  'live_services': 'Live Services',
  'watch_in_real_time': 'Watch services in real-time',
  'all': 'All',
  'confirm_delete_all_downloads':
      'Are you sure you want to delete all downloads? This action is irreversible.',
  'all_downloads_deleted': 'All downloads have been deleted',
  'try_adjusting_search': 'Try adjusting your search terms',
  'made_for_you': 'Made For You',
  'popular_this_week': 'Popular This Week',
  'discover': 'Discover',
  'explore_teachings': 'Explore teachings and find your spiritual inspiration',
  'browse_by_category': 'Browse by Category',
  'close_player': 'Close Player',
  'stop_playback_confirm': 'Do you want to stop playback?',
  'filter_by_year': 'Filter by year',
  'filter_by_month': 'Filter by month',
};

// ========================================
// TRADUCTIONS ALLEMAND
// ========================================
const Map<String, String> _germanTranslations = {
  // App
  'app_name': 'MyKOG',

  // Navigation
  'home': 'Startseite',
  'browse': 'Durchsuchen',
  'library': 'Bibliothek',
  'live': 'Live',
  'profile': 'Profil',

  // Home Screen
  'good_morning': 'Guten Morgen',
  'good_afternoon': 'Guten Tag',
  'good_evening': 'Guten Abend',
  'verse_of_the_day': 'Vers des Tages',
  'my_favorites': 'Meine Favoriten',
  'recently_played': 'Kürzlich gespielt',
  'new_releases': 'Neuerscheinungen',

  // Browse Screen
  'categories': 'Kategorien',
  'popular': 'Beliebt',
  'recommended': 'Empfohlen',

  // Library Screen
  'all_teachings': 'Alle',
  'downloads': 'Downloads',
  'culte_d_impact': 'Impact-Gottesdienst',
  'culte_prophetique': 'Prophetischer Gottesdienst',
  'culte_d_enseignement': 'Lehr-Gottesdienst',
  'search_teachings': 'Lehren, Sprecher suchen...',
  'no_teachings_found': 'Keine Lehren gefunden',

  // Audio Player
  'now_playing': 'Jetzt läuft',
  'playback_speed': 'Wiedergabegeschwindigkeit',
  'add_to_queue': 'Zur Warteschlange hinzufügen',
  'add_to_favorites': 'Zu Favoriten hinzufügen',
  'remove_from_favorites': 'Aus Favoriten entfernen',
  'share': 'Teilen',
  'download': 'Herunterladen',
  'delete_download': 'Download löschen',

  // Profile Screen
  'settings': 'Einstellungen',
  'language': 'Sprache',
  'notifications': 'Benachrichtigungen',
  'manage_downloads': 'Downloads verwalten',
  'about_app': 'Über',
  'sign_out': 'Abmelden',
  'dark_mode': 'Dunkelmodus',

  // Downloads
  'downloading': 'Herunterladen...',
  'downloaded': 'Heruntergeladen',
  'download_complete': 'Download abgeschlossen',
  'download_failed': 'Download fehlgeschlagen',
  'delete_download_confirm': 'Möchten Sie diesen Download löschen?',
  'delete_all_downloads': 'Alle Downloads löschen',
  'storage_used': 'Speicher verwendet',

  // Common
  'cancel': 'Abbrechen',
  'confirm': 'Bestätigen',
  'delete': 'Löschen',
  'save': 'Speichern',
  'search': 'Suchen',
  'filter': 'Filtern',
  'refresh': 'Aktualisieren',
  'retry': 'Wiederholen',
  'error': 'Fehler',
  'success': 'Erfolg',
  'loading': 'Laden...',
  'no_data_available': 'Keine Daten verfügbar',

  // Messages
  'added_to_favorites': 'Zu Favoriten hinzugefügt',
  'removed_from_favorites': 'Aus Favoriten entfernt',
  'added_to_queue': 'Zur Warteschlange hinzugefügt',
  'no_internet_connection': 'Keine Internetverbindung',
  'request_timeout': 'Zeitüberschreitung der Anfrage',
  'download_deleted': 'Download gelöscht',
  'share_coming_soon': 'Teilen-Funktion kommt bald',
  'no_downloads_yet': 'Noch keine Downloads',
  'download_to_listen_offline':
      'Laden Sie Lehren herunter, um offline zu hören',
  'start_listening': 'Beginnen Sie zu hören',
  'recent_teachings_appear_here': 'Ihre kürzlichen Lehren erscheinen hier',
  'no_live_streams_now': 'Momentan keine Live-Streams',
  'check_back_later':
      'Schauen Sie später vorbei oder sehen Sie geplante Dienste',
  'live_now': 'Jetzt Live',
  'scheduled': 'Geplant',
  'live_services': 'Live-Gottesdienste',
  'watch_in_real_time': 'Gottesdienste in Echtzeit ansehen',
  'all': 'Alle',
  'confirm_delete_all_downloads':
      'Sind Sie sicher, dass Sie alle Downloads löschen möchten? Diese Aktion ist unwiderruflich.',
  'all_downloads_deleted': 'Alle Downloads wurden gelöscht',
  'try_adjusting_search': 'Versuchen Sie, Ihre Suchbegriffe anzupassen',
  'made_for_you': 'Für Sie',
  'popular_this_week': 'Beliebt Diese Woche',
  'discover': 'Entdecken',
  'explore_teachings':
      'Entdecken Sie Lehren und finden Sie Ihre spirituelle Inspiration',
  'browse_by_category': 'Nach Kategorie durchsuchen',
  'close_player': 'Player schließen',
  'stop_playback_confirm': 'Möchten Sie die Wiedergabe stoppen?',
  'filter_by_year': 'Nach Jahr filtern',
  'filter_by_month': 'Nach Monat filtern',
};

// ========================================
// TRADUCTIONS ESPAGNOL
// ========================================
const Map<String, String> _spanishTranslations = {
  // App
  'app_name': 'MyKOG',

  // Navigation
  'home': 'Inicio',
  'browse': 'Explorar',
  'library': 'Biblioteca',
  'live': 'En vivo',
  'profile': 'Perfil',

  // Home Screen
  'good_morning': 'Buenos días',
  'good_afternoon': 'Buenas tardes',
  'good_evening': 'Buenas noches',
  'verse_of_the_day': 'Versículo del día',
  'my_favorites': 'Mis Favoritos',
  'recently_played': 'Reproducido recientemente',
  'new_releases': 'Novedades',

  // Browse Screen
  'categories': 'Categorías',
  'popular': 'Popular',
  'recommended': 'Recomendado',

  // Library Screen
  'all_teachings': 'Todos',
  'downloads': 'Descargas',
  'culte_d_impact': 'Servicio de Impacto',
  'culte_prophetique': 'Servicio Profético',
  'culte_d_enseignement': 'Servicio de Enseñanza',
  'search_teachings': 'Buscar enseñanzas, oradores...',
  'no_teachings_found': 'No se encontraron enseñanzas',

  // Audio Player
  'now_playing': 'Reproduciendo ahora',
  'playback_speed': 'Velocidad de reproducción',
  'add_to_queue': 'Agregar a la cola',
  'add_to_favorites': 'Agregar a favoritos',
  'remove_from_favorites': 'Quitar de favoritos',
  'share': 'Compartir',
  'download': 'Descargar',
  'delete_download': 'Eliminar descarga',

  // Profile Screen
  'settings': 'Configuración',
  'language': 'Idioma',
  'notifications': 'Notificaciones',
  'manage_downloads': 'Gestionar descargas',
  'about_app': 'Acerca de',
  'sign_out': 'Cerrar sesión',
  'dark_mode': 'Modo oscuro',

  // Downloads
  'downloading': 'Descargando...',
  'downloaded': 'Descargado',
  'download_complete': 'Descarga completa',
  'download_failed': 'Descarga fallida',
  'delete_download_confirm': '¿Desea eliminar esta descarga?',
  'delete_all_downloads': 'Eliminar todas las descargas',
  'storage_used': 'Almacenamiento usado',

  // Common
  'cancel': 'Cancelar',
  'confirm': 'Confirmar',
  'delete': 'Eliminar',
  'save': 'Guardar',
  'search': 'Buscar',
  'filter': 'Filtrar',
  'refresh': 'Actualizar',
  'retry': 'Reintentar',
  'error': 'Error',
  'success': 'Éxito',
  'loading': 'Cargando...',
  'no_data_available': 'No hay datos disponibles',

  // Messages
  'added_to_favorites': 'Agregado a favoritos',
  'removed_from_favorites': 'Quitado de favoritos',
  'added_to_queue': 'Agregado a la cola',
  'no_internet_connection': 'Sin conexión a internet',
  'request_timeout': 'Tiempo de espera agotado',
  'download_deleted': 'Descarga eliminada',
  'share_coming_soon': 'Función de compartir próximamente',
  'no_downloads_yet': 'Aún no hay descargas',
  'download_to_listen_offline':
      'Descarga enseñanzas para escuchar sin conexión',
  'start_listening': 'Comienza a escuchar',
  'recent_teachings_appear_here': 'Tus enseñanzas recientes aparecerán aquí',
  'no_live_streams_now': 'No hay transmisiones en vivo en este momento',
  'check_back_later': 'Vuelve más tarde o mira los servicios programados',
  'live_now': 'En Vivo Ahora',
  'scheduled': 'Programado',
  'live_services': 'Servicios en Vivo',
  'watch_in_real_time': 'Ver servicios en tiempo real',
  'all': 'Todos',
  'confirm_delete_all_downloads':
      '¿Está seguro de que desea eliminar todas las descargas? Esta acción es irreversible.',
  'all_downloads_deleted': 'Todas las descargas han sido eliminadas',
  'try_adjusting_search': 'Intente ajustar sus términos de búsqueda',
  'made_for_you': 'Para Ti',
  'popular_this_week': 'Popular Esta Semana',
  'discover': 'Descubrir',
  'explore_teachings':
      'Explora enseñanzas y encuentra tu inspiración espiritual',
  'browse_by_category': 'Navegar por Categoría',
  'close_player': 'Cerrar reproductor',
  'stop_playback_confirm': '¿Desea detener la reproducción?',
  'filter_by_year': 'Filtrar por año',
  'filter_by_month': 'Filtrar por mes',
};
