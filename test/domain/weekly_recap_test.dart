import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/habit_history.dart';
import 'package:komit/domain/habit_statistics.dart';
import 'package:komit/domain/weekly_recap.dart';

const int _success = 1;
const int _skipped = 2;

/// A Monday; the recap is about the week before it.
final CalendarDay _monday = CalendarDay.fromDate(2026, 11, 2);
final CalendarDay _lastWeekMonday = _monday.addDays(-7);
final CalendarDay _weekBeforeMonday = _monday.addDays(-14);

HabitHistory _history(
  int habitId,
  Iterable<CalendarDay> successDays, {
  int scheduledWeekdayMask = 0x7F,
  int? targetDaysPerWeek,
  Map<CalendarDay, int> otherLogs = const {},
  CalendarDay? startDay,
  CalendarDay? archivedDay,
}) => HabitHistory(
  habitId: habitId,
  objectiveIdByDay: {for (final day in successDays) day: _success, ...otherLogs},
  successObjectiveIds: const {_success},
  startDay: startDay ?? CalendarDay.fromDate(2026, 1, 1),
  scheduledWeekdayMask: scheduledWeekdayMask,
  targetDaysPerWeek: targetDaysPerWeek,
  archivedDay: archivedDay,
);

Iterable<CalendarDay> _days(CalendarDay first, int count) => [for (var i = 0; i < count; i++) first.addDays(i)];

void main() {
  test('an empty history gives an empty recap without activity', () {
    final recap = computeWeeklyRecap(const [], today: _monday);

    expect(recap.weekMonday, _lastWeekMonday);
    expect(recap.habitResults, isEmpty);
    expect(recap.successDayCount, 0);
    expect(recap.hasActivity, isFalse);
    expect(recap.bestStreak, isNull);
  });

  test('a partial week counts success days only and compares with the week before', () {
    final recap = computeWeeklyRecap([
      _history(
        1,
        [..._days(_lastWeekMonday, 3), ..._days(_weekBeforeMonday, 5)],
        otherLogs: {_lastWeekMonday.addDays(4): _skipped},
      ),
    ], today: _monday);

    final result = recap.habitResults.single;
    expect(result.successDayCount, 3);
    expect(result.expectedSuccessDayCount, 7);
    expect(result.isWeekMet, isFalse);
    expect(recap.previousWeekSuccessDayCount, 5);
    expect(recap.successDayCountChange, -2);
    expect(recap.hasActivity, isTrue);
  });

  test('a perfect week is met and reports the longest streak at its end', () {
    final recap = computeWeeklyRecap([
      _history(1, _days(_weekBeforeMonday, 14)),
      _history(2, _days(_lastWeekMonday.addDays(4), 3)),
    ], today: _monday.addDays(2));

    expect(recap.weekMonday, _lastWeekMonday, reason: 'any day of the week recaps the week before');
    expect(recap.habitResults.map((result) => result.isWeekMet), [true, false]);
    expect(recap.successDayCount, 10);
    expect(recap.successDayCountChange, 3);
    expect(recap.bestStreakHabitId, 1);
    expect(recap.bestStreak!.currentStreakLength, 14);
  });

  test('the recap follows each schedule: weekdays and weekly targets', () {
    const mondayWednesdayFriday = 1 | 1 << 2 | 1 << 4;
    final recap = computeWeeklyRecap([
      _history(1, [
        _lastWeekMonday,
        _lastWeekMonday.addDays(2),
        _lastWeekMonday.addDays(4),
      ], scheduledWeekdayMask: mondayWednesdayFriday),
      _history(2, [_lastWeekMonday.addDays(1), _lastWeekMonday.addDays(5)], targetDaysPerWeek: 2),
    ], today: _monday);

    expect([for (final result in recap.habitResults) result.expectedSuccessDayCount], [3, 2]);
    expect(recap.habitResults.every((result) => result.isWeekMet), isTrue);
    expect(recap.bestStreak!.unit, StreakUnit.days);
  });

  test('habits started after the week or archived before its end are left out', () {
    final recap = computeWeeklyRecap([
      _history(1, _days(_lastWeekMonday, 2), archivedDay: _lastWeekMonday.addDays(3)),
      _history(2, const [], startDay: _monday),
      _history(3, _days(_lastWeekMonday, 1)),
    ], today: _monday);

    expect(recap.habitResults.map((result) => result.habitId), [3]);
  });
}
