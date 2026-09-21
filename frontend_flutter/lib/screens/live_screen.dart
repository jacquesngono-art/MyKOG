import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/models/live_stream.dart';
import 'package:MyKOG/services/live_stream_service.dart';
import 'package:MyKOG/screens/live_player_screen.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';
import 'package:MyKOG/services/connectivity_service.dart';
import 'package:MyKOG/services/content_refresher.dart';

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

  int _lastContentVersion = ContentRefresher.instance.version;

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
    // Recharger silencieusement quand le contenu change (push FCM / polling)
    ContentRefresher.instance.addListener(_onContentRefreshed);
  }

  /// Nouveau contenu disponible (nouveau live / modification) → recharger
  void _onContentRefreshed() {
    if (!mounted) return;
    final currentVersion = ContentRefresher.instance.version;
    if (currentVersion == _lastContentVersion) return;
    _lastContentVersion = currentVersion;
    debugPrint('🔴 Nouveau contenu détecté → rechargement lives');
    _loadData();
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
    ContentRefresher.instance.removeListener(_onContentRefreshed);
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
      padding: EdgeInsets.all(16.w),
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
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: MyKOGColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.live_tv, color: MyKOGColors.accent, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.liveServices,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.watchInRealTime,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: MyKOGColors.accent,
          borderRadius: BorderRadius.circular(12.r),
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
          padding: EdgeInsets.all(16.w),
          children: [
            // Carte principale pour le live actif
            _buildActiveLiveCard(_activeLive!),
            SizedBox(height: 16.h),
            // Autres lives en cours
            if (_liveStreams.where((s) => s.id != _activeLive!.id).isNotEmpty) ...[
              Text(
                'Autres lives en cours',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 12.h),
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
              size: 64.sp,
              color: MyKOGColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              _isOffline ? 'Mode hors ligne' : l10n.noLiveStreamsNow,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            SizedBox(height: 8.h),
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
        padding: EdgeInsets.all(16.w),
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
              size: 64.sp,
              color: MyKOGColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              _isOffline ? 'Mode hors ligne' : 'Aucun live programmé',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
            ),
            SizedBox(height: 8.h),
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
        padding: EdgeInsets.all(16.w),
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
        margin: EdgeInsets.only(bottom: 16.h),
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: stream.thumbnailUrl.isNotEmpty
                          ? Image.asset(
                              stream.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: MyKOGColors.secondary,
                                child: Center(
                                  child: Icon(
                                    Icons.live_tv,
                                    color: MyKOGColors.accent,
                                    size: 32.sp,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: MyKOGColors.secondary,
                              child: Center(
                                child: Icon(
                                  Icons.live_tv,
                                  color: MyKOGColors.accent,
                                  size: 32.sp,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8.w,
                            height: 8.h,
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
                          SizedBox(width: 6.w),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye,
                              color: Colors.white, size: 16.sp),
                          SizedBox(width: 4.w),
                          Text(
                            '${stream.viewerCount}',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                stream.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MyKOGColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(Icons.person,
                      size: 16.sp, color: MyKOGColors.textSecondary),
                  SizedBox(width: 4.w),
                  Text(
                    stream.pastor,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
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
      margin: EdgeInsets.only(bottom: 16.h),
      child: GlassCard(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: stream.thumbnailUrl.isNotEmpty
                  ? Image.asset(
                      stream.thumbnailUrl,
                      width: 120.w,
                      height: 90.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: MyKOGColors.secondary,
                        child: Center(
                          child: Icon(
                            Icons.live_tv,
                            color: MyKOGColors.accent,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 120.w,
                      height: 90.h,
                      color: MyKOGColors.secondary,
                      child: Center(
                        child: Icon(
                          Icons.live_tv,
                          color: MyKOGColors.accent,
                          size: 24.sp,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
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
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 14.sp, color: MyKOGColors.textSecondary),
                      SizedBox(width: 4.w),
                      Text(
                        stream.pastor,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: MyKOGColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule,
                            size: 14.sp, color: MyKOGColors.accent),
                        SizedBox(width: 4.w),
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
          borderRadius: BorderRadius.circular(16.r),
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
                              child: Center(
                                child: Icon(
                                  Icons.live_tv,
                                  color: MyKOGColors.accent,
                                  size: 48.sp,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: MyKOGColors.secondary,
                            child: Center(
                              child: Icon(
                                Icons.live_tv,
                                color: MyKOGColors.accent,
                                size: 48.sp,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20.r),
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
                          width: 10.w,
                          height: 10.h,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(onPlay: (controller) => controller.repeat())
                            .fadeIn(duration: 500.ms)
                            .then()
                            .fadeOut(duration: 500.ms),
                        SizedBox(width: 8.w),
                        Text(
                          'LIVE MAINTENANT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
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
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.remove_red_eye, color: Colors.white, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          '${stream.viewerCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
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
              padding: EdgeInsets.all(16.w),
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
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18.sp, color: MyKOGColors.textSecondary),
                      SizedBox(width: 6.w),
                      Text(
                        stream.pastor,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: MyKOGColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  if (stream.description.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      stream.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: MyKOGColors.textTertiary,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: MyKOGColors.accent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 24.sp),
                        SizedBox(width: 8.w),
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
