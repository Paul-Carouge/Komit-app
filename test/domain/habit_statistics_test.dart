import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/habit_pause.dart';
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

  group('pauses and rest days (docs/adr/0007)', () {
    // 2026-03-10 is a Tuesday; 2026-03-02 and 2026-03-09 are Mondays.
    final lastMonday = CalendarDay.fromDate(2026, 3, 2);
    Map<CalendarDay, int> successOn(Iterable<CalendarDay> days) => {for (final day in days) day: successObjectiveId};

    StreakSummary streakWith(
      Map<CalendarDay, int> objectiveIdByDay, {
      List<HabitPause> pauses = const [],
      int restDaysPerWeek = 0,
      int? targetDaysPerWeek,
      int scheduledWeekdayMask = everyWeekdayMask,
      CalendarDay? onDay,
    }) => computeScheduledStreakSummary(
      objectiveIdByDay,
      successObjectiveIds: successObjectiveIds,
      scheduledWeekdayMask: scheduledWeekdayMask,
      targetDaysPerWeek: targetDaysPerWeek,
      today: onDay ?? today,
      pauses: pauses,
      restDaysPerWeek: restDaysPerWeek,
    );

    test('paused days neither break nor extend a daily streak, even when logged', () {
      // Successes 9 to 7 days ago and 2 to 0 days ago; paused from 6 to 3 days ago, one of them logged.
      final logs = successBeforeToday([9, 8, 7, 4, 2, 1, 0]);
      final pause = HabitPause(startDay: today.addDays(-6), endDay: today.addDays(-3));

      final withoutPause = streakWith(logs);
      expect((withoutPause.currentStreakLength, withoutPause.bestStreakLength), (3, 3));

      final withPause = streakWith(logs, pauses: [pause]);
      expect((withPause.currentStreakLength, withPause.bestStreakLength), (6, 6));
    });

    test('an open pause keeps the streak as it was when the pause started', () {
      final logs = successBeforeToday([5, 4, 3]);
      final streak = streakWith(logs, pauses: [HabitPause(startDay: today.addDays(-2))]);
      expect((streak.currentStreakLength, streak.bestStreakLength), (3, 3));
    });

    test('rest days forgive missed days up to the allowance in each ISO week', () {
      // Last week: Monday to Sunday with Wednesday and Friday missed. This week: Monday, today.
      final missed = {lastMonday.addDays(2), lastMonday.addDays(4)};
      final logs = successOn([
        for (var offset = 0; offset < 9; offset++)
          if (!missed.contains(lastMonday.addDays(offset))) lastMonday.addDays(offset),
      ]);

      final oneRestDay = streakWith(logs, restDaysPerWeek: 1);
      expect(oneRestDay.currentStreakLength, 4, reason: 'the second miss of the week breaks it');

      final twoRestDays = streakWith(logs, restDaysPerWeek: 2);
      expect(twoRestDays.currentStreakLength, 7, reason: 'rest days neither break nor count');
      expect(twoRestDays.bestStreakLength, 7);
    });

    test('the allowance starts again each week', () {
      // One miss on Sunday of last week and one on Monday of this week: one rest day per week covers both.
      final logs = successOn([
        for (var offset = 0; offset < 9; offset++)
          if (offset != 6 && offset != 7) lastMonday.addDays(offset),
      ]);
      expect(streakWith(logs, restDaysPerWeek: 1).currentStreakLength, 7);
    });

    test('an unmet week holding a paused day is neutral for a weekly target', () {
      final weekBefore = lastMonday.addDays(-7);
      // Three successes the week before, one last week (paused from Thursday), three this week so far.
      final logs = successOn([
        weekBefore,
        weekBefore.addDays(1),
        weekBefore.addDays(2),
        lastMonday,
        today.addDays(-1),
        today,
      ]);

      final unpaused = streakWith(logs, targetDaysPerWeek: 2);
      expect((unpaused.currentStreakLength, unpaused.bestStreakLength), (1, 1));

      final paused = streakWith(
        logs,
        targetDaysPerWeek: 2,
        pauses: [HabitPause(startDay: lastMonday.addDays(3), endDay: lastMonday.addDays(6))],
      );
      expect((paused.currentStreakLength, paused.bestStreakLength, paused.unit), (2, 2, StreakUnit.weeks));
    });

    test('successes on paused days do not count toward a weekly target', () {
      final logs = successOn([lastMonday, lastMonday.addDays(1)]);
      final streak = streakWith(
        logs,
        targetDaysPerWeek: 2,
        pauses: [HabitPause(startDay: lastMonday.addDays(1), endDay: lastMonday.addDays(1))],
        onDay: lastMonday.addDays(6),
      );
      expect(streak.bestStreakLength, 0);
    });

    test('a planned pause does not change today', () {
      final logs = successBeforeToday([3, 2, 1]);
      final streak = streakWith(
        logs,
        pauses: [HabitPause(startDay: today.addDays(1), endDay: today.addDays(5))],
      );
      expect((streak.currentStreakLength, streak.bestStreakLength), (3, 3));
    });

    test('rest days never make a streak unbreakable', () {
      // Monday only: no rest day allowed, so a missed Monday breaks the streak.
      const mondayOnly = 1 << (DateTime.monday - 1);
      final logs = successOn([lastMonday.addDays(-7)]);
      final streak = streakWith(logs, scheduledWeekdayMask: mondayOnly, restDaysPerWeek: 2);
      expect(streak.currentStreakLength, 0);
      expect(maximumRestDaysFor(mondayOnly), 0);
      expect(maximumRestDaysFor(1 << (DateTime.monday - 1) | 1 << (DateTime.thursday - 1)), 1);
      expect(maximumRestDaysFor(everyWeekdayMask), 2);
    });

    test('a weekly target ignores rest days', () {
      final logs = successOn([lastMonday.addDays(-7), lastMonday.addDays(-6), lastMonday]);
      final streak = streakWith(logs, targetDaysPerWeek: 2, restDaysPerWeek: 2);
      expect(streak.currentStreakLength, 0);
      expect(streak.bestStreakLength, 1);
    });

    test('successes on paused days leave the weekly progress', () {
      final logs = successOn([lastMonday, lastMonday.addDays(1)]);
      expect(
        countSuccessDaysInWeekOf(
          logs,
          successObjectiveIds: successObjectiveIds,
          day: lastMonday,
          pauses: [HabitPause(startDay: lastMonday.addDays(1), endDay: lastMonday.addDays(1))],
        ),
        1,
      );
    });

    test('the success rate leaves paused days out', () {
      final logs = successBeforeToday([0, 1]);
      final rate = computeSuccessRate(
        logs,
        successObjectiveIds: successObjectiveIds,
        scheduledWeekdayMask: everyWeekdayMask,
        firstDay: today.addDays(-3),
        today: today,
        pauses: [HabitPause(startDay: today.addDays(-3), endDay: today.addDays(-2))],
      );
      expect(rate, 1);
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
  test('countSuccessDaysInWeekOf counts success days from Monday to Sunday only', () {
    // 2026-03-10 is a Tuesday: its week runs from Monday 9 to Sunday 15.
    final objectiveIdByDay = {
      CalendarDay.fromDate(2026, 3, 8): successObjectiveId,
      CalendarDay.fromDate(2026, 3, 9): successObjectiveId,
      CalendarDay.fromDate(2026, 3, 10): skippedObjectiveId,
      CalendarDay.fromDate(2026, 3, 15): successObjectiveId,
    };

    expect(countSuccessDaysInWeekOf(objectiveIdByDay, successObjectiveIds: successObjectiveIds, day: today), 2);
    expect(today.mondayOfWeek, CalendarDay.fromDate(2026, 3, 9));
    expect(today.weekday, DateTime.tuesday);
  });
}
