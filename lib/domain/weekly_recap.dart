import '../core/calendar_day.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

class HabitWeekResult {
  const HabitWeekResult({required this.habitId, required this.successDayCount, required this.expectedSuccessDayCount});

  final int habitId;
  final int successDayCount;

  /// The weekly target, or the number of scheduled weekdays.
  final int expectedSuccessDayCount;

  bool get isWeekMet => successDayCount >= expectedSuccessDayCount;
}

/// How last week went, shown on Monday.
class WeeklyRecap {
  const WeeklyRecap({
    required this.weekMonday,
    required this.habitResults,
    required this.previousWeekSuccessDayCount,
    required this.bestStreakHabitId,
    required this.bestStreak,
  });

  /// The Monday that starts the week this recap is about.
  final CalendarDay weekMonday;

  /// In the order of the histories given, for the habits active at the end of that week.
  final List<HabitWeekResult> habitResults;
  final int previousWeekSuccessDayCount;

  /// The habit with the longest streak at the end of that week; null when no habit has one.
  final int? bestStreakHabitId;
  final StreakSummary? bestStreak;

  int get successDayCount => habitResults.fold(0, (total, result) => total + result.successDayCount);

  /// Positive when the week went better than the one before.
  int get successDayCountChange => successDayCount - previousWeekSuccessDayCount;

  /// Nothing to tell when neither week has a single success.
  bool get hasActivity => successDayCount > 0 || previousWeekSuccessDayCount > 0;
}

/// The recap of the week before the one holding [today].
WeeklyRecap computeWeeklyRecap(List<HabitHistory> histories, {required CalendarDay today}) {
  final weekMonday = today.mondayOfWeek.addDays(-DateTime.daysPerWeek);
  final weekSunday = weekMonday.addDays(DateTime.daysPerWeek - 1);
  final previousWeekMonday = weekMonday.addDays(-DateTime.daysPerWeek);
  final weekHistories = histories.where((history) => _isActiveAtEndOfDay(history, weekSunday)).toList();

  int? bestStreakHabitId;
  StreakSummary? bestStreak;
  for (final history in weekHistories) {
    final streak = history.streakSummaryOn(weekSunday);
    if (streak.currentStreakLength > (bestStreak?.currentStreakLength ?? 0)) {
      bestStreakHabitId = history.habitId;
      bestStreak = streak;
    }
  }
  return WeeklyRecap(
    weekMonday: weekMonday,
    habitResults: [
      for (final history in weekHistories)
        HabitWeekResult(
          habitId: history.habitId,
          successDayCount: history.countSuccessDaysInWeekOf(weekMonday),
          expectedSuccessDayCount: history.expectedSuccessDaysInWeekOf(weekMonday),
        ),
    ],
    previousWeekSuccessDayCount: weekHistories.fold(
      0,
      (total, history) => total + history.countSuccessDaysInWeekOf(previousWeekMonday),
    ),
    bestStreakHabitId: bestStreakHabitId,
    bestStreak: bestStreak,
  );
}

bool _isActiveAtEndOfDay(HabitHistory history, CalendarDay day) {
  final archivedDay = history.archivedDay;
  return !history.startDay.isAfter(day) && (archivedDay == null || archivedDay.isAfter(day));
}
