import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/user_program_progress.dart';
import '../models/training_program.dart';

class ProgramCalendarWidget extends StatelessWidget {
  final UserProgramProgress? progress;
  final TrainingProgram program;

  const ProgramCalendarWidget({
    super.key,
    this.progress,
    required this.program,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startDate = progress?.startedAt ?? DateTime.now();
    final currentDay = progress?.currentDay ?? 1;
    final completedDays = progress?.completedDays ?? [];

    // Calculate the range of dates for the program
    final firstDay = startDate;
    final lastDay = startDate.add(Duration(days: program.durationDays - 1));
    final focusedDay = startDate.add(Duration(days: currentDay - 1));

    return Column(
      children: [
        TableCalendar(
          firstDay: firstDay,
          lastDay: lastDay.add(const Duration(days: 30)), // Show a bit extra
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleMedium!,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: theme.colorScheme.error),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                startDate,
                currentDay,
                completedDays,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildDayCell(
                context,
                day,
                startDate,
                currentDay,
                completedDays,
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            // Optional: Show day details on tap
          },
        ),
        const SizedBox(height: 16),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    DateTime startDate,
    int currentDay,
    List<int> completedDays,
  ) {
    final theme = Theme.of(context);
    final dayNumber = day.difference(startDate).inDays + 1;

    // Determine if this day is part of the program
    if (dayNumber < 1 || dayNumber > program.durationDays) {
      return Center(
        child: Text('${day.day}', style: TextStyle(color: theme.disabledColor)),
      );
    }

    // Determine day state
    final isCompleted = completedDays.contains(dayNumber);
    final isCurrent = dayNumber == currentDay;
    final isPast = dayNumber < currentDay;
    final isFuture = dayNumber > currentDay;

    Color? backgroundColor;
    Color? textColor;
    IconData? icon;

    if (isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.7);
      textColor = Colors.white;
      icon = Icons.check;
    } else if (isCurrent) {
      backgroundColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else if (isPast && !isCompleted) {
      backgroundColor = Colors.red.withOpacity(0.3);
      textColor = theme.colorScheme.onSurface;
    } else if (isFuture) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurface;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(icon, size: 12, color: textColor),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(
          color: Colors.green.withOpacity(0.7),
          label: 'Completed',
          icon: Icons.check,
        ),
        _LegendItem(color: theme.colorScheme.primary, label: 'Current'),
        _LegendItem(color: Colors.red.withOpacity(0.3), label: 'Missed'),
        _LegendItem(
          color: theme.colorScheme.surfaceContainerHighest,
          label: 'Upcoming',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;

  const _LegendItem({required this.color, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: icon != null
              ? Icon(icon, size: 10, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
