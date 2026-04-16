import 'package:flutter/material.dart';
import '../models/teaching.dart';
import '../services/teaching_service.dart';

enum TeachingStatus {
  initial,
  loading,
  loaded,
  error,
  searching
}

class TeachingProvider extends ChangeNotifier {
  // Utiliser TeachingService au lieu de l'API directe pour la cohérence

  // État principal
  TeachingStatus _status = TeachingStatus.initial;
  List<Teaching> _allTeachings = [];
  List<Teaching> _featuredTeachings = [];
  List<Teaching> _newTeachings = [];
  List<Teaching> _popularTeachings = [];
  List<String> _availableTypeCulte = [];

  // Gestion erreurs
  String? _errorMessage;

  // Getters
  TeachingStatus get status => _status;
  List<Teaching> get allTeachings => _allTeachings;
  List<Teaching> get featuredTeachings => _featuredTeachings;
  List<Teaching> get newTeachings => _newTeachings;
  List<Teaching> get popularTeachings => _popularTeachings;
  List<String> get availableTypeCulte => _availableTypeCulte;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == TeachingStatus.loading;
  bool get hasError => _status == TeachingStatus.error;
  bool get hasData => _status == TeachingStatus.loaded && _allTeachings.isNotEmpty;

  // Constructeur
  TeachingProvider() {
    _initializeData();
  }

  // Initialisation des données avec fallback vers le stockage local
  Future<void> _initializeData() async {
    try {
      _status = TeachingStatus.loading;
      notifyListeners();
      
      // Utiliser TeachingService qui gère déjà le cache et le fallback
      final teachings = await TeachingService.getAllTeachings();
      _allTeachings = teachings;
      _categorizeTeachings();
      
      _status = TeachingStatus.loaded;
      notifyListeners();
    } catch (e) {
      print('Erreur initialisation TeachingProvider: $e');
      _status = TeachingStatus.loaded; // Afficher les données même en cas d'erreur
      notifyListeners();
    }
  }

  // Récupérer tous les enseignements
  Future<void> fetchAllTeachings() async {
    _status = TeachingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vider le cache de TeachingService pour forcer le rafraîchissement
      TeachingService.clearCache();
      
      final teachings = await TeachingService.getAllTeachings();
      _allTeachings = teachings;
      _categorizeTeachings();

      _status = TeachingStatus.loaded;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, garder les données existantes si disponibles
      if (_allTeachings.isEmpty) {
        _status = TeachingStatus.error;
        _errorMessage = 'Impossible de charger les enseignements';
      } else {
        _status = TeachingStatus.loaded; // Garder les données existantes
      }
      notifyListeners();
    }
  }

  // Récupérer enseignements featured
  Future<void> fetchFeaturedTeachings() async {
    if (_featuredTeachings.isNotEmpty && _status == TeachingStatus.loaded) {
      notifyListeners();
      return;
    }

    try {
      final teachings = await TeachingService.getFeaturedTeachings();
      _featuredTeachings = teachings;
      notifyListeners();
    } catch (e) {
      print('Erreur chargement enseignements featured: $e');
    }
  }

  // Récupérer nouveaux enseignements
  Future<void> fetchNewTeachings() async {
    if (_newTeachings.isNotEmpty && _status == TeachingStatus.loaded) {
      notifyListeners();
      return;
    }

    try {
      final teachings = await TeachingService.getNewTeachings();
      _newTeachings = teachings;
      notifyListeners();
    } catch (e) {
      print('Erreur chargement nouveaux enseignements: $e');
    }
  }

  // Récupérer enseignements populaires
  Future<void> fetchPopularTeachings({int limit = 10}) async {
    if (_popularTeachings.isNotEmpty && _status == TeachingStatus.loaded) {
      notifyListeners();
      return;
    }

    try {
      final teachings = await TeachingService.getPopularTeachings(limit: limit);
      _popularTeachings = teachings;
      notifyListeners();
    } catch (e) {
      print('Erreur chargement enseignements populaires: $e');
    }
  }

  // Récupérer types de culte disponibles
  Future<void> fetchAvailableTypeCulte() async {
    if (_availableTypeCulte.isNotEmpty && _status == TeachingStatus.loaded) {
      notifyListeners();
      return;
    }

    try {
      final typeCulte = await TeachingService.getTypeCulteOptions();
      _availableTypeCulte = typeCulte;
      notifyListeners();
    } catch (e) {
      print('Erreur chargement types de culte: $e');
    }
  }

  // Rechercher enseignements
  Future<void> searchTeachings(String query) async {
    if (query.trim().isEmpty) {
      await fetchAllTeachings();
      return;
    }

    _status = TeachingStatus.searching;
    notifyListeners();

    try {
      final results = await TeachingService.searchTeachings(query);
      _allTeachings = results;
      _status = TeachingStatus.loaded;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, utiliser les données existantes
      _status = TeachingStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Obtenir enseignements par type de culte
  Future<void> getTeachingsByTypeCulte(String typeCulte) async {
    _status = TeachingStatus.loading;
    notifyListeners();

    try {
      final results = await TeachingService.getTeachingsByTypeCulte(typeCulte);
      _allTeachings = results;
      _status = TeachingStatus.loaded;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, utiliser les données existantes
      _status = TeachingStatus.loaded;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Obtenir enseignement par ID
  Future<Teaching?> getTeachingById(String id) async {
    try {
      return await TeachingService.getTeachingById(id);
    } catch (e) {
      // Essayer de trouver dans les données locales
      return _allTeachings.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Enseignement non trouvé'),
      );
    }
  }

  // Incrémenter compteur de lecture
  Future<void> incrementPlayCount(String teachingId) async {
    try {
      await TeachingService.incrementPlayCount(teachingId);

      // Mettre à jour localement
      final index = _allTeachings.indexWhere((t) => t.id == teachingId);
      if (index != -1) {
        final teaching = _allTeachings[index];
        _allTeachings[index] = teaching.copyWith(
          playCount: teaching.playCount + 1,
          updatedAt: DateTime.now(),
        );

        // Mettre à jour aussi dans les autres listes
        _updateTeachingInLists(_allTeachings[index]);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur incrémentation compteur: $e');
    }
  }

  // Rafraîchir les données
  Future<void> refreshData() async {
    await fetchAllTeachings();
    await fetchFeaturedTeachings();
    await fetchNewTeachings();
    await fetchPopularTeachings();
    await fetchAvailableTypeCulte();
  }

  // Réessayer en cas d'erreur
  Future<void> retry() async {
    await fetchAllTeachings();
  }

  // Méthode privée pour catégoriser les enseignements
  void _categorizeTeachings() {
    _featuredTeachings = _allTeachings.where((t) => t.isFeatured).toList();
    _newTeachings = _allTeachings.where((t) => t.isNew).toList();

    _popularTeachings = List.from(_allTeachings);
    _popularTeachings.sort((a, b) => b.playCount.compareTo(a.playCount));
  }

  // Méthode privée pour mettre à jour un enseignement dans toutes les listes
  void _updateTeachingInLists(Teaching updatedTeaching) {
    // Mettre à jour dans la liste principale
    final index = _allTeachings.indexWhere((t) => t.id == updatedTeaching.id);
    if (index != -1) {
      _allTeachings[index] = updatedTeaching;
    }

    // Mettre à jour dans les listes catégorisées
    final featuredIndex = _featuredTeachings.indexWhere((t) => t.id == updatedTeaching.id);
    if (featuredIndex != -1) {
      _featuredTeachings[featuredIndex] = updatedTeaching;
    }

    final newIndex = _newTeachings.indexWhere((t) => t.id == updatedTeaching.id);
    if (newIndex != -1) {
      _newTeachings[newIndex] = updatedTeaching;
    }

    final popularIndex = _popularTeachings.indexWhere((t) => t.id == updatedTeaching.id);
    if (popularIndex != -1) {
      _popularTeachings[popularIndex] = updatedTeaching;
    }

    // Reclasser les enseignements populaires
    _popularTeachings.sort((a, b) => b.playCount.compareTo(a.playCount));
  }

  // Cache géré par TeachingService - plus besoin de cette méthode

  // Obtenir statistiques
  Map<String, dynamic> getStatistics() {
    return {
      'totalTeachings': _allTeachings.length,
      'featuredCount': _featuredTeachings.length,
      'newCount': _newTeachings.length,
      'totalPlayCount': _allTeachings.fold(0, (sum, t) => sum + t.playCount),
      'averageRating': _allTeachings.isEmpty
          ? 0
          : _allTeachings.fold(0.0, (sum, t) => sum + t.rating) / _allTeachings.length,
      'availableTypeCulte': _availableTypeCulte.length,
    };
  }
}