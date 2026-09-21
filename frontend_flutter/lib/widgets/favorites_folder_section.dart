import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/screens/favorite_selection_screen.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/widgets/resolved_artwork_image.dart';

// ─── Design tokens (Portfolio-inspired) ───────────────────────────────────────
final _kCardWidth      = 200.0.w;
final _kBackHeight     = 200.0.w;
final _kFrontHeight    = 90.0.h;
final _kCardHeight     = _kBackHeight;
final _kRadius         = 20.0.r;
const _kBorderColor    = Color(0x0FFFFFFF);
const _kBackBg         = Color(0xFF1E1E1E);
const _kFrontBg        = Color(0xD91A1A1A);

/// Full favorites section — header + horizontal scroll of folder-cards.
class FavoritesFolderSection extends StatelessWidget {
  final List<Teaching> favorites;

  const FavoritesFolderSection({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.favorite, color: MyKOGColors.accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                l10n.myFavorites,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyKOGColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              if (favorites.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: MyKOGColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${favorites.length}',
                    style: TextStyle(
                      color: MyKOGColors.accent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1),

        SizedBox(height: 14.h),

        // ── Horizontal card list ────────────────────────────────────────────
        SizedBox(
          height: _kCardHeight,
          child: favorites.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const BouncingScrollPhysics(),
                  // +1 for the "New Favorite" slot at the end
                  itemCount: favorites.length + 1,
                  itemBuilder: (context, index) {
                    if (index == favorites.length) {
                      return _NewFavoriteSlot(
                        onTap: () => _navigateToTeachings(context),
                      )
                          .animate(delay: (index * 60).ms)
                          .fadeIn(duration: 350.ms)
                          .slideX(begin: 0.15, curve: Curves.easeOutCubic);
                    }
                    return _FavoriteFolderCard(
                      teaching: favorites[index],
                      allFavorites: favorites,
                      index: index,
                    )
                        .animate(delay: (index * 60).ms)
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.15, curve: Curves.easeOutCubic);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      physics: const BouncingScrollPhysics(),
      children: [
        _NewFavoriteSlot(
          onTap: () => _navigateToTeachings(context),
        ).animate().fadeIn(duration: 400.ms),
      ],
    );
  }

  void _navigateToTeachings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const FavoriteSelectionScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─── Individual folder card (Portfolio DefaultProject-inspired) ───────────────
class _FavoriteFolderCard extends StatefulWidget {
  final Teaching teaching;
  final List<Teaching> allFavorites;
  final int index;

  const _FavoriteFolderCard({
    required this.teaching,
    required this.allFavorites,
    required this.index,
  });

  @override
  State<_FavoriteFolderCard> createState() => _FavoriteFolderCardState();
}

class _FavoriteFolderCardState extends State<_FavoriteFolderCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _isEditing = false;
  bool _editCooldown = false;
  late TextEditingController _editController;
  late AnimationController _hoverCtrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.teaching.title);
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _confirmEdit();
      }
    });
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    _editController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Date helper ────────────────────────────────────────────────────────────
  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 30) return 'Il y a ${diff}j';
    final months = (diff / 30).floor();
    return 'Il y a ${months}mo';
  }

  // ── Interactions ───────────────────────────────────────────────────────────
  void _onTap(BuildContext context) {
    final audio = Provider.of<AudioPlayerProvider>(context, listen: false);
    audio.playTeaching(widget.teaching, playlist: widget.allFavorites);
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FavoriteActionSheet(
        teaching: widget.teaching,
        onRename: _startEdit,
      ),
    );
  }

  // ── Edition mode ───────────────────────────────────────────────────────────
  void _startEdit() {
    Navigator.pop(context);
    setState(() {
      _isEditing = true;
      _editController.text = widget.teaching.title;
    });
    // Demander le focus après la reconstruction du widget
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _confirmEdit() async {
    final newTitle = _editController.text.trim();
    
    // Sortir du mode édition immédiatement
    setState(() {
      _isEditing = false;
      _editCooldown = true;
    });
    
    if (newTitle.isNotEmpty && newTitle != widget.teaching.title) {
      try {
        // Créer une copie de l'enseignement avec le nouveau titre
        final updatedTeaching = widget.teaching.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );
        
        // Mettre à jour via le service
        await TeachingService.updateTeaching(updatedTeaching);
        
        // Notifier les providers si nécessaire
        if (context.mounted) {
          // Forcer une mise à jour légère en utilisant setState
          setState(() {});
          
          // Afficher une notification de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Favori renommé avec succès'),
              backgroundColor: MyKOGColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Erreur lors du renommage: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Erreur lors du renommage'),
              backgroundColor: const Color(0xFFE22134),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      }
    }
    
    // Réinitialiser le cooldown après un délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _editCooldown = false);
      }
    });
  }

  void _cancelEdit() {
    // Sortir du mode édition immédiatement
    setState(() {
      _isEditing = false;
      _editController.text = widget.teaching.title;
      _editCooldown = true;
    });
    
    // Réinitialiser le cooldown après un délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _editCooldown = false);
      }
    });
  }

  void _handleEditKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _confirmEdit();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _cancelEdit();
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(widget.teaching.publishedAt);

    // Éviter les reconstructions pendant l'édition
    if (_isEditing) {
      return Container(
        width: _kCardWidth,
        height: _kCardHeight,
        margin: EdgeInsets.only(right: 12.w),
        child: _buildCard(formattedDate),
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!_isEditing && !_editCooldown) {
          setState(() => _pressed = true);
          _hoverCtrl.forward();
        }
      },
      onTapUp: (_) {
        if (!_isEditing && !_editCooldown) {
          setState(() => _pressed = false);
          _hoverCtrl.reverse();
          _onTap(context);
        }
      },
      onTapCancel: () {
        if (!_isEditing) {
          setState(() => _pressed = false);
          _hoverCtrl.reverse();
        }
      },
      onLongPress: () => _showMenu(context),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          width: _kCardWidth,
          height: _kCardHeight,
          margin: EdgeInsets.only(right: 12.w),
          child: _buildCard(formattedDate),
        ),
      ),
    );
  }

  Widget _buildCard(String formattedDate) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // ── Back panel — artwork images ──────────────────────────────────────
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: _kBackBg,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _kBorderColor, width: 1.w),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_kRadius),
              child: _buildFannedImages(),
            ),
          ),
        ),

        // ── Front panel — glass overlay at bottom ───────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(_kRadius),
              bottomRight: Radius.circular(_kRadius),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: _buildFrontPanel(formattedDate),
            ),
          ),
        ),
      ],
    );
  }

  // ── Fanned images (Portfolio style: left −10°, center 0°, right +10°) ──────
  Widget _buildFannedImages() {
    final url = widget.teaching.artworkUrl;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Left image — dimmed, rotated
        Positioned(
          top: 20,
          left: 18,
          child: Transform.rotate(
            angle: -10 * math.pi / 180,
            child: _artworkThumbnail(url, 68, 96, opacity: 0.30),
          ),
        ),
        // Right image — dimmed, rotated
        Positioned(
          top: 20,
          right: 18,
          child: Transform.rotate(
            angle: 10 * math.pi / 180,
            child: _artworkThumbnail(url, 68, 96, opacity: 0.30),
          ),
        ),
        // Center image — full brightness, slightly raised
        Positioned(
          top: 10,
          child: _artworkThumbnail(url, 84, 118, opacity: 1.0, elevated: true),
        ),
      ],
    );
  }

  Widget _artworkThumbnail(
    String url,
    double width,
    double height, {
    double opacity = 1.0,
    bool elevated = false,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9.r),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: url.isNotEmpty
              ? ResolvedArtworkImage(
                  url: url,
                  fit: BoxFit.cover,
                  placeholder: _placeholderBox(),
                )
              : _placeholderBox(),
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: MyKOGColors.accent.withValues(alpha: 0.45),
          size: 22.sp,
        ),
      ),
    );
  }

  // ── Front panel ─────────────────────────────────────────────────────────────
  Widget _buildFrontPanel(String formattedDate) {
    final teaching = widget.teaching;

    return Container(
      height: _kFrontHeight,
      decoration: BoxDecoration(
        color: _kFrontBg,
        border: Border(
          top: BorderSide(color: const Color(0x0AFFFFFF), width: 1.w),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title zone with edit mode
          Stack(
            children: [
              // Static title
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 38.w, 0.h),
                child: Consumer<AudioPlayerProvider>(
                  builder: (_, audio, __) {
                    final isActive = audio.currentTeaching?.id == teaching.id;
                    return AnimatedOpacity(
                      opacity: _isEditing ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        teaching.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive
                              ? MyKOGColors.accent
                              : const Color(0xB3FFFFFF), // white/70
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.35.h,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Edit mode field
              if (_isEditing)
                Positioned(
                  top: 10,
                  left: 12,
                  right: 38,
                  child: _buildEditField(),
                ),
            ],
          ),

          const Spacer(),

          // Footer: duration + date + menu
          Container(
            height: 38.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x0AFFFFFF), width: 1.w),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration
                Row(
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: 12.sp,
                      color: const Color(0x99FFFFFF),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      teaching.durationText,
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                // Date + edit controls
                Row(
                  children: [
                    if (_isEditing) ...[
                      // Cancel button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _cancelEdit,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Save button
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _confirmEdit,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: MyKOGColors.accent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Enregistrer',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            color: Color(0x80FFFFFF),
                            fontSize: 10.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showMenu(context),
                        child: Container(
                          width: 22.w,
                          height: 22.h,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Color(0x80FFFFFF),
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit field widget
  Widget _buildEditField() {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleEditKey,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.5),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: MyKOGColors.accent.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _editController,
          focusNode: _focusNode,
          autofocus: false, // Désactiver autofocus pour éviter les conflits
          maxLines: 2,
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            height: 1.35.h,
          ),
          cursorColor: MyKOGColors.accent,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: InputBorder.none,
            isDense: true,
          ),
          onTap: () {
            // S'assurer que le focus est maintenu
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
        ),
      ),
    );
  }
}

// ─── "New Favorite" slot (Portfolio NewProjectSlot-inspired) ─────────────────
class _NewFavoriteSlot extends StatefulWidget {
  final VoidCallback? onTap;

  const _NewFavoriteSlot({this.onTap});

  @override
  State<_NewFavoriteSlot> createState() => _NewFavoriteSlotState();
}

class _NewFavoriteSlotState extends State<_NewFavoriteSlot>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            width: _kCardWidth,
            height: _kCardHeight,
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: _kBackBg,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(
                color: const Color(0x1AFFFFFF), // dashed-like subtle border
                width: 1.w,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Stack(
              children: [
                // Dashed border effect (custom painter)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DashedBorderPainter(
                      color: const Color(0x26FFFFFF),
                      radius: _kRadius,
                    ),
                  ),
                ),

                // Content
                Column(
                  children: [
                    // Top zone — "+" icon
                    Expanded(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: _hovered
                                ? MyKOGColors.accent.withValues(alpha: 0.12)
                                : const Color(0x14FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: _hovered
                                ? MyKOGColors.accent
                                : const Color(0x80FFFFFF),
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),

                    // Bottom zone — label (mirrors the front-panel style)
                    Container(
                      height: _kFrontHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xCC111111),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(_kRadius),
                          bottomRight: Radius.circular(_kRadius),
                        ),
                        border: Border(
                          top: BorderSide(color: Color(0x0AFFFFFF), width: 1.w),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 0.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _hovered
                                  ? MyKOGColors.textPrimary
                                  : const Color(0xB3FFFFFF),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.35.h,
                            ),
                            child: const Text('Nouveau favori'),
                          ),
                          SizedBox(height: 4.h),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: _hovered
                                  ? MyKOGColors.accent
                                  : const Color(0x66FFFFFF),
                              fontSize: 11.sp,
                            ),
                            child: const Text('Parcourir les enseignements'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dashed border painter ────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ─── Action bottom sheet ──────────────────────────────────────────────────────
class _FavoriteActionSheet extends StatelessWidget {
  final Teaching teaching;
  final VoidCallback? onRename;

  const _FavoriteActionSheet({
    required this.teaching,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(0.w, 12.h, 0.w, 32.h),
          decoration: BoxDecoration(
            color: Color(0xF01A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border(
              top: BorderSide(color: Color(0x1AFFFFFF), width: 1.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),

              // Teaching info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: teaching.artworkUrl.isNotEmpty
                          ? ResolvedArtworkImage(
                              url: teaching.artworkUrl,
                              width: 52.w,
                              height: 52.h,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 52.w,
                              height: 52.h,
                              color: const Color(0xFF2A2A2A),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: MyKOGColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teaching.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            teaching.speaker,
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              _sheetDivider(),

              // Actions
              _sheetAction(
                context,
                icon: Icons.play_circle_outline_rounded,
                label: 'Lire maintenant',
                iconColor: MyKOGColors.accent,
                onTap: () {
                  Navigator.pop(context);
                  audioProvider.playTeaching(teaching, playlist: [teaching]);
                },
              ),
              _sheetAction(
                context,
                icon: Icons.edit_rounded,
                label: 'Renommer',
                iconColor: const Color(0xFF78B4FF),
                onTap: () {
                  Navigator.pop(context);
                  onRename?.call();
                },
              ),
              _sheetAction(
                context,
                icon: Icons.favorite_border_rounded,
                label: 'Retirer des favoris',
                iconColor: const Color(0xFFE22134),
                onTap: () {
                  Navigator.pop(context);
                  userProvider.removeFromFavorites(teaching.id);
                },
              ),
              _sheetAction(
                context,
                icon: Icons.queue_music_rounded,
                label: 'Ajouter à la file',
                onTap: () {
                  Navigator.pop(context);
                  audioProvider.addToQueue(teaching);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ajouté à la file de lecture'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                },
              ),

              _sheetDivider(),

              // Cancel
              _sheetAction(
                context,
                icon: Icons.close_rounded,
                label: 'Annuler',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetDivider() {
    return Container(
      height: 1.h,
      color: const Color(0x14FFFFFF),
      margin: EdgeInsets.symmetric(vertical: 4.h),
    );
  }

  Widget _sheetAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? const Color(0xCCFFFFFF),
              size: 20.sp,
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: TextStyle(
                color: iconColor ?? const Color(0xCCFFFFFF),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
