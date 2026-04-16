import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/api/live_api_service.dart';
import 'package:MyKOG/theme.dart';

/// Écran de lecture de live stream
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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  VlcPlayerController? _vlcPlayerController;
  final LiveApiService _apiService = LiveApiService();
  
  int _viewerCount = 0;
  Timer? _viewerCountTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _useVlcPlayer = false; // Désactiver VLC temporairement (problème d'initialisation PlatformException)

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _joinLive();
    _startViewerCountPolling();
  }

  @override
  void dispose() {
    _leaveLive();
    _viewerCountTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _vlcPlayerController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  /// Initialiser le lecteur vidéo
  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Vérifier si l'URL est valide
      final streamUrl = widget.liveStream.streamUrl;
      if (streamUrl.isEmpty) {
        throw Exception('URL de stream vide');
      }

      // Vérifier que c'est une URL HTTP valide
      if (!streamUrl.startsWith('http://') && !streamUrl.startsWith('https://')) {
        throw Exception('URL de stream invalide (doit commencer par http:// ou https://): $streamUrl');
      }

      // Vérifier que c'est une URL HLS (.m3u8)
      if (!streamUrl.contains('.m3u8')) {
        debugPrint('⚠️ URL ne semble pas être une URL HLS: $streamUrl');
      }

      debugPrint('🎥 Initialisation du lecteur avec URL: $streamUrl');

      // Utiliser directement video_player pour HLS (VLC désactivé temporairement à cause de PlatformException)
      // video_player supporte nativement HLS et fonctionne bien avec les fichiers générés par FFmpeg
      debugPrint('🎬 Initialisation video_player (HLS compatible)...');
      
      _useVlcPlayer = false;
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {
          'User-Agent': 'MyKOG-Flutter',
        },
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialiser le lecteur avec un timeout plus long pour HLS (15 secondes)
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout lors de l\'initialisation du lecteur vidéo.\n\nLe stream peut ne pas être encore prêt. Attendez 10-15 secondes après le démarrage du stream OBS.');
        },
      );
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: MyKOGColors.accent,
          handleColor: MyKOGColors.accent,
          backgroundColor: MyKOGColors.textSecondary,
          bufferedColor: MyKOGColors.textSecondary.withOpacity(0.5),
        ),
        placeholder: Container(
          color: MyKOGColors.primaryDark,
          child: const Center(
            child: CircularProgressIndicator(color: MyKOGColors.accent),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: MyKOGColors.primaryDark,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de lecture',
                    style: TextStyle(color: MyKOGColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(color: MyKOGColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _initializePlayer,
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
        },
      );

      debugPrint('✅ video_player initialisé avec succès');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur initialisation player: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      // Message d'erreur plus clair selon le type d'erreur
      String errorMsg = 'Erreur lors du chargement du stream';
      if (e.toString().contains('MediaCodec') || e.toString().contains('ExoPlaybackException')) {
        errorMsg = 'Le stream n\'est pas encore disponible.\n\nVérifiez que:\n• OBS stream est actif\n• Les fichiers HLS sont créés\n• Attendez 10-15 secondes après le démarrage du stream';
      } else if (e.toString().contains('Timeout')) {
        errorMsg = 'Timeout: Le stream ne répond pas.\n\nVérifiez que:\n• Le stream est actif dans OBS\n• L\'URL est correcte: ${widget.liveStream.streamUrl}';
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        errorMsg = 'Stream introuvable (404).\n\nLe stream n\'est peut-être pas encore disponible.\nAttendez que OBS crée les fichiers HLS.';
      } else {
        errorMsg = 'Erreur: ${e.toString()}\n\nURL: ${widget.liveStream.streamUrl}';
      }
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = errorMsg;
      });
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
        child: Stack(
          children: [
            // Lecteur vidéo
            _buildVideoPlayer(),

            // Header avec informations
            _buildHeader(),

            // Bouton retour
            Positioned(
              top: 16,
              left: 16,
              child: _buildBackButton(),
            ),

            // Compteur de viewers
            Positioned(
              top: 16,
              right: 16,
              child: _buildViewerCounter(),
            ),

            // Badge LIVE
            Positioned(
              top: 70,
              left: 16,
              child: _buildLiveBadge(),
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
        color: MyKOGColors.primaryDark,
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
                  color: MyKOGColors.textPrimary,
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
                    color: MyKOGColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializePlayer,
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

    // Utiliser VLC Player si disponible (pour MediaTek), sinon Chewie
    if (_useVlcPlayer && _vlcPlayerController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VlcPlayer(
            controller: _vlcPlayerController!,
            aspectRatio: 16 / 9,
            placeholder: const Center(
              child: CircularProgressIndicator(color: MyKOGColors.accent),
            ),
          ),
        ),
      );
    }

    if (_chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: MyKOGColors.accent),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
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

