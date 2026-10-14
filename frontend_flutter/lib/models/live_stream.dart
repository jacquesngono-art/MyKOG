class LiveStream {
  final String id;
  final String title;
  final String description;
  final String pastor;
  final String thumbnailUrl;
  final String streamUrl;
  final String roomName;
  final String livekitUrl;
  final LiveStreamStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final int viewerCount;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs LiveKit (WebRTC)
  final String? streamKey;
  final String? roomName;
  final String? livekitUrl;
  final String? whipUrl;
  final String? ingressStreamKey;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.pastor,
    required this.thumbnailUrl,
    required this.streamUrl,
    required this.roomName,
    required this.livekitUrl,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.viewerCount = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.streamKey,
    this.roomName,
    this.livekitUrl,
    this.whipUrl,
    this.ingressStreamKey,
  });

  LiveStream copyWith({
    String? id,
    String? title,
    String? description,
    String? pastor,
    String? thumbnailUrl,
    String? streamUrl,
    String? roomName,
    String? livekitUrl,
    LiveStreamStatus? status,
    DateTime? scheduledAt,
    DateTime? startedAt,
    int? viewerCount,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? streamKey,
    String? roomName,
    String? livekitUrl,
    String? whipUrl,
    String? ingressStreamKey,
  }) {
    return LiveStream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pastor: pastor ?? this.pastor,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      roomName: roomName ?? this.roomName,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      viewerCount: viewerCount ?? this.viewerCount,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      streamKey: streamKey ?? this.streamKey,
      roomName: roomName ?? this.roomName,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      whipUrl: whipUrl ?? this.whipUrl,
      ingressStreamKey: ingressStreamKey ?? this.ingressStreamKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pastor': pastor,
      'thumbnailUrl': thumbnailUrl,
      'streamUrl': streamUrl,
      'roomName': roomName,
      'livekitUrl': livekitUrl,
      'status': status.toString(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'viewerCount': viewerCount,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'streamKey': streamKey,
      'roomName': roomName,
      'livekitUrl': livekitUrl,
      'whipUrl': whipUrl,
      'ingressStreamKey': ingressStreamKey,
    };
  }

  factory LiveStream.fromJson(Map<String, dynamic> json) {
    // Gérer le statut (peut être String ou déjà un enum)
    LiveStreamStatus status;
    if (json['status'] is String) {
      final statusStr = json['status'] as String;
      status = LiveStreamStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusStr.toLowerCase(),
        orElse: () => LiveStreamStatus.scheduled,
      );
    } else {
      status = LiveStreamStatus.scheduled;
    }

    return LiveStream(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pastor: json['pastor']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      streamUrl: json['streamUrl']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      livekitUrl: json['livekitUrl']?.toString() ?? '',
      status: status,
      scheduledAt: json['scheduledAt'] != null 
          ? (json['scheduledAt'] is String 
              ? DateTime.parse(json['scheduledAt'] as String) 
              : (json['scheduledAt'] as DateTime?))
          : null,
      startedAt: json['startedAt'] != null 
          ? (json['startedAt'] is String 
              ? DateTime.parse(json['startedAt'] as String) 
              : (json['startedAt'] as DateTime?))
          : null,
      viewerCount: (json['viewerCount'] as int?) ?? 0,
      tags: json['tags'] != null
          ? List<String>.from((json['tags'] as List).map((e) => e.toString()))
          : [],
      streamKey: json['streamKey']?.toString(),
      roomName: json['roomName']?.toString(),
      livekitUrl: json['livekitUrl']?.toString(),
      whipUrl: json['whipUrl']?.toString(),
      ingressStreamKey: json['ingressStreamKey']?.toString(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'] as String) 
              : (json['createdAt'] as DateTime))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt'] as String) 
              : (json['updatedAt'] as DateTime))
          : DateTime.now(),
    );
  }
}

enum LiveStreamStatus {
  scheduled,
  live,
  ended,
}
