import '../core/calendar_day.dart';

class StreakSummary {
  const StreakSummary({required this.currentStreakDays, required this.bestStreakDays});

  final int currentStreakDays;
  final int bestStreakDays;
}

/// A streak is a run of consecutive logged days. The current streak stays alive
/// until the end of today, so a habit not yet logged today keeps yesterday's streak.
StreakSummary computeStreakSummary(Iterable<CalendarDay> loggedDays, {required CalendarDay today}) {
  final sortedDays = loggedDays.map((day) => day.daysSinceEpoch).toSet().toList()..sort();
  var bestStreakDays = 0;
  var runLength = 0;
  int? previousDay;
  for (final day in sortedDays) {
    runLength = previousDay != null && day == previousDay + 1 ? runLength + 1 : 1;
    if (runLength > bestStreakDays) bestStreakDays = runLength;
    previousDay = day;
  }

  var currentStreakDays = 0;
  final loggedDaySet = sortedDays.toSet();
  var cursor = loggedDaySet.contains(today.daysSinceEpoch) ? today.daysSinceEpoch : today.daysSinceEpoch - 1;
  while (loggedDaySet.contains(cursor)) {
    currentStreakDays++;
    cursor--;
  }
  return StreakSummary(currentStreakDays: currentStreakDays, bestStreakDays: bestStreakDays);
}

class YearStatistics {
  const YearStatistics({required this.logCountByObjectiveId, required this.logCountByMonth});

  final Map<int, int> logCountByObjectiveId;

  /// Index 0 is January.
  final List<int> logCountByMonth;

  int get totalLogCount => logCountByMonth.fold(0, (total, count) => total + count);
}

YearStatistics computeYearStatistics(Map<CalendarDay, int> objectiveIdByDay, {required int year}) {
  final logCountByObjectiveId = <int, int>{};
  final logCountByMonth = List<int>.filled(DateTime.monthsPerYear, 0);
  for (final MapEntry(key: day, value: objectiveId) in objectiveIdByDay.entries) {
    final date = day.asUtcDate;
    if (date.year != year) continue;
    logCountByObjectiveId.update(objectiveId, (count) => count + 1, ifAbsent: () => 1);
    logCountByMonth[date.month - 1]++;
  }
  return YearStatistics(logCountByObjectiveId: logCountByObjectiveId, logCountByMonth: logCountByMonth);
}

/// True when each of [habitIds] has a log on [day]; vacuously true for no habit.
bool isEveryHabitLoggedOn(
  CalendarDay day, {
  required Iterable<int> habitIds,
  required Map<int, Map<CalendarDay, int>> objectiveIdByDayByHabitId,
}) => habitIds.every((habitId) => objectiveIdByDayByHabitId[habitId]?.containsKey(day) ?? false);
