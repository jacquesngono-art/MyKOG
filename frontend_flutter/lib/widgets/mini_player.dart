import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/screens/audio_player_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        if (audioProvider.currentTeaching == null && !audioProvider.hasError) {
          return const SizedBox.shrink();
        }

        final teaching = audioProvider.currentTeaching;
        final progress = audioProvider.progress;

        // En cas d'erreur, ne rien afficher (mode silencieux)
        if (audioProvider.hasError) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
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
                  valueColor: AlwaysStoppedAnimation<Color>(MyKOGColors.accent),
                  minHeight: 2.h,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      children: [
                        // Artwork
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: teaching!.artworkUrl.startsWith('assets/')
                              ? Image.asset(
                                  teaching.artworkUrl,
                                  width: 40.w,
                                  height: 40.h,
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
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 40.w,
                                    height: 40.h,
                                    color: MyKOGColors.surface,
                                    child: Icon(
                                      Icons.music_note,
                                      color: MyKOGColors.accent,
                                      size: 16.sp,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    width: 40.w,
                                    height: 40.h,
                                    color: MyKOGColors.surface,
                                    child: Icon(
                                      Icons.music_note,
                                      color: MyKOGColors.accent,
                                      size: 16.sp,
                                    ),
                                  ),
                                ),
                        ),
                        SizedBox(width: 16.w),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 8),
                        // Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (audioProvider.hasPrevious)
                              IconButton(
                                onPressed: audioProvider.skipToPrevious,
                                icon: Icon(
                                  Icons.skip_previous,
                                  color: MyKOGColors.textPrimary,
                                  size: 24,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            // Play/Pause button
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
                            if (audioProvider.hasNext)
                              IconButton(
                                onPressed: audioProvider.skipToNext,
                                icon: Icon(
                                  Icons.skip_next,
                                  color: MyKOGColors.textPrimary,
                                  size: 24,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.zero,
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
      },
    );
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
