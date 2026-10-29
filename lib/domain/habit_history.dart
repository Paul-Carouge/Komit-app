import '../core/calendar_day.dart';
import 'habit_schedule.dart';
import 'habit_statistics.dart';

/// One habit's logs and the rules that make a day count, as recaps, achievements and
/// celebrations read them.
class HabitHistory {
  const HabitHistory({
    required this.habitId,
    required this.objectiveIdByDay,
    required this.successObjectiveIds,
    required this.startDay,
    this.scheduledWeekdayMask = everyWeekdayMask,
    this.targetDaysPerWeek,
    this.archivedDay,
  });

  final int habitId;
  final Map<CalendarDay, int> objectiveIdByDay;
  final Set<int> successObjectiveIds;

  /// The earlier of the creation day and the first log: an imported habit's history can
  /// start years before the habit row was created on this phone.
  final CalendarDay startDay;
  final int scheduledWeekdayMask;
  final int? targetDaysPerWeek;

  /// Null while the habit is active.
  final CalendarDay? archivedDay;

  bool isSuccessOn(CalendarDay day) => successObjectiveIds.contains(objectiveIdByDay[day]);

  bool isScheduledOn(CalendarDay day) => isWeekdayScheduled(scheduledWeekdayMask, day.weekday);

  /// The streak as it stood at the end of [day].
  StreakSummary streakSummaryOn(CalendarDay day) => computeScheduledStreakSummary(
    objectiveIdByDay,
    successObjectiveIds: successObjectiveIds,
    scheduledWeekdayMask: scheduledWeekdayMask,
    targetDaysPerWeek: targetDaysPerWeek,
    today: day,
  );

  /// Success days the habit asks for in the week starting on [monday]: its weekly target, or
  /// its scheduled weekdays.
  int expectedSuccessDaysInWeekOf(CalendarDay monday) =>
      targetDaysPerWeek ??
      [for (var offset = 0; offset < DateTime.daysPerWeek; offset++) monday.addDays(offset)]
          .where(isScheduledOn)
          .length;

  int countSuccessDaysInWeekOf(CalendarDay monday) =>
      [for (var offset = 0; offset < DateTime.daysPerWeek; offset++) monday.addDays(offset)].where(isSuccessOn).length;

  /// Whether the habit existed for the whole week starting on [monday].
  bool isActiveForWholeWeekOf(CalendarDay monday) {
    final archivedDay = this.archivedDay;
    return !startDay.isAfter(monday) &&
        (archivedDay == null || archivedDay.isAfter(monday.addDays(DateTime.daysPerWeek - 1)));
  }

  /// The same history with [day] logged as [objectiveId], or cleared when it is null.
  HabitHistory withDayLogged(CalendarDay day, int? objectiveId) => HabitHistory(
    habitId: habitId,
    objectiveIdByDay: objectiveId == null
        ? ({...objectiveIdByDay}..remove(day))
        : {...objectiveIdByDay, day: objectiveId},
    successObjectiveIds: successObjectiveIds,
    startDay: startDay,
    scheduledWeekdayMask: scheduledWeekdayMask,
    targetDaysPerWeek: targetDaysPerWeek,
    archivedDay: archivedDay,
  );
}
