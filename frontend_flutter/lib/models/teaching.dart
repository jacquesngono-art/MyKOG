class Teaching {
  final String id;
  final String title;
  final String speaker;
  final String? description;
  final String category;
  final Duration duration;
  final String audioUrl;
  final String artworkUrl;
  final List<String> tags;
  final int playCount;
  final double rating;
  final bool isNew;
  final bool isFeatured;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? mois;
  final String? annee;
  final String? typeCulte;

  // Méthode pour créer un enseignement vide (pour le fallback)
  static Teaching empty() {
    return Teaching(
      id: '',
      title: '',
      speaker: '',
      description: '',
      category: '',
      duration: const Duration(seconds: 0),
      audioUrl: '',
      artworkUrl: '',
      tags: const [],
      playCount: 0,
      rating: 0.0,
      isNew: false,
      isFeatured: false,
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      mois: '',
      annee: '',
      typeCulte: '',
    );
  }

  Teaching({
    required this.id,
    required this.title,
    required this.speaker,
    this.description,
    required this.category,
    required this.duration,
    required this.audioUrl,
    required this.artworkUrl,
    this.tags = const [],
    this.playCount = 0,
    this.rating = 0.0,
    this.isNew = false,
    this.isFeatured = false,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.mois,
    this.annee,
    this.typeCulte,
  });

  Teaching copyWith({
    String? id,
    String? title,
    String? speaker,
    String? description,
    String? category,
    Duration? duration,
    String? audioUrl,
    String? artworkUrl,
    List<String>? tags,
    int? playCount,
    double? rating,
    bool? isNew,
    bool? isFeatured,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mois,
    String? annee,
    String? typeCulte,
  }) {
    return Teaching(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      tags: tags ?? this.tags,
      playCount: playCount ?? this.playCount,
      rating: rating ?? this.rating,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mois: mois ?? this.mois,
      annee: annee ?? this.annee,
      typeCulte: typeCulte ?? this.typeCulte,
    );
  }

  // Getter pour vérifier si l'enseignement est vide
  bool get isEmpty => id.isEmpty && title.isEmpty;

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
      'duration': duration.inSeconds,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'tags': tags,
      'playCount': playCount,
      'rating': rating,
      'isNew': isNew,
      'isFeatured': isFeatured,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'mois': mois,
      'annee': annee,
      'typeCulte': typeCulte,
    };
  }

  factory Teaching.fromJson(Map<String, dynamic> json) {
    return Teaching(
      id: json['id'] as String,
      title: json['title'] as String,
      speaker: json['speaker'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      duration: Duration(seconds: json['duration'] as int),
      audioUrl: json['audioUrl'] as String,
      artworkUrl: json['artworkUrl'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      playCount: json['playCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isNew: json['isNew'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      mois: json['mois']?.toString(),
      annee: json['annee']?.toString(),
      typeCulte: json['typeCulte']?.toString(),
    );
  }
}