import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/providers/teaching_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';
import 'package:MyKOG/widgets/favorites_folder_section.dart';
import 'package:MyKOG/widgets/teaching_tile.dart';
import 'package:MyKOG/widgets/recent_carousel.dart';
import 'package:MyKOG/widgets/badge_widget.dart';
import 'package:MyKOG/providers/badge_provider.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/api/calendar_api_service.dart';
import 'package:MyKOG/screens/calendar_screen.dart';
import 'package:MyKOG/services/connectivity_service.dart';
import 'package:MyKOG/services/download_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadData();
  }

  void _checkConnectivity() {
    _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
      }
    });
    setState(() {
      _isOffline = !_connectivityService.isConnected;
    });
  }

  Future<void> _loadData() async {
    // En mode offline, ne pas essayer de charger depuis l'API
    if (_isOffline) {
      return;
    }

    try {
      // ⚡ Rafraîchir le provider en arrière-plan (l'UI affiche le cache d'abord)
      if (mounted) {
        final teachingProvider =
            Provider.of<TeachingProvider>(context, listen: false);
        // Ne pas bloquer : lancer le refresh et laisser le provider notifier l'UI
        teachingProvider.refreshData().catchError((e) {
          debugPrint('Erreur rafraîchissement données: $e');
        });
      }
    } catch (e) {
      // Erreurs silencieuses en mode offline
    }
  }

  List<Teaching> _getDownloadedTeachings(List<Teaching> teachings) {
    return teachings.where((teaching) => 
      DownloadService.isDownloaded(teaching.id)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final teachingProvider = Provider.of<TeachingProvider>(context);
    final favoriteTeachings = _getFavoriteTeachings(context);

    // Filtrer les enseignements selon le mode offline
    List<Teaching> availableTeachings = teachingProvider.allTeachings;
    List<Teaching> availablePopular = teachingProvider.popularTeachings;
    
    if (_isOffline) {
      availableTeachings = _getDownloadedTeachings(availableTeachings);
      availablePopular = _getDownloadedTeachings(availablePopular);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: MyKOGColors.accent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              _buildHeroSection(context, theme, userProvider),

              // Recently Played Section
              if (userProvider.recentlyPlayedIds.isNotEmpty)
                RecentCarousel(
                  recentTeachings: userProvider.recentlyPlayedIds
                      .take(5)
                      .map((id) => teachingProvider.allTeachings.firstWhere(
                            (t) => t.id == id,
                            orElse: () => Teaching.empty(),
                          ))
                      .where((t) => !t.isEmpty)
                      .toList(),
                ),

              // Favorites Section — Portfolio folder-card style
              SizedBox(height: 32.h),
              FavoritesFolderSection(favorites: favoriteTeachings),

              // recently (remplace New Releases)
              if (availablePopular.isNotEmpty) ...[
                SizedBox(height: 32.h),
                _buildSectionHeader(
                    context, l10n.recentlyPlayed, Icons.favorite_border),
                SizedBox(height: 8.h),
                ...availablePopular.map(
                  (teaching) => TeachingTile(
                    teaching: teaching,
                    playlist: availablePopular,
                  )
                      .animate(
                          delay: (availablePopular
                                      .indexOf(teaching) *
                                  100)
                              .ms)
                      .slideX(curve: Curves.easeOutCubic)
                      .fadeIn(),
                ),
              ],

              // Message élégant si aucun contenu en mode offline
              if (_isOffline && availableTeachings.isEmpty && availablePopular.isEmpty && favoriteTeachings.isEmpty)
                _buildEmptyOfflineState(context, theme),

              SizedBox(height: 100.h), // Bottom padding for mini player
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, ThemeData theme, UserProvider userProvider) {
    final userName = userProvider.currentUser?.name ?? 'User';
    final greetingTime = _getGreetingTime();

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MyKOGColors.primaryDark,
            MyKOGColors.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône calendrier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Text(
                      greetingTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                    ).animate().fadeIn().slideY(),
                    SizedBox(height: 4.h),
                    Text(
                      userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(),
                  ],
                ),
              ),
              // Icône calendrier avec badge
              Consumer<BadgeProvider>(
                builder: (context, badgeProvider, child) {
                  return IconButton(
                    onPressed: () async {
                      // Marquer les événements calendrier comme vus
                      try {
                        final calendarApi = CalendarApiService();
                        final events = await calendarApi.getAllEvents();
                        final eventIds = events.map((e) => e.id).toList();
                        await BadgeService().markCalendarEventsAsSeen(eventIds);
                      } catch (e) {
                        debugPrint('Erreur marquage événements: $e');
                      }
                      
                      if (mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      }
                    },
                    icon: BadgeWidget(
                      showBadge: badgeProvider.hasNewCalendarEvents,
                      badgeColor: Colors.green,
                      badgeSize: 10,
                      child: Icon(
                        Icons.calendar_today,
                        color: MyKOGColors.accent,
                        size: 28.w,
                      ),
                    ),
                    tooltip: 'Calendrier',
                  ).animate(delay: 300.ms).fadeIn().scale();
                },
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Daily Verse Card
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: MyKOGColors.accent,
                      size: 20.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      AppLocalizations.of(context)?.verseOfTheDay ?? 'Verse of the Day',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: MyKOGColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  '"Nous Avons un puissant culte ce dimanche ! Rejoignez-nous pour une experience spirituelle transformative."',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textPrimary,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Communiquez !',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().scale(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Icon(
            icon,
            color: MyKOGColors.accent,
            size: 20.w,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyKOGColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _getGreetingTime() {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n?.goodMorning ?? 'Bonjour';
    } else if (hour < 17) {
      return l10n?.goodAfternoon ?? 'Bon après-midi';
    } else {
      return l10n?.goodEvening ?? 'Bonsoir';
    }
  }

  // Méthode pour récupérer les enseignements favoris depuis le localStorage
  List<Teaching> _getFavoriteTeachings(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teachingProvider =
        Provider.of<TeachingProvider>(context, listen: false);

    final favoriteIds = userProvider.favoriteTeachingIds;

    if (favoriteIds.isEmpty) {
      return [];
    }

    return favoriteIds
        .map((id) => teachingProvider.allTeachings.firstWhere(
              (t) => t.id == id,
              orElse: () => Teaching.empty(),
            ))
        .where((t) => !t.isEmpty)
        .toList();
  }

  Widget _buildEmptyOfflineState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 80.w,
            color: MyKOGColors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 24.h),
          Text(
            'Mode hors ligne',
            style: theme.textTheme.titleLarge?.copyWith(
              color: MyKOGColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Aucun contenu téléchargé disponible.\nTéléchargez des enseignements pour les écouter hors ligne.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MyKOGColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
