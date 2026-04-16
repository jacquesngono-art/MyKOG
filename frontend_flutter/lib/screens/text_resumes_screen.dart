import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:MyKOG/models/text_resume.dart';
import 'package:MyKOG/api/text_resume_api_service.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/screens/text_resume_viewer_screen.dart';

enum ViewMode { grid, card, preview }

enum SortOption { newest, oldest, title, speaker, viewCount }

class TextResumesScreen extends StatefulWidget {
  const TextResumesScreen({super.key});

  @override
  State<TextResumesScreen> createState() => _TextResumesScreenState();
}

class _TextResumesScreenState extends State<TextResumesScreen> {
  final TextResumeApiService _apiService = TextResumeApiService();
  final TextEditingController _searchController = TextEditingController();

  List<TextResume> _allTextResumes = [];
  List<TextResume> _filteredTextResumes = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedTypeCulte;
  ViewMode _viewMode = ViewMode.grid;
  SortOption _sortOption = SortOption.newest;
  bool _isLoading = true;

  List<String> _availableYears = [];
  List<String> _availableMonths = [];
  List<String> _availableTypeCulte = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final textResumes = await _apiService.getAllTextResumes(
        sortBy: _getSortBy(),
        order: _getOrder(),
      );

      // Extraire les catégories, années, mois et types de culte
      final categories = textResumes.map((tr) => tr.category).toSet().toList()
        ..sort();

      final years = textResumes
          .map((tr) => tr.annee ?? DateTime.now().year.toString())
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final months = textResumes
          .map((tr) => tr.mois ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final typeCulte = textResumes
          .map((tr) => tr.typeCulte ?? '')
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allTextResumes = textResumes;
        _categories = ['All', ...categories];
        _availableYears = ['All', ...years];
        _availableMonths = ['All', ...months];
        _availableTypeCulte = ['All', ...typeCulte];
        _isLoading = false;
      });

      _filterTextResumes();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSortBy() {
    switch (_sortOption) {
      case SortOption.title:
        return 'title';
      case SortOption.speaker:
        return 'speaker';
      case SortOption.viewCount:
        return 'viewCount';
      default:
        return 'publishedAt';
    }
  }

  String _getOrder() {
    return _sortOption == SortOption.oldest ? 'asc' : 'desc';
  }

  void _filterTextResumes() {
    List<TextResume> filtered = List.from(_allTextResumes);

    // Filtrer par catégorie
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered =
          filtered.where((tr) => tr.category == _selectedCategory).toList();
    }

    // Filtrer par année
    if (_selectedYear != null && _selectedYear != 'All') {
      filtered = filtered
          .where((tr) =>
              (tr.annee ?? DateTime.now().year.toString()) == _selectedYear)
          .toList();
    }

    // Filtrer par mois
    if (_selectedMonth != null && _selectedMonth != 'All') {
      filtered = filtered.where((tr) => tr.mois == _selectedMonth).toList();
    }

    // Filtrer par type de culte
    if (_selectedTypeCulte != null && _selectedTypeCulte != 'All') {
      filtered =
          filtered.where((tr) => tr.typeCulte == _selectedTypeCulte).toList();
    }

    // Filtrer par recherche
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((tr) =>
              tr.title.toLowerCase().contains(query.toLowerCase()) ||
              tr.speaker.toLowerCase().contains(query.toLowerCase()) ||
              tr.category.toLowerCase().contains(query.toLowerCase()) ||
              (tr.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    }

    setState(() {
      _filteredTextResumes = filtered;
    });
  }

  void _onSortChanged(SortOption? option) {
    if (option != null) {
      setState(() {
        _sortOption = option;
      });
      _loadData();
    }
  }

  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: Column(
        children: [
          // Header avec recherche et contrôles
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Textes Résumés',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Boutons de vue
                    IconButton(
                      icon: Icon(
                        Icons.grid_view,
                        color: _viewMode == ViewMode.grid
                            ? MyKOGColors.accent
                            : MyKOGColors.textSecondary,
                      ),
                      onPressed: () => _onViewModeChanged(ViewMode.grid),
                      tooltip: 'Grille',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_module,
                        color: _viewMode == ViewMode.card
                            ? MyKOGColors.accent
                            : MyKOGColors.textSecondary,
                      ),
                      onPressed: () => _onViewModeChanged(ViewMode.card),
                      tooltip: 'Cartes',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.list,
                        color: _viewMode == ViewMode.preview
                            ? MyKOGColors.accent
                            : MyKOGColors.textSecondary,
                      ),
                      onPressed: () => _onViewModeChanged(ViewMode.preview),
                      tooltip: 'Liste',
                    ),
                    // Menu de tri
                    PopupMenuButton<SortOption>(
                      icon: const Icon(Icons.sort,
                          color: MyKOGColors.textPrimary),
                      onSelected: _onSortChanged,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: SortOption.newest,
                          child: Text('Plus récent'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.oldest,
                          child: Text('Plus ancien'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.title,
                          child: Text('Titre (A-Z)'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.speaker,
                          child: Text('Orateur (A-Z)'),
                        ),
                        const PopupMenuItem(
                          value: SortOption.viewCount,
                          child: Text('Plus consulté'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barre de recherche
                Container(
                  decoration: BoxDecoration(
                    color: MyKOGColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: MyKOGColors.accent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: MyKOGColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _filterTextResumes();
                              },
                              icon: const Icon(
                                Icons.clear,
                                color: MyKOGColors.textSecondary,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => _filterTextResumes(),
                  ),
                ),
              ],
            ),
          ),

          // Filtres
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Catégorie', _selectedCategory, _categories,
                    (value) {
                  setState(
                      () => _selectedCategory = value == 'All' ? null : value);
                  _filterTextResumes();
                }),
                if (_availableYears.isNotEmpty)
                  _buildFilterChip('Année', _selectedYear, _availableYears,
                      (value) {
                    setState(
                        () => _selectedYear = value == 'All' ? null : value);
                    _filterTextResumes();
                  }),
                if (_availableMonths.isNotEmpty)
                  _buildFilterChip('Mois', _selectedMonth, _availableMonths,
                      (value) {
                    setState(
                        () => _selectedMonth = value == 'All' ? null : value);
                    _filterTextResumes();
                  }),
                if (_availableTypeCulte.isNotEmpty)
                  _buildFilterChip(
                      'Type', _selectedTypeCulte, _availableTypeCulte, (value) {
                    setState(() =>
                        _selectedTypeCulte = value == 'All' ? null : value);
                    _filterTextResumes();
                  }),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: MyKOGColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: MyKOGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredTextResumes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: MyKOGColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun texte résumé trouvé',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: MyKOGColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: MyKOGColors.accent,
                        child: _buildContent(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selected,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected != null ? MyKOGColors.accent : MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? MyKOGColors.accent
                : MyKOGColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${selected ?? 'All'}',
              style: TextStyle(
                color:
                    selected != null ? Colors.black : MyKOGColors.textSecondary,
                fontWeight:
                    selected != null ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color:
                  selected != null ? Colors.black : MyKOGColors.textSecondary,
            ),
          ],
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.card:
        return _buildCardView();
      case ViewMode.preview:
        return _buildPreviewView();
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredTextResumes.length,
      itemBuilder: (context, index) {
        final textResume = _filteredTextResumes[index];
        return _buildGridCard(textResume, index);
      },
    );
  }

  Widget _buildGridCard(TextResume textResume, int index) {
    final widget = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TextResumeViewerScreen(textResume: textResume),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de couverture
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: textResume.coverImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: textResume.coverImageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: MyKOGColors.secondary,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: MyKOGColors.accent,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: MyKOGColors.secondary,
                          child: const Icon(
                            Icons.description,
                            size: 48,
                            color: MyKOGColors.textSecondary,
                          ),
                        ),
                      )
                    : Container(
                        color: MyKOGColors.secondary,
                        child: const Icon(
                          Icons.description,
                          size: 48,
                          color: MyKOGColors.textSecondary,
                        ),
                      ),
              ),
            ),
            // Informations
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      textResume.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: MyKOGColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        textResume.speaker,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 12,
                          color: MyKOGColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${textResume.viewCount}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textSecondary,
                                    fontSize: 10,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          textResume.fileSizeText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textSecondary,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return widget.animate(delay: (index * 50).ms).fadeIn().scale();
  }

  Widget _buildCardView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTextResumes.length,
      itemBuilder: (context, index) {
        final textResume = _filteredTextResumes[index];
        return _buildCardItem(textResume, index);
      },
    );
  }

  Widget _buildCardItem(TextResume textResume, int index) {
    final widget = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TextResumeViewerScreen(textResume: textResume),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: textResume.coverImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: textResume.coverImageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 120,
                        height: 120,
                        color: MyKOGColors.secondary,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: MyKOGColors.accent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 120,
                        height: 120,
                        color: MyKOGColors.secondary,
                        child: const Icon(
                          Icons.description,
                          size: 48,
                          color: MyKOGColors.textSecondary,
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 120,
                      color: MyKOGColors.secondary,
                      child: const Icon(
                        Icons.description,
                        size: 48,
                        color: MyKOGColors.textSecondary,
                      ),
                    ),
            ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textResume.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: MyKOGColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textResume.speaker,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MyKOGColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: MyKOGColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${textResume.viewCount}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          textResume.fileSizeText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: MyKOGColors.textSecondary,
            ),
          ],
        ),
      ),
    );
    return widget.animate(delay: (index * 50).ms).fadeIn().slideX();
  }

  Widget _buildPreviewView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTextResumes.length,
      itemBuilder: (context, index) {
        final textResume = _filteredTextResumes[index];
        return _buildPreviewItem(textResume, index);
      },
    );
  }

  Widget _buildPreviewItem(TextResume textResume, int index) {
    final widget = GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TextResumeViewerScreen(textResume: textResume),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    textResume.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: MyKOGColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              textResume.speaker,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            if (textResume.description != null &&
                textResume.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                textResume.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MyKOGColors.textTertiary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 14,
                  color: MyKOGColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${textResume.viewCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                ),
                const SizedBox(width: 16),
                Text(
                  textResume.fileSizeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                ),
                const Spacer(),
                Text(
                  textResume.moisAnneeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return widget.animate(delay: (index * 30).ms).fadeIn().slideX();
  }
}
