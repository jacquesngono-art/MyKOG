class MyKOGUser {
  String id;
  String name;
  String email;
  String? profileImageUrl;
  DateTime createdAt;

  List<String> favoriteTeachingIds;
  List<String> downloadedTeachingIds;
  List<String> recentlyPlayedIds;

  MyKOGUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.profileImageUrl,
    this.favoriteTeachingIds = const [],
    this.downloadedTeachingIds = const [],
    this.recentlyPlayedIds = const [],
  });

  // Convert for SharedPreferences
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'createdAt': createdAt.toIso8601String(),
        'favorites': favoriteTeachingIds,
        'downloads': downloadedTeachingIds,
        'recent': recentlyPlayedIds,
      };

  factory MyKOGUser.fromJson(Map<String, dynamic> json) {
    return MyKOGUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      profileImageUrl: json['profileImageUrl'],
      favoriteTeachingIds: List<String>.from(json['favorites'] ?? []),
      downloadedTeachingIds: List<String>.from(json['downloads'] ?? []),
      recentlyPlayedIds: List<String>.from(json['recent'] ?? []),
    );
  }
}
