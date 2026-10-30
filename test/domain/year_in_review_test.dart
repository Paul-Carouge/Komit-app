import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/achievements.dart';
import 'package:komit/domain/habit_history.dart';
import 'package:komit/domain/habit_statistics.dart';
import 'package:komit/domain/year_in_review.dart';

const int _success = 1;
const int _skipped = 2;

/// Mid-December: the review covers January 1 to today.
final CalendarDay _december15 = CalendarDay.fromDate(2026, 12, 15);

HabitHistory _history(
  int habitId,
  Iterable<CalendarDay> successDays, {
  int? targetDaysPerWeek,
  Map<CalendarDay, int> otherLogs = const {},
}) => HabitHistory(
  habitId: habitId,
  objectiveIdByDay: {for (final day in successDays) day: _success, ...otherLogs},
  successObjectiveIds: const {_success},
  startDay: CalendarDay.fromDate(2025, 1, 1),
  targetDaysPerWeek: targetDaysPerWeek,
);

Iterable<CalendarDay> _days(CalendarDay first, int count) => [for (var i = 0; i < count; i++) first.addDays(i)];

void main() {
  group('yearInReviewYearOn', () {
    test('shows the current year in December and the previous one until January 15', () {
      expect(yearInReviewYearOn(CalendarDay.fromDate(2026, 11, 30)), isNull);
      expect(yearInReviewYearOn(CalendarDay.fromDate(2026, 12, 1)), 2026);
      expect(yearInReviewYearOn(CalendarDay.fromDate(2026, 12, 31)), 2026);
      expect(yearInReviewYearOn(CalendarDay.fromDate(2027, 1, 1)), 2026);
      expect(yearInReviewYearOn(CalendarDay.fromDate(2027, 1, 15)), 2026);
      expect(yearInReviewYearOn(CalendarDay.fromDate(2027, 1, 16)), isNull);
    });
  });

  test('an empty year is quiet and has nothing to point at', () {
    final review = computeYearInReview(const [], year: 2026, today: _december15);

    expect(review.successDayCount, 0);
    expect(review.isQuietYear, isTrue);
    expect(review.longestStreak, isNull);
    expect(review.mostRegularWeekday, isNull);
    expect(review.bestMonth, isNull);
    expect(review.mostKeptHabit, isNull);
    expect(review.achievementsUnlocked, isEmpty);
    expect(review.lastDay, _december15);
  });

  test('counts each calendar day once, and only days of the year up to today', () {
    final march2 = CalendarDay.fromDate(2026, 3, 2);
    final review = computeYearInReview(
      [
        _history(1, [..._days(march2, 10), CalendarDay.fromDate(2025, 12, 31), CalendarDay.fromDate(2026, 12, 20)]),
        _history(2, _days(march2, 4), otherLogs: {march2.addDays(5): _skipped}),
      ],
      year: 2026,
      today: _december15,
    );

    expect(review.successDayCount, 10);
    expect(review.isQuietYear, isFalse);
    expect(review.mostKeptHabit?.habitId, 1);
    expect(review.mostKeptHabit?.successDayCount, 10);
    expect(review.bestMonth, DateTime.march);
  });

  test('January looks back at the whole previous year', () {
    final review = computeYearInReview(
      [
        _history(1, [CalendarDay.fromDate(2026, 12, 31), CalendarDay.fromDate(2027, 1, 2)]),
      ],
      year: 2026,
      today: CalendarDay.fromDate(2027, 1, 10),
    );

    expect(review.lastDay, CalendarDay.fromDate(2026, 12, 31));
    expect(review.successDayCount, 1);
  });

  test('the longest streak stays inside the year and weighs weeks as seven days', () {
    final review = computeYearInReview(
      [
        // 12 days in a row, the first 5 of them in the previous year.
        _history(1, _days(CalendarDay.fromDate(2025, 12, 27), 12)),
        // 9 days in a row in June.
        _history(2, _days(CalendarDay.fromDate(2026, 6, 1), 9)),
      ],
      year: 2026,
      today: _december15,
    );

    expect(review.longestStreak?.habitId, 2);
    expect(review.longestStreak?.length, 9);
    expect(review.longestStreak?.unit, StreakUnit.days);

    // Two successful weeks (once a week) outweigh nine days.
    final withWeeklyHabit = computeYearInReview(
      [
        _history(2, _days(CalendarDay.fromDate(2026, 6, 1), 9)),
        _history(3, [CalendarDay.fromDate(2026, 9, 7), CalendarDay.fromDate(2026, 9, 14)], targetDaysPerWeek: 1),
      ],
      year: 2026,
      today: _december15,
    );
    expect(withWeeklyHabit.longestStreak?.habitId, 3);
    expect(withWeeklyHabit.longestStreak?.length, 2);
    expect(withWeeklyHabit.longestStreak?.unit, StreakUnit.weeks);
  });

  test('the most regular weekday has the highest share of successes, the earliest one on a tie', () {
    final monday = CalendarDay.fromDate(2026, 2, 2);
    final successDays = [monday, monday.addDays(2), monday.addDays(7 + 2), monday.addDays(14)];

    // Over the whole year 2026 has 52 Mondays and 52 Wednesdays: two of each tie, Monday first.
    final wholeYear = computeYearInReview(
      [_history(1, successDays)],
      year: 2026,
      today: CalendarDay.fromDate(2027, 1, 5),
    );
    expect(wholeYear.mostRegularWeekday, DateTime.monday);

    // By Tuesday December 15 there were 50 Mondays but 49 Wednesdays: Wednesday's share is higher.
    final midDecember = computeYearInReview([_history(1, successDays)], year: 2026, today: _december15);
    expect(midDecember.mostRegularWeekday, DateTime.wednesday);
  });

  test('lists only the achievements unlocked during the year', () {
    final review = computeYearInReview(
      [
        _history(1, [CalendarDay.fromDate(2025, 6, 1), ..._days(CalendarDay.fromDate(2026, 4, 6), 7)]),
      ],
      year: 2026,
      today: _december15,
    );

    expect(review.achievementsUnlocked, isNot(contains(Achievement.firstStep)));
    expect(review.achievementsUnlocked, contains(Achievement.firstWeek));
  });

  test('the best month and weekday compare rates, so a perfect year does not favour long ones', () {
    // Every day of the year a success: every month and weekday ties at 100 %, the earliest wins.
    final perfect = computeYearInReview(
      [_history(1, _days(CalendarDay.fromDate(2026, 1, 1), 365))],
      year: 2026,
      today: CalendarDay.fromDate(2027, 1, 5),
    );
    expect(perfect.bestMonth, DateTime.january);
    expect(perfect.mostRegularWeekday, DateTime.monday);

    // 28 of 28 days in February beat 30 of 31 days in March, though March has more successes.
    final february = computeYearInReview(
      [
        _history(1, [..._days(CalendarDay.fromDate(2026, 2, 1), 28), ..._days(CalendarDay.fromDate(2026, 3, 1), 30)]),
      ],
      year: 2026,
      today: _december15,
    );
    expect(february.bestMonth, DateTime.february);
  });

  test('a weekly target keeps the ISO week that straddles January 1 whole', () {
    // 2026-01-01 is a Thursday; its ISO week starts on Monday 2025-12-29. Five days a week from
    // that Monday for three weeks, with a target of five, is a three-week streak.
    final weekStartingInDecember = CalendarDay.fromDate(2025, 12, 29);
    final review = computeYearInReview(
      [
        _history(1, [
          for (var week = 0; week < 3; week++) ..._days(weekStartingInDecember.addDays(week * 7), 5),
        ], targetDaysPerWeek: 5),
      ],
      year: 2026,
      today: _december15,
    );

    expect(review.longestStreak?.unit, StreakUnit.weeks);
    expect(review.longestStreak?.length, 3);
  });
}
