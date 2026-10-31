import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../core/calendar_day.dart';
import '../../domain/habit_pause.dart';
import '../../domain/habit_schedule.dart';
import '../../domain/habit_statistics.dart';
import '../../domain/quantity_goal.dart';
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

  /// Null for an objectives habit (docs/adr/0008).
  QuantityGoal? get quantityGoal => quantityGoalOf(habit);

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

/// Null for an objectives habit; the three columns are set together.
QuantityGoal? quantityGoalOf(HabitRow habit) =>
    switch ((habit.quantityUnit, habit.quantityTarget, habit.quantityStep)) {
      (final unit?, final target?, final step?) => QuantityGoal(unit: unit, target: target, step: step),
      _ => null,
    };

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
    this.quantityGoal,
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

  /// Set for a quantity habit, whose [objectives] then hold at most the id of its one hidden
  /// objective (docs/adr/0008).
  final QuantityGoal? quantityGoal;
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

/// Thrown when a habit with logs would switch between objectives and a quantity: its logs
/// would lose their meaning (docs/adr/0008).
class HabitKindChangeException implements Exception {
  const HabitKindChangeException();

  @override
  String toString() => 'HabitKindChangeException: a habit with logs keeps its kind';
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

  /// Every logged day of [habitId], mapped to the chosen objective id. A quantity day below its
  /// target is left out: it counts like a day without a log everywhere (docs/adr/0008).
  Stream<Map<CalendarDay, int>> watchObjectiveIdByDayForHabit(int habitId) =>
      _watchObjectiveIdByDayByHabitId(_database.habitLogs.habitId.equals(habitId))
          .map((logsByHabitId) => logsByHabitId[habitId] ?? const {});

  /// Logs of every habit since [firstDay] included: habit id -> day -> objective id. Quantity
  /// days below their target are left out, as in [watchObjectiveIdByDayForHabit].
  Stream<Map<int, Map<CalendarDay, int>>> watchObjectiveIdByDayForAllHabitsSince(CalendarDay firstDay) =>
      _watchObjectiveIdByDayByHabitId(_database.habitLogs.day.isBiggerOrEqualValue(firstDay.daysSinceEpoch));

  /// Every log of every habit, archived ones included: habit id -> day -> objective id. Quantity
  /// days below their target are left out, as in [watchObjectiveIdByDayForHabit].
  Stream<Map<int, Map<CalendarDay, int>>> watchObjectiveIdByDayForAllHabits() =>
      _watchObjectiveIdByDayByHabitId(const Constant(true));

  Stream<Map<int, Map<CalendarDay, int>>> _watchObjectiveIdByDayByHabitId(Expression<bool> logFilter) {
    final logs = _database.habitLogs;
    final habits = _database.habits;
    // Decided on read, so a changed target re-reads every past day.
    final isObjectiveLogOrReachedQuantity =
        habits.quantityTarget.isNull() | logs.quantity.isBiggerOrEqual(habits.quantityTarget);
    final query = _database.select(logs).join([innerJoin(habits, habits.id.equalsExp(logs.habitId), useColumns: false)])
      ..where(logFilter & isObjectiveLogOrReachedQuantity);
    return query.watch().map((rows) {
      final logsByHabitId = <int, Map<CalendarDay, int>>{};
      for (final row in rows) {
        final log = row.readTable(logs);
        logsByHabitId.putIfAbsent(log.habitId, () => {})[CalendarDay(log.day)] = log.objectiveId;
      }
      return logsByHabitId;
    });
  }

  /// The amount logged on each day of quantity habit [habitId], reached or not.
  Stream<Map<CalendarDay, double>> watchQuantityByDayForHabit(int habitId) =>
      _watchQuantityByDayByHabitId(_database.habitLogs.habitId.equals(habitId))
          .map((quantitiesByHabitId) => quantitiesByHabitId[habitId] ?? const {});

  /// Amounts of every quantity habit since [firstDay] included: habit id -> day -> amount.
  Stream<Map<int, Map<CalendarDay, double>>> watchQuantityByDayForAllHabitsSince(CalendarDay firstDay) =>
      _watchQuantityByDayByHabitId(_database.habitLogs.day.isBiggerOrEqualValue(firstDay.daysSinceEpoch));

  Stream<Map<int, Map<CalendarDay, double>>> _watchQuantityByDayByHabitId(Expression<bool> logFilter) {
    final logs = _database.habitLogs;
    final query = _database.selectOnly(logs)
      ..addColumns([logs.habitId, logs.day, logs.quantity])
      ..where(logFilter & logs.quantity.isNotNull());
    return query.watch().map((rows) {
      final quantitiesByHabitId = <int, Map<CalendarDay, double>>{};
      for (final row in rows) {
        quantitiesByHabitId.putIfAbsent(row.read(logs.habitId)!, () => {})[CalendarDay(row.read(logs.day)!)] = row.read(
          logs.quantity,
        )!;
      }
      return quantitiesByHabitId;
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
  /// Objectives missing from [draft] are deleted together with their logs. Throws
  /// [HabitKindChangeException] when a habit with logs would change kind.
  Future<int> saveHabit(HabitDraft draft) {
    final quantityGoal = draft.quantityGoal;
    // A quantity habit's one hidden objective follows its unit and color (docs/adr/0008).
    final objectiveDrafts = quantityGoal == null
        ? draft.objectives
        : [ObjectiveDraft(id: draft.objectives.firstOrNull?.id, title: quantityGoal.unit, colorArgb: draft.colorArgb)];
    return _database.transaction(() async {
      if (draft.id case final existingHabitId?) {
        await _ensureKindCanChange(existingHabitId, isQuantity: quantityGoal != null);
      }
      final habitColumns = HabitsCompanion(
        title: Value(draft.title.trim()),
        description: Value(draft.description.trim()),
        colorArgb: Value(draft.colorArgb),
        iconName: Value(draft.iconName),
        reminderMinuteOfDay: Value(draft.reminderMinuteOfDay),
        scheduledWeekdayMask: Value(draft.scheduledWeekdayMask),
        targetDaysPerWeek: Value(draft.targetDaysPerWeek),
        restDaysPerWeek: Value(draft.targetDaysPerWeek == null ? draft.restDaysPerWeek : 0),
        quantityUnit: Value(quantityGoal?.unit.trim()),
        quantityTarget: Value(switch (quantityGoal) {
          final goal? => roundQuantity(goal.target),
          null => null,
        }),
        quantityStep: Value(switch (quantityGoal) {
          final goal? => roundQuantity(goal.step),
          null => null,
        }),
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

      final keptObjectiveIds = [for (final objective in objectiveDrafts) ?objective.id];
      await (_database.delete(
        _database.objectives,
      )..where((objective) => objective.habitId.equals(habitId) & objective.id.isNotIn(keptObjectiveIds))).go();
      // Two passes avoid a transient unique (habitId, title) clash when titles are swapped.
      for (final objectiveId in keptObjectiveIds) {
        await (_database.update(_database.objectives)..where((objective) => objective.id.equals(objectiveId))).write(
          ObjectivesCompanion(title: Value('\u{FFFF}$objectiveId')),
        );
      }
      for (final (sortOrder, objective) in objectiveDrafts.indexed) {
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

  Future<void> _ensureKindCanChange(int habitId, {required bool isQuantity}) async {
    final habit = await (_database.select(
      _database.habits,
    )..where((habit) => habit.id.equals(habitId))).getSingleOrNull();
    if (habit == null || (habit.quantityTarget != null) == isQuantity) return;
    final firstLog =
        await (_database.select(_database.habitLogs)
              ..where((log) => log.habitId.equals(habitId))
              ..limit(1))
            .getSingleOrNull();
    if (firstLog != null) throw const HabitKindChangeException();
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

  /// Persists [objectiveIdsInOrder] as [habitId]'s objective order, atomically. The first
  /// objective is the one a single tap logs.
  Future<void> reorderObjectives({required int habitId, required List<int> objectiveIdsInOrder}) {
    return _database.transaction(() async {
      for (final (sortOrder, objectiveId) in objectiveIdsInOrder.indexed) {
        await (_database.update(_database.objectives)
              ..where((objective) => objective.id.equals(objectiveId) & objective.habitId.equals(habitId)))
            .write(ObjectivesCompanion(sortOrder: Value(sortOrder)));
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

  /// Ends the pause holding today on yesterday (or removes it when it started today); without
  /// one, cancels the earliest planned pause. Other pauses stay, so the history reads the same.
  Future<void> resumeHabit(int habitId) {
    final today = CalendarDay.fromDateTime(_now()).daysSinceEpoch;
    final pauses = _database.habitPauses;
    return _database.transaction(() async {
      final pause =
          await (_database.select(pauses)
                ..where(
                  (pause) =>
                      pause.habitId.equals(habitId) &
                      (pause.endDay.isNull() | pause.endDay.isBiggerOrEqualValue(today)),
                )
                ..orderBy([(pause) => OrderingTerm.asc(pause.startDay)])
                ..limit(1))
              .getSingleOrNull();
      if (pause == null) return;
      final whereThisPause = _database.delete(pauses)..where((row) => row.id.equals(pause.id));
      if (pause.startDay >= today) {
        await whereThisPause.go();
      } else {
        await (_database.update(
          pauses,
        )..where((row) => row.id.equals(pause.id))).write(HabitPausesCompanion(endDay: Value(today - 1)));
      }
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
  ///
  /// On a quantity habit this is "Done" (reminders, the widget): it raises the day's amount to
  /// the target and never lowers a bigger one (docs/adr/0008).
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
      final habit = await (_database.select(_database.habits)..where((habit) => habit.id.equals(habitId))).getSingle();
      double? quantity;
      if (habit.quantityTarget case final target?) {
        final currentQuantity = await _quantityOn(habitId, day);
        quantity = currentQuantity != null && currentQuantity > target ? currentQuantity : target;
      }
      await _upsertLog(habitId: habitId, objectiveId: objectiveId, day: day, quantity: quantity);
    });
  }

  /// Sets the amount of quantity habit [habitId] on [day]. Throws [InvalidLogException] for a
  /// future day, an objectives habit, or an amount not above zero or above
  /// [maximumQuantityValue]; clearing a day goes through [clearLogForDay].
  Future<void> logQuantityForDay({required int habitId, required double quantity, required CalendarDay day}) {
    if (day.isAfter(CalendarDay.fromDateTime(_now()))) {
      return Future.error(const InvalidLogException('cannot log a future day'));
    }
    final roundedQuantity = roundQuantity(quantity);
    if (!roundedQuantity.isFinite || roundedQuantity <= 0 || roundedQuantity > maximumQuantityValue) {
      return Future.error(InvalidLogException('invalid amount $quantity'));
    }
    return _database.transaction(() async {
      final habit = await (_database.select(
        _database.habits,
      )..where((habit) => habit.id.equals(habitId))).getSingleOrNull();
      if (habit == null || habit.quantityTarget == null) {
        throw InvalidLogException('habit $habitId does not track an amount');
      }
      final objective =
          await (_database.select(_database.objectives)
                ..where((objective) => objective.habitId.equals(habitId))
                ..limit(1))
              .getSingle();
      await _upsertLog(habitId: habitId, objectiveId: objective.id, day: day, quantity: roundedQuantity);
    });
  }

  /// Adds one step of quantity habit [habitId] to [day], read and written in one transaction so
  /// fast taps all count; capped at [maximumQuantityValue]. Returns the amount before, for "Undo".
  /// Throws [InvalidLogException] for a future day or an objectives habit.
  Future<double?> addQuantityStepForDay({required int habitId, required CalendarDay day}) {
    if (day.isAfter(CalendarDay.fromDateTime(_now()))) {
      return Future.error(const InvalidLogException('cannot log a future day'));
    }
    return _database.transaction(() async {
      final habit = await (_database.select(
        _database.habits,
      )..where((habit) => habit.id.equals(habitId))).getSingleOrNull();
      final step = habit?.quantityStep;
      if (step == null) throw InvalidLogException('habit $habitId does not track an amount');
      final objective =
          await (_database.select(_database.objectives)
                ..where((objective) => objective.habitId.equals(habitId))
                ..limit(1))
              .getSingle();
      final previousQuantity = await _quantityOn(habitId, day);
      final quantity = math.min(roundQuantity((previousQuantity ?? 0) + step), maximumQuantityValue);
      await _upsertLog(habitId: habitId, objectiveId: objective.id, day: day, quantity: quantity);
      return previousQuantity;
    });
  }

  Future<double?> _quantityOn(int habitId, CalendarDay day) async {
    final log = await (_database.select(
      _database.habitLogs,
    )..where((log) => log.habitId.equals(habitId) & log.day.equals(day.daysSinceEpoch))).getSingleOrNull();
    return log?.quantity;
  }

  Future<void> _upsertLog({
    required int habitId,
    required int objectiveId,
    required CalendarDay day,
    required double? quantity,
  }) => _database
      .into(_database.habitLogs)
      .insert(
        HabitLogsCompanion.insert(
          habitId: habitId,
          objectiveId: objectiveId,
          day: day.daysSinceEpoch,
          quantity: Value(quantity),
        ),
        onConflict: DoUpdate(
          (_) => HabitLogsCompanion(objectiveId: Value(objectiveId), quantity: Value(quantity)),
          target: [_database.habitLogs.habitId, _database.habitLogs.day],
        ),
      );

  Future<void> clearLogForDay({required int habitId, required CalendarDay day}) {
    return (_database.delete(
      _database.habitLogs,
    )..where((log) => log.habitId.equals(habitId) & log.day.equals(day.daysSinceEpoch))).go();
  }
}
