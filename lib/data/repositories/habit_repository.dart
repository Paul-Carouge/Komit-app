import 'package:drift/drift.dart';

import '../../core/calendar_day.dart';
import '../database/app_database.dart';

class HabitWithObjectives {
  const HabitWithObjectives(this.habit, this.objectives);

  final HabitRow habit;

  /// Sorted by the user-defined order.
  final List<ObjectiveRow> objectives;

  ObjectiveRow? objectiveWithId(int objectiveId) {
    for (final objective in objectives) {
      if (objective.id == objectiveId) return objective;
    }
    return null;
  }
}

/// What the editor submits; [id] is null for a new habit or objective.
class HabitDraft {
  const HabitDraft({
    required this.id,
    required this.title,
    required this.description,
    required this.colorArgb,
    required this.iconName,
    required this.reminderMinuteOfDay,
    required this.objectives,
  });

  final int? id;
  final String title;
  final String description;
  final int colorArgb;
  final String iconName;
  final int? reminderMinuteOfDay;
  final List<ObjectiveDraft> objectives;
}

class ObjectiveDraft {
  const ObjectiveDraft({required this.id, required this.title, required this.colorArgb});

  final int? id;
  final String title;
  final int colorArgb;
}

class HabitRepository {
  HabitRepository(this._database);

  final AppDatabase _database;

  Stream<List<HabitWithObjectives>> watchAllHabitsWithObjectives() {
    final query =
        _database.select(_database.habits).join([
          innerJoin(_database.objectives, _database.objectives.habitId.equalsExp(_database.habits.id)),
        ])..orderBy([
          OrderingTerm.asc(_database.habits.sortOrder),
          OrderingTerm.asc(_database.habits.id),
          OrderingTerm.asc(_database.objectives.sortOrder),
        ]);
    return query.watch().map((rows) {
      final objectivesByHabitId = <int, List<ObjectiveRow>>{};
      final habitsInOrder = <HabitRow>[];
      for (final row in rows) {
        final habit = row.readTable(_database.habits);
        final objectives = objectivesByHabitId.putIfAbsent(habit.id, () {
          habitsInOrder.add(habit);
          return [];
        });
        objectives.add(row.readTable(_database.objectives));
      }
      return [for (final habit in habitsInOrder) HabitWithObjectives(habit, objectivesByHabitId[habit.id]!)];
    });
  }

  Stream<HabitWithObjectives?> watchHabitWithObjectives(int habitId) => watchAllHabitsWithObjectives().map(
    (habits) => habits.where((candidate) => candidate.habit.id == habitId).firstOrNull,
  );

  /// Every logged day of [habitId], mapped to the chosen objective id.
  Stream<Map<CalendarDay, int>> watchObjectiveIdByDayForHabit(int habitId) {
    final query = _database.select(_database.habitLogs)..where((log) => log.habitId.equals(habitId));
    return query.watch().map((logs) => {for (final log in logs) CalendarDay(log.day): log.objectiveId});
  }

  /// Logs of every habit since [firstDay] included: habit id -> day -> objective id.
  Stream<Map<int, Map<CalendarDay, int>>> watchObjectiveIdByDayForAllHabitsSince(CalendarDay firstDay) {
    final query = _database.select(_database.habitLogs)
      ..where((log) => log.day.isBiggerOrEqualValue(firstDay.daysSinceEpoch));
    return query.watch().map((logs) {
      final logsByHabitId = <int, Map<CalendarDay, int>>{};
      for (final log in logs) {
        logsByHabitId.putIfAbsent(log.habitId, () => {})[CalendarDay(log.day)] = log.objectiveId;
      }
      return logsByHabitId;
    });
  }

  Stream<Map<int, CalendarDay>> watchLastLoggedDayByHabitId() {
    final lastDay = _database.habitLogs.day.max();
    final query = _database.selectOnly(_database.habitLogs)
      ..addColumns([_database.habitLogs.habitId, lastDay])
      ..groupBy([_database.habitLogs.habitId]);
    return query.watch().map(
      (rows) => {for (final row in rows) row.read(_database.habitLogs.habitId)!: CalendarDay(row.read(lastDay)!)},
    );
  }

  /// Creates or updates the habit and its objectives atomically; returns the habit id.
  ///
  /// Objectives missing from [draft] are deleted together with their logs.
  Future<int> saveHabit(HabitDraft draft) {
    return _database.transaction(() async {
      final habitColumns = HabitsCompanion(
        title: Value(draft.title.trim()),
        description: Value(draft.description.trim()),
        colorArgb: Value(draft.colorArgb),
        iconName: Value(draft.iconName),
        reminderMinuteOfDay: Value(draft.reminderMinuteOfDay),
      );
      final int habitId;
      if (draft.id case final existingHabitId?) {
        habitId = existingHabitId;
        await (_database.update(_database.habits)..where((habit) => habit.id.equals(habitId))).write(habitColumns);
      } else {
        final nextSortOrder = await _nextHabitSortOrder();
        habitId = await _database
            .into(_database.habits)
            .insert(habitColumns.copyWith(createdAt: Value(DateTime.now()), sortOrder: Value(nextSortOrder)));
      }

      final keptObjectiveIds = [for (final objective in draft.objectives) ?objective.id];
      await (_database.delete(
        _database.objectives,
      )..where((objective) => objective.habitId.equals(habitId) & objective.id.isNotIn(keptObjectiveIds))).go();
      // Two passes avoid a transient unique (habitId, title) clash when titles are swapped.
      for (final objectiveId in keptObjectiveIds) {
        await (_database.update(_database.objectives)..where((objective) => objective.id.equals(objectiveId))).write(
          ObjectivesCompanion(title: Value('\u{FFFF}$objectiveId')),
        );
      }
      for (final (sortOrder, objective) in draft.objectives.indexed) {
        final objectiveColumns = ObjectivesCompanion(
          habitId: Value(habitId),
          title: Value(objective.title.trim()),
          colorArgb: Value(objective.colorArgb),
          sortOrder: Value(sortOrder),
        );
        if (objective.id case final objectiveId?) {
          await (_database.update(
            _database.objectives,
          )..where((row) => row.id.equals(objectiveId))).write(objectiveColumns);
        } else {
          await _database.into(_database.objectives).insert(objectiveColumns);
        }
      }
      return habitId;
    });
  }

  Future<int> _nextHabitSortOrder() async {
    final maximumSortOrder = _database.habits.sortOrder.max();
    final row = await (_database.selectOnly(_database.habits)..addColumns([maximumSortOrder])).getSingle();
    return (row.read(maximumSortOrder) ?? -1) + 1;
  }

  Future<void> deleteHabit(int habitId) =>
      (_database.delete(_database.habits)..where((habit) => habit.id.equals(habitId))).go();

  Future<int> countLogsForObjective(int objectiveId) async {
    final logCount = _database.habitLogs.id.count();
    final query = _database.selectOnly(_database.habitLogs)
      ..addColumns([logCount])
      ..where(_database.habitLogs.objectiveId.equals(objectiveId));
    return (await query.getSingle()).read(logCount)!;
  }

  Future<void> logObjectiveForDay({required int habitId, required int objectiveId, required CalendarDay day}) {
    return _database
        .into(_database.habitLogs)
        .insert(
          HabitLogsCompanion.insert(habitId: habitId, objectiveId: objectiveId, day: day.daysSinceEpoch),
          onConflict: DoUpdate(
            (_) => HabitLogsCompanion(objectiveId: Value(objectiveId)),
            target: [_database.habitLogs.habitId, _database.habitLogs.day],
          ),
        );
  }

  Future<void> clearLogForDay({required int habitId, required CalendarDay day}) {
    return (_database.delete(
      _database.habitLogs,
    )..where((log) => log.habitId.equals(habitId) & log.day.equals(day.daysSinceEpoch))).go();
  }
}
