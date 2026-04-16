class Book {
  final String id;
  final String title;
  final String? author;
  final String? description;
  final String pdfUrl;
  final String? coverUrl;
  final int? pageCount;
  final String? publishedDate;
  final String? fileSize;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.description,
    required this.pdfUrl,
    this.coverUrl,
    this.pageCount,
    this.publishedDate,
    this.fileSize,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'],
      description: json['description'],
      pdfUrl: json['pdfUrl'] ?? json['pdf_url'] ?? '',
      coverUrl: json['coverUrl'] ?? json['cover_url'],
      pageCount: json['pageCount'] ?? json['page_count'],
      publishedDate: json['publishedDate'] ?? json['published_date'],
      fileSize: json['fileSize'] ?? json['file_size'],
      category: json['category'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'pdfUrl': pdfUrl,
      'coverUrl': coverUrl,
      'pageCount': pageCount,
      'publishedDate': publishedDate,
      'fileSize': fileSize,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
