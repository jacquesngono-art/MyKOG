import 'package:flutter/material.dart';
import 'package:MyKOG/models/teaching.dart';
import 'package:MyKOG/services/download_service.dart';
import 'package:MyKOG/l10n/app_localizations.dart';
import 'package:MyKOG/theme.dart';

/// Widget pour afficher la progression du téléchargement
class DownloadProgressWidget extends StatefulWidget {
  final Teaching teaching;
  final VoidCallback? onDownloadComplete;
  final VoidCallback? onDownloadFailed;

  const DownloadProgressWidget({
    super.key,
    required this.teaching,
    this.onDownloadComplete,
    this.onDownloadFailed,
  });

  @override
  State<DownloadProgressWidget> createState() => _DownloadProgressWidgetState();
}

class _DownloadProgressWidgetState extends State<DownloadProgressWidget> {
  DownloadProgress? _progress;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  void _checkDownloadStatus() {
    final isDownloaded = DownloadService.isDownloaded(widget.teaching.id);
    final isDownloading = DownloadService.isDownloading(widget.teaching.id);
    
    setState(() {
      _isDownloading = isDownloading;
    });

    if (isDownloading) {
      _progress = DownloadService.getDownloadProgress(widget.teaching.id);
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
    });

    final success = await DownloadService.downloadTeaching(
      widget.teaching,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
          });

          if (progress.status == DownloadStatus.completed) {
            widget.onDownloadComplete?.call();
          } else if (progress.status == DownloadStatus.failed) {
            widget.onDownloadFailed?.call();
          }
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });

      final l10n = AppLocalizations.of(context)!;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n.downloadComplete}'),
            backgroundColor: MyKOGColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${l10n.downloadFailed}'),
            backgroundColor: MyKOGColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _cancelDownload() async {
    await DownloadService.cancelDownload(widget.teaching.id);
    if (mounted) {
      setState(() {
        _isDownloading = false;
        _progress = null;
      });
    }
  }

  Future<void> _deleteDownload() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDownload),
        content: Text(l10n.deleteDownloadConfirm),
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
      await DownloadService.deleteDownload(widget.teaching.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${l10n.downloadDeleted}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloaded = DownloadService.isDownloaded(widget.teaching.id);

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.download_done, color: MyKOGColors.success),
        onPressed: _deleteDownload,
        tooltip: l10n.downloaded,
      );
    }

    if (_isDownloading && _progress != null) {
      return _buildDownloadingState();
    }

    return IconButton(
      icon: const Icon(Icons.download, color: MyKOGColors.textSecondary),
      onPressed: _startDownload,
      tooltip: l10n.download,
    );
  }

  Widget _buildDownloadingState() {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de progression
          CircularProgressIndicator(
            value: _progress?.progress ?? 0.0,
            strokeWidth: 2,
            backgroundColor: MyKOGColors.textSecondary.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(MyKOGColors.accent),
          ),
          // Bouton annuler
          GestureDetector(
            onTap: _cancelDownload,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: MyKOGColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: MyKOGColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget compact pour afficher le statut de téléchargement
class DownloadStatusBadge extends StatelessWidget {
  final String teachingId;

  const DownloadStatusBadge({
    super.key,
    required this.teachingId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDownloaded = DownloadService.isDownloaded(teachingId);
    final isDownloading = DownloadService.isDownloading(teachingId);

    if (!isDownloaded && !isDownloading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDownloaded ? MyKOGColors.success : MyKOGColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDownloaded ? Icons.download_done : Icons.downloading,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isDownloaded ? l10n.downloaded : l10n.downloading,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

