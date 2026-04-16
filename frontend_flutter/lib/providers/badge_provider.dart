import 'package:flutter/material.dart';
import 'package:MyKOG/services/badge_service.dart';

class BadgeProvider extends ChangeNotifier {
  final BadgeService _badgeService = BadgeService();

  bool get hasNewTeachings => _badgeService.hasNewTeachings;
  bool get hasNewCalendarEvents => _badgeService.hasNewCalendarEvents;

  BadgeProvider() {
    // Écouter les changements du service de badges
    _badgeService.addListener(_onBadgeChanged);
  }

  void _onBadgeChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _badgeService.removeListener(_onBadgeChanged);
    super.dispose();
  }
}

