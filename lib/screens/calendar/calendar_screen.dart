import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/event_model.dart';
import '../../providers/event_provider.dart';
import 'add_event_sheet.dart';

const _typeIcons = {
  'Randevu': Icons.event_available_rounded,
  'Toplantı': Icons.groups_rounded,
  'Ders': Icons.school_rounded,
  'Not': Icons.sticky_note_2_rounded,
  'Etkinlik': Icons.celebration_rounded,
};

const _dayLabels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

enum _CalendarViewMode { month, week, day }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  _CalendarViewMode _viewMode = _CalendarViewMode.month;

  DateTime _startOfWeek(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: (d.weekday - 1) % 7));

  @override
  Widget build(BuildContext context) {
    final eventNotifier = ref.watch(eventProvider.notifier);
    ref.watch(eventProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dayEvents = eventNotifier.eventsOn(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddEventSheet(context, ref, _selectedDay),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            const Text('Takvim', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildViewToggle(isDark),
            const SizedBox(height: 16),
            if (_viewMode == _CalendarViewMode.month) _buildMonthCard(isDark, eventNotifier),
            if (_viewMode == _CalendarViewMode.week) _buildWeekCard(isDark, eventNotifier),
            if (_viewMode == _CalendarViewMode.day) _buildDayHeaderCard(isDark),
            const SizedBox(height: 24),
            Text(
              DateFormat('d MMMM EEEE', 'tr_TR').format(_selectedDay),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight),
            ),
            const SizedBox(height: 12),
            _buildDayAgenda(dayEvents, isDark, eventNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    final options = const [
      (_CalendarViewMode.month, 'Ay'),
      (_CalendarViewMode.week, 'Hafta'),
      (_CalendarViewMode.day, 'Gün'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: options.map((o) {
          final selected = _viewMode == o.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  o.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white
                        : (isDark ? AppColors.subtitleDark : AppColors.subtitleLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCard(bool isDark, EventNotifier eventNotifier) {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leadingEmpty = (firstDayOfMonth.weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                DateFormat('MMMM y', 'tr_TR').format(_visibleMonth),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _dayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: daysInMonth + leadingEmpty,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();
              final day = index - leadingEmpty + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final isSelected = date.year == _selectedDay.year &&
                  date.month == _selectedDay.month &&
                  date.day == _selectedDay.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasEvents = eventNotifier.hasEventsOn(date);

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? AppColors.primary.withValues(alpha: 0.15) : null),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textDark : AppColors.textLight),
                        ),
                      ),
                      if (hasEvents)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(bool isDark, EventNotifier eventNotifier) {
    final weekStart = _startOfWeek(_selectedDay);
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '${DateFormat('d MMM', 'tr_TR').format(weekStart)} - ${DateFormat('d MMM y', 'tr_TR').format(weekStart.add(const Duration(days: 6)))}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekDays.map((date) {
              final isSelected = date.year == _selectedDay.year &&
                  date.month == _selectedDay.month &&
                  date.day == _selectedDay.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasEvents = eventNotifier.hasEventsOn(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday ? AppColors.primary.withValues(alpha: 0.15) : null),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(_dayLabels[(date.weekday - 1) % 7],
                            style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.white70
                                    : (isDark ? AppColors.subtitleDark : AppColors.subtitleLight))),
                        const SizedBox(height: 4),
                        Text('${date.day}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.textDark : AppColors.textLight))),
                        const SizedBox(height: 4),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: hasEvents ? (isSelected ? Colors.white : AppColors.accent) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedDay = _selectedDay.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            DateFormat('d MMMM y', 'tr_TR').format(_selectedDay),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildDayAgenda(List<EventModel> dayEvents, bool isDark, EventNotifier eventNotifier) {
    if (dayEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Bu gün için etkinlik yok',
              style: TextStyle(color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
        ),
      );
    }
    return Column(
      children: dayEvents
          .map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcons[e.type] ?? Icons.event_rounded, color: AppColors.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (e.location.isNotEmpty)
                            Text(e.location,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.subtitleDark : AppColors.subtitleLight)),
                        ],
                      ),
                    ),
                    Text(e.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => eventNotifier.deleteEvent(e),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
