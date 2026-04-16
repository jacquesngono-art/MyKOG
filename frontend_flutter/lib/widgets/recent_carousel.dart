import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/teaching_tile.dart';
import 'package:MyKOG/providers/audio_player_provider.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/providers/teaching_provider.dart';

class RecentCarousel extends StatelessWidget {
  final List<Teaching> recentTeachings;
  final Function(Teaching)? onTeachingTap;

  const RecentCarousel({
    super.key,
    required this.recentTeachings,
    this.onTeachingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    if (recentTeachings.isEmpty) {
      // Afficher un placeholder avec un message d'invitation
      return Container(
        height: 240,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? MyKOGColors.secondary
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: MyKOGColors.accent,
                    size: 20,
                  ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.recentlyPlayed,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

            // Contenu du placeholder
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.headphones,
                      color: MyKOGColors.accent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.startListening,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.recentTeachingsAppearHere,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240, // Hauteur fixe pour le caroucelle
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: MyKOGColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recentlyPlayed,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: MyKOGColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Caroucelle horizontale
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: recentTeachings.length,
              itemBuilder: (context, index) {
                final teaching = recentTeachings[index];
                return Container(
                  width: 160, // Largeur fixe pour chaque item
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildRecentCard(context, teaching, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, Teaching teaching, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<AudioPlayerProvider, UserProvider>(
      builder: (context, audioProvider, userProvider, child) {
        final isCurrentlyPlaying =
            audioProvider.currentTeaching?.id == teaching.id;
        final isPlaying = isCurrentlyPlaying && audioProvider.isPlaying;

        return InkWell(
          onTap: () => _handleCardTap(context, teaching, audioProvider, userProvider),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentlyPlaying
                  ? (isDark
                      ? MyKOGColors.secondary
                      : Colors.grey.shade100)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isCurrentlyPlaying
                  ? Border.all(
                      color: MyKOGColors.accent.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artwork
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        MyKOGColors.primaryDark,
                        MyKOGColors.secondary,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Image de l'enseignement
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: FadeInImage.assetNetwork(
                          placeholder: 'assets/images/kog.png',
                          image: teaching.artworkUrl,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderArtwork(context);
                          },
                        ),
                      ),

                      // Indicateur de lecture
                      if (isPlaying)
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: MyKOGColors.accent,
                              size: 32,
                            ),
                          ),
                        ),

                      // Badge "NEW" si applicable
                      if (teaching.isNew)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MyKOGColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),

                      // Badge "FEATURED" si applicable
                      if (teaching.isFeatured)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Icon(
                            Icons.star,
                            color: MyKOGColors.accent,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                // Informations
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Expanded(
                          child: Text(
                            teaching.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isCurrentlyPlaying
                                  ? MyKOGColors.accent
                                  : (isDark
                                      ? MyKOGColors.textPrimary
                                      : Colors.black87),
                              fontWeight: isCurrentlyPlaying
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Orateur
                        Text(
                          teaching.speaker,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? MyKOGColors.textSecondary
                                : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Type de culte
                        if (teaching.typeCulte != null && teaching.typeCulte!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: MyKOGColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              teaching.typeCulte!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: MyKOGColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(
              delay: (index * 100).ms,
              // Animation simple sans AnimationTarget
            )
            .fadeIn(delay: (index * 100).ms)
            .slideX(begin: index % 2 == 0 ? -20.0 : 20.0);
      },
    );
  }

  void _handleCardTap(
      BuildContext context,
      Teaching teaching,
      AudioPlayerProvider audioProvider,
      UserProvider userProvider,
      ) {
    // Mettre à jour les récemment écoutés
    if (!userProvider.recentlyPlayedIds.contains(teaching.id)) {
      userProvider.addToRecentlyPlayed(teaching.id);
    }

    // Jouer l'enseignement
    audioProvider.playTeaching(teaching, playlist: recentTeachings);

    // Optionnel: naviguer vers l'écran de lecture détaillée
    // Navigator.push(context, MaterialPageRoute(builder: (context) => AudioPlayerScreen(teaching: teaching)));
  }

  Widget _buildPlaceholderArtwork(BuildContext context) {
    return Container(
      color: MyKOGColors.secondary,
      child: Center(
        child: Icon(
          Icons.music_note,
          color: MyKOGColors.accent,
          size: 48,
        ),
      ),
    );
  }
}