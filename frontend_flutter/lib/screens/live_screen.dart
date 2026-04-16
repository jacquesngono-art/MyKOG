import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/services/live_stream_service.dart';
import 'package:MyKOG/screens/live_player_screen.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';
import 'package:MyKOG/services/connectivity_service.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen>
    with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  List<LiveStream> _liveStreams = [];
  List<LiveStream> _scheduledStreams = [];
  LiveStream? _activeLive;
  bool _isLoading = true;
  bool _isOffline = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
    _loadData();
    // Vérifier le live actif toutes les 10 secondes seulement si online
    if (!_isOffline) {
      _startActiveLivePolling();
    }
  }

  void _checkConnectivity() {
    _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOffline = !isConnected;
        });
        if (isConnected) {
          _loadData();
          _startActiveLivePolling();
        }
      }
    });
    setState(() {
      _isOffline = !_connectivityService.isConnected;
    });
  }

  void _startActiveLivePolling() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _checkActiveLive();
        _startActiveLivePolling();
      }
    });
  }

  Future<void> _checkActiveLive() async {
    try {
      final activeLive = await LiveStreamService.getActiveLive();
      if (mounted) {
        setState(() {
          _activeLive = activeLive;
          // Si un live actif existe et qu'on est sur l'onglet "Live", ouvrir automatiquement
          if (activeLive != null && _tabController.index == 0 && _liveStreams.isEmpty) {
            _openLiveStream(activeLive);
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur _checkActiveLive: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_isOffline) {
        // En mode offline, pas de live disponible
        setState(() {
          _liveStreams = [];
          _scheduledStreams = [];
          _activeLive = null;
          _isLoading = false;
        });
        return;
      }

      // Charger depuis l'API
      final activeLive = await LiveStreamService.getActiveLive();
      final live = await LiveStreamService.getLiveStreams();
      final scheduled = await LiveStreamService.getScheduledStreams();

      if (mounted) {
        setState(() {
          _activeLive = activeLive;
          _liveStreams = live;
          _scheduledStreams = scheduled;
          _isLoading = false;
        });

        // Si un live actif existe, l'afficher en premier dans la liste
        if (activeLive != null && !_liveStreams.any((s) => s.id == activeLive.id)) {
          setState(() {
            _liveStreams.insert(0, activeLive);
          });
        }
      }
    } catch (e) {
      // En cas d'erreur, considérer comme offline
      if (mounted) {
        setState(() {
          _isOffline = true;
          _liveStreams = [];
          _scheduledStreams = [];
          _activeLive = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: MyKOGColors.accent))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLiveTab(),
                        _buildScheduledTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MyKOGColors.primaryDark, MyKOGColors.secondary],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyKOGColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.live_tv, color: MyKOGColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.liveServices,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                l10n.watchInRealTime,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: MyKOGColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: MyKOGColors.primaryDark,
        unselectedLabelColor: MyKOGColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: AppLocalizations.of(context)!.liveNow),
          Tab(text: AppLocalizations.of(context)!.scheduled),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    final l10n = AppLocalizations.of(context)!;
    
    // Si un live actif existe, l'afficher en grand en haut
    if (_activeLive != null) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: MyKOGColors.accent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Carte principale pour le live actif
            _buildActiveLiveCard(_activeLive!),
            const SizedBox(height: 16),
            // Autres lives en cours
            if (_liveStreams.where((s) => s.id != _activeLive!.id).isNotEmpty) ...[
              Text(
                'Autres lives en cours',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ..._liveStreams
                  .where((s) => s.id != _activeLive!.id)
                  .map((stream) => _buildLiveStreamCard(stream))
                  .toList(),
            ],
          ],
        ),
      );
    }
    
    if (_liveStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.live_tv,
              size: 64,
              color: MyKOGColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _isOffline ? 'Mode hors ligne' : l10n.noLiveStreamsNow,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOffline
                  ? 'Les lives ne sont pas disponibles hors ligne'
                  : l10n.checkBackLater,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: MyKOGColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _liveStreams.length,
        itemBuilder: (context, index) {
          final stream = _liveStreams[index];
          return _buildLiveStreamCard(stream)
              .animate(delay: (index * 100).ms)
              .fadeIn()
              .slideX();
        },
      ),
    );
  }

  Widget _buildScheduledTab() {
    if (_scheduledStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isOffline ? Icons.wifi_off : Icons.calendar_today,
              size: 64,
              color: MyKOGColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _isOffline ? 'Mode hors ligne' : 'Aucun live programmé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            if (_isOffline)
              Text(
                'Les lives programmés ne sont pas disponibles hors ligne',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textTertiary,
                    ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: MyKOGColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _scheduledStreams.length,
        itemBuilder: (context, index) {
          final stream = _scheduledStreams[index];
          return _buildScheduledStreamCard(stream)
              .animate(delay: (index * 100).ms)
              .fadeIn()
              .slideX();
        },
      ),
    );
  }

  Widget _buildLiveStreamCard(LiveStream stream) {
    return GestureDetector(
      onTap: () => _openLiveStream(stream),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: stream.thumbnailUrl.isNotEmpty
                          ? Image.asset(
                              stream.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: MyKOGColors.secondary,
                                child: const Center(
                                  child: Icon(
                                    Icons.live_tv,
                                    color: MyKOGColors.accent,
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: MyKOGColors.secondary,
                              child: const Center(
                                child: Icon(
                                  Icons.live_tv,
                                  color: MyKOGColors.accent,
                                  size: 32,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(
                                  onPlay: (controller) => controller.repeat())
                              .fadeIn(duration: 500.ms)
                              .then()
                              .fadeOut(duration: 500.ms),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${stream.viewerCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                stream.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person,
                      size: 16, color: MyKOGColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    stream.pastor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stream.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MyKOGColors.textTertiary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledStreamCard(LiveStream stream) {
    final scheduledDate = stream.scheduledAt;
    String scheduledText = '';

    if (scheduledDate != null) {
      final now = DateTime.now();
      final difference = scheduledDate.difference(now);

      if (difference.inDays > 0) {
        scheduledText =
            'In ${difference.inDays} day${difference.inDays > 1 ? "s" : ""}';
      } else if (difference.inHours > 0) {
        scheduledText =
            'In ${difference.inHours} hour${difference.inHours > 1 ? "s" : ""}';
      } else {
        scheduledText = 'Starting soon';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: stream.thumbnailUrl.isNotEmpty
                  ? Image.asset(
                      stream.thumbnailUrl,
                      width: 120,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: MyKOGColors.secondary,
                        child: const Center(
                          child: Icon(
                            Icons.live_tv,
                            color: MyKOGColors.accent,
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 90,
                      color: MyKOGColors.secondary,
                      child: const Center(
                        child: Icon(
                          Icons.live_tv,
                          color: MyKOGColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 14, color: MyKOGColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        stream.pastor,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: MyKOGColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: MyKOGColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          scheduledText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: MyKOGColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.notifications_outlined,
                color: MyKOGColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLiveCard(LiveStream stream) {
    return GestureDetector(
      onTap: () => _openLiveStream(stream),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyKOGColors.accent.withValues(alpha: 0.2),
              MyKOGColors.secondary,
            ],
          ),
          border: Border.all(
            color: MyKOGColors.accent.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: stream.thumbnailUrl.isNotEmpty
                        ? Image.asset(
                            stream.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: MyKOGColors.secondary,
                              child: const Center(
                                child: Icon(
                                  Icons.live_tv,
                                  color: MyKOGColors.accent,
                                  size: 48,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: MyKOGColors.secondary,
                            child: const Center(
                              child: Icon(
                                Icons.live_tv,
                                color: MyKOGColors.accent,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 500.ms)
                            .then()
                            .fadeOut(duration: 500.ms),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE MAINTENANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${stream.viewerCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: MyKOGColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: MyKOGColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        stream.pastor,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  if (stream.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      stream.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MyKOGColors.textTertiary,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Regarder maintenant',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLiveStream(LiveStream stream) {
    // Naviguer vers l'écran de lecture live
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePlayerScreen(liveStream: stream),
      ),
    ).then((_) {
      // Rafraîchir les données quand on revient
      _loadData();
    });
  }
}
