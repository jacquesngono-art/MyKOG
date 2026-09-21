import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/providers/teaching_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/resolved_artwork_image.dart';

/// Écran de sélection multiple d'enseignements pour créer un package de favoris.
/// Aucune lecture audio — sert uniquement de classeur.
class FavoriteSelectionScreen extends StatefulWidget {
  const FavoriteSelectionScreen({super.key});

  @override
  State<FavoriteSelectionScreen> createState() =>
      _FavoriteSelectionScreenState();
}

class _FavoriteSelectionScreenState extends State<FavoriteSelectionScreen> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Teaching> teachings) {
    setState(() {
      if (_selectedIds.length == teachings.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(teachings.map((t) => t.id));
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyKOGColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Ajouter aux favoris',
          style: TextStyle(color: MyKOGColors.textPrimary, fontSize: 18.sp),
        ),
        content: Text(
          'Ajouter $count enseignement${count > 1 ? 's' : ''} à vos favoris ?',
          style: TextStyle(color: MyKOGColors.textSecondary, fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: MyKOGColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyKOGColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.addMultipleFavorites(_selectedIds.toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count enseignement${count > 1 ? 's' : ''} ajouté${count > 1 ? 's' : ''} aux favoris'),
          backgroundColor: MyKOGColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  List<Teaching> _filterTeachings(List<Teaching> all) {
    if (_searchQuery.isEmpty) return all;
    final q = _searchQuery.toLowerCase();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.speaker.toLowerCase().contains(q) ||
            (t.typeCulte?.toLowerCase() ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final teachingProvider = Provider.of<TeachingProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final existingFavIds = userProvider.favoriteTeachingIds;
    final allTeachings = teachingProvider.allTeachings;
    final filtered = _filterTeachings(allTeachings);

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      appBar: AppBar(
        backgroundColor: MyKOGColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: MyKOGColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nouveaux favoris',
          style: TextStyle(
            color: MyKOGColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          // Tout sélectionner / Tout désélectionner
          IconButton(
            onPressed: () => _selectAll(filtered),
            icon: Icon(
              _selectedIds.length == filtered.length
                  ? Icons.deselect
                  : Icons.select_all,
              color: MyKOGColors.accent,
            ),
            tooltip: _selectedIds.length == filtered.length
                ? 'Tout désélectionner'
                : 'Tout sélectionner',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: MyKOGColors.textPrimary, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'Rechercher un enseignement...',
                hintStyle: TextStyle(
                  color: MyKOGColors.textTertiary,
                  fontSize: 14.sp,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: MyKOGColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: MyKOGColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: MyKOGColors.secondary,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Compteur de sélection
          if (_selectedIds.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: MyKOGColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: MyKOGColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: MyKOGColors.accent, size: 20),
                  SizedBox(width: 8.w),
                  Text(
                    '${_selectedIds.length} sélectionné${_selectedIds.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: MyKOGColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIds.clear()),
                    child: Text(
                      'Effacer',
                      style: TextStyle(
                        color: MyKOGColors.textSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),

          // Liste des enseignements
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun enseignement trouvé',
                      style: TextStyle(
                        color: MyKOGColors.textSecondary,
                        fontSize: 15.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final teaching = filtered[index];
                      final isSelected = _selectedIds.contains(teaching.id);
                      final isAlreadyFavorite =
                          existingFavIds.contains(teaching.id);

                      return _SelectableTeachingTile(
                        teaching: teaching,
                        isSelected: isSelected,
                        isAlreadyFavorite: isAlreadyFavorite,
                        onTap: () => _toggleSelection(teaching.id),
                      )
                          .animate(delay: (index * 30).ms)
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.05, curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),

      // Bouton de validation flottant
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
              decoration: BoxDecoration(
                color: MyKOGColors.primaryDark,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(Icons.folder_special, color: Colors.black),
                    label: Text(
                      'Ajouter aux favoris (${_selectedIds.length})',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyKOGColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.3, curve: Curves.easeOutCubic)
          : null,
    );
  }
}

/// Tile d'enseignement sélectionnable (pas de lecture audio)
class _SelectableTeachingTile extends StatelessWidget {
  final Teaching teaching;
  final bool isSelected;
  final bool isAlreadyFavorite;
  final VoidCallback onTap;

  const _SelectableTeachingTile({
    required this.teaching,
    required this.isSelected,
    required this.isAlreadyFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? MyKOGColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? MyKOGColors.accent.withOpacity(0.5)
                : Colors.transparent,
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            // Checkbox animé
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28.w,
              height: 28.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? MyKOGColors.accent
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? MyKOGColors.accent
                      : MyKOGColors.textTertiary,
                  width: 2.w,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.black, size: 18.sp)
                  : null,
            ),

            SizedBox(width: 12.w),

            // Artwork
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: teaching.artworkUrl.startsWith('assets/')
                    ? Image.asset(
                        teaching.artworkUrl,
                        width: 56.w,
                        height: 56.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : ResolvedArtworkImage(
                        url: teaching.artworkUrl,
                        width: 56.w,
                        height: 56.w,
                        fit: BoxFit.cover,
                        placeholder: _buildPlaceholder(),
                      ),
              ),
            ),

            SizedBox(width: 12.w),

            // Titre + orateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teaching.title,
                    style: TextStyle(
                      color: isSelected
                          ? MyKOGColors.accent
                          : MyKOGColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${teaching.speaker}${teaching.typeCulte != null && teaching.typeCulte!.isNotEmpty ? ' • ${teaching.typeCulte}' : ''}',
                    style: TextStyle(
                      color: MyKOGColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Badge "déjà favori"
            if (isAlreadyFavorite && !isSelected)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.favorite, color: Colors.red, size: 16.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyKOGColors.accent.withValues(alpha: 0.3),
            MyKOGColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: MyKOGColors.accent,
          size: 24.w,
        ),
      ),
    );
  }
}
