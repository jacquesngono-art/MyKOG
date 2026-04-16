import 'package:flutter/material.dart';
import 'package:MyKOG/config/api_config.dart';
import 'package:MyKOG/theme.dart';

/// Widget pour sélectionner le mode de connexion réseau
class ConnectionModeSelector extends StatefulWidget {
  const ConnectionModeSelector({super.key});

  @override
  State<ConnectionModeSelector> createState() => _ConnectionModeSelectorState();
}

class _ConnectionModeSelectorState extends State<ConnectionModeSelector> {
  String _currentMode = ApiConfig.modeWifi;
  String? _currentIP;
  bool _isTesting = false;
  bool _isConnected = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }
  
  Future<void> _loadCurrentSettings() async {
    final mode = ApiConfig.getCurrentMode();
    final ip = await ApiConfig.getCurrentIP();
    final info = await ApiConfig.getConnectionInfo();
    
    setState(() {
      _currentMode = mode;
      _currentIP = ip;
      _isConnected = info['isConnected'] as bool;
    });
  }
  
  Future<void> _changeMode(String mode) async {
    setState(() => _isTesting = true);
    
    await ApiConfig.setConnectionMode(mode);
    await _loadCurrentSettings();
    
    // Tester la connexion
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
              ? '✅ Connexion réussie avec le mode $mode'
              : '❌ Connexion échouée. Vérifiez votre réseau.',
          ),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _detectIP() async {
    setState(() => _isTesting = true);
    
    final detectedIP = await ApiConfig.detectIP();
    
    if (detectedIP != null) {
      await _loadCurrentSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ IP détectée automatiquement'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Impossible de détecter l\'IP automatiquement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    
    setState(() => _isTesting = false);
  }
  
  Future<void> _setCustomIP(String ip) async {
    if (ip.isEmpty) return;
    
    setState(() => _isTesting = true);
    
    await ApiConfig.setIP(ip);
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
              ? '✅ IP configurée: $ip'
              : '❌ Connexion échouée avec $ip',
          ),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
    
    await _loadCurrentSettings();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configuration Réseau',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mode de connexion
            Text(
              'Mode de connexion:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildModeChip(
                  'WiFi',
                  ApiConfig.modeWifi,
                  Icons.wifi,
                  'Même réseau WiFi',
                ),
                _buildModeChip(
                  'Hotspot Téléphone',
                  ApiConfig.modeHotspotPhone,
                  Icons.phone_android,
                  'Téléphone partage sa connexion',
                ),
                _buildModeChip(
                  'Hotspot Ordinateur',
                  ApiConfig.modeHotspotComputer,
                  Icons.computer,
                  'Ordinateur crée un hotspot',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // IP actuelle
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IP actuelle:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentIP ?? 'Non définie',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isTesting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _detectIP,
                    icon: const Icon(Icons.search),
                    label: const Text('Détecter IP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : () => _showIPDialog(),
                    icon: const Icon(Icons.edit),
                    label: const Text('IP manuelle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyKOGColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Bouton pour réinitialiser le cache
            OutlinedButton.icon(
              onPressed: _isTesting ? null : () async {
                setState(() => _isTesting = true);
                await ApiConfig.forceReset();
                await _loadCurrentSettings();
                // Tester la connexion après réinitialisation
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
                          ? '✅ Cache réinitialisé et connexion réussie !'
                          : '⚠️ Cache réinitialisé mais connexion échouée. Vérifiez votre réseau.',
                      ),
                      backgroundColor: connected ? Colors.green : Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser le cache'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModeChip(String label, String mode, IconData icon, String tooltip) {
    final isSelected = _currentMode == mode;
    
    return Tooltip(
      message: tooltip,
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          if (selected) {
            _changeMode(mode);
          }
        },
        selectedColor: MyKOGColors.accent.withOpacity(0.2),
        checkmarkColor: MyKOGColors.accent,
      ),
    );
  }
  
  void _showIPDialog() {
    final controller = TextEditingController(text: _currentIP);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IP manuelle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Adresse IP',
            hintText: '192.168.1.1',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _setCustomIP(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

