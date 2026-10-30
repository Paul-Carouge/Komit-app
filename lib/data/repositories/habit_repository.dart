import 'package:drift/drift.dart';

import '../../core/calendar_day.dart';
import '../../domain/habit_pause.dart';
import '../../domain/habit_schedule.dart';
import '../../domain/habit_statistics.dart';
import '../database/app_database.dart';

class HabitWithObjectives {
  const HabitWithObjectives(this.habit, this.objectives, [this.pauses = const []]);

  final HabitRow habit;

  /// Sorted by the user-defined order.
  final List<ObjectiveRow> objectives;

  /// Past, current and planned pauses, earliest first (docs/adr/0007).
  final List<HabitPause> pauses;

  /// The pause holding [day], or null.
  HabitPause? pauseOn(CalendarDay day) {
    for (final pause in pauses) {
      if (pause.contains(day)) return pause;
    }
    return null;
  }

  /// The pause holding [today] or starting after it: what "Resume" ends.
  HabitPause? currentOrPlannedPause(CalendarDay today) {
    for (final pause in pauses) {
      if (pause.contains(today) || pause.startDay.isAfter(today)) return pause;
    }
    return null;
  }

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

/// Whether [habit] asks for a log on [day]: on its schedule and not paused. A weekly target can
/// be met on any day of the week.
bool isHabitScheduledOn(HabitWithObjectives habit, CalendarDay day) =>
    isWeekdayScheduled(habit.habit.scheduledWeekdayMask, day.weekday) && !isPausedOn(habit.pauses, day);

/// [habit]'s streak at the end of [today], with its schedule, pauses and rest days.
StreakSummary streakSummaryOf(
  HabitWithObjectives habit,
  Map<CalendarDay, int> objectiveIdByDay, {
  required CalendarDay today,
}) => computeScheduledStreakSummary(
  objectiveIdByDay,
  successObjectiveIds: habit.successObjectiveIds,
  scheduledWeekdayMask: habit.habit.scheduledWeekdayMask,
  targetDaysPerWeek: habit.habit.targetDaysPerWeek,
  today: today,
  pauses: habit.pauses,
  restDaysPerWeek: habit.habit.restDaysPerWeek,
);

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
    this.restDaysPerWeek = 0,
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

  /// See [HabitRow.restDaysPerWeek]; ignored with a weekly target.
  final int restDaysPerWeek;
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

/// Thrown when a pause would overlap another one or end before it starts.
class InvalidPauseException implements Exception {
  const InvalidPauseException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPauseException: $message';
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
            // Few pauses per habit: repeating each objective once per pause stays cheap.
            leftOuterJoin(_database.habitPauses, _database.habitPauses.habitId.equalsExp(_database.habits.id)),
          ])
          ..where(habitFilter)
          ..orderBy([
            OrderingTerm.asc(_database.habits.sortOrder),
            OrderingTerm.asc(_database.habits.id),
            OrderingTerm.asc(_database.objectives.sortOrder),
            OrderingTerm.asc(_database.habitPauses.startDay),
          ]);
    return query.watch().map((rows) {
      final objectivesByHabitId = <int, Map<int, ObjectiveRow>>{};
      final pausesByHabitId = <int, Map<int, HabitPause>>{};
      final habitsInOrder = <HabitRow>[];
      for (final row in rows) {
        final habit = row.readTable(_database.habits);
        final objectives = objectivesByHabitId.putIfAbsent(habit.id, () {
          habitsInOrder.add(habit);
          return {};
        });
        final objective = row.readTable(_database.objectives);
        objectives[objective.id] = objective;
        if (row.readTableOrNull(_database.habitPauses) case final pause?) {
          pausesByHabitId.putIfAbsent(habit.id, () => {})[pause.id] = HabitPause(
            startDay: CalendarDay(pause.startDay),
            endDay: switch (pause.endDay) {
              final endDay? => CalendarDay(endDay),
              null => null,
            },
          );
        }
      }
      return [
        for (final habit in habitsInOrder)
          HabitWithObjectives(
            habit,
            objectivesByHabitId[habit.id]!.values.toList(),
            (pausesByHabitId[habit.id]?.values.toList() ?? [])
              ..sort((first, second) => first.startDay.daysSinceEpoch.compareTo(second.startDay.daysSinceEpoch)),
          ),
      ];
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

  /// Habits never logged are left out.
  Stream<Map<int, CalendarDay>> watchLastLoggedDayByHabitId() {
    // One subquery per habit seeks the end of the (habit_id, day) unique index, instead of a
    // GROUP BY that scans every log: 0.4 ms instead of 6.7 ms for 182,500 logs.
    final logs = _database.alias(_database.habitLogs, 'logs');
    final lastDay = subqueryExpression<int>(
      _database.selectOnly(logs)
        ..addColumns([logs.day.max()])
        ..where(logs.habitId.equalsExp(_database.habits.id)),
    );
    final query = _database.selectOnly(_database.habits)..addColumns([_database.habits.id, lastDay]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          if (row.read(lastDay) case final day?) row.read(_database.habits.id)!: CalendarDay(day),
      },
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
        restDaysPerWeek: Value(draft.targetDaysPerWeek == null ? draft.restDaysPerWeek : 0),
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

  /// Puts the habit on hold from [startDay] (today or later) to [endDay] included, or until it is
  /// resumed when [endDay] is null. Throws [InvalidPauseException] on an overlap or a bad range.
  Future<void> pauseHabit(int habitId, {required CalendarDay startDay, CalendarDay? endDay}) {
    final today = CalendarDay.fromDateTime(_now());
    if (today.isAfter(startDay)) return Future.error(const InvalidPauseException('a pause cannot start in the past'));
    if (endDay != null && startDay.isAfter(endDay)) {
      return Future.error(const InvalidPauseException('a pause cannot end before it starts'));
    }
    return _database.transaction(() async {
      final pauses = _database.habitPauses;
      final overlapping =
          await (_database.select(pauses)..where(
                (pause) =>
                    pause.habitId.equals(habitId) &
                    (pause.endDay.isNull() | pause.endDay.isBiggerOrEqualValue(startDay.daysSinceEpoch)) &
                    (endDay == null
                        ? const Constant(true)
                        : pause.startDay.isSmallerOrEqualValue(endDay.daysSinceEpoch)),
              ))
              .get();
      if (overlapping.isNotEmpty) throw const InvalidPauseException('the habit is already paused then');
      await _database
          .into(pauses)
          .insert(
            HabitPausesCompanion.insert(
              habitId: habitId,
              startDay: startDay.daysSinceEpoch,
              endDay: Value(endDay?.daysSinceEpoch),
            ),
          );
    });
  }

  /// Ends the current pause on yesterday and cancels any planned one, so the habit counts again
  /// from today. Past pauses stay, so the history reads the same.
  Future<void> resumeHabit(int habitId) {
    final today = CalendarDay.fromDateTime(_now()).daysSinceEpoch;
    final pauses = _database.habitPauses;
    return _database.transaction(() async {
      await (_database.delete(
        pauses,
      )..where((pause) => pause.habitId.equals(habitId) & pause.startDay.isBiggerOrEqualValue(today))).go();
      await (_database.update(pauses)..where(
            (pause) =>
                pause.habitId.equals(habitId) & (pause.endDay.isNull() | pause.endDay.isBiggerOrEqualValue(today)),
          ))
          .write(HabitPausesCompanion(endDay: Value(today - 1)));
    });
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
