import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/api/live_api_service.dart';
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
  Room? _room;
  RemoteParticipant? _participant;
  VideoTrack? _videoTrack;
  EventsListener<RoomEvent>? _listener;
  final LiveApiService _apiService = LiveApiService();

  int _viewerCount = 0;
  Timer? _viewerCountTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToLive();
    _joinLive();
    _startViewerCountPolling();
  }

  @override
  void dispose() {
    _leaveLive();
    _viewerCountTimer?.cancel();
    _disconnectFromLive();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  /// Se connecter au live via LiveKit
  Future<void> _connectToLive() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Obtenir le token via API
      final tokenData = await _apiService.getViewerToken(widget.liveStream.id);
      if (tokenData == null) {
        throw Exception('Impossible d\'obtenir le token LiveKit');
      }

      final token = tokenData['token']?.toString() ?? '';
      final url = tokenData['url']?.toString() ?? widget.liveStream.livekitUrl;

      if (token.isEmpty || url.isEmpty) {
        throw Exception('Token ou URL LiveKit manquant');
      }

      debugPrint('🎥 Connexion à LiveKit: $url, room: ${tokenData['roomName']}');

      // 2. Connecter la room LiveKit
      _room = Room();
      await _room!.connect(url, token);

      // 3. Écouter les événements de la room
      _setupRoomListeners();

      // 4. Vérifier les participants déjà connectés
      _tryAttachVideoTrack();

      setState(() {
        _isLoading = false;
        _isConnected = true;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur connexion LiveKit: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      String errorMsg = 'Erreur lors de la connexion au live';
      if (e.toString().contains('timeout') ||
          e.toString().contains('Timeout')) {
        errorMsg =
            'Timeout: Le serveur LiveKit ne répond pas.\n\nVérifiez que:\n• Le live est actif\n• Le diffuseur est connecté';
      } else if (e.toString().contains('token') ||
          e.toString().contains('Token')) {
        errorMsg =
            'Erreur d\'authentification LiveKit.\n\nImpossible d\'obtenir un token valide.';
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
  }

  /// Configurer les listeners d'événements de la room
  void _setupRoomListeners() {
    _listener = _room!.createListener();
    _listener!
      ..on<ParticipantConnectedEvent>((_) {
        _tryAttachVideoTrack();
      })
      ..on<TrackSubscribedEvent>((_) {
        _tryAttachVideoTrack();
      })
      ..on<TrackUnsubscribedEvent>((_) {
        _tryAttachVideoTrack();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        _tryAttachVideoTrack();
      })
      ..on<RoomDisconnectedEvent>((_) {
        debugPrint('🔌 Room déconnectée');
        if (mounted) {
          setState(() {
            _isConnected = false;
            _videoTrack = null;
            _participant = null;
          });
        }
      });
  }

  /// Tenter d'attacher la piste vidéo du participant distant (le diffuseur)
  void _tryAttachVideoTrack() {
    if (_room == null || !mounted) return;

    // Parcourir tous les participants distants
    for (final participant in _room!.remoteParticipants.values) {
      // Parcourir les pistes vidéo publiées
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null && track is VideoTrack) {
          if (mounted) {
            setState(() {
              _participant = participant;
              _videoTrack = track;
            });
          }
          debugPrint('📹 Piste vidéo attachée: ${publication.sid}');
          return;
        }
      }
    }

    // Aucune piste vidéo trouvée
    if (mounted && _videoTrack != null) {
      setState(() {
        _videoTrack = null;
        _participant = null;
      });
    }
  }

  /// Déconnecter proprement de la room LiveKit
  Future<void> _disconnectFromLive() async {
    try {
      _listener?.dispose();
      _listener = null;
      if (_room != null) {
        await _room!.disconnect();
        _room = null;
      }
    } catch (e) {
      debugPrint('Erreur déconnexion LiveKit: $e');
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Lecteur vidéo LiveKit
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
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Erreur de chargement du stream',
                style: TextStyle(
                  color: MyKOGColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  _errorMessage ?? 'Impossible de charger le live',
                  style: TextStyle(
                    color: MyKOGColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () {
                  _disconnectFromLive();
                  _connectToLive();
                },
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

    // Connecté mais aucune piste vidéo disponible (diffuseur pas encore prêt)
    if (_videoTrack == null) {
      return Container(
        color: MyKOGColors.primaryDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: MyKOGColors.accent),
              SizedBox(height: 16.h),
              Text(
                'En attente du diffuseur...',
                style: TextStyle(
                  color: MyKOGColors.textPrimary,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Le live va démarrer automatiquement',
                style: TextStyle(
                  color: MyKOGColors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Déconnecté
    if (!_isConnected) {
      return Container(
        color: MyKOGColors.primaryDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                color: MyKOGColors.textSecondary,
                size: 64.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'Déconnecté du live',
                style: TextStyle(
                  color: MyKOGColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () {
                  _disconnectFromLive();
                  _connectToLive();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reconnecter'),
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

    // Afficher la vidéo LiveKit
    return Center(
      child: VideoTrackRenderer(
        _videoTrack!,
        fit: VideoViewFit.cover,
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
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.liveStream.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.white70,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  widget.liveStream.pastor,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            if (widget.liveStream.description.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                widget.liveStream.description,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: MyKOGColors.accent.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_red_eye,
            color: Colors.white,
            size: 16.sp,
          ),
          SizedBox(width: 6.w),
          Text(
            _formatViewerCount(_viewerCount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20.r),
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
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
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
