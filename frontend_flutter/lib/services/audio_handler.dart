import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Handler audio pour gérer les commandes de la notification
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer player = AudioPlayer();
  
  MyAudioHandler() {
    _init();
  }

  void _init() {
    // Écouter les changements de position
    player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: player.bufferedPosition,
      ));
    });

    // Écouter les changements d'état du player
    player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = _getProcessingState(state.processingState);

      playbackState.add(playbackState.value.copyWith(
        controls: _getControls(isPlaying),
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: isPlaying,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ));
    });
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  List<MediaControl> _getControls(bool isPlaying) {
    return [
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];
  }

  @override
  Future<void> play() async {
    debugPrint('🎵 Notification: Play');
    await player.play();
  }

  @override
  Future<void> pause() async {
    debugPrint('⏸️ Notification: Pause');
    await player.pause();
  }

  @override
  Future<void> stop() async {
    debugPrint('⏹️ Notification: Stop');
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('⏩ Notification: Seek to $position');
    await player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('⏭️ Notification: Skip to next');
    // Cette action sera propagée via un stream
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('⏮️ Notification: Skip to previous');
    // Cette action sera propagée via un stream
  }

  @override
  Future<void> fastForward() async {
    debugPrint('⏩⏩ Notification: Fast forward');
    final newPosition = player.position + const Duration(seconds: 15);
    await player.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    debugPrint('⏪⏪ Notification: Rewind');
    final newPosition = player.position - const Duration(seconds: 15);
    await player.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  /// Charger et jouer une URL
  Future<void> loadAndPlay(String url, MediaItem item) async {
    mediaItem.add(item);
    await player.setUrl(url);
    await player.play();
  }

  /// Charger et jouer un fichier local
  Future<void> loadAndPlayFile(String filePath, MediaItem item) async {
    mediaItem.add(item);
    await player.setFilePath(filePath);
    await player.play();
  }

  /// Libérer les ressources
  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
}
