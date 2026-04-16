import 'package:flutter/material.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/audio_service.dart';

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

  AudioPlayerProvider() {
    _initializeListeners();
  }

  void _initializeListeners() {
    _audioService.currentTeachingStream.listen((teaching) {
      _currentTeaching = teaching;
      notifyListeners();
    });

    _audioService.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });

    _audioService.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioService.durationStream.listen((duration) {
      _duration = duration;
      notifyListeners();
    });

    _audioService.queueStream.listen((queue) {
      _queue = queue;
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
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation audio: ${e.toString()}';
      notifyListeners();
    }
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
