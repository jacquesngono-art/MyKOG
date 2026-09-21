import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer le stockage des fichiers locaux (audio, images, pdfs)
class FileStorageService {
  static const String _audioFolder = 'audio_cache';
  static const String _imageFolder = 'image_cache';
  static const String _pdfFolder = 'pdf_cache';

  /// Obtenir le répertoire de l'application
  static Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Obtenir le répertoire pour les audios
  static Future<Directory> getAudioDirectory() async {
    final appDir = await getAppDirectory();
    final audioDir = Directory('${appDir.path}/$_audioFolder');
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    return audioDir;
  }

  /// Obtenir le répertoire pour les images
  static Future<Directory> getImageDirectory() async {
    final appDir = await getAppDirectory();
    final imageDir = Directory('${appDir.path}/$_imageFolder');
    
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    
    return imageDir;
  }

  /// Obtenir le répertoire pour les PDFs
  static Future<Directory> getPdfDirectory() async {
    final appDir = await getAppDirectory();
    final pdfDir = Directory('${appDir.path}/$_pdfFolder');
    
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    
    return pdfDir;
  }

  /// Générer un nom de fichier safe à partir d'une URL
  static String sanitizeFileName(String url) {
    // Extraire le nom du fichier de l'URL ou créer un hash
    final uri = Uri.tryParse(url);
    if (uri == null) return url.hashCode.toString();
    
    String filename = uri.pathSegments.isNotEmpty 
        ? uri.pathSegments.last 
        : url.hashCode.toString();
    
    // Nettoyer le nom de fichier
    filename = filename.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
    
    return filename;
  }

  /// Obtenir le chemin complet pour un fichier audio
  static Future<String> getAudioFilePath(String teachingId, String audioUrl) async {
    final audioDir = await getAudioDirectory();
    final fileName = '${teachingId}_${sanitizeFileName(audioUrl)}';
    return '${audioDir.path}/$fileName';
  }

  /// Obtenir le chemin complet pour une image
  static Future<String> getImageFilePath(String teachingId, String imageUrl) async {
    final imageDir = await getImageDirectory();
    final fileName = '${teachingId}_${sanitizeFileName(imageUrl)}';
    return '${imageDir.path}/$fileName';
  }

  /// Obtenir le chemin complet pour un PDF
  static Future<String> getPdfFilePath(String textResumeId, String pdfUrl) async {
    final pdfDir = await getPdfDirectory();
    final fileName = '${textResumeId}_${sanitizeFileName(pdfUrl)}';
    return '${pdfDir.path}/$fileName';
  }

  /// Vérifier si un fichier existe
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('Erreur vérification fichier: $e');
      return false;
    }
  }

  /// Supprimer un fichier
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur suppression fichier: $e');
      return false;
    }
  }

  /// Obtenir la taille d'un fichier en bytes
  static Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('Erreur lecture taille fichier: $e');
      return 0;
    }
  }

  /// Obtenir la taille totale des fichiers téléchargés
  static Future<int> getTotalCacheSize() async {
    try {
      int totalSize = 0;

      // Taille des audios
      final audioDir = await getAudioDirectory();
      if (await audioDir.exists()) {
        await for (var entity in audioDir.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      // Taille des images
      final imageDir = await getImageDirectory();
      if (await imageDir.exists()) {
        await for (var entity in imageDir.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      // Taille des PDFs
      final pdfDir = await getPdfDirectory();
      if (await pdfDir.exists()) {
        await for (var entity in pdfDir.list()) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Erreur calcul taille cache: $e');
      return 0;
    }
  }

  /// Taille des téléchargements (audio + images) hors PDF
  static Future<int> getDownloadsSize() async {
    try {
      int totalSize = 0;
      final audioDir = await getAudioDirectory();
      if (await audioDir.exists()) {
        await for (var entity in audioDir.list()) {
          if (entity is File) totalSize += await entity.length();
        }
      }
      final imageDir = await getImageDirectory();
      if (await imageDir.exists()) {
        await for (var entity in imageDir.list()) {
          if (entity is File) totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Erreur calcul taille downloads: $e');
      return 0;
    }
  }

  /// Taille du cache PDF uniquement
  static Future<int> getPdfCacheSize() async {
    try {
      int totalSize = 0;
      final pdfDir = await getPdfDirectory();
      if (await pdfDir.exists()) {
        await for (var entity in pdfDir.list()) {
          if (entity is File) totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      debugPrint('Erreur calcul taille PDF: $e');
      return 0;
    }
  }

  /// Formater la taille en format lisible (KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Nettoyer les fichiers de téléchargement (audio + image) uniquement
  /// Le cache PDF (textes-résumés) n'est PAS supprimé
  static Future<bool> clearDownloadsOnly() async {
    try {
      final audioDir = await getAudioDirectory();
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }

      final imageDir = await getImageDirectory();
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }

      return true;
    } catch (e) {
      debugPrint('Erreur nettoyage downloads: $e');
      return false;
    }
  }

  /// Nettoyer tous les fichiers du cache
  static Future<bool> clearAllCache() async {
    try {
      // Supprimer le dossier audio
      final audioDir = await getAudioDirectory();
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
      
      // Supprimer le dossier images
      final imageDir = await getImageDirectory();
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }
      
      // Supprimer le dossier PDFs
      final pdfDir = await getPdfDirectory();
      if (await pdfDir.exists()) {
        await pdfDir.delete(recursive: true);
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur nettoyage cache: $e');
      return false;
    }
  }

  /// Lister tous les fichiers téléchargés
  static Future<List<String>> listDownloadedFiles() async {
    List<String> files = [];
    
    try {
      final audioDir = await getAudioDirectory();
      if (await audioDir.exists()) {
        await for (var entity in audioDir.list()) {
          if (entity is File) {
            files.add(entity.path);
          }
        }
      }
      
      final imageDir = await getImageDirectory();
      if (await imageDir.exists()) {
        await for (var entity in imageDir.list()) {
          if (entity is File) {
            files.add(entity.path);
          }
        }
      }
      
      final pdfDir = await getPdfDirectory();
      if (await pdfDir.exists()) {
        await for (var entity in pdfDir.list()) {
          if (entity is File) {
            files.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur listage fichiers: $e');
    }
    
    return files;
  }
}

