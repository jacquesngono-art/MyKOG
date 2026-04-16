import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';

class TeachingTile extends StatelessWidget {
  final Teaching teaching;
  final List<Teaching>? playlist;
  final VoidCallback? onTap;
  final bool showArtwork;
  final bool showMenuButton;

  const TeachingTile({
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
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<AudioPlayerProvider, UserProvider>(
      builder: (context, audioProvider, userProvider, child) {
        final isCurrentlyPlaying =
            audioProvider.currentTeaching?.id == teaching.id;
        final isPlaying = isCurrentlyPlaying && audioProvider.isPlaying;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentlyPlaying
                ? (isDark ? MyKOGColors.secondary : Colors.grey.shade100)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentlyPlaying
                ? Border.all(
                    color: MyKOGColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: showArtwork ? _buildArtwork(context, isPlaying) : null,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    teaching.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isCurrentlyPlaying
                          ? MyKOGColors.accent
                          : (isDark ? MyKOGColors.textPrimary : Colors.black87),
                      fontWeight:
                          isCurrentlyPlaying ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                // Badge "NEW" si publié dans les 2 derniers jours
                if (BadgeService().isTeachingNew(teaching.id, teaching.publishedAt))
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'NEW',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teaching.speaker,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? MyKOGColors.textSecondary
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (teaching.typeCulte != null && teaching.typeCulte!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MyKOGColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      teaching.typeCulte!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      teaching.durationText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? MyKOGColors.textTertiary
                            : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    if (teaching.isNew) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MyKOGColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (teaching.isFeatured) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: MyKOGColors.accent,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing:
                showMenuButton ? _buildMenuButton(context, userProvider) : null,
            onTap: onTap ?? () => _playTeaching(context, audioProvider),
          ),
        );
      },
    );
  }

  Widget _buildArtwork(BuildContext context, bool isPlaying) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            teaching.artworkUrl.startsWith('assets/')
                ? Image.asset(
                    teaching.artworkUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: MyKOGColors.secondary,
                      child: const Icon(
                        Icons.music_note,
                        color: MyKOGColors.accent,
                        size: 24,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: teaching.artworkUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: MyKOGColors.secondary,
                      child: const Icon(
                        Icons.music_note,
                        color: MyKOGColors.accent,
                        size: 24,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: MyKOGColors.secondary,
                      child: const Icon(
                        Icons.music_note,
                        color: MyKOGColors.accent,
                        size: 24,
                      ),
                    ),
                  ),
            if (isPlaying)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Icon(
                    Icons.graphic_eq,
                    color: MyKOGColors.accent,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, UserProvider userProvider) {
    final l10n = AppLocalizations.of(context)!;
    
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).brightness == Brightness.dark
            ? MyKOGColors.textSecondary
            : Colors.grey.shade600,
      ),
      onSelected: (value) => _handleMenuAction(context, value, userProvider),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'download',
          child: Row(
            children: [
              Icon(
                DownloadService.isDownloaded(teaching.id)
                    ? Icons.delete_outline
                    : Icons.download,
                color: DownloadService.isDownloaded(teaching.id)
                    ? Colors.red
                    : MyKOGColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(DownloadService.isDownloaded(teaching.id)
                  ? l10n.deleteDownload
                  : l10n.download),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'add_to_queue',
          child: Row(
            children: [
              Icon(Icons.queue_music, color: MyKOGColors.textSecondary),
              const SizedBox(width: 12),
              Text(l10n.addToQueue),
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
                    isFavorite ? Icons.favorite : Icons.favorite_border,
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
                      ? l10n.removeFromFavorites
                      : l10n.addToFavorites);
                },
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, color: MyKOGColors.textSecondary),
              const SizedBox(width: 12),
              Text(l10n.share),
            ],
          ),
        ),
      ],
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
          // Supprimer le téléchargement
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteDownload),
              content: Text(l10n.deleteDownloadConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await DownloadService.deleteDownload(teaching.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ ${l10n.translate("download_deleted")}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          // Démarrer le téléchargement
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📥 ${l10n.downloading}'),
                duration: const Duration(seconds: 2),
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
                SnackBar(
                  content: Text('✅ ${l10n.downloadComplete}'),
                  backgroundColor: MyKOGColors.success,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${l10n.downloadFailed}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
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
            SnackBar(
              content: Text(l10n.addedToQueue),
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
              SnackBar(content: Text(l10n.removedFromFavorites)),
            );
          }
        } else {
          await userProvider.addToFavorites(teaching.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.addedToFavorites),
                backgroundColor: MyKOGColors.success,
              ),
            );
          }
        }
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.translate('share_coming_soon'))),
        );
        break;
    }
  }
}
