import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/config/api_config.dart';
import 'package:MyKOG/theme.dart';

class ConnectionSettingsScreen extends StatefulWidget {
  const ConnectionSettingsScreen({super.key});

  @override
  State<ConnectionSettingsScreen> createState() =>
      _ConnectionSettingsScreenState();
}

class _ConnectionSettingsScreenState extends State<ConnectionSettingsScreen> {
  bool _isLoading = false;
  String? _currentMode;
  String? _currentIP;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConnectionInfo();
  }

  Future<void> _loadConnectionInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await ApiConfig.getConnectionInfo();
      setState(() {
        _currentMode = info['mode'];
        _currentIP = info['ip'];
        _isConnected = info['isConnected'];
      });
    } catch (e) {
      debugPrint('Erreur chargement infos connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setConnectionMode(String mode) async {
    setState(() => _isLoading = true);

    try {
      await ApiConfig.setConnectionMode(mode);
      await _loadConnectionInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mode de connexion changé: $mode'),
            backgroundColor: MyKOGColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final isConnected = await ApiConfig.testConnection();
      setState(() => _isConnected = isConnected);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isConnected ? '✅ Connexion réussie' : '❌ Connexion échouée'),
            backgroundColor: isConnected ? MyKOGColors.success : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetConnection() async {
    setState(() => _isLoading = true);

    try {
      await ApiConfig.forceReset();
      await _loadConnectionInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔄 Connexion réinitialisée'),
            backgroundColor: MyKOGColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _wakeUpRender() async {
    setState(() => _isLoading = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('☁️ Réveil du backend Render...'),
          duration: Duration(seconds: 2),
        ),
      );

      await ApiConfig.forceRenderMode();
      await ApiConfig.testRenderConnection();
      await _loadConnectionInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isConnected
                ? '✅ Backend réveillé!'
                : '⚠️ Backend peut être en veille, réessayez dans 30s'),
            backgroundColor:
                _isConnected ? MyKOGColors.success : MyKOGColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      appBar: AppBar(
        title: const Text('Paramètres de Connexion'),
        backgroundColor: MyKOGColors.primaryDark,
        foregroundColor: MyKOGColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MyKOGColors.accent))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentStatus(),
                  SizedBox(height: 24.h),
                  _buildConnectionModes(),
                  SizedBox(height: 24.h),
                  _buildActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _isConnected
              ? MyKOGColors.success.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
          width: 2.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isConnected
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: _isConnected ? MyKOGColors.success : Colors.red,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'État de la Connexion',
                style: TextStyle(
                  color: MyKOGColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildStatusRow('Mode actuel', _currentMode ?? 'Inconnu'),
          _buildStatusRow('Adresse IP', _currentIP ?? 'Inconnue'),
          _buildStatusRow('Statut', _isConnected ? 'Connecté' : 'Non connecté'),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: MyKOGColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: MyKOGColors.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionModes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modes de Connexion',
          style: TextStyle(
            color: MyKOGColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // Mode Render (priorité)
        _buildModeOption(
          title: 'Backend Render (Recommandé)',
          subtitle: 'https://mykog-backend-api.onrender.com',
          icon: Icons.cloud_rounded,
          color: MyKOGColors.accent,
          mode: ApiConfig.modeRender,
          isRecommended: true,
        ),

        SizedBox(height: 12.h),

        // Mode USB
        _buildModeOption(
          title: 'Connexion USB',
          subtitle: 'Câble USB avec adb reverse',
          icon: Icons.usb_rounded,
          color: Colors.blue,
          mode: ApiConfig.modeUsb,
        ),

        SizedBox(height: 12.h),

        // Mode WiFi
        _buildModeOption(
          title: 'Connexion WiFi',
          subtitle: 'Même réseau WiFi que le serveur',
          icon: Icons.wifi_rounded,
          color: Colors.green,
          mode: ApiConfig.modeWifi,
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String mode,
    bool isRecommended = false,
  }) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () => _setConnectionMode(mode),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.2) : MyKOGColors.secondary,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                isSelected ? color : MyKOGColors.accent.withValues(alpha: 0.2),
            width: isSelected ? 2.w : 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: MyKOGColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: MyKOGColors.accent,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'RECOMMANDÉ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: MyKOGColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24.w,
              ),
          ],
        ),
      ),
    ).animate(delay: (title.length * 5).ms).fadeIn().slideX();
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            color: MyKOGColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),

        // Bouton réveiller Render
        if (_currentMode == ApiConfig.modeRender)
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: ElevatedButton.icon(
              onPressed: _wakeUpRender,
              icon: const Icon(Icons.wb_sunny_rounded),
              label: const Text('☁️ Réveiller le backend Render'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tester la connexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyKOGColors.accent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetConnection,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MyKOGColors.textPrimary,
                  side: BorderSide(
                      color: MyKOGColors.accent.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
