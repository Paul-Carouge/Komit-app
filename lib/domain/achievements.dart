import 'dart:math' as math;

import '../core/calendar_day.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

/// Long-term goals across every habit. They are derived from the logs each time, never stored,
/// so an import, an edit or a cleared day always shows the truth.
enum Achievement {
  /// The first success day on any habit.
  firstStep,

  /// A habit reached a seven-day streak, or one successful week for a weekly target.
  firstWeek,

  /// A habit reached a thirty-day streak, or four successful weeks in a row.
  monthStreak,

  /// A habit reached a hundred-day streak.
  hundredDayStreak,

  /// A habit reached a full year of streak.
  yearStreak,

  /// Every daily or weekday habit scheduled on one day was a success that day.
  perfectDay,

  /// Every habit active for a whole week met its schedule that week.
  perfectWeek,

  /// One habit reached a hundred success days.
  hundredSuccessDays,

  /// Five hundred success days across all habits.
  fiveHundredTotalSuccessDays,

  /// A thousand success days across all habits.
  thousandTotalSuccessDays,

  /// Three different habits each have a success day.
  threeHabits,

  /// A habit got a success day again after missing a week of its scheduled days.
  comeback,

  /// The first log is at least a year old.
  oneYearVeteran,

  /// The first log is at least two years old.
  twoYearVeteran,
}

const int firstWeekStreakDayCount = DateTime.daysPerWeek;
const int monthStreakDayCount = 30;
const int hundredDayStreakDayCount = 100;
const int yearStreakDayCount = 365;
const int hundredSuccessDaysTarget = 100;
const int fiveHundredTotalSuccessDaysTarget = 500;
const int thousandTotalSuccessDaysTarget = 1000;
const int threeHabitsTarget = 3;

/// Scheduled days missed in a row before a new success counts as a comeback.
const int comebackMissedScheduledDayCount = DateTime.daysPerWeek;
const int oneYearVeteranDayCount = 365;
const int twoYearVeteranDayCount = 2 * 365;

/// Logs after [today] (imported from the original app) never unlock anything.
Set<Achievement> computeUnlockedAchievements(List<HabitHistory> histories, {required CalendarDay today}) {
  final pastHistories = [for (final history in histories) _withoutDaysAfter(history, today)];
  final bestStreakDayCount = pastHistories.map((history) => _bestStreakDayCount(history, today)).fold(0, math.max);
  final successDayCounts = [for (final history in pastHistories) _countSuccessDays(history)];
  final totalSuccessDayCount = successDayCounts.fold(0, (total, count) => total + count);
  final firstLogAgeInDays = _firstLogAgeInDays(pastHistories, today);
  return {
    if (totalSuccessDayCount > 0) Achievement.firstStep,
    if (bestStreakDayCount >= firstWeekStreakDayCount) Achievement.firstWeek,
    if (bestStreakDayCount >= monthStreakDayCount) Achievement.monthStreak,
    if (bestStreakDayCount >= hundredDayStreakDayCount) Achievement.hundredDayStreak,
    if (bestStreakDayCount >= yearStreakDayCount) Achievement.yearStreak,
    if (_hasPerfectDay(pastHistories)) Achievement.perfectDay,
    if (_hasPerfectWeek(pastHistories, today)) Achievement.perfectWeek,
    if (successDayCounts.any((count) => count >= hundredSuccessDaysTarget)) Achievement.hundredSuccessDays,
    if (totalSuccessDayCount >= fiveHundredTotalSuccessDaysTarget) Achievement.fiveHundredTotalSuccessDays,
    if (totalSuccessDayCount >= thousandTotalSuccessDaysTarget) Achievement.thousandTotalSuccessDays,
    if (successDayCounts.where((count) => count > 0).length >= threeHabitsTarget) Achievement.threeHabits,
    if (pastHistories.any(_hasComeback)) Achievement.comeback,
    if (firstLogAgeInDays >= oneYearVeteranDayCount) Achievement.oneYearVeteran,
    if (firstLogAgeInDays >= twoYearVeteranDayCount) Achievement.twoYearVeteran,
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

/// A weekly-target streak counts as seven days per successful week, so the same milestones
/// apply to every kind of schedule.
int _bestStreakDayCount(HabitHistory history, CalendarDay today) {
  final streaks = history.streakSummaryOn(today);
  return switch (streaks.unit) {
    StreakUnit.days => streaks.bestStreakLength,
    StreakUnit.weeks => streaks.bestStreakLength * DateTime.daysPerWeek,
  };
}

int _countSuccessDays(HabitHistory history) =>
    history.objectiveIdByDay.values.where(history.successObjectiveIds.contains).length;

/// Weekly-target habits have no fixed days, so a perfect day only asks the daily and weekday
/// habits that existed and were scheduled that day.
bool _hasPerfectDay(List<HabitHistory> histories) {
  final dailyHistories = histories.where((history) => history.targetDaysPerWeek == null).toList();
  final candidateDays = {for (final history in dailyHistories) ...history.objectiveIdByDay.keys};
  return candidateDays.any((day) {
    final scheduledHistories = dailyHistories.where(
      (history) =>
          !history.startDay.isAfter(day) &&
          (history.archivedDay == null || history.archivedDay!.isAfter(day)) &&
          history.isScheduledOn(day),
    );
    return scheduledHistories.isNotEmpty && scheduledHistories.every((history) => history.isSuccessOn(day));
  });
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

/// Zero without any log.
int _firstLogAgeInDays(List<HabitHistory> histories, CalendarDay today) {
  final loggedDays = histories.expand((history) => history.objectiveIdByDay.keys);
  if (loggedDays.isEmpty) return 0;
  final firstLoggedDay = loggedDays.reduce((earliest, day) => day.isAfter(earliest) ? earliest : day);
  return today.daysSinceEpoch - firstLoggedDay.daysSinceEpoch;
}
