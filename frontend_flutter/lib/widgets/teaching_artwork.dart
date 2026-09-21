import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/b2_stream_refresher.dart';
import 'package:MyKOG/theme.dart';

class TeachingArtwork extends StatelessWidget {
  final Teaching teaching;
  final double width;
  final double height;
  final double borderRadius;
  final bool showPlayingOverlay;
  final bool isPlaying;
  final double iconSize;

  const TeachingArtwork({
    super.key,
    required this.teaching,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.showPlayingOverlay = false,
    this.isPlaying = false,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolveArtworkUrl(),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data ?? teaching.artworkUrl;
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              _buildImage(imageUrl),
              if (showPlayingOverlay && isPlaying)
                Container(
                  decoration: BoxDecoration(
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
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Résout l'URL finale : fichier local téléchargé si disponible,
  /// sinon URL distante (avec rafraîchissement des URLs signées B2)
  Future<String> _resolveArtworkUrl() async {
    final effective = await DownloadService.getEffectiveArtworkUrl(
      teaching.id,
      teaching.artworkUrl,
    );
    if (effective.startsWith('assets/') ||
        effective.startsWith('/') ||
        effective.startsWith('file://')) {
      return effective;
    }
    return B2StreamRefresher.instance.refresh(effective);
  }

  Widget _buildImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (url.startsWith('/') || url.startsWith('file://')) {
      final filePath = url.startsWith('file://')
          ? url.replaceFirst('file://', '')
          : url;
      return Image.file(
        File(filePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
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
          size: width * 0.4,
        ),
      ),
    );
  }
}
