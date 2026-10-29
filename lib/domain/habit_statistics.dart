import '../core/calendar_day.dart';
import 'habit_schedule.dart';

enum StreakUnit { days, weeks }

class StreakSummary {
  const StreakSummary({required this.currentStreakLength, required this.bestStreakLength, this.unit = StreakUnit.days});

  final int currentStreakLength;
  final int bestStreakLength;
  final StreakUnit unit;

  // Value equality lets a dashboard row skip its rebuild when another habit's log recomputes it.
  @override
  bool operator ==(Object other) =>
      other is StreakSummary &&
      other.currentStreakLength == currentStreakLength &&
      other.bestStreakLength == bestStreakLength &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(currentStreakLength, bestStreakLength, unit);
}

/// Streak lengths worth celebrating; 1 celebrates the very first success.
const List<int> streakMilestoneDays = [1, 3, 7, 14, 21, 30, 50, 100, 200, 365, 500, 1000];

/// The largest milestone crossed when a streak goes from [previousStreakLength] to
/// [nextStreakLength], or null when none is crossed (including when the streak shrinks).
int? milestoneReachedBetween(int previousStreakLength, int nextStreakLength) {
  int? reachedMilestone;
  for (final milestone in streakMilestoneDays) {
    if (milestone > previousStreakLength && milestone <= nextStreakLength) reachedMilestone = milestone;
  }
  return reachedMilestone;
}

/// The days whose log points to one of [successObjectiveIds].
Set<int> _successDaysSinceEpoch(Map<CalendarDay, int> objectiveIdByDay, Set<int> successObjectiveIds) => {
  for (final MapEntry(key: day, value: objectiveId) in objectiveIdByDay.entries)
    if (successObjectiveIds.contains(objectiveId)) day.daysSinceEpoch,
};

/// A streak is a run of consecutive success days. The current streak stays alive
/// until the end of today, so a habit not yet logged today keeps yesterday's streak.
/// A day logged with an objective outside [successObjectiveIds] breaks it like a missed day.
StreakSummary computeStreakSummary(
  Map<CalendarDay, int> objectiveIdByDay, {
  required Set<int> successObjectiveIds,
  required CalendarDay today,
}) {
  final successDays = _successDaysSinceEpoch(objectiveIdByDay, successObjectiveIds);
  final sortedDays = successDays.toList()..sort();
  var bestStreakLength = 0;
  var runLength = 0;
  int? previousDay;
  for (final day in sortedDays) {
    runLength = previousDay != null && day == previousDay + 1 ? runLength + 1 : 1;
    if (runLength > bestStreakLength) bestStreakLength = runLength;
    previousDay = day;
  }

  var currentStreakLength = 0;
  var cursor = successDays.contains(today.daysSinceEpoch) ? today.daysSinceEpoch : today.daysSinceEpoch - 1;
  while (successDays.contains(cursor)) {
    currentStreakLength++;
    cursor--;
  }
  return StreakSummary(currentStreakLength: currentStreakLength, bestStreakLength: bestStreakLength);
}

/// Like [computeStreakSummary], following the habit's schedule:
/// - with [targetDaysPerWeek], the streak counts consecutive ISO weeks (Monday first) with at
///   least that many success days; the current week keeps the streak alive until it ends;
/// - otherwise days off [scheduledWeekdayMask] neither count nor break the streak.
StreakSummary computeScheduledStreakSummary(
  Map<CalendarDay, int> objectiveIdByDay, {
  required Set<int> successObjectiveIds,
  required int scheduledWeekdayMask,
  required int? targetDaysPerWeek,
  required CalendarDay today,
}) {
  if (targetDaysPerWeek != null) {
    return _computeWeeklyTargetStreakSummary(
      _successDaysSinceEpoch(objectiveIdByDay, successObjectiveIds),
      targetDaysPerWeek: targetDaysPerWeek,
      today: today,
    );
  }
  if (scheduledWeekdayMask == everyWeekdayMask) {
    return computeStreakSummary(objectiveIdByDay, successObjectiveIds: successObjectiveIds, today: today);
  }
  assert(scheduledWeekdayMask & everyWeekdayMask != 0, 'A habit is scheduled on at least one weekday');
  final successDays = _successDaysSinceEpoch(objectiveIdByDay, successObjectiveIds);
  if (successDays.isEmpty) return const StreakSummary(currentStreakLength: 0, bestStreakLength: 0);
  bool isScheduled(int daySinceEpoch) => isWeekdayScheduled(scheduledWeekdayMask, _weekdayOf(daySinceEpoch));

  final firstSuccessDay = successDays.reduce((earliest, day) => day < earliest ? day : earliest);
  var bestStreakLength = 0;
  var runLength = 0;
  for (var day = firstSuccessDay; day <= today.daysSinceEpoch; day++) {
    if (!isScheduled(day)) continue;
    if (successDays.contains(day)) {
      runLength++;
      if (runLength > bestStreakLength) bestStreakLength = runLength;
    } else if (day != today.daysSinceEpoch) {
      runLength = 0;
    }
  }
  // The loop ends on today, where a missing log does not break the run yet.
  return StreakSummary(currentStreakLength: runLength, bestStreakLength: bestStreakLength);
}

/// ISO weeks start on Monday; day 0 (1970-01-01) is a Thursday, three days after one.
const int _daysFromMondayToEpoch = 3;

/// [DateTime.monday]..[DateTime.sunday], without allocating a DateTime in the day loops.
int _weekdayOf(int daySinceEpoch) => (daySinceEpoch + _daysFromMondayToEpoch) % DateTime.daysPerWeek + 1;

int _isoWeekIndex(int daySinceEpoch) {
  final daysSinceFirstMonday = daySinceEpoch + _daysFromMondayToEpoch;
  // Floor division, also correct before 1970.
  return (daysSinceFirstMonday - daysSinceFirstMonday % DateTime.daysPerWeek) ~/ DateTime.daysPerWeek;
}

StreakSummary _computeWeeklyTargetStreakSummary(
  Set<int> successDays, {
  required int targetDaysPerWeek,
  required CalendarDay today,
}) {
  final successCountByWeekIndex = <int, int>{};
  for (final day in successDays) {
    if (day > today.daysSinceEpoch) continue;
    successCountByWeekIndex.update(_isoWeekIndex(day), (count) => count + 1, ifAbsent: () => 1);
  }
  final successfulWeekIndexes = {
    for (final MapEntry(key: weekIndex, value: count) in successCountByWeekIndex.entries)
      if (count >= targetDaysPerWeek) weekIndex,
  };

  final sortedWeekIndexes = successfulWeekIndexes.toList()..sort();
  var bestStreakLength = 0;
  var runLength = 0;
  int? previousWeekIndex;
  for (final weekIndex in sortedWeekIndexes) {
    runLength = previousWeekIndex != null && weekIndex == previousWeekIndex + 1 ? runLength + 1 : 1;
    if (runLength > bestStreakLength) bestStreakLength = runLength;
    previousWeekIndex = weekIndex;
  }

  final currentWeekIndex = _isoWeekIndex(today.daysSinceEpoch);
  var currentStreakLength = 0;
  var cursor = successfulWeekIndexes.contains(currentWeekIndex) ? currentWeekIndex : currentWeekIndex - 1;
  while (successfulWeekIndexes.contains(cursor)) {
    currentStreakLength++;
    cursor--;
  }
  return StreakSummary(
    currentStreakLength: currentStreakLength,
    bestStreakLength: bestStreakLength,
    unit: StreakUnit.weeks,
  );
}

/// Success days in the ISO week (Monday to Sunday) holding [day], for a weekly target.
int countSuccessDaysInWeekOf(
  Map<CalendarDay, int> objectiveIdByDay, {
  required Set<int> successObjectiveIds,
  required CalendarDay day,
}) {
  final weekIndex = _isoWeekIndex(day.daysSinceEpoch);
  return _successDaysSinceEpoch(
    objectiveIdByDay,
    successObjectiveIds,
  ).where((successDay) => _isoWeekIndex(successDay) == weekIndex).length;
}

/// Share of the scheduled days from [firstDay] to [today] included that are success days;
/// null when that range holds no scheduled day.
double? computeSuccessRate(
  Map<CalendarDay, int> objectiveIdByDay, {
  required Set<int> successObjectiveIds,
  required int scheduledWeekdayMask,
  required CalendarDay firstDay,
  required CalendarDay today,
}) {
  final successDays = _successDaysSinceEpoch(objectiveIdByDay, successObjectiveIds);
  var scheduledDayCount = 0;
  var successDayCount = 0;
  for (var day = firstDay.daysSinceEpoch; day <= today.daysSinceEpoch; day++) {
    if (!isWeekdayScheduled(scheduledWeekdayMask, _weekdayOf(day))) continue;
    scheduledDayCount++;
    if (successDays.contains(day)) successDayCount++;
  }
  return scheduledDayCount == 0 ? null : successDayCount / scheduledDayCount;
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
