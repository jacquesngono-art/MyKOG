import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/api/live_api_service.dart';
import 'package:MyKOG/widgets/live_comments.dart';
import 'package:MyKOG/theme.dart';

/// Écran de lecture de live stream via LiveKit (WebRTC)
class LivePlayerScreen extends StatefulWidget {
  final LiveStream liveStream;

  const LivePlayerScreen({
    super.key,
    required this.liveStream,
  });

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen> {
  final LiveApiService _apiService = LiveApiService();

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _videoTrack;

  int _viewerCount = 0;
  Timer? _viewerCountTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
    _joinLive();
    _startViewerCountPolling();
  }

  @override
  void dispose() {
    _leaveLive();
    _viewerCountTimer?.cancel();
    _disconnectRoom();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  /// Déconnecter et libérer la room LiveKit
  Future<void> _disconnectRoom() async {
    try {
      await _listener?.dispose();
    } catch (_) {}
    _listener = null;

    final room = _room;
    _room = null;
    if (room != null) {
      try {
        await room.disconnect();
      } catch (_) {}
      try {
        await room.dispose();
      } catch (_) {}
    }
    _videoTrack = null;
  }

  /// Attacher un track vidéo distant
  void _attachVideoTrack(VideoTrack track) {
    if (!mounted || _videoTrack == track) return;
    debugPrint('📺 Track vidéo attaché');
    setState(() {
      _videoTrack = track;
    });
  }

  /// Détacher le track vidéo courant
  void _detachVideoTrack() {
    if (!mounted || _videoTrack == null) return;
    setState(() {
      _videoTrack = null;
    });
  }

  /// Connecter la room LiveKit et afficher le flux du broadcaster
  Future<void> _connectToRoom() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _errorMessage = null;
        });
      }

      // Nettoyer une éventuelle room précédente (cas d'un retry)
      await _disconnectRoom();

      // 1. Déterminer l'URL LiveKit (modèle → server-info → token)
      String? livekitUrl = widget.liveStream.livekitUrl;
      if (livekitUrl == null || livekitUrl.isEmpty) {
        final serverInfo = await _apiService.getServerInfo();
        livekitUrl = serverInfo['livekitUrl'] as String?;
      }

      // 2. Obtenir le token viewer depuis le backend
      final tokenData = await _apiService.getViewerToken(widget.liveStream.id);
      final token = tokenData['token'] as String?;
      livekitUrl ??= tokenData['url'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Token viewer introuvable');
      }
      if (livekitUrl == null || livekitUrl.isEmpty) {
        throw Exception('URL LiveKit introuvable');
      }

      debugPrint(
          '🎥 Connexion LiveKit: $livekitUrl (room: ${tokenData['roomName']})');

      // 3. Créer la room et écouter les événements
      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );
      _room = room;

      final listener = room.createListener();
      _listener = listener;

      listener
        ..on<TrackSubscribedEvent>((event) {
          debugPrint('📡 Track subscribed: ${event.track.kind}');
          final track = event.track;
          if (track is VideoTrack) {
            _attachVideoTrack(track);
          }
        })
        ..on<TrackUnsubscribedEvent>((event) {
          final track = event.track;
          if (track is VideoTrack && track == _videoTrack) {
            _detachVideoTrack();
          }
        })
        ..on<RoomReconnectingEvent>((event) {
          debugPrint('🔄 Reconnexion LiveKit en cours...');
          if (mounted) {
            setState(() {
              _isReconnecting = true;
            });
          }
        })
        ..on<RoomReconnectedEvent>((event) {
          debugPrint('✅ Reconnecté à la room LiveKit');
          if (mounted) {
            setState(() {
              _isReconnecting = false;
            });
          }
          _attachExistingVideoTracks();
        })
        ..on<RoomDisconnectedEvent>((event) {
          debugPrint('🔌 Room LiveKit déconnectée');
          if (mounted) {
            setState(() {
              _isReconnecting = false;
              _videoTrack = null;
              _hasError = true;
              _errorMessage =
                  'La connexion au live a été perdue.\n\nLe live est peut-être terminé ou vérifiez votre connexion internet.';
            });
          }
        });

      // 4. Connecter la room
      await room.connect(livekitUrl, token);

      // 5. Attacher les tracks déjà publiés (arrivée après le début du live)
      _attachExistingVideoTracks();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('✅ Connecté à la room LiveKit');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur connexion LiveKit: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      String errorMsg;
      if (e.toString().contains('pas encore actif')) {
        errorMsg =
            'Le live n\'est pas encore actif.\n\nRéessayez dans quelques instants.';
      } else if (e.toString().contains('connexion internet')) {
        errorMsg = 'Aucune connexion internet.\n\nVérifiez votre réseau.';
      } else {
        errorMsg = 'Erreur de connexion au live:\n${e.toString()}';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = errorMsg;
        });
      }
    }
  }

  /// Attacher les tracks vidéo déjà souscrits parmi les participants distants
  void _attachExistingVideoTracks() {
    final room = _room;
    if (room == null) return;

    for (final participant in room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null) {
          _attachVideoTrack(track);
          return;
        }
      }
    }
  }

  /// Rejoindre le live (incrémenter le compteur)
  Future<void> _joinLive() async {
    try {
      final result = await _apiService.joinLive(widget.liveStream.id);
      if (result != null && mounted) {
        setState(() {
          _viewerCount = result['viewerCount'] ?? 0;
        });
        debugPrint('👥 Rejoint le live: $_viewerCount viewers');
      }
    } catch (e) {
      debugPrint('Erreur joinLive: $e');
    }
  }

  /// Quitter le live (décrémenter le compteur)
  Future<void> _leaveLive() async {
    try {
      final result = await _apiService.leaveLive(widget.liveStream.id);
      debugPrint('👋 Quitté le live: ${result?['viewerCount']} viewers');
    } catch (e) {
      debugPrint('Erreur leaveLive: $e');
    }
  }

  /// Démarrer le polling du compteur de viewers
  void _startViewerCountPolling() {
    // Mettre à jour toutes les 5 secondes
    _viewerCountTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        try {
          final result = await _apiService.getViewerCount(widget.liveStream.id);
          if (result != null && mounted) {
            setState(() {
              _viewerCount = result['viewerCount'] ?? 0;
            });
          }
        } catch (e) {
          debugPrint('Erreur polling viewerCount: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Zone vidéo 16:9 avec overlays
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  // Lecteur vidéo LiveKit
                  Positioned.fill(child: _buildVideoPlayer()),

                  // Header avec informations
                  _buildHeader(),

                  // Bouton retour
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildBackButton(),
                  ),

                  // Compteur de viewers
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildViewerCounter(),
                  ),

                  // Badge LIVE
                  Positioned(
                    top: 52,
                    left: 12,
                    child: _buildLiveBadge(),
                  ),

                  // Indicateur de reconnexion
                  if (_isReconnecting)
                    Positioned(
                      top: 52,
                      right: 8,
                      child: _buildReconnectingBadge(),
                    ),
                ],
              ),
            ),

            // Section commentaires (style Reddit)
            Expanded(
              child: LiveCommentsPanel(liveId: widget.liveStream.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: MyKOGColors.accent),
      );
    }

    if (_hasError) {
      return Container(
        color: context.appColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement du stream',
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Impossible de charger le live',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _connectToRoom,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyKOGColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final videoTrack = _videoTrack;

    // Connecté à la room mais le broadcaster n'a pas encore publié de vidéo
    if (videoTrack == null) {
      return Container(
        color: context.appColors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: MyKOGColors.accent),
              const SizedBox(height: 16),
              Text(
                'En attente du flux vidéo...',
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoTrackRenderer(
          videoTrack,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.liveStream.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.liveStream.pastor,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (widget.liveStream.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.liveStream.description,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildViewerCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MyKOGColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _formatViewerCount(_viewerCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReconnectingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'Reconnexion...',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Formater le nombre de viewers (1234 → 1.2K)
  String _formatViewerCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}
