import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:MyKOG/models/text_resume.dart';
import 'package:MyKOG/theme.dart';

class TextResumeViewerScreen extends StatefulWidget {
  final TextResume textResume;

  const TextResumeViewerScreen({
    super.key,
    required this.textResume,
  });

  @override
  State<TextResumeViewerScreen> createState() => _TextResumeViewerScreenState();
}

class _TextResumeViewerScreenState extends State<TextResumeViewerScreen> {
  PdfController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Télécharger le PDF
      final response = await http.get(Uri.parse(widget.textResume.pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }

      final Uint8List pdfBytes = response.bodyBytes;

      _pdfController = PdfController(
        document: PdfDocument.openData(pdfBytes),
      );

      // Attendre que le document soit chargé pour obtenir le nombre de pages
      final pageCount = _pdfController!.pagesCount ?? 0;
      
      setState(() {
        _totalPages = pageCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pdfController?.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      appBar: AppBar(
        backgroundColor: MyKOGColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MyKOGColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.textResume.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: MyKOGColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page ${_currentPage + 1} / $_totalPages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MyKOGColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (_totalPages > 0) ...[
            IconButton(
              icon: const Icon(Icons.first_page, color: MyKOGColors.textPrimary),
              onPressed: () => _goToPage(0),
              tooltip: 'Première page',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, color: MyKOGColors.textPrimary),
              onPressed: _previousPage,
              tooltip: 'Page précédente',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: MyKOGColors.textPrimary),
              onPressed: _nextPage,
              tooltip: 'Page suivante',
            ),
            IconButton(
              icon: const Icon(Icons.last_page, color: MyKOGColors.textPrimary),
              onPressed: () => _goToPage(_totalPages - 1),
              tooltip: 'Dernière page',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: MyKOGColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement du PDF...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: MyKOGColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: MyKOGColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Impossible de charger le PDF',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyKOGColors.accent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PdfView(
                        controller: _pdfController!,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                      ),
                    ),
                    // Barre de navigation en bas
                    if (_totalPages > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: MyKOGColors.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _previousPage,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: MyKOGColors.textPrimary,
                              ),
                              label: Text(
                                'Précédent',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: MyKOGColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${_currentPage + 1} / $_totalPages',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: MyKOGColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _nextPage,
                              label: Text(
                                'Suivant',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: MyKOGColors.textPrimary,
                                ),
                              ),
                              icon: const Icon(
                                Icons.chevron_right,
                                color: MyKOGColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

