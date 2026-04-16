import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/storage_service.dart';
import 'package:MyKOG/services/file_storage_service.dart';

/// Statut de téléchargement
enum DownloadStatus {
  notStarted,
  downloading,
  completed,
  failed,
  paused,
}

/// Informations de progression du téléchargement
class DownloadProgress {
  final String teachingId;
  final double progress; // 0.0 à 1.0
  final int downloaded; // bytes
  final int total; // bytes
  final DownloadStatus status;
  final String? error;

  DownloadProgress({
    required this.teachingId,
    required this.progress,
    required this.downloaded,
    required this.total,
    required this.status,
    this.error,
  });

  String get progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';
  String get downloadedSize => FileStorageService.formatFileSize(downloaded);
  String get totalSize => FileStorageService.formatFileSize(total);
}

class DownloadService {
  static const String _downloadedTeachingsKey = 'downloaded_teachings';
  static const String _downloadedDataKey = 'downloaded_data';
  
  static List<String> _downloadedTeachingIds = [];
  static final Map<String, DownloadProgress> _activeDownloads = {};
  static final Map<String, CancelToken> _cancelTokens = {};
  static final Dio _dio = Dio();

  // Callbacks pour notifier l'UI des changements
  static final Map<String, Function(DownloadProgress)?> _progressCallbacks = {};

  static Future<void> initialize() async {
    final stored = StorageService.getString(_downloadedTeachingsKey);
    if (stored != null && stored.isNotEmpty) {
      _downloadedTeachingIds = stored.split(',').where((id) => id.isNotEmpty).toList();
    }
  }

  static Future<void> _saveDownloadedList() async {
    await StorageService.storeString(
      _downloadedTeachingsKey,
      _downloadedTeachingIds.join(','),
    );
  }

  /// Enregistrer un callback pour suivre la progression
  static void registerProgressCallback(
    String teachingId,
    Function(DownloadProgress)? callback,
  ) {
    _progressCallbacks[teachingId] = callback;
  }

  /// Supprimer un callback
  static void unregisterProgressCallback(String teachingId) {
    _progressCallbacks.remove(teachingId);
  }

  /// Télécharger un enseignement complet (audio + image)
  static Future<bool> downloadTeaching(
    Teaching teaching, {
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      // Vérifier si déjà téléchargé
      if (isDownloaded(teaching.id)) {
        debugPrint('Enseignement ${teaching.id} déjà téléchargé');
        return true;
      }

      // Enregistrer le callback si fourni
      if (onProgress != null) {
        registerProgressCallback(teaching.id, onProgress);
      }

      // Créer le CancelToken pour ce téléchargement
      _cancelTokens[teaching.id] = CancelToken();

      // Initialiser la progression
      _updateProgress(teaching.id, 0.0, 0, 0, DownloadStatus.downloading);

      // Télécharger l'audio
      final audioPath = await _downloadAudio(teaching);
      if (audioPath == null) {
        _updateProgress(
          teaching.id,
          0.0,
          0,
          0,
          DownloadStatus.failed,
          error: 'Échec du téléchargement audio',
        );
        return false;
      }

      // Télécharger l'image
      final imagePath = await _downloadImage(teaching);
      if (imagePath == null) {
        debugPrint('Avertissement: Image non téléchargée pour ${teaching.id}');
      }

      // Sauvegarder les métadonnées du téléchargement
      await _saveDownloadMetadata(teaching, audioPath, imagePath);

      // Ajouter à la liste des téléchargements
      if (!_downloadedTeachingIds.contains(teaching.id)) {
        _downloadedTeachingIds.add(teaching.id);
        await _saveDownloadedList();
      }

      // Marquer comme complété
      _updateProgress(teaching.id, 1.0, 1, 1, DownloadStatus.completed);

      // Nettoyer
      _cancelTokens.remove(teaching.id);
      _activeDownloads.remove(teaching.id);

      debugPrint('✅ Téléchargement complété: ${teaching.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur téléchargement: $e');
      _updateProgress(
        teaching.id,
        0.0,
        0,
        0,
        DownloadStatus.failed,
        error: e.toString(),
      );
      return false;
    } finally {
      unregisterProgressCallback(teaching.id);
    }
  }

  /// Télécharger le fichier audio
  static Future<String?> _downloadAudio(Teaching teaching) async {
    try {
      // Vérifier si l'URL est un asset local
      if (teaching.audioUrl.startsWith('assets/') || 
          teaching.audioUrl.startsWith('http') == false) {
        debugPrint('Audio est un asset local, pas de téléchargement nécessaire');
        return teaching.audioUrl;
      }

      final filePath = await FileStorageService.getAudioFilePath(
        teaching.id,
        teaching.audioUrl,
      );

      // Vérifier si déjà téléchargé
      if (await FileStorageService.fileExists(filePath)) {
        debugPrint('Audio déjà existant: $filePath');
        return filePath;
      }

      debugPrint('📥 Téléchargement audio: ${teaching.audioUrl}');

      // Télécharger le fichier
      final response = await _dio.download(
        teaching.audioUrl,
        filePath,
        cancelToken: _cancelTokens[teaching.id],
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total * 0.8; // 80% pour l'audio
            _updateProgress(teaching.id, progress, received, total, DownloadStatus.downloading);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Audio téléchargé: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erreur téléchargement audio: $e');
      return null;
    }
  }

  /// Télécharger l'image de couverture
  static Future<String?> _downloadImage(Teaching teaching) async {
    try {
      // Vérifier si l'URL est un asset local
      if (teaching.artworkUrl.startsWith('assets/') || 
          teaching.artworkUrl.startsWith('http') == false) {
        debugPrint('Image est un asset local, pas de téléchargement nécessaire');
        return teaching.artworkUrl;
      }

      final filePath = await FileStorageService.getImageFilePath(
        teaching.id,
        teaching.artworkUrl,
      );

      // Vérifier si déjà téléchargée
      if (await FileStorageService.fileExists(filePath)) {
        debugPrint('Image déjà existante: $filePath');
        return filePath;
      }

      debugPrint('📥 Téléchargement image: ${teaching.artworkUrl}');

      // Télécharger le fichier
      final response = await _dio.download(
        teaching.artworkUrl,
        filePath,
        cancelToken: _cancelTokens[teaching.id],
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = 0.8 + (received / total * 0.2); // 20% pour l'image
            _updateProgress(teaching.id, progress, received, total, DownloadStatus.downloading);
          }
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Image téléchargée: $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erreur téléchargement image: $e');
      return null;
    }
  }

  /// Sauvegarder les métadonnées du téléchargement
  static Future<void> _saveDownloadMetadata(
    Teaching teaching,
    String? audioPath,
    String? imagePath,
  ) async {
    final metadata = {
      'teachingId': teaching.id,
      'audioPath': audioPath,
      'imagePath': imagePath,
      'downloadedAt': DateTime.now().toIso8601String(),
      'teaching': teaching.toJson(),
    };

    await StorageService.storeJson(
      '${_downloadedDataKey}_${teaching.id}',
      metadata,
    );
  }

  /// Récupérer les métadonnées d'un téléchargement
  static Future<Map<String, dynamic>?> getDownloadMetadata(String teachingId) async {
    return StorageService.getJson('${_downloadedDataKey}_$teachingId');
  }

  /// Obtenir le chemin local de l'audio téléchargé
  static Future<String?> getLocalAudioPath(String teachingId) async {
    final metadata = await getDownloadMetadata(teachingId);
    return metadata?['audioPath'] as String?;
  }

  /// Obtenir le chemin local de l'image téléchargée
  static Future<String?> getLocalImagePath(String teachingId) async {
    final metadata = await getDownloadMetadata(teachingId);
    return metadata?['imagePath'] as String?;
  }

  /// Mettre à jour la progression
  static void _updateProgress(
    String teachingId,
    double progress,
    int downloaded,
    int total,
    DownloadStatus status, {
    String? error,
  }) {
    final downloadProgress = DownloadProgress(
      teachingId: teachingId,
      progress: progress,
      downloaded: downloaded,
      total: total,
      status: status,
      error: error,
    );

    _activeDownloads[teachingId] = downloadProgress;

    // Notifier le callback s'il existe
    _progressCallbacks[teachingId]?.call(downloadProgress);
  }

  /// Obtenir la progression actuelle d'un téléchargement
  static DownloadProgress? getDownloadProgress(String teachingId) {
    return _activeDownloads[teachingId];
  }

  /// Annuler un téléchargement en cours
  static Future<bool> cancelDownload(String teachingId) async {
    try {
      _cancelTokens[teachingId]?.cancel('Téléchargement annulé par l\'utilisateur');
      _activeDownloads.remove(teachingId);
      _cancelTokens.remove(teachingId);
      return true;
    } catch (e) {
      debugPrint('Erreur annulation téléchargement: $e');
      return false;
    }
  }

  /// Supprimer un téléchargement
  static Future<bool> deleteDownload(String teachingId) async {
    try {
      // Annuler si téléchargement en cours
      await cancelDownload(teachingId);

      // Récupérer les métadonnées
      final metadata = await getDownloadMetadata(teachingId);

      // Supprimer les fichiers
      if (metadata != null) {
        final audioPath = metadata['audioPath'] as String?;
        final imagePath = metadata['imagePath'] as String?;

        if (audioPath != null) {
          await FileStorageService.deleteFile(audioPath);
        }
        if (imagePath != null) {
          await FileStorageService.deleteFile(imagePath);
        }
      }

      // Supprimer les métadonnées
      await StorageService.remove('${_downloadedDataKey}_$teachingId');

      // Retirer de la liste
      _downloadedTeachingIds.remove(teachingId);
      await _saveDownloadedList();

      debugPrint('🗑️ Téléchargement supprimé: $teachingId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression téléchargement: $e');
      return false;
    }
  }

  /// Vérifier si un enseignement est téléchargé
  static bool isDownloaded(String teachingId) {
    return _downloadedTeachingIds.contains(teachingId);
  }

  /// Vérifier si un téléchargement est en cours
  static bool isDownloading(String teachingId) {
    return _activeDownloads.containsKey(teachingId) &&
        _activeDownloads[teachingId]?.status == DownloadStatus.downloading;
  }

  /// Obtenir la liste des IDs téléchargés
  static List<String> getDownloadedTeachingIds() {
    return List.from(_downloadedTeachingIds);
  }

  /// Supprimer tous les téléchargements
  static Future<void> clearAllDownloads() async {
    try {
      // Annuler tous les téléchargements en cours
      for (var teachingId in _activeDownloads.keys.toList()) {
        await cancelDownload(teachingId);
      }

      // Supprimer tous les fichiers
      await FileStorageService.clearAllCache();

      // Supprimer toutes les métadonnées
      for (var teachingId in _downloadedTeachingIds) {
        await StorageService.remove('${_downloadedDataKey}_$teachingId');
      }

      // Vider la liste
      _downloadedTeachingIds.clear();
      await _saveDownloadedList();

      debugPrint('🗑️ Tous les téléchargements supprimés');
    } catch (e) {
      debugPrint('❌ Erreur suppression complète: $e');
    }
  }

  /// Obtenir la taille totale des téléchargements
  static Future<String> getTotalDownloadSize() async {
    final size = await FileStorageService.getTotalCacheSize();
    return FileStorageService.formatFileSize(size);
  }

  /// Obtenir des statistiques sur les téléchargements
  static Future<Map<String, dynamic>> getDownloadStatistics() async {
    final totalSize = await FileStorageService.getTotalCacheSize();
    final fileCount = (await FileStorageService.listDownloadedFiles()).length;

    return {
      'totalTeachings': _downloadedTeachingIds.length,
      'totalSize': totalSize,
      'totalSizeFormatted': FileStorageService.formatFileSize(totalSize),
      'totalFiles': fileCount,
      'activeDownloads': _activeDownloads.length,
    };
  }
}
