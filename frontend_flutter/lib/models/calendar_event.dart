class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? category; // Ex: "Culte", "Réunion", "Événement", etc.
  final String? color; // Couleur hex pour l'affichage
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy; // ID de l'admin qui a créé l'événement
  
  // Champs pour le système d'alarme
  final bool hasAlarm; // Si l'alarme est activée
  final int? alarmDaysBefore; // Nombre de jours avant l'événement
  final int? alarmHoursBefore; // Nombre d'heures avant l'événement
  final int? alarmMinutesBefore; // Nombre de minutes avant l'événement

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    this.location,
    this.category,
    this.color,
    this.isAllDay = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.hasAlarm = false,
    this.alarmDaysBefore,
    this.alarmHoursBefore,
    this.alarmMinutesBefore,
  });

  // Créer un événement vide
  static CalendarEvent empty() {
    return CalendarEvent(
      id: '',
      title: '',
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      hasAlarm: false,
    );
  }

  // Vérifier si l'événement est vide
  bool get isEmpty => id.isEmpty || title.isEmpty;

  // Conversion en Map pour JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'location': location,
      'category': category,
      'color': color,
      'isAllDay': isAllDay,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'hasAlarm': hasAlarm,
      'alarmDaysBefore': alarmDaysBefore,
      'alarmHoursBefore': alarmHoursBefore,
      'alarmMinutesBefore': alarmMinutesBefore,
    };
  }

  // Création depuis un Map
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      location: json['location'],
      category: json['category'],
      color: json['color'],
      isAllDay: json['isAllDay'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
      hasAlarm: json['hasAlarm'] ?? false,
      alarmDaysBefore: json['alarmDaysBefore'],
      alarmHoursBefore: json['alarmHoursBefore'],
      alarmMinutesBefore: json['alarmMinutesBefore'],
    );
  }

  // CopyWith pour les mises à jour
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? category,
    String? color,
    bool? isAllDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? hasAlarm,
    int? alarmDaysBefore,
    int? alarmHoursBefore,
    int? alarmMinutesBefore,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      category: category ?? this.category,
      color: color ?? this.color,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      alarmDaysBefore: alarmDaysBefore ?? this.alarmDaysBefore,
      alarmHoursBefore: alarmHoursBefore ?? this.alarmHoursBefore,
      alarmMinutesBefore: alarmMinutesBefore ?? this.alarmMinutesBefore,
    );
  }
  
  // Calculer la date de déclenchement de l'alarme
  DateTime? get alarmTriggerTime {
    if (!hasAlarm) return null;
    
    DateTime triggerTime = startDate;
    
    if (alarmDaysBefore != null && alarmDaysBefore! > 0) {
      triggerTime = triggerTime.subtract(Duration(days: alarmDaysBefore!));
    }
    if (alarmHoursBefore != null && alarmHoursBefore! > 0) {
      triggerTime = triggerTime.subtract(Duration(hours: alarmHoursBefore!));
    }
    if (alarmMinutesBefore != null && alarmMinutesBefore! > 0) {
      triggerTime = triggerTime.subtract(Duration(minutes: alarmMinutesBefore!));
    }
    
    return triggerTime;
  }

  // Obtenir la durée de l'événement
  Duration? get duration {
    if (endDate == null) return null;
    return endDate!.difference(startDate);
  }

  // Vérifier si l'événement est en cours
  bool isHappeningNow() {
    final now = DateTime.now();
    if (endDate == null) {
      return startDate.isBefore(now) || startDate.isAtSameMomentAs(now);
    }
    return now.isAfter(startDate) && now.isBefore(endDate!);
  }

  // Vérifier si l'événement est passé
  bool isPast() {
    final now = DateTime.now();
    if (endDate == null) {
      return startDate.isBefore(now);
    }
    return endDate!.isBefore(now);
  }

  // Vérifier si l'événement est à venir
  bool isUpcoming() {
    return startDate.isAfter(DateTime.now());
  }
}

