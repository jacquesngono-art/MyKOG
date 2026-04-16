import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/services/audio_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  // Suppression des AnimationControllers pour une interface stable

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: Consumer2<AudioPlayerProvider, UserProvider>(
        builder: (context, audioProvider, userProvider, child) {
          final teaching = audioProvider.currentTeaching;

          if (teaching == null) {
            return const Center(
              child: Text(
                'No audio playing',
                style: TextStyle(color: MyKOGColors.textPrimary),
              ),
            );
          }

          // Interface stable - aucune animation automatique

          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, theme),

                // Album Art
                Expanded(
                  flex: 3,
                  child: _buildAlbumArt(teaching, size),
                ),

                // Teaching Info
                Expanded(
                  flex: 1,
                  child: _buildTeachingInfo(
                      context, theme, teaching, userProvider),
                ),

                // Progress Bar
                _buildProgressBar(context, audioProvider),

                // Controls
                _buildControls(context, audioProvider),

                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: MyKOGColors.textPrimary,
              size: 32.w,
            ),
          ),
          Text(
            'Now Playing',
            style: theme.textTheme.titleMedium?.copyWith(
              color: MyKOGColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: () => _showQueue(context),
            icon: Icon(
              Icons.queue_music,
              color: MyKOGColors.textPrimary,
              size: 24.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(dynamic teaching, Size size) {
    final artSize = (size.width - 80) < 320.0 ? (size.width - 80) : 320.0;

    // Interface stable - aucune rotation ni animation
    return Center(
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MyKOGColors.accent.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: teaching.artworkUrl.startsWith('assets/')
              ? Image.asset(
                  teaching.artworkUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: MyKOGColors.secondary,
                    child: Icon(
                      Icons.music_note,
                      color: MyKOGColors.accent,
                      size: 48.w,
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: teaching.artworkUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: MyKOGColors.secondary,
                    child: const Center(
                      child: Icon(
                        Icons.music_note,
                        color: MyKOGColors.accent,
                        size: 64,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: MyKOGColors.secondary,
                    child: const Center(
                      child: Icon(
                        Icons.music_note,
                        color: MyKOGColors.accent,
                        size: 64,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTeachingInfo(BuildContext context, ThemeData theme,
      dynamic teaching, UserProvider userProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Permet de s'adapter au contenu
        children: [
          Flexible(
            child: Text(
              teaching.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: MyKOGColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            teaching.speaker,
            style: theme.textTheme.titleMedium?.copyWith(
              color: MyKOGColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h), // Réduit de 16 à 12
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<bool>(
                future: userProvider.isFavorite(teaching.id),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.data ?? false;
                  return IconButton(
                    onPressed: () async {
                      if (isFavorite) {
                        await userProvider.removeFromFavorites(teaching.id);
                      } else {
                        await userProvider.addToFavorites(teaching.id);
                      }
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          isFavorite ? Colors.red : MyKOGColors.textSecondary,
                      size: 28.w,
                    ),
                  );
                },
              ),
              SizedBox(width: 32.w),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Share functionality coming soon')),
                  );
                },
                icon: Icon(
                  Icons.share,
                  color: MyKOGColors.textSecondary,
                  size: 28.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, AudioPlayerProvider audioProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MyKOGColors.accent,
              inactiveTrackColor:
                  MyKOGColors.textTertiary.withValues(alpha: 0.3),
              thumbColor: MyKOGColors.accent,
              overlayColor: MyKOGColors.accent.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: audioProvider.progress.clamp(0.0, 1.0),
              onChanged: (value) {
                if (audioProvider.duration != null) {
                  final position = Duration(
                    milliseconds:
                        (value * audioProvider.duration!.inMilliseconds)
                            .round(),
                  );
                  audioProvider.seek(position);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  audioProvider.positionText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                ),
                Text(
                  audioProvider.durationText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, AudioPlayerProvider audioProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Shuffle
              Flexible(
                child: IconButton(
                  onPressed: audioProvider.toggleShuffle,
                  icon: Icon(
                    Icons.shuffle,
                    color: audioProvider.isShuffleOn
                        ? MyKOGColors.accent
                        : MyKOGColors.textSecondary,
                    size: 24.w,
                  ),
                ),
              ),
              // Seek backward
              Flexible(
                child: IconButton(
                  onPressed: audioProvider.seekBackward,
                  icon: Icon(
                    Icons.replay_10,
                    color: MyKOGColors.textPrimary,
                    size: 28.w,
                  ),
                ),
              ),
              // Previous
              IconButton(
                onPressed: audioProvider.hasPrevious
                    ? audioProvider.skipToPrevious
                    : null,
                icon: Icon(
                  Icons.skip_previous,
                  color: audioProvider.hasPrevious
                      ? MyKOGColors.textPrimary
                      : MyKOGColors.textTertiary,
                  size: 32.w,
                ),
              ),
              // Play/Pause - Interface stable sans animation
              GestureDetector(
                onTap: audioProvider.isPlaying
                    ? audioProvider.pause
                    : audioProvider.play,
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: MyKOGColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MyKOGColors.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    audioProvider.isLoading
                        ? Icons.hourglass_empty
                        : audioProvider.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                    color: Colors.black,
                    size: 28.w,
                  ),
                ),
              ),
              // Next
              IconButton(
                onPressed:
                    audioProvider.hasNext ? audioProvider.skipToNext : null,
                icon: Icon(
                  Icons.skip_next,
                  color: audioProvider.hasNext
                      ? MyKOGColors.textPrimary
                      : MyKOGColors.textTertiary,
                  size: 32.w,
                ),
              ),
              // Seek forward
              SizedBox(
                width: 40.w,
                child: IconButton(
                  onPressed: audioProvider.seekForward,
                  icon: Icon(
                    Icons.forward_10,
                    color: MyKOGColors.textPrimary,
                    size: 28.w,
                  ),
                ),
              ),
              // Repeat
              IconButton(
                onPressed: audioProvider.toggleRepeatMode,
                icon: Icon(
                  audioProvider.repeatMode == AudioRepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: audioProvider.repeatMode != AudioRepeatMode.off
                      ? MyKOGColors.accent
                      : MyKOGColors.textSecondary,
                  size: 24.w,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyKOGColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => const QueueBottomSheet(),
    );
  }
}

class QueueBottomSheet extends StatelessWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        final queue = audioProvider.queue;

        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: MyKOGColors.textTertiary,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Up Next',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      audioProvider.clearQueue();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(color: MyKOGColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Queue list
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Text(
                          'Queue is empty',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: MyKOGColors.textSecondary,
                                  ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final teaching = queue[index];
                          final isCurrentlyPlaying =
                              audioProvider.currentTeaching?.id == teaching.id;

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: MyKOGColors.surface,
                              ),
                              child: teaching.artworkUrl.startsWith('assets/')
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(
                                        teaching.artworkUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: MyKOGColors.secondary,
                                          child: const Icon(
                                            Icons.music_note,
                                            color: MyKOGColors.accent,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: CachedNetworkImage(
                                        imageUrl: teaching.artworkUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const Icon(
                                          Icons.music_note,
                                          color: MyKOGColors.accent,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                          Icons.music_note,
                                          color: MyKOGColors.accent,
                                        ),
                                      ),
                                    ),
                            ),
                            title: Text(
                              teaching.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: isCurrentlyPlaying
                                        ? MyKOGColors.accent
                                        : MyKOGColors.textPrimary,
                                    fontWeight: isCurrentlyPlaying
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
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
                            trailing: isCurrentlyPlaying
                                ? Icon(
                                    Icons.graphic_eq,
                                    color: MyKOGColors.accent,
                                    size: 20,
                                  )
                                : IconButton(
                                    onPressed: () {
                                      audioProvider.removeFromQueue(index);
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: MyKOGColors.textTertiary,
                                      size: 20,
                                    ),
                                  ),
                            onTap: () {
                              audioProvider.playTeaching(teaching,
                                  playlist: queue);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
