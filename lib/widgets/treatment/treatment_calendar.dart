import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/treatment_model.dart';
import '../../utils/app_constants.dart';

class TreatmentCalendar extends StatefulWidget {
  final TreatmentModel treatment;
  final Function(DateTime) onDaySelected;

  const TreatmentCalendar({super.key, required this.treatment, required this.onDaySelected});

  @override
  State<TreatmentCalendar> createState() => _TreatmentCalendarState();
}

class _TreatmentCalendarState extends State<TreatmentCalendar> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TableCalendar(
      locale: 'pt_BR',
      focusedDay: _focusedDay,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      calendarFormat: CalendarFormat.month,
      onDaySelected: (s, f) { 
        setState(() => _focusedDay = f);
        widget.onDaySelected(s);
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
        selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      ),
      calendarBuilders: CalendarBuilders(
        prioritizedBuilder: (context, day, focusedDay) {
          final dateStr = DateFormat('yyyy-MM-dd').format(day);
          final sessionsOnDay = widget.treatment.sessions.where((s) => DateFormat('yyyy-MM-dd').format(s.date) == dateStr).toList();
          bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;

          if (sessionsOnDay.isNotEmpty) {
            final status = sessionsOnDay.first.status;
            Color color = Colors.orange.shade400;
            if (status == AppConstants.statusRealizada) color = Colors.blue.shade600;
            if (status == AppConstants.statusCancelada) color = Colors.red.shade600;
            if (status == AppConstants.statusRemarcada) color = Colors.purple.shade600;
            
            return Container(
              margin: const EdgeInsets.all(4), 
              alignment: Alignment.center, 
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isToday ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null), 
              child: Text(day.day.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            );
          } else if (isToday) {
            return Container(
              margin: const EdgeInsets.all(4),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white70 : Colors.black54, width: 1)),
              child: Text(day.day.toString(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            );
          }
          return null;
        },
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
    );
  }
}
