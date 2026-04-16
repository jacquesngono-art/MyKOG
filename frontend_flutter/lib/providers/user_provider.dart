import 'package:flutter/material.dart';
import 'package:MyKOG/models/user.dart';
import 'package:MyKOG/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  // -----------------------------
  // GETTERS (inchangés)
  // -----------------------------
  bool get notificationsEnabled => _currentUser?.notificationsEnabled ?? true;

  List<String> get favoriteTeachingIds =>
      _currentUser?.favoriteTeachingIds ?? [];

  List<String> get downloadedTeachingIds =>
      _currentUser?.downloadedTeachingIds ?? [];

  List<String> get recentlyPlayedIds => _currentUser?.recentlyPlayedIds ?? [];

  // -----------------------------
  // INITIALISATION
  // -----------------------------
  Future<void> initialize() async {
    await loadUser();
  }

  Future<void> loadUser() async {
    _currentUser = await UserService.getCurrentUser();

    if (_currentUser == null) {
      await UserService.initializeDefaultUser();
      _currentUser = await UserService.getCurrentUser();
    }

    notifyListeners();
  }

  // -----------------------------
  // INSCRIPTION UTILISATEUR
  // -----------------------------
  Future<bool> registerUser(String name, String email) async {
    try {
      final newUser = User(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
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

      await UserService.updateUser(newUser);
      await loadUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  // -----------------------------
  // FAVORIS
  // -----------------------------
  Future<bool> isFavorite(String id) async {
    return UserService.isFavorite(id);
  }

  Future<void> addToFavorites(String id) async {
    await UserService.addToFavorites(id);
    await loadUser();
  }

  Future<void> removeFromFavorites(String id) async {
    await UserService.removeFromFavorites(id);
    await loadUser();
  }

  // -----------------------------
  // RECENTLY PLAYED
  // -----------------------------
  Future<void> addToRecentlyPlayed(String id) async {
    await UserService.addToRecentlyPlayed(id);
    await loadUser();
  }

  // -----------------------------
  // MISE À JOUR UTILISATEUR
  // -----------------------------
  Future<void> updateUserName(String name) async {
    await UserService.updateUserName(name);
    await loadUser();
  }

  Future<void> updateUserEmail(String email) async {
    await UserService.updateUserEmail(email);
    await loadUser();
  }

  Future<void> updateProfileImage(String url) async {
    await UserService.updateProfileImage(url);
    await loadUser();
  }

  // -----------------------------
  // NOTIFICATIONS
  // -----------------------------
  Future<void> toggleNotifications(bool enabled) async {
    await UserService.toggleNotifications(enabled);
    await loadUser();
  }

  // -----------------------------
  // DÉCONNEXION
  // -----------------------------
  Future<void> signOut() async {
    await UserService.clearUserData();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> clearUser() async {
    await UserService.clearUserData();
    _currentUser = null;
    notifyListeners();
  }
}
