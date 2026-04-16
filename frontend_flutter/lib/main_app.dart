import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/services/storage_service.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';

import 'package:MyKOG/screens/home_screen.dart';
import 'package:MyKOG/screens/browse_screen.dart';
import 'package:MyKOG/screens/teachings_screen.dart';
import 'package:MyKOG/screens/live_screen.dart';
import 'package:MyKOG/screens/profile_screen.dart';

import 'package:MyKOG/widgets/mini_player_improved.dart';
import 'package:MyKOG/widgets/badge_widget.dart';
import 'package:MyKOG/providers/badge_provider.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/api/calendar_api_service.dart';
import 'package:MyKOG/services/alarm_service.dart';
import 'package:MyKOG/theme.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isInitialized = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _textController;

  static const List<String> _loadingParagraphs = [
    'Conduire le peuple\ndans sa véritable repentance',
    'Révéler les mystères\ndu royaume',
    'Accomplir sa destinée',
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const BrowseScreen(),
    const LiveScreen(),
    const TeachingsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    try {
      // ⚡ Phase 1 : Initialisations CRITIQUES uniquement (rapide)
      await StorageService.init();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final audioProvider =
          Provider.of<AudioPlayerProvider>(context, listen: false);

      // ⚡ Paralléliser user + audio + downloads (indépendants)
      await Future.wait([
        userProvider.initialize(),
        audioProvider.initialize(),
        DownloadService.initialize(),
      ]);

      // ⚡ Temps minimum réduit : 2 secondes au lieu de 12
      final elapsedTime = DateTime.now().difference(startTime);
      const minimumDuration = Duration(seconds: 2);

      if (elapsedTime < minimumDuration) {
        final remainingTime = minimumDuration - elapsedTime;
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      _fadeController.forward();

      // ⚡ Phase 2 : Services NON-CRITIQUES en arrière-plan (après affichage UI)
      _initBackgroundServices();
    } catch (e) {
      debugPrint("Initialization failed: $e");

      // En cas d'erreur, afficher l'app quand même après 1 seconde
      final elapsedTime = DateTime.now().difference(startTime);
      const minimumDuration = Duration(seconds: 1);

      if (elapsedTime < minimumDuration) {
        final remainingTime = minimumDuration - elapsedTime;
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Services non-critiques chargés APRÈS l'affichage de l'interface
  void _initBackgroundServices() {
    Future.microtask(() async {
      try {
        await BadgeService().initialize();
      } catch (e) {
        debugPrint('Erreur initialisation badges: $e');
      }

      try {
        await TeachingService.initializeSampleData();
      } catch (e) {
        debugPrint('Erreur initialisation sample data: $e');
      }

      // Vérifier les nouveaux contenus pour les badges
      _checkForNewContent();

      // Synchroniser les alarmes en arrière-plan
      try {
        await AlarmService().syncAlarms();
      } catch (e) {
        debugPrint('Erreur synchronisation alarmes: $e');
      }
    });
  }

  Future<void> _checkForNewContent() async {
    try {
      final badgeService = BadgeService();

      // Vérifier les nouveaux enseignements (publiés dans les 2 derniers jours)
      final teachings = await TeachingService.getAllTeachings();
      final teachingIds = teachings.map((t) => t.id).toList();
      final teachingPublishedDates = {
        for (var t in teachings) t.id: t.publishedAt
      };
      await badgeService.checkNewTeachings(teachingIds, teachingPublishedDates);

      // Vérifier les nouveaux événements calendrier
      final calendarApi = CalendarApiService();
      final events = await calendarApi.getAllEvents();
      final eventIds = events.map((e) => e.id).toList();
      await badgeService.checkNewCalendarEvents(eventIds);
    } catch (e) {
      debugPrint('Erreur vérification nouveaux contenus: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen(context);
    }
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 70.h,
              child: const MiniPlayerImproved(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _buildLoadingLogo(),
            SizedBox(height: 40.h),
            _buildVerticalWordSlider(),
            const Spacer(),
            _buildLoadingBar(),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/kog.png',
          width: 100.w,
          height: 100.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 20.h),
        Text(
          'MyKOG',
          style: GoogleFonts.poppins(
            color: MyKOGColors.textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalWordSlider() {
    return SizedBox(
      height: 120.h,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _textController,
        builder: (context, child) {
          final totalParagraphs = _loadingParagraphs.length;
          final segmentDuration = 1.0 / totalParagraphs;
          final progress = _textController.value;

          int currentIndex = (progress / segmentDuration).floor();
          currentIndex = currentIndex.clamp(0, totalParagraphs - 1);

          double fadeProgress =
              (progress - (currentIndex * segmentDuration)) / segmentDuration;
          fadeProgress = fadeProgress.clamp(0.0, 1.0);

          final nextIndex = (currentIndex + 1) % totalParagraphs;

          final currentOpacity =
              fadeProgress < 0.5 ? fadeProgress * 2 : (1.0 - fadeProgress) * 2;
          final nextOpacity =
              fadeProgress >= 0.5 ? (fadeProgress - 0.5) * 2 : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: currentOpacity.clamp(0.0, 1.0),
                child: Text(
                  _loadingParagraphs[currentIndex],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: MyKOGColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
              Opacity(
                opacity: nextOpacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 20.h * (1 - nextOpacity)),
                  child: Text(
                    _loadingParagraphs[nextIndex],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: MyKOGColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingBar() {
    return SizedBox(
      width: 160.w,
      child: Column(
        children: [
          SizedBox(
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: MyKOGColors.primaryDark,
        border: Border(
          top: BorderSide(
            color: MyKOGColors.accent.withValues(alpha: 0.2),
            width: 0.5.w,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.explore, 'Browse')),
              Expanded(child: _buildNavItem(2, Icons.live_tv, 'Live')),
              Expanded(child: _buildNavItem(3, Icons.library_music, 'Library')),
              Expanded(child: _buildNavItem(4, Icons.person, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String labelKey) {
    final bool isSelected = _currentIndex == index;
    final l10n = AppLocalizations.of(context);

    // Map des labels traduits
    final labels = [
      l10n?.home ?? 'Home',
      l10n?.browse ?? 'Browse',
      l10n?.live ?? 'Live',
      l10n?.library ?? 'Library',
      l10n?.profile ?? 'Profile',
    ];

    return Consumer<BadgeProvider>(
      builder: (context, badgeProvider, child) {
        // Déterminer si ce bouton doit afficher un badge
        bool showBadge = false;
        if (index == 1) {
          // Badge sur Browse pour les nouveaux enseignements
          showBadge = badgeProvider.hasNewTeachings;
        }

        return GestureDetector(
          onTap: () async {
            setState(() => _currentIndex = index);
            HapticFeedback.lightImpact();

            // Marquer comme vus quand on clique sur l'icône
            if (index == 1) {
              // Marquer les enseignements comme vus
              try {
                final teachings = await TeachingService.getAllTeachings();
                final teachingIds = teachings.map((t) => t.id).toList();
                await BadgeService().markTeachingsAsSeen(teachingIds);
              } catch (e) {
                debugPrint('Erreur marquage enseignements: $e');
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? MyKOGColors.accent.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BadgeWidget(
                  showBadge: showBadge,
                  badgeColor: Colors.green,
                  badgeSize: 10.w,
                  child: Icon(
                    icon,
                    color: isSelected
                        ? MyKOGColors.accent
                        : MyKOGColors.textSecondary,
                    size: 22.w,
                  ),
                ),
                SizedBox(height: 2.h),
                Flexible(
                  child: Text(
                    labels[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? MyKOGColors.accent
                              : MyKOGColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 10.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
