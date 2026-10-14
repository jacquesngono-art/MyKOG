/// Modèle d'un commentaire de live (structure arbre : replies imbriquées)
class LiveComment {
  final String id;
  final String author;
  final String? userId;
  final String content;
  final String avatar;
  final String? parentId;
  int votes;
  final DateTime? createdAt;
  final List<LiveComment> replies;

  LiveComment({
    required this.id,
    required this.author,
    required this.content,
    this.userId,
    this.avatar = '',
    this.parentId,
    this.votes = 0,
    this.createdAt,
    List<LiveComment>? replies,
  }) : replies = replies ?? [];

  factory LiveComment.fromJson(Map<String, dynamic> json) {
    return LiveComment(
      id: json['id']?.toString() ?? '',
      author: json['author']?.toString() ?? 'Anonyme',
      userId: json['userId']?.toString(),
      content: json['content']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      votes: json['votes'] is int ? json['votes'] : int.tryParse('${json['votes']}') ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      replies: (json['replies'] as List? ?? [])
          .map((r) => LiveComment.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }
}
