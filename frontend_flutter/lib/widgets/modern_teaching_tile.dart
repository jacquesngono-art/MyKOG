import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';

class ModernTeachingTile extends StatelessWidget {
  final Teaching teaching;
  final List<Teaching>? playlist;
  final VoidCallback? onTap;
  final bool showArtwork;
  final bool showMenuButton;

  const ModernTeachingTile({
    super.key,
    required this.teaching,
    this.playlist,
    this.onTap,
    this.showArtwork = true,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<AudioPlayerProvider, UserProvider>(
      builder: (context, audioProvider, userProvider, child) {
        final isCurrentlyPlaying =
            audioProvider.currentTeaching?.id == teaching.id;
        final isPlaying = isCurrentlyPlaying && audioProvider.isPlaying;

        return GestureDetector(
          onTap: onTap ?? () => _playTeaching(context, audioProvider),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isCurrentlyPlaying
                  ? MyKOGColors.secondary.withValues(alpha: 0.4)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isCurrentlyPlaying
                    ? MyKOGColors.accent.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                // Artwork 80x80 comme code.html
                _buildLibraryArtwork(context, isPlaying),
                SizedBox(width: 16.w),

                // Titre et sous-titre empilés
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Titre style code.html
                      Text(
                        teaching.title,
                        style: GoogleFonts.poppins(
                          color: isCurrentlyPlaying
                              ? MyKOGColors.accent
                              : MyKOGColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      // Sous-titre (orateur + type)
                      Text(
                        '${teaching.speaker}${teaching.typeCulte != null && teaching.typeCulte!.isNotEmpty ? ' • ${teaching.typeCulte}' : ''}',
                        style: GoogleFonts.manrope(
                          color: MyKOGColors.textSecondary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Bouton menu ou play
                if (showMenuButton)
                  _buildCompactMenuButton(context, userProvider, isPlaying)
                else
                  _buildCompactPlayButton(context, isPlaying),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernArtwork(BuildContext context, bool isPlaying) {
    return Container(
      width: 64.w,
      height: 64.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyKOGColors.accent.withValues(alpha: 0.3),
            MyKOGColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                    width: 64.w,
                    height: 64.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                : CachedNetworkImage(
                    imageUrl: teaching.artworkUrl,
                    width: 64.w,
                    height: 64.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  ),

            // Overlay de lecture
            if (isPlaying)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                ),
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
      child: Icon(
        Icons.music_note_rounded,
        color: MyKOGColors.accent,
        size: 28.w,
      ),
    );
  }

  Widget _buildTitleSection(
      BuildContext context, ThemeData theme, bool isCurrentlyPlaying) {
    return Row(
      children: [
        Expanded(
          child: Text(
            teaching.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isCurrentlyPlaying
                  ? MyKOGColors.accent
                  : MyKOGColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Badge NEW
        if (BadgeService().isTeachingNew(teaching.id, teaching.publishedAt))
          Container(
            margin: EdgeInsets.only(left: 8.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'NEW',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpeakerSection(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.person_outline_rounded,
          size: 14.w,
          color: MyKOGColors.textSecondary,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            teaching.speaker,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MyKOGColors.textSecondary,
              fontSize: 13.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Type culte badge
        if (teaching.typeCulte != null && teaching.typeCulte!.isNotEmpty) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: MyKOGColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: MyKOGColors.primary.withValues(alpha: 0.3),
                width: 0.5.w,
              ),
            ),
            child: Text(
              teaching.typeCulte!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: MyKOGColors.primary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataSection(
      BuildContext context, ThemeData theme, bool isPlaying) {
    return Row(
      children: [
        // Durée
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: MyKOGColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 12.w,
                color: MyKOGColors.accent,
              ),
              SizedBox(width: 4.w),
              Text(
                teaching.durationText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyKOGColors.accent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Badge Featured
        if (teaching.isFeatured) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: MyKOGColors.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              size: 14.w,
              color: MyKOGColors.accent,
            ),
          ),
        ],

        Spacer(),

        // Téléchargé
        if (DownloadService.isDownloaded(teaching.id))
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_done_rounded,
              size: 14.w,
              color: Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, UserProvider userProvider, bool isPlaying) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton play/lecture
        Container(
          decoration: BoxDecoration(
            color: isPlaying
                ? MyKOGColors.accent
                : MyKOGColors.accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MyKOGColors.accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _playTeaching(context,
                Provider.of<AudioPlayerProvider>(context, listen: false)),
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: isPlaying ? Colors.black : MyKOGColors.accent,
              size: 24.w,
            ),
          ),
        ),

        SizedBox(width: 8.w),

        // Menu
        PopupMenuButton<String>(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: MyKOGColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: MyKOGColors.accent.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              color: MyKOGColors.textSecondary,
              size: 20.w,
            ),
          ),
          onSelected: (value) =>
              _handleMenuAction(context, value, userProvider),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(
                    DownloadService.isDownloaded(teaching.id)
                        ? Icons.delete_outline_rounded
                        : Icons.download_rounded,
                    color: DownloadService.isDownloaded(teaching.id)
                        ? Colors.red
                        : MyKOGColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(DownloadService.isDownloaded(teaching.id)
                      ? 'Supprimer'
                      : 'Télécharger'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'add_to_queue',
              child: Row(
                children: [
                  Icon(Icons.queue_music_rounded,
                      color: MyKOGColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('Ajouter à la file'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'favorite',
              child: Row(
                children: [
                  FutureBuilder<bool>(
                    future: userProvider.isFavorite(teaching.id),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
                      return Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            isFavorite ? Colors.red : MyKOGColors.textSecondary,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<bool>(
                    future: userProvider.isFavorite(teaching.id),
                    builder: (context, snapshot) {
                      final isFavorite = snapshot.data ?? false;
                      return Text(isFavorite
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris');
                    },
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share_rounded, color: MyKOGColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('Partager'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context, bool isPlaying) {
    return Container(
      decoration: BoxDecoration(
        color: isPlaying
            ? MyKOGColors.accent
            : MyKOGColors.accent.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: MyKOGColors.accent.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => _playTeaching(
            context, Provider.of<AudioPlayerProvider>(context, listen: false)),
        icon: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: isPlaying ? Colors.black : MyKOGColors.accent,
          size: 24.w,
        ),
      ),
    );
  }

  Widget _buildLibraryArtwork(BuildContext context, bool isPlaying) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildLibraryPlaceholder(),
                  )
                : CachedNetworkImage(
                    imageUrl: teaching.artworkUrl,
                    width: 80.w,
                    height: 80.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLibraryPlaceholder(),
                    errorWidget: (context, url, error) =>
                        _buildLibraryPlaceholder(),
                  ),

            // Overlay de lecture
            if (isPlaying)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.graphic_eq,
                      color: Colors.black,
                      size: 22.w,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyKOGColors.accent.withValues(alpha: 0.4),
            MyKOGColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: MyKOGColors.accent,
          size: 32.w,
        ),
      ),
    );
  }

  Widget _buildCompactMenuButton(
      BuildContext context, UserProvider userProvider, bool isPlaying) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: MyKOGColors.textSecondary,
        size: 24.w,
      ),
      onSelected: (value) =>
          _handleMenuAction(context, value, userProvider),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(
                DownloadService.isDownloaded(teaching.id)
                    ? Icons.delete_outline_rounded
                    : Icons.download_rounded,
                color: DownloadService.isDownloaded(teaching.id)
                    ? Colors.red
                    : MyKOGColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(DownloadService.isDownloaded(teaching.id)
                  ? 'Supprimer'
                  : 'Télécharger'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_to_queue',
          child: Row(
            children: [
              Icon(Icons.queue_music_rounded,
                  color: MyKOGColors.textSecondary),
              const SizedBox(width: 12),
              Text('Ajouter à la file'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'favorite',
          child: Row(
            children: [
              FutureBuilder<bool>(
                future: userProvider.isFavorite(teaching.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.red : MyKOGColors.textSecondary,
                  );
                },
              ),
              const SizedBox(width: 12),
              FutureBuilder<bool>(
                future: userProvider.isFavorite(teaching.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return Text(isFavorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris');
                },
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_rounded, color: MyKOGColors.textSecondary),
              const SizedBox(width: 12),
              Text('Partager'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPlayButton(BuildContext context, bool isPlaying) {
    return GestureDetector(
      onTap: () => _playTeaching(
          context, Provider.of<AudioPlayerProvider>(context, listen: false)),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isPlaying
              ? MyKOGColors.accent
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPlaying
                ? MyKOGColors.accent
                : MyKOGColors.textSecondary.withValues(alpha: 0.3),
            width: 1.5.w,
          ),
        ),
        child: Center(
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: isPlaying ? Colors.black : MyKOGColors.textSecondary,
            size: 20.w,
          ),
        ),
      ),
    );
  }

  void _playTeaching(BuildContext context, AudioPlayerProvider audioProvider) {
    audioProvider.playTeaching(teaching, playlist: playlist);
  }

  void _handleMenuAction(
      BuildContext context, String action, UserProvider userProvider) async {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'download':
        final isDownloaded = DownloadService.isDownloaded(teaching.id);
        if (isDownloaded) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer le téléchargement'),
              content: const Text(
                  'Êtes-vous sûr de vouloir supprimer ce téléchargement ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await DownloadService.deleteDownload(teaching.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Téléchargement supprimé'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📥 Téléchargement en cours...'),
                duration: Duration(seconds: 2),
              ),
            );
          }

          final success = await DownloadService.downloadTeaching(
            teaching,
            onProgress: (progress) {
              debugPrint('Progression: ${progress.progressPercentage}');
            },
          );

          if (context.mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Téléchargement terminé'),
                  backgroundColor: MyKOGColors.success,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Échec du téléchargement'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
        break;
      case 'add_to_queue':
        final audioProvider =
            Provider.of<AudioPlayerProvider>(context, listen: false);
        await audioProvider.addToQueue(teaching);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté à la file d\'attente'),
              backgroundColor: MyKOGColors.success,
            ),
          );
        }
        break;
      case 'favorite':
        final isFavorite = await userProvider.isFavorite(teaching.id);
        if (isFavorite) {
          await userProvider.removeFromFavorites(teaching.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Retiré des favoris')),
            );
          }
        } else {
          await userProvider.addToFavorites(teaching.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ajouté aux favoris'),
                backgroundColor: MyKOGColors.success,
              ),
            );
          }
        }
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partage bientôt disponible')),
        );
        break;
    }
  }
}
