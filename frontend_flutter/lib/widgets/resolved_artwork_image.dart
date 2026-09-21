import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:MyKOG/services/b2_stream_refresher.dart';
import 'package:MyKOG/theme.dart';

/// Image d'artwork qui rafraîchit automatiquement les URLs signées B2
/// avant de charger l'image réseau.
class ResolvedArtworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const ResolvedArtworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: B2StreamRefresher.instance.refresh(url),
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? url;
        return CachedNetworkImage(
          imageUrl: resolved,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) =>
              placeholder ?? _defaultPlaceholder(),
          errorWidget: (context, url, error) => _defaultPlaceholder(),
        );
      },
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: MyKOGColors.accent.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: MyKOGColors.accent,
        ),
      ),
    );
  }
}