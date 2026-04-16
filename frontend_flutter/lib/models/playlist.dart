class Playlist {
  final String id;
  final String name;
  final String? description;
  final List<String> teachingIds;
  final String? coverImageUrl;
  final String userId;
  final bool isSystemGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.teachingIds = const [],
    this.coverImageUrl,
    required this.userId,
    this.isSystemGenerated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? teachingIds,
    String? coverImageUrl,
    String? userId,
    bool? isSystemGenerated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teachingIds: teachingIds ?? this.teachingIds,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      userId: userId ?? this.userId,
      isSystemGenerated: isSystemGenerated ?? this.isSystemGenerated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get teachingCount => teachingIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teachingIds': teachingIds,
      'coverImageUrl': coverImageUrl,
      'userId': userId,
      'isSystemGenerated': isSystemGenerated,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      teachingIds: List<String>.from(json['teachingIds'] ?? []),
      coverImageUrl: json['coverImageUrl'] as String?,
      userId: json['userId'] as String,
      isSystemGenerated: json['isSystemGenerated'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}