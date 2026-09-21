import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:MyKOG/config/api_config.dart';

/// Rafraîchit les URLs signées Backblaze B2 qui expirent (par défaut 1h).
///
/// Les URLs servies par le backend sont des URLs présignées B2 valides
/// `expiresIn` secondes. Quand elles sont stockées dans le cache local
/// (Hive), elles peuvent expirer. Ce service :
///  1. analyse l'URL signée pour en extraire la clé objet et la date
///     d'expiration,
///  2. si l'URL expirera sous peu (≤ 5 min), appelle le backend
///     `GET /api/stream/<key>` qui retourne une URL fraîche,
///  3. garde un cache mémoire court (50 min) pour limiter les requêtes,
///     avec fallback sur l'URL d'origine en cas d'erreur réseau.
class B2StreamRefresher {
  B2StreamRefresher._();

  static final B2StreamRefresher instance = B2StreamRefresher._();

  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _freshThreshold = Duration(minutes: 5);
  static const Duration _cacheTtl = Duration(minutes: 50);

  final Map<String, _CachedUrl> _cache = {};

  /// Retourne une URL de lecture exploitable pour [url].
  /// Si [url] est une URL signée B2 proche de l'expiration, la régénère.
  /// Sinon retourne l'URL inchangée.
  Future<String> refresh(String url) async {
    if (url.isEmpty || !_isSignedB2Url(url)) return url;

    final key = _extractKey(url);
    if (key == null) return url;

    // Cache mémoire : si encore valide, réutiliser
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    // URL encore valide (expiration pas proche) : réutiliser telle quelle
    final expiresAt = _parseExpiration(url);
    if (expiresAt != null &&
        DateTime.now().add(_freshThreshold).isBefore(expiresAt)) {
      return url;
    }

    // Régénération via le backend
    try {
      final refreshed = await _fetchFreshUrl(key);
      if (refreshed != null) {
        _cache[key] = _CachedUrl(
          url: refreshed,
          expiresAt: DateTime.now().add(_cacheTtl),
        );
        return refreshed;
      }
    } catch (e) {
      debugPrint('⚠️ B2StreamRefresher: échec régénération ($key): $e');
    }

    return url;
  }

  /// Demande une URL signée fraîche via `GET /api/stream/<key>`.
  Future<String?> _fetchFreshUrl(String key) async {
    final base = await ApiConfig.getBaseUrl();
    final response = await http
        .get(Uri.parse('$base/api/stream/$key'))
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  bool _isSignedB2Url(String url) {
    return url.contains('backblaze') &&
        url.contains('X-Amz-') &&
        url.contains('X-Amz-Signature');
  }

  /// Extrait la clé objet (chemin après le bucket) d'une URL signée B2.
  String? _extractKey(String url) {
    try {
      final uri = Uri.parse(url);
      // Chemin de la forme: /<bucket>/<key...>
      final segments = uri.pathSegments;
      if (segments.length < 2) return null;
      return segments.sublist(1).join('/');
    } catch (_) {
      return null;
    }
  }

  /// Calcule la date d'expiration à partir des paramètres X-Amz-Date et
  /// X-Amz-Expires présents dans l'URL signée.
  DateTime? _parseExpiration(String url) {
    try {
      final uri = Uri.parse(url);
      final dateStr = uri.queryParameters['X-Amz-Date'];
      final expiresStr = uri.queryParameters['X-Amz-Expires'];
      if (dateStr == null || expiresStr == null) return null;

      final date = DateTime.parse('${dateStr.substring(0, 8)}T'
          '${dateStr.substring(8, 10)}:${dateStr.substring(10, 12)}:'
          '${dateStr.substring(12, 14)}Z');
      final expiresIn = int.tryParse(expiresStr) ?? 3600;
      return date.add(Duration(seconds: expiresIn));
    } catch (_) {
      return null;
    }
  }

  /// Vide le cache mémoire (appelé lors d'un changement de base URL)
  void clearCache() {
    _cache.clear();
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;

  _CachedUrl({required this.url, required this.expiresAt});
}