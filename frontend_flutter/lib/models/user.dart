import 'package:MyKOG/models/favorite_package.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  // 🎯 Métadonnées utilisateur
  final List<String> favoriteTeachingIds; // IDs des enseignements favoris
  final List<FavoritePackage> favoritePackages; // Packages de favoris
  final List<String> downloadedTeachingIds; // IDs des téléchargements
  final List<String> recentlyPlayedIds; // IDs récemment lus

  final bool notificationsEnabled; // Notifications activées

  final DateTime createdAt; // Date de création
  final DateTime updatedAt; // Dernière mise à jour

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.favoriteTeachingIds,
    this.favoritePackages = const [],
    required this.downloadedTeachingIds,
    required this.recentlyPlayedIds,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  // ➡️ Conversion en Map pour stockage (Shared Prefs, API…)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'favoriteTeachingIds': favoriteTeachingIds,
      'favoritePackages': favoritePackages.map((p) => p.toJson()).toList(),
      'downloadedTeachingIds': downloadedTeachingIds,
      'recentlyPlayedIds': recentlyPlayedIds,
      'notificationsEnabled': notificationsEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ➡️ Création depuis un Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      favoriteTeachingIds: List<String>.from(json['favoriteTeachingIds'] ?? []),
      favoritePackages: (json['favoritePackages'] as List<dynamic>?)
              ?.map((p) => FavoritePackage.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      downloadedTeachingIds:
          List<String>.from(json['downloadedTeachingIds'] ?? []),
      recentlyPlayedIds: List<String>.from(json['recentlyPlayedIds'] ?? []),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // ➡️ CopyWith pour les mises à jour
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    List<String>? favoriteTeachingIds,
    List<FavoritePackage>? favoritePackages,
    List<String>? downloadedTeachingIds,
    List<String>? recentlyPlayedIds,
    bool? notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteTeachingIds: favoriteTeachingIds ?? this.favoriteTeachingIds,
      favoritePackages: favoritePackages ?? this.favoritePackages,
      downloadedTeachingIds:
          downloadedTeachingIds ?? this.downloadedTeachingIds,
      recentlyPlayedIds: recentlyPlayedIds ?? this.recentlyPlayedIds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
