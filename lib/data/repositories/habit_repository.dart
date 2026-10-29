import 'package:drift/drift.dart';

import '../../core/calendar_day.dart';
import '../../domain/habit_schedule.dart';
import '../database/app_database.dart';

class HabitWithObjectives {
  const HabitWithObjectives(this.habit, this.objectives);

  final HabitRow habit;

  /// Sorted by the user-defined order.
  final List<ObjectiveRow> objectives;

  /// The objectives whose logs extend a streak.
  Set<int> get successObjectiveIds => {
    for (final objective in objectives)
      if (objective.countsAsSuccess) objective.id,
  };

  ObjectiveRow? objectiveWithId(int objectiveId) {
    for (final objective in objectives) {
      if (objective.id == objectiveId) return objective;
    }
    return null;
  }
}

/// Whether [habit] asks for a log on [day]. A weekly target can be met on any day of the week.
bool isHabitScheduledOn(HabitWithObjectives habit, CalendarDay day) =>
    isWeekdayScheduled(habit.habit.scheduledWeekdayMask, day.weekday);

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
    this.scheduledWeekdayMask = everyWeekdayMask,
    this.targetDaysPerWeek,
  });

  final int? id;
  final String title;
  final String description;
  final int colorArgb;
  final String iconName;
  final int? reminderMinuteOfDay;
  final List<ObjectiveDraft> objectives;

  /// See [HabitRow.scheduledWeekdayMask]; every day by default.
  final int scheduledWeekdayMask;

  /// Null for a daily habit; see [HabitRow.targetDaysPerWeek].
  final int? targetDaysPerWeek;
}

class ObjectiveDraft {
  const ObjectiveDraft({required this.id, required this.title, required this.colorArgb, this.countsAsSuccess = true});

  final int? id;
  final String title;
  final int colorArgb;
  final bool countsAsSuccess;
}

/// Thrown when a log would break an invariant the UI is expected to enforce.
class InvalidLogException implements Exception {
  const InvalidLogException(this.message);

  final String message;

  @override
  String toString() => 'InvalidLogException: $message';
}

class HabitRepository {
  /// [now] is injectable so tests control what "today" is.
  HabitRepository(this._database, {this._now = DateTime.now});

  final AppDatabase _database;
  final DateTime Function() _now;

  /// Habits not archived, in the user-defined order.
  Stream<List<HabitWithObjectives>> watchActiveHabits() =>
      _watchHabitsWithObjectives(_database.habits.archivedAt.isNull());

  Stream<List<HabitWithObjectives>> watchArchivedHabits() =>
      _watchHabitsWithObjectives(_database.habits.archivedAt.isNotNull());

  /// Active and archived habits, in the user-defined order.
  Stream<List<HabitWithObjectives>> watchAllHabits() => _watchHabitsWithObjectives(const Constant(true));

  Stream<HabitWithObjectives?> watchHabitWithObjectives(int habitId) =>
      _watchHabitsWithObjectives(_database.habits.id.equals(habitId)).map((habits) => habits.firstOrNull);

  Stream<List<HabitWithObjectives>> _watchHabitsWithObjectives(Expression<bool> habitFilter) {
    final query =
        _database.select(_database.habits).join([
            innerJoin(_database.objectives, _database.objectives.habitId.equalsExp(_database.habits.id)),
          ])
          ..where(habitFilter)
          ..orderBy([
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

  /// Every logged day of [habitId], mapped to the chosen objective id.
  Stream<Map<CalendarDay, int>> watchObjectiveIdByDayForHabit(int habitId) {
    final query = _database.select(_database.habitLogs)..where((log) => log.habitId.equals(habitId));
    return query.watch().map((logs) => {for (final log in logs) CalendarDay(log.day): log.objectiveId});
  }

  /// Logs of every habit since [firstDay] included: habit id -> day -> objective id.
  Stream<Map<int, Map<CalendarDay, int>>> watchObjectiveIdByDayForAllHabitsSince(CalendarDay firstDay) =>
      _watchObjectiveIdByDayByHabitId(
        _database.select(_database.habitLogs)..where((log) => log.day.isBiggerOrEqualValue(firstDay.daysSinceEpoch)),
      );

  /// Every log of every habit, archived ones included: habit id -> day -> objective id.
  Stream<Map<int, Map<CalendarDay, int>>> watchObjectiveIdByDayForAllHabits() =>
      _watchObjectiveIdByDayByHabitId(_database.select(_database.habitLogs));

  Stream<Map<int, Map<CalendarDay, int>>> _watchObjectiveIdByDayByHabitId(
    SimpleSelectStatement<$HabitLogsTable, HabitLogRow> query,
  ) {
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
        scheduledWeekdayMask: Value(draft.scheduledWeekdayMask),
        targetDaysPerWeek: Value(draft.targetDaysPerWeek),
      );
      final int habitId;
      if (draft.id case final existingHabitId?) {
        habitId = existingHabitId;
        await (_database.update(_database.habits)..where((habit) => habit.id.equals(habitId))).write(habitColumns);
      } else {
        final nextSortOrder = await _nextHabitSortOrder();
        habitId = await _database
            .into(_database.habits)
            .insert(habitColumns.copyWith(createdAt: Value(_now()), sortOrder: Value(nextSortOrder)));
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
          countsAsSuccess: Value(objective.countsAsSuccess),
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

  /// Persists [habitIdsInOrder] as the dashboard order, atomically.
  Future<void> reorderHabits(List<int> habitIdsInOrder) {
    return _database.transaction(() async {
      for (final (sortOrder, habitId) in habitIdsInOrder.indexed) {
        await (_database.update(
          _database.habits,
        )..where((habit) => habit.id.equals(habitId))).write(HabitsCompanion(sortOrder: Value(sortOrder)));
      }
    });
  }

  /// Hides the habit from the dashboard and its reminders; its logs are kept.
  Future<void> archiveHabit(int habitId) => _writeArchivedAt(habitId, _now());

  Future<void> unarchiveHabit(int habitId) => _writeArchivedAt(habitId, null);

  Future<void> _writeArchivedAt(int habitId, DateTime? archivedAt) => (_database.update(
    _database.habits,
  )..where((habit) => habit.id.equals(habitId))).write(HabitsCompanion(archivedAt: Value(archivedAt)));

  Future<void> deleteHabit(int habitId) =>
      (_database.delete(_database.habits)..where((habit) => habit.id.equals(habitId))).go();

  Future<int> countLogsForObjective(int objectiveId) async {
    final logCount = _database.habitLogs.id.count();
    final query = _database.selectOnly(_database.habitLogs)
      ..addColumns([logCount])
      ..where(_database.habitLogs.objectiveId.equals(objectiveId));
    return (await query.getSingle()).read(logCount)!;
  }

  /// Throws [InvalidLogException] when [day] is after today or [objectiveId] is not one of
  /// [habitId]'s objectives; the foreign keys alone would accept both.
  Future<void> logObjectiveForDay({required int habitId, required int objectiveId, required CalendarDay day}) {
    if (day.isAfter(CalendarDay.fromDateTime(_now()))) {
      return Future.error(const InvalidLogException('cannot log a future day'));
    }
    return _database.transaction(() async {
      final objective = await (_database.select(
        _database.objectives,
      )..where((objective) => objective.id.equals(objectiveId) & objective.habitId.equals(habitId))).getSingleOrNull();
      if (objective == null) {
        throw InvalidLogException('objective $objectiveId does not belong to habit $habitId');
      }
      await _database
          .into(_database.habitLogs)
          .insert(
            HabitLogsCompanion.insert(habitId: habitId, objectiveId: objectiveId, day: day.daysSinceEpoch),
            onConflict: DoUpdate(
              (_) => HabitLogsCompanion(objectiveId: Value(objectiveId)),
              target: [_database.habitLogs.habitId, _database.habitLogs.day],
            ),
          );
    });
  }

  Future<void> clearLogForDay({required int habitId, required CalendarDay day}) {
    return (_database.delete(
      _database.habitLogs,
    )..where((log) => log.habitId.equals(habitId) & log.day.equals(day.daysSinceEpoch))).go();
  }
}
