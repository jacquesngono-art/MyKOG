import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/audio_service.dart';
import 'package:MyKOG/services/hive_storage_service.dart';
import 'package:MyKOG/services/download_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  Teaching? _currentTeaching;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _duration;
  List<Teaching> _queue = [];
  bool _isShuffleOn = false;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;
  String? _errorMessage;

  // Getters
  Teaching? get currentTeaching => _currentTeaching;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration? get duration => _duration;
  List<Teaching> get queue => _queue;
  bool get isShuffleOn => _isShuffleOn;
  AudioRepeatMode get repeatMode => _repeatMode;
  bool get isPlaying => _playerState == PlayerState.playing;
  bool get isLoading => _playerState == PlayerState.loading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasNext => _audioService.hasNext;
  bool get hasPrevious => _audioService.hasPrevious;

  // Clés de persistance
  static const String _currentTeachingKey = 'audio_current_teaching';
  static const String _positionKey = 'audio_position_ms';
  static const String _queueKey = 'audio_queue';

  // Throttle pour éviter trop d'écritures de position
  DateTime _lastPositionSave = DateTime.now();
  static const _positionSaveInterval = Duration(seconds: 5);

  AudioPlayerProvider() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _audioService.currentTeachingStream.listen((teaching) {
      _currentTeaching = teaching;
      _saveCurrentTeaching();
      notifyListeners();
    });

    _audioService.playerStateStream.listen((state) {
      _playerState = state;
      // Sauvegarder la position quand on met en pause ou on arrête
      if (state == PlayerState.paused || state == PlayerState.stopped) {
        _savePosition();
      }
      notifyListeners();
    });

    _audioService.positionStream.listen((position) {
      _position = position;
      // Throttle: sauvegarder la position toutes les 5 secondes
      final now = DateTime.now();
      if (now.difference(_lastPositionSave) > _positionSaveInterval) {
        _lastPositionSave = now;
        _savePosition();
      }
      notifyListeners();
    });

    _audioService.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioService.queueStream.listen((queue) {
      _queue = queue;
      _saveQueue();
      notifyListeners();
    });

    _audioService.shuffleStream.listen((shuffle) {
      _isShuffleOn = shuffle;
      notifyListeners();
    });

    _audioService.repeatModeStream.listen((repeatMode) {
      _repeatMode = repeatMode;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    try {
      await _audioService.initialize();
      _errorMessage = null;
      // Restaurer l'état audio (Spotify-like resume)
      await _restoreState();
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation audio: ${e.toString()}';
      notifyListeners();
    }
  }

  // ── Persistance locale ─────────────────────────────────────────────────────
  Future<void> _saveCurrentTeaching() async {
    try {
      if (_currentTeaching != null) {
        final json = jsonEncode(_currentTeaching!.toJson());
        await HiveStorageService.storeString(_currentTeachingKey, json);
      } else {
        await HiveStorageService.delete(_currentTeachingKey);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde teaching courant: $e');
    }
  }

  Future<void> _savePosition() async {
    try {
      await HiveStorageService.storeInt(_positionKey, _position.inMilliseconds);
    } catch (_) {}
  }

  Future<void> _saveQueue() async {
    try {
      if (_queue.isNotEmpty) {
        final list = _queue.map((t) => t.toJson()).toList();
        await HiveStorageService.storeString(_queueKey, jsonEncode(list));
      } else {
        await HiveStorageService.delete(_queueKey);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde queue: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      // Restaurer le teaching courant
      final teachingJson = HiveStorageService.getString(_currentTeachingKey);
      if (teachingJson != null && teachingJson.isNotEmpty) {
        final map = jsonDecode(teachingJson) as Map<String, dynamic>;
        final teaching = Teaching.fromJson(map);

        // IMPORTANT: Ne restaurer que si téléchargé (offline-safe)
        // Si non téléchargé, effacer l'état pour éviter l'erreur
        if (!DownloadService.isDownloaded(teaching.id)) {
          debugPrint('⚠️ Teaching non téléchargé, effacement de l\'état audio');
          await _clearAudioState();
          return;
        }

        // Restaurer la queue
        List<Teaching> restoredQueue = [teaching];
        final queueJson = HiveStorageService.getString(_queueKey);
        if (queueJson != null && queueJson.isNotEmpty) {
          final list = jsonDecode(queueJson) as List<dynamic>;
          restoredQueue = list
              .map((e) => Teaching.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        // Restaurer la position
        final posMs = HiveStorageService.getInt(_positionKey);
        final savedPosition = Duration(milliseconds: posMs);

        // Charger le teaching en pause à la position sauvegardée
        _currentTeaching = teaching;
        _position = savedPosition;
        _queue = restoredQueue;
        _playerState = PlayerState.paused;
        notifyListeners();

        // Charger la source audio et seek à la position (en pause)
        // trackMetrics: false → ne pas attendre les appels réseau (incrementPlayCount,
        // addToRecentlyPlayed) au démarrage : sinon l'écran de chargement bloque
        // des dizaines de secondes si le backend est injoignable.
        await _audioService.playTeaching(
          teaching,
          playlist: restoredQueue,
          trackMetrics: false,
        );
        await Future.delayed(const Duration(milliseconds: 300));
        await _audioService.seek(savedPosition);
        await _audioService.pause();

        debugPrint('✅ État audio restauré: ${teaching.title} @ ${savedPosition.inSeconds}s');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur restauration état audio: $e');
      // Effacer l'état pour éviter des erreurs répétées
      await _clearAudioState();
    }
  }

  /// Effacer l'état audio sauvegardé
  Future<void> _clearAudioState() async {
    try {
      await HiveStorageService.delete(_currentTeachingKey);
      await HiveStorageService.delete(_positionKey);
      await HiveStorageService.delete(_queueKey);
      _currentTeaching = null;
      _position = Duration.zero;
      _queue = [];
      _playerState = PlayerState.stopped;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> playTeaching(Teaching teaching,
      {List<Teaching>? playlist}) async {
    try {
      await _audioService.playTeaching(teaching, playlist: playlist);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur de chargement audio: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> stop() async {
    await _audioService.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> seekForward() async {
    await _audioService.seekRelative(const Duration(seconds: 15));
  }

  Future<void> seekBackward() async {
    await _audioService.seekRelative(const Duration(seconds: -15));
  }

  Future<void> skipToNext() async {
    await _audioService.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await _audioService.skipToPrevious();
  }

  void toggleShuffle() {
    _audioService.toggleShuffle();
  }

  void toggleRepeatMode() {
    _audioService.toggleRepeatMode();
  }

  Future<void> addToQueue(Teaching teaching) async {
    await _audioService.addToQueue(teaching);
  }

  Future<void> removeFromQueue(int index) async {
    await _audioService.removeFromQueue(index);
  }

  Future<void> clearQueue() async {
    await _audioService.clearQueue();
  }

  double get progress {
    if (_duration == null || _duration!.inMilliseconds == 0) return 0.0;
    return _position.inMilliseconds / _duration!.inMilliseconds;
  }

  String get positionText {
    return _formatDuration(_position);
  }

  String get durationText {
    return _formatDuration(_duration ?? Duration.zero);
  }

  String get remainingText {
    if (_duration == null) return '0:00';
    final remaining = _duration! - _position;
    return '-${_formatDuration(remaining)}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
