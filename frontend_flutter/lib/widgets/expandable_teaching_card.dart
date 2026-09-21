import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/resolved_artwork_image.dart';

/// Card enseignement avec morphing vers le plein écran (équivalent Flutter du
/// composant framer-motion "ExpandableCard" de l'inspiration).
class ExpandableTeachingCard extends StatefulWidget {
  final Teaching teaching;
  final void Function(Teaching teaching) onPlay;

  const ExpandableTeachingCard({
    super.key,
    required this.teaching,
    required this.onPlay,
  });

  @override
  State<ExpandableTeachingCard> createState() => _ExpandableTeachingCardState();
}

class _ExpandableTeachingCardState extends State<ExpandableTeachingCard> {
  final GlobalKey _cardKey = GlobalKey();
  bool _hovered = false;

  void _expand() {
    // Lecture audio immédiate au clic (comportement d'origine conservé)
    widget.onPlay(widget.teaching);

    final box =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;

    final origin = box.localToGlobal(Offset.zero) & box.size;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ExpandedCardOverlay(
        originRect: origin,
        teaching: widget.teaching,
        onPlay: widget.onPlay,
        onClose: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Widget _buildArtwork(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Effet Ken Burns : image en 115% qui panne de 0% → -15% (16s, boucle)
          _PanningArtwork(
            image: _Artwork(teaching: widget.teaching, iconSize: 32.w),
          ),
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
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${widget.teaching.playCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teaching = widget.teaching;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: GestureDetector(
          key: _cardKey,
          onTap: _expand,
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
                    child: _buildArtwork(context),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  teaching.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}

/// Overlay plein écran animé : morphing depuis le rect de la card
/// (position/size/border-radius/backdrop 0.5s easeInOut, Échap pour fermer).
class _ExpandedCardOverlay extends StatefulWidget {
  final Rect originRect;
  final Teaching teaching;
  final void Function(Teaching teaching) onPlay;
  final VoidCallback onClose;

  const _ExpandedCardOverlay({
    required this.originRect,
    required this.teaching,
    required this.onPlay,
    required this.onClose,
  });

  @override
  State<_ExpandedCardOverlay> createState() => _ExpandedCardOverlayState();
}

class _ExpandedCardOverlayState extends State<_ExpandedCardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildArtwork(BuildContext context) {
    return _Artwork(teaching: widget.teaching, iconSize: 48.w);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teaching = widget.teaching;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final fullRect = Rect.fromLTWH(
            0,
            0,
            MediaQuery.sizeOf(context).width,
            MediaQuery.sizeOf(context).height,
          );
          final rect = Rect.lerp(widget.originRect, fullRect, t)!;
          final radius = 12.r * (1 - t);

          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: Colors.black.withValues(alpha: 0.9 * t),
                      ),
                      _buildArtwork(context),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Contenu de la vue agrandie (fade-in après l'expansion)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: t < 0.4,
                  child: AnimatedOpacity(
                    opacity: t,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teaching.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: MyKOGColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                teaching.speaker,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: MyKOGColors.textSecondary,
                                    ),
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                children: [
                                  _buildPlayButton(context, l10n),
                                  SizedBox(width: 12.w),
                                  _buildFavoriteButton(context),
                                  SizedBox(width: 12.w),
                                  _buildDownloadButton(context),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bouton fermer (haut droite, comme l'inspiration)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 12,
                right: 16,
                child: IgnorePointer(
                  ignoring: t < 0.6,
                  child: AnimatedOpacity(
                    opacity: t,
                    duration: const Duration(milliseconds: 200),
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _close,
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24.w,
                        ),
                        tooltip: l10n.close,
                      ),
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

  Widget _buildPlayButton(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: MyKOGColors.accent,
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        onPressed: () => widget.onPlay(widget.teaching),
        icon: Icon(
          Icons.play_arrow_rounded,
          color: Colors.black,
          size: 32.w,
        ),
        tooltip: l10n.play,
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return _FavoriteButton(teaching: widget.teaching);
  }

  Widget _buildDownloadButton(BuildContext context) {
    return _DownloadButton(teaching: widget.teaching);
  }
}

class _FavoriteButton extends StatefulWidget {
  final Teaching teaching;

  const _FavoriteButton({required this.teaching});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool? _isFavorite;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    final isFavorite = await userProvider.isFavorite(widget.teaching.id);
    if (mounted) setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggle() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final isFavorite = _isFavorite ?? false;

    if (isFavorite) {
      await userProvider.removeFromFavorites(widget.teaching.id);
    } else {
      await userProvider.addToFavorites(widget.teaching.id);
    }
    if (!mounted) return;
    setState(() => _isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isFavorite ? l10n.removedFromFavorites : l10n.addedToFavorites),
        backgroundColor: isFavorite ? null : MyKOGColors.success,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFavorite = _isFavorite ?? false;
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: _toggle,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white,
          size: 24.w,
        ),
        tooltip:
            isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
      ),
    );
  }
}

class _DownloadButton extends StatefulWidget {
  final Teaching teaching;

  const _DownloadButton({required this.teaching});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _isDownloaded = DownloadService.isDownloaded(widget.teaching.id);
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isDownloaded) {
      await DownloadService.deleteDownload(widget.teaching.id);
      if (!mounted) return;
      setState(() => _isDownloaded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloadDeleted),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloading),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      final success = await DownloadService.downloadTeaching(
        widget.teaching,
      );
      if (!mounted) return;
      setState(() => _isDownloaded = success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.downloadComplete : l10n.downloadFailed,
          ),
          backgroundColor: success ? MyKOGColors.success : Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: _toggle,
        icon: Icon(
          _isDownloaded
              ? Icons.download_done
              : Icons.download_rounded,
          color: _isDownloaded ? MyKOGColors.accent : Colors.white,
          size: 24.w,
        ),
        tooltip: l10n.download,
      ),
    );
  }
}

/// Image d'artwork réutilisable (assets ou réseau B2) avec fallback.
class _Artwork extends StatelessWidget {
  final Teaching teaching;
  final double iconSize;

  const _Artwork({required this.teaching, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      color: MyKOGColors.secondary,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: MyKOGColors.accent,
          size: iconSize,
        ),
      ),
    );

    if (teaching.artworkUrl.startsWith('assets/')) {
      return Image.asset(
        teaching.artworkUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
    return ResolvedArtworkImage(
      url: teaching.artworkUrl,
      fit: BoxFit.cover,
      placeholder: fallback,
    );
  }
}

/// Effet Ken Burns : image élargie à 115% qui panne de 0% → -15% en boucle
/// (équivalent du panningAnimation de l'inspiration image-gallery.tsx : 16s, linear).
class _PanningArtwork extends StatefulWidget {
  final Widget image;

  const _PanningArtwork({required this.image});

  @override
  State<_PanningArtwork> createState() => _PanningArtworkState();
}

class _PanningArtworkState extends State<_PanningArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    // Défilement horizontal centré : l'image 115% oscille de +7.5% à -7.5%
    // de la card (≈ 6.5% relatif à l'élément) — cadrage d'origine au repos
    _pan = Tween<double>(begin: 0.065, end: -0.065).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRect(
          child: Align(
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _pan,
              builder: (context, child) {
                return FractionalTranslation(
                  translation: Offset(_pan.value, 0),
                  child: child,
                );
              },
              child: SizedBox(
                // Image élargie à 115% et centrée : couverture garantie pendant
                // le panning et cadrage identique à l'original au repos
                width: w * 1.15,
                height: h,
                child: widget.image,
              ),
            ),
          ),
        );
      },
    );
  }
}
