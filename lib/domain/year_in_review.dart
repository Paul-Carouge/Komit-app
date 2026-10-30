import '../core/calendar_day.dart';
import 'achievements.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

/// The review opens on December 1 and stays until January 15, about the year that just ended.
const int _lastJanuaryDayShowingPreviousYear = 15;

/// Below this many success days, the review tells a short, kind story instead of near-empty numbers.
const int minimumSuccessDaysForFullYearInReview = 7;

/// The year the review is about on [today], or null outside December 1 to January 15.
int? yearInReviewYearOn(CalendarDay today) {
  final date = today.asUtcDate;
  if (date.month == DateTime.december) return date.year;
  if (date.month == DateTime.january && date.day <= _lastJanuaryDayShowingPreviousYear) return date.year - 1;
  return null;
}

class YearStreak {
  const YearStreak({required this.habitId, required this.length, required this.unit});

  final int habitId;
  final int length;
  final StreakUnit unit;
}

class HabitYearSuccess {
  const HabitYearSuccess({required this.habitId, required this.successDayCount});

  final int habitId;
  final int successDayCount;
}

/// A year of habits, from January 1 to the end of the year or [YearInReview.lastDay] if earlier.
class YearInReview {
  const YearInReview({
    required this.year,
    required this.lastDay,
    required this.successDayCount,
    required this.longestStreak,
    required this.mostRegularWeekday,
    required this.bestMonth,
    required this.mostKeptHabit,
    required this.achievementsUnlocked,
  });

  final int year;

  /// December 31, or today while December is not over.
  final CalendarDay lastDay;

  /// Calendar days with at least one success, whatever the number of habits that day.
  final int successDayCount;

  /// The longest streak run inside the year; weeks for a weekly target. Null without any success.
  final YearStreak? longestStreak;

  /// [DateTime.monday]..[DateTime.sunday] with the highest share of successful days, the earliest on
  /// a tie; null without any success.
  final int? mostRegularWeekday;

  /// 1 (January) to 12 with the highest share of successful days, the earliest on a tie; null
  /// without any success.
  final int? bestMonth;

  /// The habit with the most success days in the year; null without any success.
  final HabitYearSuccess? mostKeptHabit;

  /// Unlocked during the year, in display order.
  final List<Achievement> achievementsUnlocked;

  bool get isQuietYear => successDayCount < minimumSuccessDaysForFullYearInReview;
}

YearInReview computeYearInReview(List<HabitHistory> histories, {required int year, required CalendarDay today}) {
  final firstDay = CalendarDay.fromDate(year, DateTime.january, 1);
  final yearLastDay = CalendarDay.fromDate(year, DateTime.december, 31);
  final lastDay = today.isAfter(yearLastDay) ? yearLastDay : today;
  bool isInYear(CalendarDay day) => !firstDay.isAfter(day) && !day.isAfter(lastDay);
  // A weekly target counts whole ISO weeks: the weeks around January 1 and the last day keep
  // their days from the next or previous year, or they could never be met.
  final weeklyFirstDay = firstDay.mondayOfWeek;
  final lastDayWeekSunday = lastDay.mondayOfWeek.addDays(DateTime.daysPerWeek - 1);
  final weeklyLastDay = lastDayWeekSunday.isAfter(today) ? today : lastDayWeekSunday;
  bool isInWeeklyRange(CalendarDay day) => !weeklyFirstDay.isAfter(day) && !day.isAfter(weeklyLastDay);

  final successDays = <CalendarDay>{};
  final successCountByWeekday = List<int>.filled(DateTime.daysPerWeek, 0);
  final successCountByMonth = List<int>.filled(DateTime.monthsPerYear, 0);
  YearStreak? longestStreak;
  HabitYearSuccess? mostKeptHabit;
  for (final history in histories) {
    final yearObjectiveIdByDay = {
      for (final MapEntry(key: day, value: objectiveId) in history.objectiveIdByDay.entries)
        if (isInYear(day)) day: objectiveId,
    };
    var habitSuccessDayCount = 0;
    for (final day in yearObjectiveIdByDay.keys.where(history.isSuccessOn)) {
      habitSuccessDayCount++;
      successDays.add(day);
      successCountByWeekday[day.weekday - DateTime.monday]++;
      successCountByMonth[day.asUtcDate.month - 1]++;
    }
    if (habitSuccessDayCount > (mostKeptHabit?.successDayCount ?? 0)) {
      mostKeptHabit = HabitYearSuccess(habitId: history.habitId, successDayCount: habitSuccessDayCount);
    }
    final streakObjectiveIdByDay = history.targetDaysPerWeek == null
        ? yearObjectiveIdByDay
        : {
            for (final MapEntry(key: day, value: objectiveId) in history.objectiveIdByDay.entries)
              if (isInWeeklyRange(day)) day: objectiveId,
          };
    final streak = computeScheduledStreakSummary(
      streakObjectiveIdByDay,
      successObjectiveIds: history.successObjectiveIds,
      scheduledWeekdayMask: history.scheduledWeekdayMask,
      targetDaysPerWeek: history.targetDaysPerWeek,
      today: history.targetDaysPerWeek == null ? lastDay : weeklyLastDay,
    );
    if (streak.bestStreakLength > 0 && _lengthInDays(streak) > _yearStreakLengthInDays(longestStreak)) {
      longestStreak = YearStreak(habitId: history.habitId, length: streak.bestStreakLength, unit: streak.unit);
    }
  }

  // Rates, not raw counts: a 31-day month or a weekday that occurs 53 times must not win just
  // for being longer, and December in progress is not penalised for being partial.
  final dayCountByWeekday = List<int>.filled(DateTime.daysPerWeek, 0);
  final dayCountByMonth = List<int>.filled(DateTime.monthsPerYear, 0);
  for (var day = firstDay; !day.isAfter(lastDay); day = day.addDays(1)) {
    dayCountByWeekday[day.weekday - DateTime.monday]++;
    dayCountByMonth[day.asUtcDate.month - 1]++;
  }
  final mostRegularWeekdayIndex = _indexOfHighestPositiveRate(successCountByWeekday, dayCountByWeekday);
  final bestMonthIndex = _indexOfHighestPositiveRate(successCountByMonth, dayCountByMonth);
  final unlockedBeforeYear = computeUnlockedAchievements(histories, today: firstDay.addDays(-1));
  final unlockedByLastDay = computeUnlockedAchievements(histories, today: lastDay);
  return YearInReview(
    year: year,
    lastDay: lastDay,
    successDayCount: successDays.length,
    longestStreak: longestStreak,
    mostRegularWeekday: mostRegularWeekdayIndex == null ? null : mostRegularWeekdayIndex + DateTime.monday,
    bestMonth: bestMonthIndex == null ? null : bestMonthIndex + 1,
    mostKeptHabit: mostKeptHabit,
    achievementsUnlocked: [
      for (final achievement in Achievement.values)
        if (unlockedByLastDay.contains(achievement) && !unlockedBeforeYear.contains(achievement)) achievement,
    ],
  );
}

/// A week of a weekly target weighs seven days, so a daily streak and a weekly one compare fairly.
int _lengthInDays(StreakSummary streak) =>
    streak.unit == StreakUnit.weeks ? streak.bestStreakLength * DateTime.daysPerWeek : streak.bestStreakLength;

int _yearStreakLengthInDays(YearStreak? streak) => switch (streak) {
  null => 0,
  YearStreak(unit: StreakUnit.weeks) => streak.length * DateTime.daysPerWeek,
  _ => streak.length,
};

/// The first index with the highest `successCounts[i] / dayCounts[i]`, or null when no index has
/// a success. Compared by cross-multiplication, so equal rates tie exactly and the earliest wins.
int? _indexOfHighestPositiveRate(List<int> successCounts, List<int> dayCounts) {
  int? bestIndex;
  for (var index = 0; index < successCounts.length; index++) {
    if (successCounts[index] == 0) continue;
    if (bestIndex == null ||
        successCounts[index] * dayCounts[bestIndex] > successCounts[bestIndex] * dayCounts[index]) {
      bestIndex = index;
    }
  }
  return bestIndex;
}
