import 'package:MyKOG/models/book.dart';
import 'package:MyKOG/config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  static List<Book>? _cachedBooks;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  static Future<List<Book>> getAllBooks({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBooks != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedBooks!;
      }
    }

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/books'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _cachedBooks = data.map((json) => Book.fromJson(json)).toList();
        _cacheTime = DateTime.now();
        return _cachedBooks!;
      } else {
        return _getSampleBooks();
      }
    } catch (e) {
      return _getSampleBooks();
    }
  }

  static Future<Book?> getBookById(String id) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  static void clearCache() {
    _cachedBooks = null;
    _cacheTime = null;
  }

  static List<Book> _getSampleBooks() {
    return [
      Book(
        id: '1',
        title: 'La Vie de Prière',
        author: 'Pasteur Melissa',
        description:
            'Un guide complet sur la prière et la communion avec Dieu.',
        pdfUrl: 'https://example.com/vie-priere.pdf',
        coverUrl: null,
        pageCount: 120,
        publishedDate: 'Jan 2024',
        fileSize: '2.5 MB',
        category: 'Spiritualité',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: '2',
        title: 'Les Fondements de la Foi',
        author: 'Pasteur Jean',
        description: 'Les bases essentielles de la foi chrétienne.',
        pdfUrl: 'https://example.com/fondements-foi.pdf',
        coverUrl: null,
        pageCount: 85,
        publishedDate: 'Fév 2024',
        fileSize: '1.8 MB',
        category: 'Doctrine',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: '3',
        title: 'Marcher par l\'Esprit',
        author: 'Pasteur Marie',
        description: 'Comment vivre quotidien guidé par le Saint-Esprit.',
        pdfUrl: 'https://example.com/marcher-esprit.pdf',
        coverUrl: null,
        pageCount: 95,
        publishedDate: 'Mar 2024',
        fileSize: '2.1 MB',
        category: 'Spiritualité',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: '4',
        title: 'L\'Ancien Testament Explained',
        author: 'Pasteur Pierre',
        description: 'Une étude approfondie de l\'Ancien Testament.',
        pdfUrl: 'https://example.com/at-explained.pdf',
        coverUrl: null,
        pageCount: 200,
        publishedDate: 'Avr 2024',
        fileSize: '4.2 MB',
        category: 'Étude',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Book(
        id: '5',
        title: 'Le Nouveau Testament Guide',
        author: 'Pasteur Thomas',
        description: 'Guide pratique pour étudier le Nouveau Testament.',
        pdfUrl: 'https://example.com/nt-guide.pdf',
        coverUrl: null,
        pageCount: 150,
        publishedDate: 'Mai 2024',
        fileSize: '3.0 MB',
        category: 'Étude',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
