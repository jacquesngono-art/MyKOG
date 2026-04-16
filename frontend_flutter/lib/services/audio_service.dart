import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/storage_service.dart';
import 'package:MyKOG/services/user_service.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/download_service.dart';

enum PlayerState { stopped, loading, playing, paused, completed }

enum AudioRepeatMode { off, one, all }

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Teaching? _currentTeaching;
  List<Teaching> _queue = [];
  int _currentIndex = 0;
  bool _isShuffleOn = false;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;

  // Streams
  final StreamController<Teaching?> _currentTeachingController =
      StreamController<Teaching?>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<List<Teaching>> _queueController =
      StreamController<List<Teaching>>.broadcast();
  final StreamController<bool> _shuffleController =
      StreamController<bool>.broadcast();
  final StreamController<AudioRepeatMode> _repeatModeController =
      StreamController<AudioRepeatMode>.broadcast();

  // Getters for streams
  Stream<Teaching?> get currentTeachingStream =>
      _currentTeachingController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<List<Teaching>> get queueStream => _queueController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<AudioRepeatMode> get repeatModeStream => _repeatModeController.stream;

  // Getters
  Teaching? get currentTeaching => _currentTeaching;
  List<Teaching> get queue => _queue;
  bool get isShuffleOn => _isShuffleOn;
  AudioRepeatMode get repeatMode => _repeatMode;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;
  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  Future<void> initialize() async {
    debugPrint('ℹ️ AudioService initialisé avec just_audio_background');

    // Listen to player state changes
    final player = _player;

    player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _playerStateController.add(PlayerState.stopped);
          break;
        case ProcessingState.loading:
          _playerStateController.add(PlayerState.loading);
          break;
        case ProcessingState.buffering:
          _playerStateController.add(PlayerState.loading);
          break;
        case ProcessingState.ready:
          if (state.playing) {
            _playerStateController.add(PlayerState.playing);
          } else {
            _playerStateController.add(PlayerState.paused);
          }
          break;
        case ProcessingState.completed:
          _playerStateController.add(PlayerState.completed);
          _handlePlaybackCompleted();
          break;
      }
    });

    // Listen to position changes
    player.positionStream.listen((position) {
      _positionController.add(position);
    });

    // Listen to duration changes
    player.durationStream.listen((duration) {
      _durationController.add(duration);
    });

    await _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final currentPlayingJson = StorageService.getJson(
        StorageService.currentPlayingKey,
      );
      if (currentPlayingJson != null) {
        final teachingId = currentPlayingJson['teachingId'] as String?;
        if (teachingId != null) {
          final teaching = await TeachingService.getTeachingById(teachingId);
          if (teaching != null) {
            _currentTeaching = teaching;
            _currentTeachingController.add(_currentTeaching);
          }
        }
      }

      final queueJson = StorageService.getJsonList(StorageService.queueKey);
      if (queueJson.isNotEmpty) {
        _queue = queueJson.map((json) => Teaching.fromJson(json)).toList();
        _queueController.add(_queue);
      }
    } catch (e) {
      // Handle corrupted saved state
    }
  }

  Future<void> _saveCurrentState() async {
    if (_currentTeaching != null) {
      final position = _player.position;
      await StorageService.storeJson(StorageService.currentPlayingKey, {
        'teachingId': _currentTeaching!.id,
        'position': position.inSeconds,
      });
    }

    if (_queue.isNotEmpty) {
      final queueJson = _queue.map((t) => t.toJson()).toList();
      await StorageService.storeJsonList(StorageService.queueKey, queueJson);
    }
  }

  Future<void> playTeaching(
    Teaching teaching, {
    List<Teaching>? playlist,
  }) async {
    try {
      _currentTeaching = teaching;
      _currentTeachingController.add(_currentTeaching);

      if (playlist != null) {
        _queue = List.from(playlist);
        _currentIndex = _queue.indexWhere((t) => t.id == teaching.id);
        if (_currentIndex == -1) {
          _queue.insert(0, teaching);
          _currentIndex = 0;
        }
      } else {
        _queue = [teaching];
        _currentIndex = 0;
      }

      _queueController.add(_queue);

      // Créer les sources audio avec MediaItem tags pour just_audio_background
      final sources = await Future.wait(
        _queue.map((t) => _createAudioSource(t)),
      );

      // Charger les sources dans le player
      if (sources.length > 1) {
        // Playlist avec plusieurs éléments
        await _player.setAudioSources(
          sources,
          initialIndex: _currentIndex,
          initialPosition: Duration.zero,
        );
        debugPrint('▶️ Playlist chargée: ${sources.length} éléments');
      } else {
        // Source unique
        await _player.setAudioSource(sources[0]);
        debugPrint('▶️ Source unique chargée: ${teaching.title}');
      }

      // Démarrer la lecture
      await _player.play();
      debugPrint('▶️ Lecture avec background: ${teaching.title}');

      // Track play count and recently played
      await TeachingService.incrementPlayCount(teaching.id);
      await UserService.addToRecentlyPlayed(teaching.id);
      await _saveCurrentState();
    } catch (e) {
      debugPrint('❌ Erreur playTeaching: $e');
      _playerStateController.add(PlayerState.stopped);
      rethrow;
    }
  }

  /// Créer un AudioSource avec MediaItem tag pour un Teaching
  Future<AudioSource> _createAudioSource(Teaching teaching) async {
    // Vérifier si l'enseignement est téléchargé localement
    String audioSource = teaching.audioUrl;
    bool isLocalFile = false;

    if (DownloadService.isDownloaded(teaching.id)) {
      final localPath = await DownloadService.getLocalAudioPath(teaching.id);
      if (localPath != null && localPath.isNotEmpty) {
        debugPrint('🎵 Source locale: $localPath');
        audioSource = localPath;
        isLocalFile = true;
      }
    }

    // Créer MediaItem pour la notification
    Uri? artUri;
    if (teaching.artworkUrl.startsWith('http')) {
      artUri = Uri.parse(teaching.artworkUrl);
    }

    final mediaItem = MediaItem(
      id: teaching.id,
      album: teaching.category,
      title: teaching.title,
      artist: teaching.speaker,
      duration: teaching.duration,
      artUri: artUri,
    );

    // Créer l'AudioSource approprié
    if (isLocalFile) {
      // Fichier local
      return AudioSource.uri(
        Uri.file(audioSource),
        tag: mediaItem,
      );
    } else if (audioSource.startsWith('http://') ||
        audioSource.startsWith('https://')) {
      // URL distante
      return AudioSource.uri(
        Uri.parse(audioSource),
        tag: mediaItem,
      );
    } else if (audioSource.startsWith('assets/')) {
      // Asset (moins courant avec background)
      return AudioSource.asset(
        audioSource,
        tag: mediaItem,
      );
    } else {
      throw Exception('Format de source audio non supporté: $audioSource');
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentTeaching = null;
    _currentTeachingController.add(null);
    _playerStateController.add(PlayerState.stopped);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekRelative(Duration offset) async {
    final newPosition = _player.position + offset;
    final duration = _player.duration ?? Duration.zero;

    if (newPosition < Duration.zero) {
      await seek(Duration.zero);
    } else if (newPosition > duration) {
      await seek(duration);
    } else {
      await seek(newPosition);
    }
  }

  Future<void> skipToNext() async {
    if (hasNext || _repeatMode == AudioRepeatMode.all) {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
      } else if (_repeatMode == AudioRepeatMode.all) {
        _currentIndex = 0;
      }

      if (_currentIndex < _queue.length) {
        // Utiliser seekToNext du player si disponible, sinon recharger
        try {
          await _player.seekToNext();
        } catch (e) {
          // Fallback: recharger la source
          await playTeaching(_queue[_currentIndex], playlist: _queue);
        }
      }
    }
  }

  Future<void> skipToPrevious() async {
    if (hasPrevious || _repeatMode == AudioRepeatMode.all) {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_repeatMode == AudioRepeatMode.all) {
        _currentIndex = _queue.length - 1;
      }

      if (_currentIndex >= 0 && _currentIndex < _queue.length) {
        // Utiliser seekToPrevious du player si disponible, sinon recharger
        try {
          await _player.seekToPrevious();
        } catch (e) {
          // Fallback: recharger la source
          await playTeaching(_queue[_currentIndex], playlist: _queue);
        }
      }
    }
  }

  void toggleShuffle() {
    _isShuffleOn = !_isShuffleOn;
    _player.setShuffleModeEnabled(_isShuffleOn);
    _shuffleController.add(_isShuffleOn);
  }

  void toggleRepeatMode() {
    switch (_repeatMode) {
      case AudioRepeatMode.off:
        _repeatMode = AudioRepeatMode.one;
        _player.setLoopMode(LoopMode.one);
        break;
      case AudioRepeatMode.one:
        _repeatMode = AudioRepeatMode.all;
        _player.setLoopMode(LoopMode.all);
        break;
      case AudioRepeatMode.all:
        _repeatMode = AudioRepeatMode.off;
        _player.setLoopMode(LoopMode.off);
        break;
    }
    _repeatModeController.add(_repeatMode);
  }

  Future<void> _handlePlaybackCompleted() async {
    // Le player gère automatiquement la répétition via LoopMode
    // Cette méthode est appelée pour gérer les cas spéciaux
    if (_repeatMode == AudioRepeatMode.off && !hasNext) {
      await stop();
    }
  }

  Future<void> addToQueue(Teaching teaching) async {
    _queue.add(teaching);
    _queueController.add(_queue);
    await _saveCurrentState();
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex && _queue.isNotEmpty) {
        // If current song is removed, play next or previous
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        if (_currentIndex >= 0) {
          await playTeaching(_queue[_currentIndex], playlist: _queue);
        }
      }
      _queueController.add(_queue);
      await _saveCurrentState();
    }
  }

  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentIndex = 0;
    _queueController.add(_queue);
    await StorageService.remove(StorageService.queueKey);
  }

  void dispose() {
    _player.dispose();
    _currentTeachingController.close();
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
    _queueController.close();
    _shuffleController.close();
    _repeatModeController.close();
  }
}
