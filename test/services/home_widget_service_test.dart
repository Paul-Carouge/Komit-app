import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/services/home_widget_service.dart';

final CalendarDay _thursday = CalendarDay.fromDate(2026, 10, 29);
const int _mondayOnlyMask = 1 << (DateTime.monday - 1);

HabitWithObjectives _habit(
  int id, {
  int scheduledWeekdayMask = everyWeekdayMask,
  DateTime? archivedAt,
  bool hasObjective = true,
}) => HabitWithObjectives(
  HabitRow(
    id: id,
    title: 'Habit $id',
    description: 'A private description',
    colorArgb: 0xFFFF8C1A,
    iconName: 'check',
    sortOrder: id,
    createdAt: DateTime(2026),
    scheduledWeekdayMask: scheduledWeekdayMask,
    archivedAt: archivedAt,
  ),
  [
    if (hasObjective)
      ObjectiveRow(id: id * 10, habitId: id, title: 'Done', colorArgb: 0xFF00FF00, sortOrder: 0, countsAsSuccess: true),
  ],
);

Map<String, Object?> _decodedSnapshot(List<HabitWithObjectives> habits, Map<int, Map<CalendarDay, int>> logs) =>
    jsonDecode(
      encodeTodayWidgetSnapshot(
        habits: habits,
        objectiveIdByDayByHabitId: logs,
        today: _thursday,
        isAppLockEnabled: false,
      ),
    ) as Map<String, Object?>;

void main() {
  test('lists only the active habits scheduled today, in order, with whether each is logged', () {
    final snapshot = _decodedSnapshot(
      [
        _habit(1),
        _habit(2, scheduledWeekdayMask: _mondayOnlyMask),
        _habit(3, archivedAt: DateTime(2026, 10)),
        _habit(4, hasObjective: false),
        _habit(5),
      ],
      {
        1: {_thursday: 10},
        // Logged yesterday only: not done today.
        5: {_thursday.addDays(-1): 50},
      },
    );

    expect(snapshot, {
      'version': todayWidgetSnapshotFormatVersion,
      'day': _thursday.daysSinceEpoch,
      'habits': [
        {'id': 1, 'title': 'Habit 1', 'colorArgb': 0xFFFF8C1A, 'isLoggedToday': true},
        {'id': 5, 'title': 'Habit 5', 'colorArgb': 0xFFFF8C1A, 'isLoggedToday': false},
      ],
    });
  });

  test('never writes descriptions, icons or objectives outside the database', () {
    final json = encodeTodayWidgetSnapshot(
      habits: [_habit(1)],
      objectiveIdByDayByHabitId: const {},
      today: _thursday,
      isAppLockEnabled: false,
    );

    expect(json, isNot(contains('private description')));
    expect(json, isNot(contains('Done')));
  });

  test('a day with nothing scheduled gives an empty checklist', () {
    final snapshot = _decodedSnapshot([_habit(1, scheduledWeekdayMask: _mondayOnlyMask)], const {});

    expect(snapshot['habits'], isEmpty);
  });

  test('with the app lock on, names no habit and offers nothing to log', () {
    final json = encodeTodayWidgetSnapshot(
      habits: [_habit(1)],
      objectiveIdByDayByHabitId: {
        1: {_thursday: 10},
      },
      today: _thursday,
      isAppLockEnabled: true,
    );

    expect(json, isNot(contains('Habit 1')));
    expect(jsonDecode(json), {
      'version': todayWidgetSnapshotFormatVersion,
      'day': _thursday.daysSinceEpoch,
      'isLocked': true,
      'habits': <Object?>[],
    });
  });
}
