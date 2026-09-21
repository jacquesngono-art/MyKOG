class FavoritePackage {
  final String id;
  final String name;
  final List<String> teachingIds;
  final DateTime createdAt;

  FavoritePackage({
    required this.id,
    required this.name,
    required this.teachingIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teachingIds': teachingIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoritePackage.fromJson(Map<String, dynamic> json) {
    return FavoritePackage(
      id: json['id'],
      name: json['name'],
      teachingIds: List<String>.from(json['teachingIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  FavoritePackage copyWith({
    String? id,
    String? name,
    List<String>? teachingIds,
    DateTime? createdAt,
  }) {
    return FavoritePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      teachingIds: teachingIds ?? this.teachingIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
