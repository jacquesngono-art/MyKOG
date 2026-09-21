import 'dart:async';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/hive_storage_service.dart';
import 'package:MyKOG/services/user_service.dart';
import 'package:MyKOG/services/teaching_service.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/b2_stream_refresher.dart';
import 'package:MyKOG/services/audio_handler.dart';

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

  audio_service.AudioHandler? _audioHandler;
  audio_service.AudioHandler? get audioHandler => _audioHandler;

  Future<void> initialize() async {
    if (_audioHandler != null) return;
    debugPrint('ℹ️ AudioService: création de la session audio Android…');

    // Session audio UNIQUE : le player utilisé par l'UI est celui qui
    // pilote la notification média (play/pause/seek depuis la notification
    // agissent sur le vrai lecteur → le son sort toujours).
    _audioHandler = await audio_service.AudioService.init(
      builder: () => MyAudioHandler(_player),
      config: audio_service.AudioServiceConfig(
        androidNotificationChannelId: 'com.mykog.audio.channel',
        androidNotificationChannelName: 'MyKOG Audio Playback',
        androidNotificationChannelDescription: 'Lecture audio en arrière-plan',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    debugPrint('✅ Session audio créée (player unique branché)');

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

    // Nettoyage one-shot des clés legacy de persistance audio.
    // La persistance est désormais gérée uniquement par AudioPlayerProvider
    // (clés audio_current_teaching / audio_position_ms / audio_queue).
    if (HiveStorageService.containsKey('audio_state_cleaned_v2') == false) {
      await HiveStorageService.delete('current_playing');
      await HiveStorageService.delete('queue');
      await HiveStorageService.storeBool('audio_state_cleaned_v2', true);
      debugPrint('🧹 Anciennes clés audio (legacy) supprimées');
    }
  }

  Future<void> playTeaching(
    Teaching teaching, {
    List<Teaching>? playlist,
    bool trackMetrics = true,
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

      // Créer les sources audio avec MediaItem tags pour la notification
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

      // Track play count and recently played (non-bloquant, en arrière-plan)
      if (trackMetrics) {
        unawaited(
          Future.wait<Object?>([
            TeachingService.incrementPlayCount(teaching.id),
            UserService.addToRecentlyPlayed(teaching.id),
          ]).then(
            (values) => debugPrint('✅ Metrics trackées'),
            onError: (Object e, StackTrace st) =>
                debugPrint('⚠️ Track metrics: $e'),
          ),
        );
      }
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
      if (localPath != null && localPath.isNotEmpty && !localPath.startsWith('assets/')) {
        debugPrint('🎵 Source locale: $localPath');
        audioSource = localPath;
        isLocalFile = true;
      }
    }

    if (!isLocalFile && !audioSource.startsWith('assets/')) {
      // Régénérer les URLs B2 signées si proches de l'expiration
      try {
        audioSource =
            await B2StreamRefresher.instance.refresh(audioSource);
      } catch (e) {
        debugPrint('⚠️ Refresh URL audio impossible, fallback URL originale: $e');
      }
    }

    // Créer MediaItem pour la notification
    Uri? artUri;
    if (teaching.artworkUrl.startsWith('http')) {
      try {
        final freshArtwork =
            await B2StreamRefresher.instance.refresh(teaching.artworkUrl);
        artUri = Uri.parse(freshArtwork);
      } catch (e) {
        debugPrint('⚠️ Refresh artwork impossible: $e');
      }
    }

    final mediaItem = audio_service.MediaItem(
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
    }
  }

  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentIndex = 0;
    _queueController.add(_queue);
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
