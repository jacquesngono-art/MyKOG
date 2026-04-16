import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/config/api_config.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/screens/connection_settings_screen.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onTap;

  const ConnectionStatusWidget({
    super.key,
    this.showDetails = true,
    this.onTap,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = false;
  String? _currentMode;
  String? _currentIP;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final info = await ApiConfig.getConnectionInfo();
      if (mounted) {
        setState(() {
          _isConnected = info['isConnected'] ?? false;
          _currentMode = info['mode'];
          _currentIP = info['ip'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: widget.onTap ?? () => _openSettings(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _isConnected 
              ? MyKOGColors.success.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: _isConnected 
                ? MyKOGColors.success.withValues(alpha: 0.3)
                : Colors.red.withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône de statut
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: _isConnected ? MyKOGColors.success : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isConnected ? MyKOGColors.success : Colors.red).withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scale(
              begin: 1.0,
              end: 1.2,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
            ),
            
            SizedBox(width: 8.w),
            
            // Texte de statut
            if (widget.showDetails) ...[
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: _isConnected ? MyKOGColors.success : Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                '• ${_getModeText()}',
                style: TextStyle(
                  color: MyKOGColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ] else ...[
              Text(
                _isConnected ? 'Connecté' : 'Hors ligne',
                style: TextStyle(
                  color: _isConnected ? MyKOGColors.success : Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            
            // Flèche pour les détails
            if (widget.showDetails) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: MyKOGColors.textSecondary,
                size: 16.w,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: MyKOGColors.accent.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: MyKOGColors.accent,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Vérification...',
            style: TextStyle(
              color: MyKOGColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (_isConnected) {
      return 'En ligne';
    } else {
      return 'Hors ligne';
    }
  }

  String _getModeText() {
    switch (_currentMode) {
      case ApiConfig.modeRender:
        return 'Render';
      case ApiConfig.modeUsb:
        return 'USB';
      case ApiConfig.modeWifi:
        return 'WiFi';
      case ApiConfig.modeHotspotPhone:
        return 'Hotspot';
      case ApiConfig.modeHotspotComputer:
        return 'Hotspot PC';
      default:
        return 'Inconnu';
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectionSettingsScreen(),
      ),
    ).then((_) => _checkConnection()); // Re-vérifier au retour
  }
}

// Widget compact pour la barre d'état
class CompactConnectionStatusWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactConnectionStatusWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiConfig.getConnectionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final isConnected = snapshot.data!['isConnected'] ?? false;
        final mode = snapshot.data!['mode'] ?? 'unknown';

        return GestureDetector(
          onTap: onTap ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConnectionSettingsScreen(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isConnected 
                  ? MyKOGColors.success.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: isConnected ? MyKOGColors.success : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  _getCompactModeText(mode),
                  style: TextStyle(
                    color: isConnected ? MyKOGColors.success : Colors.red,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCompactModeText(String mode) {
    switch (mode) {
      case ApiConfig.modeRender:
        return '☁️ Render';
      case ApiConfig.modeUsb:
        return '🔌 USB';
      case ApiConfig.modeWifi:
        return '📶 WiFi';
      default:
        return '❓';
    }
  }
}
