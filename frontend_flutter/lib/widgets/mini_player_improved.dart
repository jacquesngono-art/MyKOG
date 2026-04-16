import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/screens/audio_player_screen.dart';

/// Mini Player Amélioré avec boutons reculer/avancer et fermer
class MiniPlayerImproved extends StatelessWidget {
  const MiniPlayerImproved({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentTeaching == null && !audioProvider.hasError) {
          return const SizedBox.shrink();
        }

        final teaching = audioProvider.currentTeaching;
        final progress = audioProvider.progress;

        if (audioProvider.hasError) {
          return _buildErrorState(context, audioProvider);
        }

        return Stack(
          children: [
            GestureDetector(
              onTap: () => _openFullPlayer(context),
              child: Container(
                height: 72.h,
                margin: EdgeInsets.symmetric(
                  vertical: 8.h,
                  horizontal: 16.h,
                ),
                decoration: BoxDecoration(
                  color: MyKOGColors.secondary,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: MyKOGColors.accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16.r,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          MyKOGColors.textTertiary.withValues(alpha: 0.3),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(MyKOGColors.accent),
                      minHeight: 2.h,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        child: Row(
                          children: [
                            // Artwork
                            _buildArtwork(teaching!),
                            SizedBox(width: 12.w),
                            
                            // Teaching info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    teaching.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: MyKOGColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    teaching.speaker,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: MyKOGColors.textSecondary,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Controls
                            _buildControls(audioProvider),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton de fermeture
            Positioned(
              top: 12.h,
              right: 20.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: () => _closeMiniPlayer(context, audioProvider),
                  tooltip: 'Fermer',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildArtwork(teaching) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6.r),
      child: teaching.artworkUrl.startsWith('assets/')
          ? Image.asset(
              teaching.artworkUrl,
              width: 48.w,
              height: 48.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
            )
          : CachedNetworkImage(
              imageUrl: teaching.artworkUrl,
              width: 48.w,
              height: 48.h,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 48.w,
      height: 48.h,
      color: MyKOGColors.surface,
      child: Icon(
        Icons.music_note,
        color: MyKOGColors.accent,
        size: 24.sp,
      ),
    );
  }

  Widget _buildControls(AudioPlayerProvider audioProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reculer 15s
        IconButton(
          onPressed: audioProvider.seekBackward,
          icon: Icon(
            Icons.replay_10,
            color: MyKOGColors.textPrimary,
            size: 24,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: EdgeInsets.zero,
          tooltip: '-15s',
        ),
        
        // Play/Pause
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MyKOGColors.accent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: audioProvider.isPlaying
                ? audioProvider.pause
                : audioProvider.play,
            icon: Icon(
              audioProvider.isLoading
                  ? Icons.hourglass_empty
                  : audioProvider.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
              color: Colors.black,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ),
        
        // Avancer 15s
        IconButton(
          onPressed: audioProvider.seekForward,
          icon: Icon(
            Icons.forward_10,
            color: MyKOGColors.textPrimary,
            size: 24,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: EdgeInsets.zero,
          tooltip: '+15s',
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, AudioPlayerProvider audioProvider) {
    return Container(
      height: 72.h,
      margin: EdgeInsets.symmetric(
        vertical: 8.h,
        horizontal: 16.h,
      ),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 16.w),
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 24.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context)?.error ?? 'Erreur audio',
              style: TextStyle(
                fontSize: 14.sp,
                color: MyKOGColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => audioProvider.clearError(),
            icon: Icon(
              Icons.refresh,
              color: MyKOGColors.accent,
              size: 20.w,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Future<void> _closeMiniPlayer(
      BuildContext context, AudioPlayerProvider audioProvider) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyKOGColors.secondary,
        title: Text(
          l10n?.closePlayer ?? 'Fermer le lecteur',
          style: TextStyle(color: MyKOGColors.textPrimary),
        ),
        content: Text(
          l10n?.stopPlaybackConfirm ?? 'Voulez-vous arrêter la lecture ?',
          style: TextStyle(color: MyKOGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n?.cancel ?? 'Annuler',
              style: TextStyle(color: MyKOGColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n?.confirm ?? 'Confirmer',
              style: TextStyle(color: MyKOGColors.accent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await audioProvider.stop();
    }
  }

  void _openFullPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AudioPlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

