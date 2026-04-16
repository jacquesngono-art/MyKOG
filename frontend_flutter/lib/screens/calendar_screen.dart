import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:MyKOG/models/calendar_event.dart';
import 'package:MyKOG/services/calendar_service.dart';
import 'package:MyKOG/services/badge_service.dart';
import 'package:MyKOG/services/alarm_service.dart';
import 'package:MyKOG/theme.dart';
import 'package:MyKOG/widgets/glass_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<CalendarEvent> _events = [];
  bool _isLoading = true;
  String? _error;

  // Pour l'admin (à déterminer selon votre système d'auth)
  bool _isAdmin = false; // TODO: Récupérer depuis UserProvider ou auth

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await CalendarService.getAllEvents();
      
      // Vérifier les nouveaux événements pour le badge
      try {
        final eventIds = events.map((e) => e.id).toList();
        await BadgeService().checkNewCalendarEvents(eventIds);
      } catch (e) {
        debugPrint('Erreur vérification badges événements: $e');
      }
      
      // Synchroniser les alarmes pour tous les événements avec alarme activée
      try {
        for (final event in events) {
          if (event.hasAlarm && event.isUpcoming()) {
            await AlarmService().scheduleAlarm(event);
          }
        }
        debugPrint('✅ Alarmes synchronisées pour ${events.where((e) => e.hasAlarm && e.isUpcoming()).length} événements');
      } catch (e) {
        debugPrint('Erreur synchronisation alarmes: $e');
      }
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = null;
        _isLoading = false;
      });
    }
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.startDate.year == date.year &&
          event.startDate.month == date.month &&
          event.startDate.day == date.day;
    }).toList();
  }

  List<CalendarEvent> _getEventsForMonth(DateTime month) {
    return _events.where((event) {
      return event.startDate.year == month.year &&
          event.startDate.month == month.month;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MyKOGColors.primaryDark,
      appBar: AppBar(
        backgroundColor: MyKOGColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: MyKOGColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calendrier',
          style: theme.textTheme.titleLarge?.copyWith(
            color: MyKOGColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add, color: MyKOGColors.accent),
              onPressed: () => _showAddEventDialog(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MyKOGColors.accent),
            )
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 64.w, color: MyKOGColors.textSecondary),
                      SizedBox(height: 16.h),
                      Text(
                        'Aucun événement',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: MyKOGColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Les événements apparaîtront ici',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  color: MyKOGColors.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header avec navigation du mois
                        _buildMonthHeader(context, theme),
                        SizedBox(height: 16.h),

                        // Calendrier mensuel
                        _buildCalendar(context, theme),
                        SizedBox(height: 24.h),

                        // Événements du mois
                        _buildMonthEvents(context, theme),
                        SizedBox(height: 100.h), // Padding pour mini player
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, ThemeData theme) {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: MyKOGColors.accent),
            onPressed: _previousMonth,
          ),
          Text(
            monthName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: MyKOGColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideX(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.today, color: MyKOGColors.accent),
                onPressed: _goToToday,
                tooltip: "Aujourd'hui",
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: MyKOGColors.accent),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, ThemeData theme) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    // Jours de la semaine
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return GlassCard(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // En-tête des jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: MyKOGColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 8.h),
          Divider(color: MyKOGColors.textTertiary, height: 1.h),
          SizedBox(height: 8.h),

          // Grille du calendrier
          ...List.generate(
            ((daysInMonth + firstDayWeekday - 1) / 7).ceil(),
            (weekIndex) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstDayWeekday + 2;
                    final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
                    final dayDate = isCurrentMonth
                        ? DateTime(_currentMonth.year, _currentMonth.month, dayNumber)
                        : null;
                    final isToday = dayDate != null &&
                        dayDate.year == DateTime.now().year &&
                        dayDate.month == DateTime.now().month &&
                        dayDate.day == DateTime.now().day;
                    final isSelected = dayDate != null &&
                        dayDate.year == _selectedDate.year &&
                        dayDate.month == _selectedDate.month &&
                        dayDate.day == _selectedDate.day;
                    final dayEvents = dayDate != null
                        ? _getEventsForDate(dayDate)
                        : <CalendarEvent>[];

                    return Expanded(
                      child: GestureDetector(
                        onTap: isCurrentMonth
                            ? () {
                                setState(() {
                                  _selectedDate = dayDate!;
                                });
                                HapticFeedback.lightImpact();
                              }
                            : null,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? MyKOGColors.accent.withValues(alpha: 0.2)
                                : isToday
                                    ? MyKOGColors.accent.withValues(alpha: 0.1)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                            border: isToday
                                ? Border.all(
                                    color: MyKOGColors.accent,
                                    width: 2.w,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isCurrentMonth ? '$dayNumber' : '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isSelected
                                      ? MyKOGColors.accent
                                      : isToday
                                          ? MyKOGColors.accent
                                          : MyKOGColors.textPrimary,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (dayEvents.isNotEmpty)
                                Container(
                                  margin: EdgeInsets.only(top: 2.h),
                                  width: 4.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: dayEvents.first.color != null
                                        ? Color(int.parse(
                                            dayEvents.first.color!.replaceFirst('#', '0xFF')))
                                        : MyKOGColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildMonthEvents(BuildContext context, ThemeData theme) {
    final monthEvents = _getEventsForMonth(_currentMonth);
    final selectedDateEvents = _getEventsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Événements du jour sélectionné
        if (selectedDateEvents.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDate),
              style: theme.textTheme.titleLarge?.copyWith(
                color: MyKOGColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...selectedDateEvents.map((event) => _buildEventCard(context, theme, event)),
          SizedBox(height: 24.h),
        ],

        // Tous les événements du mois
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Événements du mois',
            style: theme.textTheme.titleLarge?.copyWith(
              color: MyKOGColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        if (monthEvents.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GlassCard(
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy,
                        size: 48, color: MyKOGColors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun événement ce mois-ci',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: MyKOGColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...monthEvents.map((event) => _buildEventCard(context, theme, event)),
      ],
    );
  }

  Widget _buildEventCard(
      BuildContext context, ThemeData theme, CalendarEvent event) {
    final eventColor = event.color != null
        ? Color(int.parse(event.color!.replaceFirst('#', '0xFF')))
        : MyKOGColors.accent;
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    final dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassCard(
        child: InkWell(
          onTap: () => _showEventDetails(context, event),
          onLongPress: _isAdmin
              ? () => _showEventActions(context, event)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Indicateur de couleur
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: eventColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: MyKOGColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: MyKOGColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: MyKOGColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(event.startDate)} ${event.isAllDay ? '' : 'à ${timeFormat.format(event.startDate)}'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: MyKOGColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: MyKOGColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: MyKOGColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isAdmin)
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: MyKOGColors.textSecondary),
                  onPressed: () => _showEventActions(context, event),
                ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyKOGColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: MyKOGColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (event.description != null) ...[
              const SizedBox(height: 12),
              Text(
                event.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MyKOGColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
                .format(event.startDate)),
            if (event.location != null)
              _buildDetailRow(Icons.location_on, event.location!),
            if (event.category != null)
              _buildDetailRow(Icons.category, event.category!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MyKOGColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MyKOGColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventActions(BuildContext context, CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyKOGColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: MyKOGColors.accent),
              title: const Text('Modifier', style: TextStyle(color: MyKOGColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showEditEventDialog(context, event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: MyKOGColors.error),
              title: const Text('Supprimer', style: TextStyle(color: MyKOGColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    // TODO: Implémenter le formulaire d'ajout
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyKOGColors.secondary,
        title: const Text('Nouvel événement', style: TextStyle(color: MyKOGColors.textPrimary)),
        content: const Text('Formulaire à implémenter', style: TextStyle(color: MyKOGColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEvent event) {
    // TODO: Implémenter le formulaire d'édition
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyKOGColors.secondary,
        title: const Text('Modifier l\'événement', style: TextStyle(color: MyKOGColors.textPrimary)),
        content: const Text('Formulaire à implémenter', style: TextStyle(color: MyKOGColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MyKOGColors.secondary,
        title: const Text('Supprimer l\'événement', style: TextStyle(color: MyKOGColors.textPrimary)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${event.title}" ?',
          style: const TextStyle(color: MyKOGColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CalendarService.deleteEvent(event.id);
                _loadEvents();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Événement supprimé'),
                      backgroundColor: MyKOGColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: MyKOGColors.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: MyKOGColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

