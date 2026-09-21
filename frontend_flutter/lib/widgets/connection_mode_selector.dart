import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:MyKOG/config/api_config.dart';
import 'package:MyKOG/theme.dart';

/// Widget pour afficher le statut de connexion au backend VPS
class ConnectionModeSelector extends StatefulWidget {
  const ConnectionModeSelector({super.key});

  @override
  State<ConnectionModeSelector> createState() => _ConnectionModeSelectorState();
}

class _ConnectionModeSelectorState extends State<ConnectionModeSelector> {
  String? _currentIP;
  bool _isTesting = false;
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  Future<void> _loadCurrentSettings() async {
    final ip = await ApiConfig.getCurrentIP();
    final info = await ApiConfig.getConnectionInfo();
    
    setState(() {
      _currentIP = ip;
      _isConnected = info['isConnected'] as bool;
    });
  }
  
  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    
    final connected = await ApiConfig.testConnection();
    
    setState(() {
      _isConnected = connected;
      _isTesting = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected 
              ? '✅ Connexion VPS réussie'
              : '❌ Connexion VPS échouée. Vérifiez votre réseau.',
          ),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Backend VPS',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // URL du backend
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'URL du backend:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _currentIP ?? '185.98.128.123:3001/mykog-api',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isTesting)
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Bouton tester la connexion
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: const Icon(Icons.refresh),
                label: const Text('Tester la connexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyKOGColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

