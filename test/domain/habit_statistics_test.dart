import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/habit_schedule.dart';
import 'package:komit/domain/habit_statistics.dart';

void main() {
  final today = CalendarDay.fromDate(2026, 3, 10);

  const successObjectiveId = 1;
  const skippedObjectiveId = 2;
  const successObjectiveIds = {successObjectiveId};

  /// Logs the success objective [offsets] days before today.
  Map<CalendarDay, int> successBeforeToday(Iterable<int> offsets) => {
    for (final offset in offsets) today.addDays(-offset): successObjectiveId,
  };

  StreakSummary streakOf(Map<CalendarDay, int> objectiveIdByDay) =>
      computeStreakSummary(objectiveIdByDay, successObjectiveIds: successObjectiveIds, today: today);

  group('computeStreakSummary', () {
    test('is zero without logs', () {
      final summary = streakOf(const {});
      expect(summary.currentStreakLength, 0);
      expect(summary.bestStreakLength, 0);
    });

    test('counts today and the consecutive days before it', () {
      final summary = streakOf(successBeforeToday([0, 1, 2, 4]));
      expect(summary.currentStreakLength, 3);
      expect(summary.bestStreakLength, 3);
      expect(summary.unit, StreakUnit.days);
    });

    test('keeps the streak alive when today is not logged yet', () {
      expect(streakOf(successBeforeToday([1, 2])).currentStreakLength, 2);
    });

    test('breaks the current streak after a missed day', () {
      expect(streakOf(successBeforeToday([2, 3])).currentStreakLength, 0);
    });

    test('a day logged with a non-success objective breaks the streak', () {
      final summary = streakOf({
        ...successBeforeToday([0, 2, 3, 4]),
        today.addDays(-1): skippedObjectiveId,
      });
      expect(summary.currentStreakLength, 1);
      expect(summary.bestStreakLength, 3);
    });

    test('finds the best streak across a month boundary, ignoring order', () {
      final days = {
        CalendarDay.fromDate(2026, 3, 1): successObjectiveId,
        CalendarDay.fromDate(2026, 2, 27): successObjectiveId,
        CalendarDay.fromDate(2026, 2, 28): successObjectiveId,
        CalendarDay.fromDate(2026, 1, 1): successObjectiveId,
      };
      expect(streakOf(days).bestStreakLength, 3);
    });
  });

  group('computeScheduledStreakSummary', () {
    // 2026-03-10 is a Tuesday.
    final monday = CalendarDay.fromDate(2026, 3, 9);
    const mondayWednesdayFriday = 0x15;

    StreakSummary scheduledStreakOf(
      Map<CalendarDay, int> objectiveIdByDay, {
      int scheduledWeekdayMask = everyWeekdayMask,
      int? targetDaysPerWeek,
      CalendarDay? onDay,
    }) => computeScheduledStreakSummary(
      objectiveIdByDay,
      successObjectiveIds: successObjectiveIds,
      scheduledWeekdayMask: scheduledWeekdayMask,
      targetDaysPerWeek: targetDaysPerWeek,
      today: onDay ?? today,
    );

    Map<CalendarDay, int> successOn(Iterable<CalendarDay> days) => {for (final day in days) day: successObjectiveId};

    test('counts every consecutive day for a daily habit', () {
      final logs = successBeforeToday([0, 1, 2, 5, 6]);
      final scheduled = scheduledStreakOf(logs);
      expect((scheduled.currentStreakLength, scheduled.bestStreakLength), (3, 3));
    });

    test('off-schedule weekdays neither count nor break the streak', () {
      // Mon, Wed, Fri of last week and Mon of this week; Tuesday today is off schedule.
      final logs = successOn([monday.addDays(-7), monday.addDays(-5), monday.addDays(-3), monday]);
      final summary = scheduledStreakOf(logs, scheduledWeekdayMask: mondayWednesdayFriday);
      expect(summary.currentStreakLength, 4);
      expect(summary.bestStreakLength, 4);
    });

    test('a success on an off day does not count', () {
      final logs = successOn([monday, monday.addDays(1)]);
      expect(scheduledStreakOf(logs, scheduledWeekdayMask: mondayWednesdayFriday).currentStreakLength, 1);
    });

    test('a missed scheduled day breaks the streak, but not today before it ends', () {
      final wednesday = monday.addDays(2);
      // Fri last week logged, Mon missed: broken. Today (Wednesday) not logged yet: alive.
      final broken = scheduledStreakOf(
        successOn([monday.addDays(-3)]),
        scheduledWeekdayMask: mondayWednesdayFriday,
        onDay: wednesday,
      );
      expect(broken.currentStreakLength, 0);
      final alive = scheduledStreakOf(
        successOn([monday.addDays(-3), monday]),
        scheduledWeekdayMask: mondayWednesdayFriday,
        onDay: wednesday,
      );
      expect(alive.currentStreakLength, 2);
    });

    test('a 3-per-week habit counts consecutive weeks that reach 3', () {
      final logs = successOn([
        // Two weeks ago: 3 days.
        monday.addDays(-14), monday.addDays(-13), monday.addDays(-10),
        // Last week: 4 days.
        monday.addDays(-7), monday.addDays(-6), monday.addDays(-5), monday.addDays(-1),
        // This week so far: 1 day, the week is still open.
        monday,
      ]);
      final summary = scheduledStreakOf(logs, targetDaysPerWeek: 3);
      expect(summary.unit, StreakUnit.weeks);
      expect(summary.currentStreakLength, 2);
      expect(summary.bestStreakLength, 2);
    });

    test('the current week counts as soon as it reaches the target', () {
      final logs = successOn([monday.addDays(-7), monday.addDays(-6), monday.addDays(-5), monday, monday.addDays(1)]);
      expect(scheduledStreakOf(logs, targetDaysPerWeek: 2).currentStreakLength, 2);
    });

    test('a past week below the target breaks the weekly streak', () {
      final logs = successOn([monday.addDays(-14), monday.addDays(-13), monday.addDays(-7)]);
      final summary = scheduledStreakOf(logs, targetDaysPerWeek: 2);
      expect(summary.currentStreakLength, 0);
      expect(summary.bestStreakLength, 1);
    });

    test('weekly days logged with a non-success objective do not count', () {
      final logs = {
        ...successOn([monday.addDays(-7), monday.addDays(-6)]),
        monday.addDays(-5): skippedObjectiveId,
      };
      expect(scheduledStreakOf(logs, targetDaysPerWeek: 3).bestStreakLength, 0);
    });
  });

  group('milestoneReachedBetween', () {
    test('celebrates the very first log', () {
      expect(milestoneReachedBetween(0, 1), 1);
    });

    test('returns the milestone crossed, or null when none is', () {
      expect(milestoneReachedBetween(6, 7), 7);
      expect(milestoneReachedBetween(7, 8), isNull);
      expect(milestoneReachedBetween(8, 7), isNull);
    });

    test('returns the largest milestone when several are crossed at once', () {
      expect(milestoneReachedBetween(2, 30), 30);
    });
  });

  test('computeSuccessRate counts success days on scheduled days only', () {
    final rate = computeSuccessRate(
      {
        ...successBeforeToday([0, 1]),
        today.addDays(-2): skippedObjectiveId,
      },
      successObjectiveIds: successObjectiveIds,
      scheduledWeekdayMask: everyWeekdayMask,
      firstDay: today.addDays(-3),
      today: today,
    );
    expect(rate, 0.5);
  });

  test('computeYearStatistics counts logs per objective and month for that year only', () {
    final statistics = computeYearStatistics({
      CalendarDay.fromDate(2025, 12, 31): 1,
      CalendarDay.fromDate(2026, 1, 1): 1,
      CalendarDay.fromDate(2026, 1, 2): 2,
      CalendarDay.fromDate(2026, 12, 31): 2,
    }, year: 2026);

    expect(statistics.logCountByObjectiveId, {1: 1, 2: 2});
    expect(statistics.logCountByMonth.first, 2);
    expect(statistics.logCountByMonth.last, 1);
    expect(statistics.totalLogCount, 3);
  });

  test('CalendarDay keeps the calendar date whatever the time of day', () {
    expect(CalendarDay.fromDateTime(DateTime(2026, 3, 29, 23, 59)), CalendarDay.fromDate(2026, 3, 29));
    expect(CalendarDay.fromDate(2026, 3, 29).asLocalDate, DateTime(2026, 3, 29));
  });
}
