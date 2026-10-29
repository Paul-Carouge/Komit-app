import 'dart:math' as math;

import '../core/calendar_day.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

/// Long-term goals across every habit. They are derived from the logs each time, never stored,
/// so an import, an edit or a cleared day always shows the truth. The order is the display order.
enum Achievement {
  /// The first success day on any habit.
  firstStep,

  /// The first log is at least thirty days old.
  firstMonthWithKomit,

  /// A habit reached a seven-day streak, or one successful week for a weekly target.
  firstWeek,

  /// A habit reached a fourteen-day streak.
  twoWeekStreak,

  /// A habit reached a thirty-day streak, or four successful weeks in a row.
  monthStreak,

  /// A habit reached a hundred-day streak.
  hundredDayStreak,

  /// A habit reached a two-hundred-day streak.
  twoHundredDayStreak,

  /// A habit reached a full year of streak.
  yearStreak,

  /// Every daily or weekday habit scheduled on one day was a success that day.
  perfectDay,

  /// Ten perfect days, in a row or not.
  tenPerfectDays,

  /// Fifty perfect days, in a row or not.
  fiftyPerfectDays,

  /// Every habit active for a whole week met its schedule that week.
  perfectWeek,

  /// A daily or weekday habit succeeded on every scheduled day of a calendar month.
  perfectMonth,

  /// A hundred success days across all habits.
  hundredTotalSuccessDays,

  /// One habit reached a hundred success days.
  hundredSuccessDays,

  /// One habit reached three hundred sixty-five success days.
  yearOfSuccessDays,

  /// Five hundred success days across all habits.
  fiveHundredTotalSuccessDays,

  /// A thousand success days across all habits.
  thousandTotalSuccessDays,

  /// Two thousand five hundred success days across all habits.
  twoThousandFiveHundredTotalSuccessDays,

  /// Three different habits each have a success day.
  threeHabits,

  /// Five different habits each have a success day.
  fiveHabits,

  /// One habit has success days on three different objectives.
  threeObjectivesOnOneHabit,

  /// One habit succeeded on a Saturday and the Sunday after it.
  weekendWarrior,

  /// A success day on the first of January.
  newYearsDay,

  /// A success day on Christmas Day.
  christmasDay,

  /// A success day on the twenty-ninth of February.
  leapDay,

  /// A habit got a success day again after missing a week of its scheduled days.
  comeback,

  /// A habit got a success day again after missing a month of its scheduled days.
  phoenix,

  /// The first log is at least a year old.
  oneYearVeteran,

  /// The first log is at least two years old.
  twoYearVeteran,
}

const int firstWeekStreakDayCount = DateTime.daysPerWeek;
const int twoWeekStreakDayCount = 2 * DateTime.daysPerWeek;
const int monthStreakDayCount = 30;
const int hundredDayStreakDayCount = 100;
const int twoHundredDayStreakDayCount = 200;
const int yearStreakDayCount = 365;
const int tenPerfectDaysTarget = 10;
const int fiftyPerfectDaysTarget = 50;
const int hundredTotalSuccessDaysTarget = 100;
const int hundredSuccessDaysTarget = 100;
const int yearOfSuccessDaysTarget = 365;
const int fiveHundredTotalSuccessDaysTarget = 500;
const int thousandTotalSuccessDaysTarget = 1000;
const int twoThousandFiveHundredTotalSuccessDaysTarget = 2500;
const int threeHabitsTarget = 3;
const int fiveHabitsTarget = 5;
const int threeObjectivesOnOneHabitTarget = 3;

/// Scheduled days missed in a row before a new success counts as a comeback.
const int comebackMissedScheduledDayCount = DateTime.daysPerWeek;
const int phoenixMissedScheduledDayCount = 30;
const int firstMonthWithKomitDayCount = 30;
const int oneYearVeteranDayCount = 365;
const int twoYearVeteranDayCount = 2 * 365;

/// Logs after [today] (imported from the original app) never unlock anything.
Set<Achievement> computeUnlockedAchievements(List<HabitHistory> histories, {required CalendarDay today}) {
  final pastHistories = [for (final history in histories) _withoutDaysAfter(history, today)];
  final bestStreakDayCount = pastHistories.map((history) => _bestStreakDayCount(history, today)).fold(0, math.max);
  final successDayCounts = [for (final history in pastHistories) _countSuccessDays(history)];
  final bestSuccessDayCount = successDayCounts.fold(0, math.max);
  final totalSuccessDayCount = successDayCounts.fold(0, (total, count) => total + count);
  final habitWithSuccessCount = successDayCounts.where((count) => count > 0).length;
  final perfectDayCount = _countPerfectDays(pastHistories);
  final successDays = {
    for (final history in pastHistories) ...history.objectiveIdByDay.keys.where(history.isSuccessOn),
  };
  final firstLogAgeInDays = _firstLogAgeInDays(pastHistories, today);
  return {
    if (totalSuccessDayCount > 0) Achievement.firstStep,
    if (firstLogAgeInDays >= firstMonthWithKomitDayCount) Achievement.firstMonthWithKomit,
    if (bestStreakDayCount >= firstWeekStreakDayCount) Achievement.firstWeek,
    if (bestStreakDayCount >= twoWeekStreakDayCount) Achievement.twoWeekStreak,
    if (bestStreakDayCount >= monthStreakDayCount) Achievement.monthStreak,
    if (bestStreakDayCount >= hundredDayStreakDayCount) Achievement.hundredDayStreak,
    if (bestStreakDayCount >= twoHundredDayStreakDayCount) Achievement.twoHundredDayStreak,
    if (bestStreakDayCount >= yearStreakDayCount) Achievement.yearStreak,
    if (perfectDayCount > 0) Achievement.perfectDay,
    if (perfectDayCount >= tenPerfectDaysTarget) Achievement.tenPerfectDays,
    if (perfectDayCount >= fiftyPerfectDaysTarget) Achievement.fiftyPerfectDays,
    if (_hasPerfectWeek(pastHistories, today)) Achievement.perfectWeek,
    if (pastHistories.any((history) => _hasPerfectMonth(history, today))) Achievement.perfectMonth,
    if (totalSuccessDayCount >= hundredTotalSuccessDaysTarget) Achievement.hundredTotalSuccessDays,
    if (bestSuccessDayCount >= hundredSuccessDaysTarget) Achievement.hundredSuccessDays,
    if (bestSuccessDayCount >= yearOfSuccessDaysTarget) Achievement.yearOfSuccessDays,
    if (totalSuccessDayCount >= fiveHundredTotalSuccessDaysTarget) Achievement.fiveHundredTotalSuccessDays,
    if (totalSuccessDayCount >= thousandTotalSuccessDaysTarget) Achievement.thousandTotalSuccessDays,
    if (totalSuccessDayCount >= twoThousandFiveHundredTotalSuccessDaysTarget)
      Achievement.twoThousandFiveHundredTotalSuccessDays,
    if (habitWithSuccessCount >= threeHabitsTarget) Achievement.threeHabits,
    if (habitWithSuccessCount >= fiveHabitsTarget) Achievement.fiveHabits,
    if (pastHistories.any(_hasThreeSuccessObjectivesLogged)) Achievement.threeObjectivesOnOneHabit,
    if (pastHistories.any(_hasSuccessfulWeekend)) Achievement.weekendWarrior,
    if (successDays.any((day) => _isOn(day, DateTime.january, 1))) Achievement.newYearsDay,
    if (successDays.any((day) => _isOn(day, DateTime.december, 25))) Achievement.christmasDay,
    if (successDays.any((day) => _isOn(day, DateTime.february, 29))) Achievement.leapDay,
    if (pastHistories.any((history) => _hasComebackAfter(history, comebackMissedScheduledDayCount)))
      Achievement.comeback,
    if (pastHistories.any((history) => _hasComebackAfter(history, phoenixMissedScheduledDayCount))) Achievement.phoenix,
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
int _countPerfectDays(List<HabitHistory> histories) {
  final dailyHistories = histories.where((history) => history.targetDaysPerWeek == null).toList();
  final candidateDays = {for (final history in dailyHistories) ...history.objectiveIdByDay.keys};
  return candidateDays.where((day) {
    final scheduledHistories = dailyHistories.where(
      (history) => _isActiveOn(history, day) && history.isScheduledOn(day),
    );
    return scheduledHistories.isNotEmpty && scheduledHistories.every((history) => history.isSuccessOn(day));
  }).length;
}

bool _isActiveOn(HabitHistory history, CalendarDay day) {
  final archivedDay = history.archivedDay;
  return !history.startDay.isAfter(day) && (archivedDay == null || archivedDay.isAfter(day));
}

/// Only months that ended by [today], during which the habit existed from the first day to the
/// last, and that asked for at least one day.
bool _hasPerfectMonth(HabitHistory history, CalendarDay today) {
  if (history.targetDaysPerWeek != null) return false;
  final startDate = history.startDay.asUtcDate;
  for (var month = DateTime.utc(startDate.year, startDate.month); ; month = DateTime.utc(month.year, month.month + 1)) {
    final firstDay = CalendarDay.fromDate(month.year, month.month, 1);
    final lastDay = CalendarDay.fromDate(month.year, month.month + 1, 1).addDays(-1);
    if (lastDay.isAfter(today)) return false;
    if (!_isActiveOn(history, firstDay) || !_isActiveOn(history, lastDay)) continue;
    var hasScheduledDay = false;
    var isEveryScheduledDayASuccess = true;
    for (var day = firstDay; !day.isAfter(lastDay) && isEveryScheduledDayASuccess; day = day.addDays(1)) {
      if (!history.isScheduledOn(day)) continue;
      hasScheduledDay = true;
      isEveryScheduledDayASuccess = history.isSuccessOn(day);
    }
    if (hasScheduledDay && isEveryScheduledDayASuccess) return true;
  }
}

bool _hasThreeSuccessObjectivesLogged(HabitHistory history) =>
    history.objectiveIdByDay.values.where(history.successObjectiveIds.contains).toSet().length >=
    threeObjectivesOnOneHabitTarget;

bool _hasSuccessfulWeekend(HabitHistory history) => history.objectiveIdByDay.keys.any(
  (day) => day.weekday == DateTime.saturday && history.isSuccessOn(day) && history.isSuccessOn(day.addDays(1)),
);

bool _isOn(CalendarDay day, int month, int dayOfMonth) {
  final date = day.asUtcDate;
  return date.month == month && date.day == dayOfMonth;
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
bool _hasComebackAfter(HabitHistory history, int missedScheduledDayThreshold) {
  final loggedDays = history.objectiveIdByDay.keys.toList()
    ..sort((first, second) => first.daysSinceEpoch.compareTo(second.daysSinceEpoch));
  for (var index = 1; index < loggedDays.length; index++) {
    final day = loggedDays[index];
    if (!history.isSuccessOn(day)) continue;
    var missedScheduledDayCount = 0;
    for (var missedDay = loggedDays[index - 1].addDays(1); day.isAfter(missedDay); missedDay = missedDay.addDays(1)) {
      if (history.isScheduledOn(missedDay)) missedScheduledDayCount++;
    }
    if (missedScheduledDayCount >= missedScheduledDayThreshold) return true;
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
