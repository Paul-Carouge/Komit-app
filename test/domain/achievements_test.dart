import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/achievements.dart';
import 'package:komit/domain/celebrations.dart';
import 'package:komit/domain/habit_history.dart';
import 'package:komit/domain/habit_statistics.dart';

const int _success = 1;
const int _skipped = 2;

/// A Wednesday.
final CalendarDay _today = CalendarDay.fromDate(2026, 10, 28);
final CalendarDay _thisMonday = _today.mondayOfWeek;

HabitHistory _history(
  int habitId,
  Iterable<CalendarDay> successDays, {
  int scheduledWeekdayMask = 0x7F,
  int? targetDaysPerWeek,
  Map<CalendarDay, int> otherLogs = const {},
  CalendarDay? startDay,
}) => HabitHistory(
  habitId: habitId,
  objectiveIdByDay: {for (final day in successDays) day: _success, ...otherLogs},
  successObjectiveIds: const {_success},
  startDay: startDay ?? (successDays.isEmpty ? _today : successDays.reduce((a, b) => a.isAfter(b) ? b : a)),
  scheduledWeekdayMask: scheduledWeekdayMask,
  targetDaysPerWeek: targetDaysPerWeek,
);

Iterable<CalendarDay> _days(CalendarDay first, int count) => [for (var i = 0; i < count; i++) first.addDays(i)];

void main() {
  group('computeUnlockedAchievements', () {
    test('nothing is unlocked without logs', () {
      expect(computeUnlockedAchievements(const [], today: _today), isEmpty);
      expect(computeUnlockedAchievements([_history(1, const [])], today: _today), isEmpty);
    });

    test('six days in a row are not yet a first week; seven are', () {
      final lastMonday = _thisMonday.addDays(-7);
      final partial = _history(1, _days(lastMonday, 6), startDay: lastMonday.addDays(-7));
      final complete = _history(1, _days(lastMonday, 7), startDay: lastMonday.addDays(-7));

      expect(computeUnlockedAchievements([partial], today: _today), isNot(contains(Achievement.firstWeek)));
      expect(computeUnlockedAchievements([complete], today: _today), contains(Achievement.firstWeek));
    });

    test('a perfect week needs every active habit to meet its schedule', () {
      final lastMonday = _thisMonday.addDays(-7);
      final daily = _history(1, _days(lastMonday, 7));
      final halfDone = _history(2, _days(lastMonday, 3));

      expect(computeUnlockedAchievements([daily], today: _today), contains(Achievement.perfectWeek));
      expect(computeUnlockedAchievements([daily, halfDone], today: _today), isNot(contains(Achievement.perfectWeek)));
    });

    test('a perfect week follows schedules: days off and weekly targets', () {
      final lastMonday = _thisMonday.addDays(-7);
      const mondayAndThursday = 1 | 1 << 3;
      final someDays = _history(1, [lastMonday, lastMonday.addDays(3)], scheduledWeekdayMask: mondayAndThursday);
      final weeklyTarget = _history(2, [lastMonday.addDays(5), lastMonday.addDays(6)], targetDaysPerWeek: 2);

      expect(
        computeUnlockedAchievements([someDays, weeklyTarget], today: _today),
        containsAll([Achievement.perfectWeek, Achievement.firstWeek]),
      );
    });

    test('the current week is perfect only once nothing it asks for is left', () {
      final todayIsSunday = _thisMonday.addDays(6);
      final dailyThisWeek = _history(1, _days(_thisMonday, 6), startDay: _thisMonday);

      expect(
        computeUnlockedAchievements([dailyThisWeek], today: todayIsSunday),
        isNot(contains(Achievement.perfectWeek)),
      );
      expect(
        computeUnlockedAchievements([dailyThisWeek.withDayLogged(todayIsSunday, _success)], today: todayIsSunday),
        contains(Achievement.perfectWeek),
      );
    });

    test('a hundred success days on one habit; skipped days do not count', () {
      final firstDay = _today.addDays(-200);
      final ninetyNine = _history(
        1,
        [for (var i = 0; i < 99; i++) firstDay.addDays(2 * i)],
        otherLogs: {firstDay.addDays(1): _skipped},
      );

      expect(computeUnlockedAchievements([ninetyNine], today: _today), isNot(contains(Achievement.hundredSuccessDays)));
      expect(
        computeUnlockedAchievements([ninetyNine.withDayLogged(_today, _success)], today: _today),
        contains(Achievement.hundredSuccessDays),
      );
    });

    test('a comeback is a success after a week of missed scheduled days', () {
      final beforeBreak = _today.addDays(-20);
      final sixDaysMissed = _history(1, [beforeBreak, beforeBreak.addDays(7)]);
      final sevenDaysMissed = _history(1, [beforeBreak, beforeBreak.addDays(8)]);

      expect(computeUnlockedAchievements([sixDaysMissed], today: _today), isNot(contains(Achievement.comeback)));
      expect(computeUnlockedAchievements([sevenDaysMissed], today: _today), contains(Achievement.comeback));
    });

    test('a comeback counts scheduled days only', () {
      const mondaysOnly = 1;
      final monday = _thisMonday.addDays(-7 * 10);
      final weeklyHabit = _history(1, [monday, monday.addDays(7 * 8)], scheduledWeekdayMask: mondaysOnly);

      expect(
        computeUnlockedAchievements([
          _history(1, [monday, monday.addDays(7)], scheduledWeekdayMask: mondaysOnly),
        ], today: _today),
        isNot(contains(Achievement.comeback)),
      );
      expect(computeUnlockedAchievements([weeklyHabit], today: _today), contains(Achievement.comeback));
    });

    test('a one-year veteran logged a year ago; future logs unlock nothing', () {
      final aYearAgo = _today.addDays(-oneYearVeteranDayCount);
      final futureOnly = _history(1, _days(_today.addDays(1), 120));

      expect(
        computeUnlockedAchievements([
          _history(1, [aYearAgo]),
        ], today: _today),
        contains(Achievement.oneYearVeteran),
      );
      expect(
        computeUnlockedAchievements([
          _history(1, [aYearAgo.addDays(1)]),
        ], today: _today),
        isNot(contains(Achievement.oneYearVeteran)),
      );
      expect(computeUnlockedAchievements([futureOnly], today: _today), isEmpty);
    });

    test('a first step needs a success day, not any log', () {
      final skippedOnly = _history(1, const [], otherLogs: {_today: _skipped});

      expect(computeUnlockedAchievements([skippedOnly], today: _today), isEmpty);
      expect(
        computeUnlockedAchievements([
          _history(1, [_today]),
        ], today: _today),
        contains(Achievement.firstStep),
      );
    });

    test('streak milestones follow the best streak, weekly targets counting seven days a week', () {
      final start = _today.addDays(-400);
      Set<Achievement> unlockedFor(int dayCount) => computeUnlockedAchievements([
        _history(1, _days(_today.addDays(1 - dayCount), dayCount), startDay: start),
      ], today: _today);

      expect(unlockedFor(29), isNot(contains(Achievement.monthStreak)));
      expect(unlockedFor(30), contains(Achievement.monthStreak));
      expect(unlockedFor(99), isNot(contains(Achievement.hundredDayStreak)));
      expect(unlockedFor(100), contains(Achievement.hundredDayStreak));
      expect(unlockedFor(364), isNot(contains(Achievement.yearStreak)));
      expect(unlockedFor(365), contains(Achievement.yearStreak));

      final fiveWeeksAgo = _thisMonday.addDays(-5 * DateTime.daysPerWeek);
      final weekly = _history(
        1,
        [for (var week = 0; week < 5; week++) fiveWeeksAgo.addDays(week * DateTime.daysPerWeek)],
        targetDaysPerWeek: 1,
        startDay: fiveWeeksAgo,
      );
      expect(computeUnlockedAchievements([weekly], today: _today), contains(Achievement.monthStreak));
    });

    test('a perfect day asks every daily habit scheduled that day, not weekly targets', () {
      final yesterday = _today.addDays(-1);
      final daily = _history(1, [yesterday], startDay: yesterday);
      final missedDaily = _history(2, const [], startDay: yesterday);
      final weekly = _history(3, const [], targetDaysPerWeek: 3, startDay: yesterday);
      // Yesterday is a Tuesday.
      final notScheduled = _history(4, const [], scheduledWeekdayMask: 0x7F & ~(1 << 1), startDay: yesterday);

      expect(
        computeUnlockedAchievements([daily, weekly, notScheduled], today: _today),
        contains(Achievement.perfectDay),
      );
      expect(computeUnlockedAchievements([daily, missedDaily], today: _today), isNot(contains(Achievement.perfectDay)));
    });

    test('total successes add up across habits; three habits need a success each', () {
      final start = _today.addDays(-1000);
      final histories = [
        for (var habitId = 1; habitId <= 3; habitId++)
          _history(habitId, _days(start.addDays(habitId * 300 - 300), 300), startDay: start),
      ];

      final unlocked = computeUnlockedAchievements(histories, today: _today);
      expect(unlocked, containsAll([Achievement.fiveHundredTotalSuccessDays, Achievement.threeHabits]));
      expect(unlocked, isNot(contains(Achievement.thousandTotalSuccessDays)));
      expect(
        computeUnlockedAchievements([
          ...histories,
          _history(4, _days(_today.addDays(-99), 100), startDay: start),
        ], today: _today),
        contains(Achievement.thousandTotalSuccessDays),
      );
      expect(
        computeUnlockedAchievements(histories.take(2).toList(), today: _today),
        isNot(contains(Achievement.threeHabits)),
      );
    });

    test('a two-year veteran logged two years ago', () {
      final twoYearsAgo = _today.addDays(-twoYearVeteranDayCount);

      expect(
        computeUnlockedAchievements([
          _history(1, [twoYearsAgo]),
        ], today: _today),
        containsAll([Achievement.oneYearVeteran, Achievement.twoYearVeteran]),
      );
      expect(
        computeUnlockedAchievements([
          _history(1, [twoYearsAgo.addDays(1)]),
        ], today: _today),
        isNot(contains(Achievement.twoYearVeteran)),
      );
    });
  });

  group('computeCelebrationsEarnedByLog', () {
    test('the first log of a habit is celebrated, not as a one-day streak', () {
      final celebrations = computeCelebrationsEarnedByLog(
        historiesBeforeLog: [_history(1, const [])],
        habitId: 1,
        day: _today,
        objectiveId: _success,
        today: _today,
      );

      expect(celebrations.map((celebration) => celebration.id), [
        'habit:1:first_log',
        'achievement:firstStep',
        'achievement:perfectDay',
      ]);
    });

    test('crossing seven days celebrates the milestone and the first week once', () {
      final celebrations = computeCelebrationsEarnedByLog(
        historiesBeforeLog: [_history(1, _days(_today.addDays(-6), 6), startDay: _today.addDays(-30))],
        habitId: 1,
        day: _today,
        objectiveId: _success,
        today: _today,
      );

      expect(celebrations.map((celebration) => celebration.id), ['habit:1:streak:7:days', 'achievement:firstWeek']);
      expect((celebrations.first as StreakMilestoneCelebration).unit, StreakUnit.days);
    });

    test('a log that crosses nothing, or a skipped day, earns nothing', () {
      final history = _history(1, _days(_today.addDays(-4), 4), startDay: _today.addDays(-30));

      expect(
        computeCelebrationsEarnedByLog(
          historiesBeforeLog: [history],
          habitId: 1,
          day: _today,
          objectiveId: _skipped,
          today: _today,
        ),
        isEmpty,
      );
      expect(
        computeCelebrationsEarnedByLog(
          historiesBeforeLog: [history.withDayLogged(_today.addDays(-5), _skipped)],
          habitId: 1,
          day: _today,
          objectiveId: _success,
          today: _today,
        ),
        isEmpty,
        reason: 'five days in a row is not a milestone',
      );
    });
  });
}
