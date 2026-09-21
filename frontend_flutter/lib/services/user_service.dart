import 'dart:convert';
import 'package:MyKOG/models/user.dart';
import 'package:MyKOG/models/favorite_package.dart';
import 'package:MyKOG/api/user_api_service.dart';
import 'package:MyKOG/services/hive_storage_service.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static User? _fakeUser;
  static final UserApiService _apiService = UserApiService();

  // Clé Hive (HiveStorageService) pour la persistance locale
  static const String _localUserKey = 'local_user_data';

  // File d'attente FIFO pour sérialiser les sync backend (éviter les lost updates)
  static Future<void> _syncQueue = Future.value();

  // ---------------------------------------
  // PERSISTANCE LOCALE (Spotify-like)
  // ---------------------------------------
  static Future<void> _saveLocal() async {
    if (_fakeUser == null) return;
    try {
      final json = jsonEncode(_fakeUser!.toJson());
      await HiveStorageService.storeString(_localUserKey, json);
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde locale user: $e');
    }
  }

  static Future<User?> _loadLocal() async {
    try {
      final json = HiveStorageService.getString(_localUserKey);
      if (json != null && json.isNotEmpty) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return User.fromJson(map);
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement local user: $e');
    }
    return null;
  }

  /// Sync backend en arrière-plan (non-bloquant), sérialisée en FIFO
  static Future<void> _syncToBackend() {
    if (_fakeUser == null) return Future.value();
    final currentUser = _fakeUser!;
    _syncQueue = _syncQueue.then((_) => _performSync(currentUser)).catchError((e) {
      debugPrint('⚠️ Erreur sync backend: $e');
    });
    return _syncQueue;
  }

  static Future<void> _performSync(User snapshot) async {
    try {
      final savedUser = await _apiService.createOrUpdateUser(snapshot);
      // Ne pas écraser les données locales (favoris packages déjà inclus dans snapshot)
      _fakeUser = savedUser.copyWith(
        favoritePackages: snapshot.favoritePackages,
        downloadedTeachingIds: snapshot.downloadedTeachingIds,
        recentlyPlayedIds: snapshot.recentlyPlayedIds,
        favoriteTeachingIds: snapshot.favoriteTeachingIds,
      );
      await _saveLocal();
    } catch (e) {
      debugPrint('⚠️ Erreur sync backend: $e');
    }
  }

  /// Synchroniser la liste des téléchargements locaux vers le user
  static Future<void> syncDownloadedTeachingIds(List<String> ids) async {
    if (_fakeUser == null) return;
    _fakeUser = _fakeUser!.copyWith(
      downloadedTeachingIds: List.from(ids),
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  // ---------------------------------------
  // RÉCUPÉRER L'UTILISATEUR COURANT
  // ---------------------------------------
  static Future<User?> getCurrentUser() async {
    // Charger depuis le local d'abord (offline-first)
    _fakeUser ??= await _loadLocal();
    return _fakeUser;
  }

  // ---------------------------------------
  // INITIALISER UN USER PAR DÉFAUT
  // ---------------------------------------
  static Future<void> initializeDefaultUser() async {
    // Essayer de charger depuis le local d'abord
    final localUser = await _loadLocal();
    if (localUser != null) {
      _fakeUser = localUser;
      debugPrint('✅ Utilisateur restauré depuis le stockage local');
      return;
    }

    // Sinon créer un user par défaut et le persister
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
    await _saveLocal();
  }

  // ---------------------------------------
  // MISE À JOUR DU USER ENTIER
  // ---------------------------------------
  static Future<void> updateUser(User user) async {
    _fakeUser = user.copyWith(updatedAt: DateTime.now());
    await _saveLocal();
    // Sync backend en arrière-plan
    _syncToBackend();
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
    await _saveLocal();
    _syncToBackend();
  }

  static Future<void> addMultipleFavorites(List<String> ids) async {
    if (_fakeUser == null) return;

    final list = List<String>.from(_fakeUser!.favoriteTeachingIds);
    for (final id in ids) {
      if (!list.contains(id)) list.add(id);
    }

    _fakeUser = _fakeUser!.copyWith(
      favoriteTeachingIds: list,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  // ----------------------------------------------------------
  // FAVORITE PACKAGES
  // ----------------------------------------------------------
  static Future<void> createFavoritePackage(String name, List<String> teachingIds) async {
    if (_fakeUser == null) return;

    final package = FavoritePackage(
      id: 'pkg-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      teachingIds: teachingIds,
      createdAt: DateTime.now(),
    );

    final packages = List<FavoritePackage>.from(_fakeUser!.favoritePackages)
      ..add(package);

    _fakeUser = _fakeUser!.copyWith(
      favoritePackages: packages,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  static Future<void> removeFavoritePackage(String packageId) async {
    if (_fakeUser == null) return;

    final packages = List<FavoritePackage>.from(_fakeUser!.favoritePackages)
      ..removeWhere((p) => p.id == packageId);

    _fakeUser = _fakeUser!.copyWith(
      favoritePackages: packages,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  static Future<void> renameFavoritePackage(String packageId, String newName) async {
    if (_fakeUser == null) return;

    final packages = _fakeUser!.favoritePackages.map((p) {
      if (p.id == packageId) return p.copyWith(name: newName);
      return p;
    }).toList();

    _fakeUser = _fakeUser!.copyWith(
      favoritePackages: packages,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  static List<FavoritePackage> getFavoritePackages() {
    return _fakeUser?.favoritePackages ?? [];
  }

  static Future<void> removeFromFavorites(String id) async {
    if (_fakeUser == null) return;

    final list = List<String>.from(_fakeUser!.favoriteTeachingIds);
    list.remove(id);

    _fakeUser = _fakeUser!.copyWith(
      favoriteTeachingIds: list,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
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

    // Garder seulement 20 derniers
    if (list.length > 20) list.removeLast();

    _fakeUser = _fakeUser!.copyWith(
      recentlyPlayedIds: list,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
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
    await _saveLocal();
    _syncToBackend();
  }

  static Future<void> updateUserEmail(String email) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      email: email,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
  }

  static Future<void> updateProfileImage(String url) async {
    if (_fakeUser == null) return;

    _fakeUser = _fakeUser!.copyWith(
      profileImageUrl: url,
      updatedAt: DateTime.now(),
    );
    await _saveLocal();
    _syncToBackend();
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
    await _saveLocal();
  }

  // ----------------------------------------------------------
  // DÉCONNEXION
  // ----------------------------------------------------------
  static Future<void> clearUserData() async {
    _fakeUser = null;
    await HiveStorageService.delete(_localUserKey);
  }

  // ----------------------------------------------------------
  // LOGIN (avec sauvegarde backend)
  // ----------------------------------------------------------
  static Future<User?> login(String email, String password) async {
    try {
      // Si l'utilisateur existe localement, le synchroniser avec le backend
      if (_fakeUser != null && _fakeUser!.email == email) {
        await _saveLocal();
        _syncToBackend();
        return _fakeUser;
      }
      
      // Si l'utilisateur n'existe pas localement, créer un nouveau
      final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      _fakeUser = User(
        id: userId,
        name: email.split('@')[0],
        email: email,
        profileImageUrl: null,
        favoriteTeachingIds: [],
        downloadedTeachingIds: [],
        recentlyPlayedIds: [],
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _saveLocal();
      _syncToBackend();

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
      await _saveLocal();
      _syncToBackend();

      return _fakeUser;
    } catch (e) {
      debugPrint('❌ Erreur register: $e');
      return null;
    }
  }
}
