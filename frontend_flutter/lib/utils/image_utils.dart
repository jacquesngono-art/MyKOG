import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:MyKOG/theme.dart';

/// Widget utilitaire pour afficher des images avec fallback automatique
class SafeImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String placeholderPath;

  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderPath = 'assets/images/kog.png',
  });

  @override
  Widget build(BuildContext context) {
    // Si c'est une URL réseau
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    // Si c'est un asset local
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Par défaut, afficher le placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: MyKOGColors.secondary,
      child: const Icon(
        Icons.music_note,
        color: MyKOGColors.accent,
        size: 32,
      ),
    );
  }
}

/// Fonction utilitaire pour obtenir une URL d'image sécurisée
String getSafeImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return 'assets/images/kog.png';
  }

  // Si c'est une URL valide, la retourner
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // Si c'est un asset local qui existe, le retourner
  if (url.startsWith('assets/')) {
    return url;
  }

  // Sinon, retourner le placeholder
  return 'assets/images/placeholder.jpg';
}

