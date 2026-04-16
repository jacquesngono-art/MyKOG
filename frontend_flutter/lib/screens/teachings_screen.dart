import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/storage_service.dart';
import 'package:MyKOG/services/connectivity_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/modern_teaching_tile.dart';
import 'package:MyKOG/screens/text_resumes_screen.dart';
import 'package:MyKOG/screens/books_screen.dart';

class TeachingsScreen extends StatefulWidget {
  final String? selectedCategory;

  const TeachingsScreen({
    super.key,
    this.selectedCategory,
  });

  @override
  State<TeachingsScreen> createState() => _TeachingsScreenState();
}

class _TeachingsScreenState extends State<TeachingsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<Teaching> _allTeachings = [];
  List<Teaching> _filteredTeachings = [];
  List<Teaching> _downloadedTeachings = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String? _selectedYear;
  String? _selectedMonth;
  bool _isLoading = true;
  bool _isOffline = false;
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Listes pour les filtres
  List<String> _availableYears = [];
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 6, vsync: this); // 5 onglets enseignements + 1 textes résumés
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _selectedCategory = widget.selectedCategory;
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Teaching> teachings;
      List<String> categories;

      if (_isOffline) {
        // En mode offline, charger uniquement les contenus téléchargés
        final downloadedIds = DownloadService.getDownloadedTeachingIds();
        teachings = [];
        for (String id in downloadedIds) {
          final teaching = await TeachingService.getTeachingById(id);
          if (teaching != null) {
            teachings.add(teaching);
          }
        }
        categories = ['All'];
      } else {
        teachings = await TeachingService.getAllTeachings();
        categories = await TeachingService.getCategories();
      }

      // Load downloaded teachings
      final downloadedIds = DownloadService.getDownloadedTeachingIds();
      List<Teaching> downloaded = [];
      for (String id in downloadedIds) {
        final teaching = await TeachingService.getTeachingById(id);
        if (teaching != null) {
          downloaded.add(teaching);
        }
      }

      // Extraire les années et mois disponibles
      final years = teachings
          .map((t) => t.annee ?? DateTime.now().year.toString())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Plus récent en premier

      final months = teachings
          .map((t) => t.mois ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allTeachings = teachings;
        _downloadedTeachings = downloaded;
        _categories = ['All', ...categories];
        _availableYears = ['All', ...years];
        _availableMonths = ['All', ...months];
        _isLoading = false;
      });

      _filterTeachings();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllDataAndReload() async {
    try {
      // Afficher une confirmation
      final bool? shouldReset = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Réinitialiser les données'),
          content: const Text(
            'Êtes-vous sûr de vouloir effacer toutes les données locales et recharger depuis le backend ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Effacer'),
            ),
          ],
        ),
      );

      if (shouldReset != true) return;

      // Effacer les données
      await StorageService.clearAllTeachingsData();

      // Effacer le cache TeachingService
      TeachingService.clearCache();

      // Recharger les données
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Données réinitialisées et rechargées depuis le backend'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterTeachings() {
    List<Teaching> filtered = List.from(_allTeachings);

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered
          .where((teaching) => teaching.category == _selectedCategory)
          .toList();
    }

    // Filter by year
    if (_selectedYear != null && _selectedYear != 'All') {
      filtered = filtered
          .where((teaching) =>
              (teaching.annee ?? DateTime.now().year.toString()) ==
              _selectedYear)
          .toList();
    }

    // Filter by month
    if (_selectedMonth != null && _selectedMonth != 'All') {
      filtered = filtered
          .where((teaching) => teaching.mois == _selectedMonth)
          .toList();
    }

    // Filter by search query
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((teaching) =>
              teaching.title.toLowerCase().contains(query.toLowerCase()) ||
              teaching.speaker.toLowerCase().contains(query.toLowerCase()) ||
              teaching.category.toLowerCase().contains(query.toLowerCase()) ||
              (teaching.mois?.toLowerCase().contains(query.toLowerCase()) ??
                  false) ||
              (teaching.annee?.contains(query) ?? false) ||
              (teaching.description
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();
    }

    // Sort by newest first, then by featured/new status
    filtered.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      if (a.isNew && !b.isNew) return -1;
      if (!a.isNew && b.isNew) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    setState(() {
      _filteredTeachings = filtered;
    });
  }

  Future<void> _performSearch(String query) async {
    // Simulate search delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _filterTeachings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          // Header with search
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 60.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: MyKOGColors.primaryDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with refresh button and books icon
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.library,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu_book_outlined,
                          color: MyKOGColors.accent),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BooksScreen()),
                        );
                      },
                      tooltip: 'Livres',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.refresh, color: MyKOGColors.accent),
                      onPressed: _clearAllDataAndReload,
                      tooltip: 'Rafraîchir et effacer les données',
                    ),
                  ],
                ).animate().fadeIn().slideY(),
                SizedBox(height: 16.h),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: MyKOGColors.secondary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      color: MyKOGColors.accent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    labelColor: MyKOGColors.primaryDark,
                    unselectedLabelColor: MyKOGColors.textSecondary,
                    labelStyle:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                    unselectedLabelStyle: TextStyle(fontSize: 12.sp),
                    labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
                    tabs: [
                      Tab(text: l10n.allTeachings),
                      Tab(text: l10n.culteDImpact),
                      Tab(text: l10n.culteProphetique),
                      Tab(text: l10n.culteDEnseignement),
                      Tab(text: l10n.downloads),
                      const Tab(text: 'Textes Résumés'),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Search bar (only for All Teachings tab)
                if (_currentTabIndex == 0)
                  Container(
                    decoration: BoxDecoration(
                      color: MyKOGColors.secondary,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: MyKOGColors.accent.withValues(alpha: 0.2),
                        width: 1.w,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MyKOGColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.searchTeachings,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: MyKOGColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterTeachings();
                                },
                                icon: Icon(
                                  Icons.clear,
                                  color: MyKOGColors.textSecondary,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                      onChanged: (value) {
                        _performSearch(value);
                      },
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(),
              ],
            ),
          ),

          // Filters (only for All Teachings tab)
          if (_currentTabIndex == 0) ...[
            // Year filter
            if (_availableYears.isNotEmpty)
              Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _availableYears.length,
                  itemBuilder: (context, index) {
                    final year = _availableYears[index];
                    final isSelected = year == _selectedYear ||
                        (year == 'All' && _selectedYear == null);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedYear = year == 'All' ? null : year;
                        });
                        _filterTeachings();
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MyKOGColors.accent
                              : MyKOGColors.secondary,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? MyKOGColors.accent
                                : MyKOGColors.textSecondary.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14.w,
                              color: isSelected
                                  ? Colors.black
                                  : MyKOGColors.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              year,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Colors.black
                                    : MyKOGColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (index * 30).ms).fadeIn().scale();
                  },
                ),
              ),

            // Month filter
            if (_availableMonths.isNotEmpty)
              Container(
                height: 50.h,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = _availableMonths[index];
                    final isSelected = month == _selectedMonth ||
                        (month == 'All' && _selectedMonth == null);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMonth = month == 'All' ? null : month;
                        });
                        _filterTeachings();
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? MyKOGColors.accent.withOpacity(0.2)
                              : MyKOGColors.secondary,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSelected
                                ? MyKOGColors.accent
                                : MyKOGColors.textSecondary.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14.w,
                              color: isSelected
                                  ? MyKOGColors.accent
                                  : MyKOGColors.textSecondary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              month,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? MyKOGColors.accent
                                    : MyKOGColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (index * 30).ms).fadeIn().scale();
                  },
                ),
              ),
          ],

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeachingsList(), // Tous
                _buildTeachingsListByType('Culte d\'Impact'), // Culte d'Impact
                _buildTeachingsListByType(
                    'Culte Prophétique'), // Culte Prophétique
                _buildTeachingsListByType(
                    'Culte d\'Enseignement'), // Culte d'Enseignement
                _buildDownloadsList(), // Téléchargés
                const TextResumesScreen(), // Textes Résumés
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingsList() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MyKOGColors.accent),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_filteredTeachings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.w,
              color: MyKOGColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noTeachingsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchController.text.isNotEmpty
                  ? l10n.translate('try_adjusting_search')
                  : l10n.checkBackLater,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: MyKOGColors.accent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredTeachings.length + 1, // +1 for bottom padding
        itemBuilder: (context, index) {
          if (index == _filteredTeachings.length) {
            return const SizedBox(
                height: 100); // Bottom padding for mini player
          }

          final teaching = _filteredTeachings[index];
          return ModernTeachingTile(
            teaching: teaching,
            playlist: _filteredTeachings,
          )
              .animate(delay: (index * 50).ms)
              .slideX(curve: Curves.easeOutCubic)
              .fadeIn();
        },
      ),
    );
  }

  Widget _buildTeachingsListByType(String typeCulte) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MyKOGColors.accent),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    // Filtrer les enseignements par type de culte
    final teachingsByType = _allTeachings
        .where((teaching) =>
            teaching.typeCulte != null &&
            teaching.typeCulte!.toLowerCase() == typeCulte.toLowerCase())
        .toList();

    // Trier par date de publication
    teachingsByType.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      if (a.isNew && !b.isNew) return -1;
      if (!a.isNew && b.isNew) return 1;
      return b.publishedAt.compareTo(a.publishedAt);
    });

    if (teachingsByType.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church,
              size: 64,
              color: MyKOGColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noTeachingsFound,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.noDataAvailable} - $typeCulte',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: MyKOGColors.accent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: teachingsByType.length + 1,
        itemBuilder: (context, index) {
          if (index == teachingsByType.length) {
            return const SizedBox(height: 100);
          }

          final teaching = teachingsByType[index];
          return ModernTeachingTile(
            teaching: teaching,
            playlist: teachingsByType,
          )
              .animate(delay: (index * 50).ms)
              .slideX(curve: Curves.easeOutCubic)
              .fadeIn();
        },
      ),
    );
  }

  Widget _buildDownloadsList() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MyKOGColors.accent),
            const SizedBox(height: 16),
            Text(
              l10n.loading,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_downloadedTeachings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download,
              size: 64,
              color: MyKOGColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDownloadsYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.downloadToListenOffline,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MyKOGColors.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: MyKOGColors.accent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _downloadedTeachings.length + 1,
        itemBuilder: (context, index) {
          if (index == _downloadedTeachings.length) {
            return const SizedBox(height: 100);
          }

          final teaching = _downloadedTeachings[index];
          return ModernTeachingTile(
            teaching: teaching,
            playlist: _downloadedTeachings,
          )
              .animate(delay: (index * 50).ms)
              .slideX(curve: Curves.easeOutCubic)
              .fadeIn();
        },
      ),
    );
  }
}
