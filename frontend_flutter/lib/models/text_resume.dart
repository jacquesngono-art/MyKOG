class TextResume {
  final String id;
  final String title;
  final String speaker;
  final String? description;
  final String category;
  final String pdfUrl;
  final String coverImageUrl;
  final List<String> tags;
  final int viewCount;
  final double rating;
  final bool isNew;
  final bool isFeatured;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mois;
  final String? annee;
  final String? typeCulte;
  final int fileSize; // Taille en bytes
  final int pageCount;

  TextResume({
    required this.id,
    required this.title,
    required this.speaker,
    this.description,
    required this.category,
    required this.pdfUrl,
    required this.coverImageUrl,
    this.tags = const [],
    this.viewCount = 0,
    this.rating = 0.0,
    this.isNew = false,
    this.isFeatured = false,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.mois,
    this.annee,
    this.typeCulte,
    this.fileSize = 0,
    this.pageCount = 0,
  });

  TextResume copyWith({
    String? id,
    String? title,
    String? speaker,
    String? description,
    String? category,
    String? pdfUrl,
    String? coverImageUrl,
    List<String>? tags,
    int? viewCount,
    double? rating,
    bool? isNew,
    bool? isFeatured,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mois,
    String? annee,
    String? typeCulte,
    int? fileSize,
    int? pageCount,
  }) {
    return TextResume(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      description: description ?? this.description,
      category: category ?? this.category,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      typeCulte: typeCulte ?? this.typeCulte,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  // Getter pour la taille formatée
  String get fileSizeText {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Getters pour mois et année avec valeurs par défaut
  String get moisSafe => mois ?? DateTime.now().month.toString();
  String get anneeSafe => annee ?? DateTime.now().year.toString();

  // Formatage de la date mois/année
  String get moisAnneeText {
    if (mois != null && annee != null) {
      return '$mois/$annee';
    }
    return '${DateTime.now().month}/${DateTime.now().year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'speaker': speaker,
      'description': description,
      'category': category,
      'pdfUrl': pdfUrl,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'viewCount': viewCount,
      'rating': rating,
      'isNew': isNew,
      'isFeatured': isFeatured,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mois': mois,
      'annee': annee,
      'typeCulte': typeCulte,
      'fileSize': fileSize,
      'pageCount': pageCount,
    };
  }

  factory TextResume.fromJson(Map<String, dynamic> json) {
    return TextResume(
      id: json['id'] as String,
      title: json['title'] as String,
      speaker: json['speaker'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      pdfUrl: json['pdfUrl'] as String,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['viewCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isNew: json['isNew'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mois: json['mois']?.toString(),
      annee: json['annee']?.toString(),
      typeCulte: json['typeCulte']?.toString(),
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 0,
    );
  }
}

