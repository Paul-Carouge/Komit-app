import '../core/calendar_day.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

/// Long-term goals across every habit. They are derived from the logs each time, never stored,
/// so an import, an edit or a cleared day always shows the truth.
enum Achievement {
  /// A habit reached a seven-day streak, or one successful week for a weekly target.
  firstWeek,

  /// Every habit active for a whole week met its schedule that week.
  perfectWeek,

  /// One habit reached a hundred success days.
  hundredSuccessDays,

  /// A habit got a success day again after missing a week of its scheduled days.
  comeback,

  /// The first log is at least a year old.
  oneYearVeteran,
}

const int firstWeekStreakDayCount = DateTime.daysPerWeek;
const int hundredSuccessDaysTarget = 100;

/// Scheduled days missed in a row before a new success counts as a comeback.
const int comebackMissedScheduledDayCount = DateTime.daysPerWeek;
const int oneYearVeteranDayCount = 365;

/// Logs after [today] (imported from the original app) never unlock anything.
Set<Achievement> computeUnlockedAchievements(List<HabitHistory> histories, {required CalendarDay today}) {
  final pastHistories = [for (final history in histories) _withoutDaysAfter(history, today)];
  return {
    if (pastHistories.any((history) => _hasFirstWeek(history, today))) Achievement.firstWeek,
    if (_hasPerfectWeek(pastHistories, today)) Achievement.perfectWeek,
    if (pastHistories.any(_hasHundredSuccessDays)) Achievement.hundredSuccessDays,
    if (pastHistories.any(_hasComeback)) Achievement.comeback,
    if (_isOneYearVeteran(pastHistories, today)) Achievement.oneYearVeteran,
  };
}

HabitHistory _withoutDaysAfter(HabitHistory history, CalendarDay today) {
  if (!history.objectiveIdByDay.keys.any((day) => day.isAfter(today))) return history;
  return HabitHistory(
    habitId: history.habitId,
    objectiveIdByDay: {
      for (final MapEntry(key: day, value: objectiveId) in history.objectiveIdByDay.entries)
        if (!day.isAfter(today)) day: objectiveId,
    },
    successObjectiveIds: history.successObjectiveIds,
    startDay: history.startDay,
    scheduledWeekdayMask: history.scheduledWeekdayMask,
    targetDaysPerWeek: history.targetDaysPerWeek,
    archivedDay: history.archivedDay,
  );
}

bool _hasFirstWeek(HabitHistory history, CalendarDay today) {
  final streaks = history.streakSummaryOn(today);
  return switch (streaks.unit) {
    StreakUnit.days => streaks.bestStreakLength >= firstWeekStreakDayCount,
    StreakUnit.weeks => streaks.bestStreakLength >= 1,
  };
}

/// Only weeks that started by [today] are checked; the current week counts once every day
/// it still asks for is done, so a weekly target can be perfect before Sunday.
bool _hasPerfectWeek(List<HabitHistory> histories, CalendarDay today) {
  if (histories.isEmpty) return false;
  final firstMonday = histories
      .map((history) => history.startDay)
      .reduce((earliest, day) => day.isAfter(earliest) ? earliest : day)
      .mondayOfWeek;
  for (var monday = firstMonday; !monday.isAfter(today); monday = monday.addDays(DateTime.daysPerWeek)) {
    final weekHistories = histories.where((history) => history.isActiveForWholeWeekOf(monday)).toList();
    final hasSomethingToDo = weekHistories.any((history) => history.expectedSuccessDaysInWeekOf(monday) > 0);
    if (hasSomethingToDo && weekHistories.every((history) => _isWeekMet(history, monday))) return true;
  }
  return false;
}

bool _isWeekMet(HabitHistory history, CalendarDay monday) {
  if (history.targetDaysPerWeek case final targetDaysPerWeek?) {
    return history.countSuccessDaysInWeekOf(monday) >= targetDaysPerWeek;
  }
  for (var offset = 0; offset < DateTime.daysPerWeek; offset++) {
    final day = monday.addDays(offset);
    if (history.isScheduledOn(day) && !history.isSuccessOn(day)) return false;
  }
  return true;
}

bool _hasHundredSuccessDays(HabitHistory history) =>
    history.objectiveIdByDay.values.where(history.successObjectiveIds.contains).length >= hundredSuccessDaysTarget;

/// A missed day is a scheduled day without any log, between two logged days.
bool _hasComeback(HabitHistory history) {
  final loggedDays = history.objectiveIdByDay.keys.toList()
    ..sort((first, second) => first.daysSinceEpoch.compareTo(second.daysSinceEpoch));
  for (var index = 1; index < loggedDays.length; index++) {
    final day = loggedDays[index];
    if (!history.isSuccessOn(day)) continue;
    var missedScheduledDayCount = 0;
    for (var missedDay = loggedDays[index - 1].addDays(1); day.isAfter(missedDay); missedDay = missedDay.addDays(1)) {
      if (history.isScheduledOn(missedDay)) missedScheduledDayCount++;
    }
    if (missedScheduledDayCount >= comebackMissedScheduledDayCount) return true;
  }
  return false;
}

bool _isOneYearVeteran(List<HabitHistory> histories, CalendarDay today) {
  final loggedDays = histories.expand((history) => history.objectiveIdByDay.keys);
  if (loggedDays.isEmpty) return false;
  final firstLoggedDay = loggedDays.reduce((earliest, day) => day.isAfter(earliest) ? earliest : day);
  return today.daysSinceEpoch - firstLoggedDay.daysSinceEpoch >= oneYearVeteranDayCount;
}
