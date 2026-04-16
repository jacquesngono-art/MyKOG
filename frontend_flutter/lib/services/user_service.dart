import 'package:MyKOG/models/user.dart';
import 'package:MyKOG/api/user_api_service.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // Simule une base de données locale pour l'exemple
  static User? _fakeUser;
  static final UserApiService _apiService = UserApiService();

  // ---------------------------------------
  // RÉCUPÉRER L’UTILISATEUR COURANT
  // ---------------------------------------
  static Future<User?> getCurrentUser() async {
    return _fakeUser;
  }

  // ---------------------------------------
  // INITIALISER UN USER PAR DÉFAUT
  // ---------------------------------------
  static Future<void> initializeDefaultUser() async {
    _fakeUser = User(
      id: "default-user",
      name: "Invité",
      email: "guest@example.com",
      profileImageUrl: null,
      favoriteTeachingIds: [],
      downloadedTeachingIds: [],
      recentlyPlayedIds: [],
      notificationsEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------
  // MISE À JOUR DU USER ENTIER
  // ---------------------------------------
  static Future<void> updateUser(User user) async {
    _fakeUser = user.copyWith(updatedAt: DateTime.now());
    
    // Envoyer les données au backend
    try {
      final updatedUser = await _apiService.createOrUpdateUser(_fakeUser!);
      _fakeUser = updatedUser;
      debugPrint('✅ Utilisateur synchronisé avec le backend');
    } catch (e) {
      debugPrint('⚠️ Erreur synchronisation utilisateur: $e');
      // Continuer même en cas d'erreur (mode offline)
    }
  }

  // ----------------------------------------------------------
  // FAVORIS
  // ----------------------------------------------------------
  static Future<bool> isFavorite(String id) async {
    return _fakeUser?.favoriteTeachingIds.contains(id) ?? false;
  }

  static Future<void> addToFavorites(String id) async {
    if (_fakeUser == null) return;

    final list = List<String>.from(_fakeUser!.favoriteTeachingIds);
    if (!list.contains(id)) list.add(id);

    _fakeUser = _fakeUser!.copyWith(
      favoriteTeachingIds: list,
      updatedAt: DateTime.now(),
    );
    
    // Synchroniser avec le backend
    try {
      await _apiService.createOrUpdateUser(_fakeUser!);
    } catch (e) {
      debugPrint('⚠️ Erreur synchronisation favoris: $e');
    }
  }

  static Future<void> removeFromFavorites(String id) async {
    if (_fakeUser == null) return;

    final list = List<String>.from(_fakeUser!.favoriteTeachingIds);
    list.remove(id);

    _fakeUser = _fakeUser!.copyWith(
      favoriteTeachingIds: list,
      updatedAt: DateTime.now(),
    );
  }

  // ----------------------------------------------------------
  // RECENTLY PLAYED
  // ----------------------------------------------------------
  static Future<void> addToRecentlyPlayed(String id) async {
    if (_fakeUser == null) return;

    final list = List<String>.from(_fakeUser!.recentlyPlayedIds);

    // Supprimer si déjà présent pour le remettre devant
    list.remove(id);
    list.insert(0, id);

    // Optionnel : garder seulement 20 derniers
    if (list.length > 20) list.removeLast();

    _fakeUser = _fakeUser!.copyWith(
      recentlyPlayedIds: list,
      updatedAt: DateTime.now(),
    );
    
    // Synchroniser avec le backend (moins fréquent pour les recently played)
    // On peut faire une synchronisation périodique au lieu de chaque fois
  }

  // ----------------------------------------------------------
  // MISE À JOUR DES INFORMATIONS UTILISATEUR
  // ----------------------------------------------------------
  static Future<void> updateUserName(String name) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      name: name,
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> updateUserEmail(String email) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      email: email,
      updatedAt: DateTime.now(),
    );
  }

  static Future<void> updateProfileImage(String url) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      profileImageUrl: url,
      updatedAt: DateTime.now(),
    );
  }

  // ----------------------------------------------------------
  // NOTIFICATIONS
  // ----------------------------------------------------------
  static Future<void> toggleNotifications(bool enabled) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      notificationsEnabled: enabled,
      updatedAt: DateTime.now(),
    );
  }

  // ----------------------------------------------------------
  // DÉCONNEXION
  // ----------------------------------------------------------
  static Future<void> clearUserData() async {
    _fakeUser = null;
  }

  // ----------------------------------------------------------
  // LOGIN (avec sauvegarde backend)
  // ----------------------------------------------------------
  static Future<User?> login(String email, String password) async {
    try {
      // Si l'utilisateur existe localement, le synchroniser avec le backend
      if (_fakeUser != null && _fakeUser!.email == email) {
        // Synchroniser avec le backend
        try {
          final savedUser = await _apiService.createOrUpdateUser(_fakeUser!);
          _fakeUser = savedUser;
          debugPrint('✅ Utilisateur synchronisé lors de la connexion');
        } catch (e) {
          debugPrint('⚠️ Erreur synchronisation lors de la connexion: $e');
          // Continuer même en cas d'erreur
        }
        return _fakeUser;
      }
      
      // Si l'utilisateur n'existe pas localement, créer un nouveau
      // (dans un vrai système, on vérifierait d'abord dans le backend)
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      _fakeUser = User(
        id: userId,
        name: email.split('@')[0], // Utiliser le nom avant @ comme nom par défaut
        email: email,
        profileImageUrl: null,
        favoriteTeachingIds: [],
        downloadedTeachingIds: [],
        recentlyPlayedIds: [],
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Envoyer les données au backend
      try {
        final savedUser = await _apiService.createOrUpdateUser(_fakeUser!);
        _fakeUser = savedUser;
        debugPrint('✅ Nouvel utilisateur créé et enregistré');
      } catch (e) {
        debugPrint('⚠️ Erreur création utilisateur: $e');
      }

      return _fakeUser;
    } catch (e) {
      debugPrint('❌ Erreur login: $e');
      return null;
    }
  }

  // ----------------------------------------------------------
  // REGISTER (avec sauvegarde backend)
  // ----------------------------------------------------------
  static Future<User?> register(
      String name, String email, String password) async {
    try {
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      
      _fakeUser = User(
        id: userId,
        name: name,
        email: email,
        profileImageUrl: null,
        favoriteTeachingIds: [],
        downloadedTeachingIds: [],
        recentlyPlayedIds: [],
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Envoyer les données au backend
      try {
        final savedUser = await _apiService.createOrUpdateUser(_fakeUser!);
        _fakeUser = savedUser;
        debugPrint('✅ Utilisateur enregistré dans Firebase');
      } catch (e) {
        debugPrint('⚠️ Erreur enregistrement utilisateur: $e');
        // Continuer même en cas d'erreur (mode offline)
      }

      return _fakeUser;
    } catch (e) {
      debugPrint('❌ Erreur register: $e');
      return null;
    }
  }
}
