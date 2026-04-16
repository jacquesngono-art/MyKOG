class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  // 🎯 Métadonnées utilisateur
  final List<String> favoriteTeachingIds; // IDs des enseignements favoris
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
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      favoriteTeachingIds: List<String>.from(json['favoriteTeachingIds'] ?? []),
      downloadedTeachingIds:
          List<String>.from(json['downloadedTeachingIds'] ?? []),
      recentlyPlayedIds: List<String>.from(json['recentlyPlayedIds'] ?? []),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ➡️ CopyWith pour les mises à jour
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
    List<String>? favoriteTeachingIds,
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
      downloadedTeachingIds:
          downloadedTeachingIds ?? this.downloadedTeachingIds,
      recentlyPlayedIds: recentlyPlayedIds ?? this.recentlyPlayedIds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
