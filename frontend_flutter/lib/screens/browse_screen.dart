import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';
import 'package:MyKOG/widgets/image_carousel.dart';
import 'package:MyKOG/screens/teachings_screen.dart';
import 'package:MyKOG/services/connectivity_service.dart';
import 'package:MyKOG/services/download_service.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<String> _categories = [];
  List<Teaching> _popularTeachings = [];
  List<Teaching> _recommendedTeachings = [];
  bool _isLoading = true;
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
        _loadData();
      }
    });
    setState(() {
      _isOffline = !_connectivityService.isConnected;
    });
  }

  Future<void> _loadData() async {
    if (_isOffline) {
      // En mode offline, charger uniquement les contenus téléchargés
      final allTeachings = await TeachingService.getAllTeachings();
      final downloaded = allTeachings.where((t) => 
        DownloadService.isDownloaded(t.id)
      ).toList();
      
      setState(() {
        _popularTeachings = downloaded.take(6).toList();
        _recommendedTeachings = downloaded.take(6).toList();
        _isLoading = false;
      });
      return;
    }

    try {
      final categories = await TeachingService.getCategories();
      final popular = await TeachingService.getPopularTeachings(limit: 6);
      final recommended = await TeachingService.getRecommendedTeachings();

      // Mélanger aléatoirement les recommandations
      recommended.shuffle();
      popular.shuffle();

      // Vérifier les nouveaux enseignements pour le badge (publiés dans les 2 derniers jours)
      try {
        final allTeachings = await TeachingService.getAllTeachings();
        final teachingIds = allTeachings.map((t) => t.id).toList();
        final teachingPublishedDates = {
          for (var t in allTeachings) t.id: t.publishedAt
        };
        await BadgeService().checkNewTeachings(teachingIds, teachingPublishedDates);
      } catch (e) {
        // Erreur silencieuse
      }

      setState(() {
        _categories = categories;
        _popularTeachings = popular.take(6).toList();
        _recommendedTeachings = recommended.take(6).toList();
        _isLoading = false;
      });
    } catch (e) {
      // En cas d'erreur, utiliser les contenus téléchargés
      final allTeachings = await TeachingService.getAllTeachings();
      final downloaded = allTeachings.where((t) => 
        DownloadService.isDownloaded(t.id)
      ).toList();
      
      setState(() {
        _popularTeachings = downloaded.take(6).toList();
        _recommendedTeachings = downloaded.take(6).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: MyKOGColors.accent),
              SizedBox(height: 16.h),
              Text(
                l10n.loading,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MyKOGColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
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
              // Header
              _buildHeader(context, theme),

              // Carrousel d'images Cloudinary
              const ImageCarousel(),

              // Made For You Section
              if (_recommendedTeachings.isNotEmpty) ...[
                SizedBox(height: 32.h),
                _buildSectionHeader(
                    context, l10n.madeForYou, Icons.person_outline),
                SizedBox(height: 16.h),
                _buildHorizontalTeachingsList(_recommendedTeachings),
              ],

              // Popular This Week
              if (_popularTeachings.isNotEmpty) ...[
                SizedBox(height: 32.h),
                _buildSectionHeader(
                    context, l10n.popularThisWeek, Icons.trending_up),
                SizedBox(height: 16.h),
                _buildHorizontalTeachingsList(_popularTeachings),
              ],

              // Browse by Category
              SizedBox(height: 32.h),
              _buildSectionHeader(
                  context, l10n.browseByCategory, Icons.category),
              SizedBox(height: 16.h),
              _buildCategoriesGrid(),

              SizedBox(height: 100.h), // Bottom padding for mini player
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyKOGColors.primaryDark,
            MyKOGColors.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.discover,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: MyKOGColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideY(),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context)!.exploreTeachings,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: MyKOGColors.textSecondary,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(),
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

  Widget _buildHorizontalTeachingsList(List<Teaching> teachings) {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: teachings.length,
        itemBuilder: (context, index) {
          final teaching = teachings[index];
          return _buildTeachingCard(teaching, index);
        },
      ),
    );
  }

  Widget _buildTeachingCard(Teaching teaching, int index) {
    return GestureDetector(
      onTap: () => _playTeaching(context, teaching),
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      teaching.artworkUrl.startsWith('assets/')
                          ? Image.asset(
                              teaching.artworkUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: MyKOGColors.secondary,
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32.w,
                                  ),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: teaching.artworkUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: MyKOGColors.secondary,
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32.w,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: MyKOGColors.secondary,
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: MyKOGColors.accent,
                                    size: 32.w,
                                  ),
                                ),
                              ),
                            ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      // Play count
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${teaching.playCount}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              teaching.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: MyKOGColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 2.h),
            Text(
              teaching.speaker,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn()
        .slideX(curve: Curves.easeOutCubic);
  }

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 2.5,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category, index);
        },
      ),
    );
  }

  Widget _buildCategoryCard(String category, int index) {
    final colors = [
      MyKOGColors.accent,
      MyKOGColors.success,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => _navigateToTeachings(context, category: category),
      child: GlassCard(
        padding: EdgeInsets.all(16.w),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.w,
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Colors.white,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().scale();
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'foi':
        return Icons.favorite;
      case 'priere':
        return Icons.back_hand;
      case 'amour':
        return Icons.volunteer_activism;
      case 'joie':
        return Icons.light_mode;
      case 'fondation':
        return Icons.foundation;
      case 'principe divin':
        return Icons.celebration;
      default:
        return Icons.library_books;
    }
  }

  void _navigateToTeachings(BuildContext context, {String? category}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TeachingsScreen(selectedCategory: category),
      ),
    );
  }

  /// Lancer la lecture d'un enseignement directement
  void _playTeaching(BuildContext context, Teaching teaching) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
    
    // Créer une playlist avec les enseignements de la même section
    List<Teaching> playlist = [];
    
    // Déterminer quelle liste utiliser
    if (_recommendedTeachings.contains(teaching)) {
      playlist = _recommendedTeachings;
    } else if (_popularTeachings.contains(teaching)) {
      playlist = _popularTeachings;
    } else {
      playlist = [teaching];
    }
    
    // Lancer la lecture
    audioProvider.playTeaching(teaching, playlist: playlist);
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('▶️ ${teaching.title}'),
        backgroundColor: MyKOGColors.accent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
