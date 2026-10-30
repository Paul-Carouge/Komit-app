import '../core/calendar_day.dart';

/// Days a habit is on hold (holiday, illness), [startDay] to [endDay] included. A paused day counts
/// like a day off the schedule: it neither breaks nor extends a streak (docs/adr/0007).
class HabitPause {
  const HabitPause({required this.startDay, this.endDay});

  final CalendarDay startDay;

  /// Null while the pause is open: every day from [startDay] on is paused.
  final CalendarDay? endDay;

  bool contains(CalendarDay day) {
    final endDay = this.endDay;
    return !startDay.isAfter(day) && (endDay == null || !day.isAfter(endDay));
  }

  @override
  bool operator ==(Object other) => other is HabitPause && other.startDay == startDay && other.endDay == endDay;

  @override
  int get hashCode => Object.hash(startDay, endDay);
}

bool isPausedOn(List<HabitPause> pauses, CalendarDay day) => pauses.any((pause) => pause.contains(day));
