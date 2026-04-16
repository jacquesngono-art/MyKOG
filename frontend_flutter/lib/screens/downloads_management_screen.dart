import 'package:flutter/material.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/services/file_storage_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';

/// Écran de gestion des téléchargements
class DownloadsManagementScreen extends StatefulWidget {
  const DownloadsManagementScreen({super.key});

  @override
  State<DownloadsManagementScreen> createState() => _DownloadsManagementScreenState();
}

class _DownloadsManagementScreenState extends State<DownloadsManagementScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await DownloadService.getDownloadStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearAllDownloads() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllDownloads),
        content: Text(l10n.translate('confirm_delete_all_downloads')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DownloadService.clearAllDownloads();
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${l10n.translate("all_downloads_deleted")}'),
            backgroundColor: MyKOGColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageDownloads),
        backgroundColor: MyKOGColors.primaryDark,
        foregroundColor: MyKOGColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MyKOGColors.accent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte de statistiques
                  _buildStatsCard(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Informations
                  _buildInfoSection(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MyKOGColors.accent.withOpacity(0.8),
            MyKOGColors.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyKOGColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                l10n.storageUsed,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Taille totale
          Text(
            _stats?['totalSizeFormatted'] ?? '0 B',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Détails
          Row(
            children: [
              _buildStatItem(
                icon: Icons.music_note,
                label: 'Enseignements',
                value: '${_stats?['totalTeachings'] ?? 0}',
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.folder,
                label: 'Fichiers',
                value: '${_stats?['totalFiles'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: theme.textTheme.titleLarge?.copyWith(
            color: MyKOGColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildInfoTile(
          icon: Icons.info_outline,
          title: 'Téléchargements actifs',
          value: '${_stats?['activeDownloads'] ?? 0}',
          theme: theme,
        ),
        
        _buildInfoTile(
          icon: Icons.download_done,
          title: 'Enseignements téléchargés',
          value: '${_stats?['totalTeachings'] ?? 0}',
          theme: theme,
        ),
        
        _buildInfoTile(
          icon: Icons.storage,
          title: 'Espace de stockage',
          value: _stats?['totalSizeFormatted'] ?? '0 B',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyKOGColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MyKOGColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MyKOGColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: MyKOGColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: MyKOGColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bouton rafraîchir
        OutlinedButton.icon(
          onPressed: _loadStats,
          icon: const Icon(Icons.refresh),
          label: const Text('Actualiser'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MyKOGColors.accent,
            side: BorderSide(color: MyKOGColors.accent),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton supprimer tout
        ElevatedButton.icon(
          onPressed: _clearAllDownloads,
          icon: const Icon(Icons.delete_sweep),
          label: const Text('Supprimer tous les téléchargements'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Note d'information
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyKOGColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MyKOGColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: MyKOGColors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Les enseignements téléchargés sont disponibles hors ligne. '
                  'Vous pouvez les écouter sans connexion internet.',
                  style: TextStyle(
                    color: MyKOGColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

