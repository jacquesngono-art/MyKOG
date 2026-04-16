import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service pour gérer les notifications de lecture audio (comme Spotify)
/// Permet d'afficher les contrôles dans la barre de notification
class AudioNotificationService {
  static AudioHandler? _audioHandler;
  static bool _isInitialized = false;

  /// Initialiser le service de notification audio
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.mycompany.mykog_fixed.audio',
          androidNotificationChannelName: 'MyKOG Audio Playback',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'mipmap/ic_launcher',
          notificationColor: const Color(0xFFd4af37), // MyKOGColors.accent
        ),
      );
      _isInitialized = true;
      debugPrint('✅ AudioNotificationService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur init AudioNotificationService: $e');
    }
  }

  /// Mettre à jour les métadonnées de la notification
  static Future<void> updateMetadata({
    required String id,
    required String title,
    required String artist,
    String? artworkUrl,
    Duration? duration,
  }) async {
    if (_audioHandler == null) return;

    try {
      final mediaItem = MediaItem(
        id: id,
        title: title,
        artist: artist,
        artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        duration: duration,
        playable: true,
      );

      await (_audioHandler as MyAudioHandler).updateMediaItem(mediaItem);
    } catch (e) {
      debugPrint('Erreur updateMetadata: $e');
    }
  }

  /// Mettre à jour l'état de lecture
  static Future<void> updatePlaybackState({
    required bool playing,
    Duration? position,
    Duration? bufferedPosition,
  }) async {
    if (_audioHandler == null) return;

    try {
      await (_audioHandler as MyAudioHandler).updatePlaybackState(
        playing: playing,
        position: position ?? Duration.zero,
        bufferedPosition: bufferedPosition,
      );
    } catch (e) {
      debugPrint('Erreur updatePlaybackState: $e');
    }
  }

  /// Obtenir le AudioHandler
  static AudioHandler? get audioHandler => _audioHandler;
}

/// Handler personnalisé pour gérer les événements de notification
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _currentMediaItem;

  MyAudioHandler() {
    // Écouter les changements de position
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });

    // Écouter les changements d'état
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = state.processingState;

      PlaybackState newState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        newState = playbackState.value.copyWith(
          controls: [
            MediaControl.pause,
            MediaControl.stop,
          ],
          processingState: AudioProcessingState.loading,
        );
      } else if (isPlaying) {
        newState = playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.rewind,
            MediaControl.pause,
            MediaControl.fastForward,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          processingState: AudioProcessingState.ready,
          playing: true,
        );
      } else {
        newState = playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.rewind,
            MediaControl.play,
            MediaControl.fastForward,
            MediaControl.skipToNext,
            MediaControl.stop,
          ],
          processingState: AudioProcessingState.ready,
          playing: false,
        );
      }

      playbackState.add(newState);
    });
  }

  /// Mettre à jour le MediaItem
  Future<void> updateMediaItem(MediaItem item) async {
    _currentMediaItem = item;
    mediaItem.add(item);
  }

  /// Mettre à jour l'état de lecture
  Future<void> updatePlaybackState({
    required bool playing,
    required Duration position,
    Duration? bufferedPosition,
  }) async {
    playbackState.add(playbackState.value.copyWith(
      playing: playing,
      updatePosition: position,
      bufferedPosition: bufferedPosition ?? position,
    ));
  }

  @override
  Future<void> play() async {
    debugPrint('🎵 Notification: Play');
    // L'action sera gérée par AudioPlayerProvider
    playbackState.add(playbackState.value.copyWith(playing: true));
  }

  @override
  Future<void> pause() async {
    debugPrint('⏸️ Notification: Pause');
    playbackState.add(playbackState.value.copyWith(playing: false));
  }

  @override
  Future<void> stop() async {
    debugPrint('⏹️ Notification: Stop');
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    mediaItem.add(null);
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('⏩ Notification: Seek to $position');
    await _player.seek(position);
  }

  @override
  Future<void> rewind() async {
    debugPrint('⏪ Notification: Rewind 15s');
    final position = _player.position;
    final newPosition = position - const Duration(seconds: 15);
    await _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  Future<void> fastForward() async {
    debugPrint('⏩ Notification: Fast forward 15s');
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;
    final newPosition = position + const Duration(seconds: 15);
    await _player.seek(newPosition > duration ? duration : newPosition);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('⏭️ Notification: Skip to next');
    // L'action sera gérée par AudioPlayerProvider
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ Notification: Skip to previous');
    // L'action sera gérée par AudioPlayerProvider
  }
}

