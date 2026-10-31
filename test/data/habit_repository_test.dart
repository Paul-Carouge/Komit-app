import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/habit_pause.dart';
import 'package:komit/domain/quantity_goal.dart';

void main() {
  late AppDatabase database;
  late HabitRepository repository;
  final day = CalendarDay.fromDate(2026, 5, 1);
  // "Now" is the end of the day after [day], so both can be logged.
  final now = DateTime(2026, 5, 2, 23, 59);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = HabitRepository(database, now: () => now);
  });
  tearDown(() => database.close());

  HabitDraft draftWith(List<ObjectiveDraft> objectives, {int? id}) => HabitDraft(
    id: id,
    title: '  Running ',
    description: '',
    colorArgb: 0xFFF141CE,
    iconName: 'footprints',
    reminderMinuteOfDay: 19 * 60,
    objectives: objectives,
  );

  test('creates a habit with ordered, trimmed objectives', () async {
    final habitId = await repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'Nothing ', colorArgb: 1),
        ObjectiveDraft(id: null, title: '5km', colorArgb: 2),
      ]),
    );

    final habit = (await repository.watchHabitWithObjectives(habitId).first)!;
    expect(habit.habit.title, 'Running');
    expect(habit.objectives.map((objective) => objective.title), ['Nothing', '5km']);
  });

  test('swapping two objective titles keeps their logs attached to the same ids', () async {
    final habitId = await repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'A', colorArgb: 1),
        ObjectiveDraft(id: null, title: 'B', colorArgb: 2),
      ]),
    );
    final [first, second] = (await repository.watchHabitWithObjectives(habitId).first)!.objectives;
    await repository.logObjectiveForDay(habitId: habitId, objectiveId: first.id, day: day);

    await repository.saveHabit(
      draftWith(id: habitId, [
        ObjectiveDraft(id: second.id, title: 'A', colorArgb: 2),
        ObjectiveDraft(id: first.id, title: 'B', colorArgb: 1),
      ]),
    );

    final habit = (await repository.watchHabitWithObjectives(habitId).first)!;
    expect(habit.objectives.map((objective) => objective.title), ['A', 'B']);
    expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, {day: first.id});
  });

  test('removing an objective deletes its logs only', () async {
    final habitId = await repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'A', colorArgb: 1),
        ObjectiveDraft(id: null, title: 'B', colorArgb: 2),
      ]),
    );
    final [first, second] = (await repository.watchHabitWithObjectives(habitId).first)!.objectives;
    await repository.logObjectiveForDay(habitId: habitId, objectiveId: first.id, day: day);
    await repository.logObjectiveForDay(habitId: habitId, objectiveId: second.id, day: day.addDays(1));

    await repository.saveHabit(draftWith(id: habitId, [ObjectiveDraft(id: second.id, title: 'B', colorArgb: 2)]));

    expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, {day.addDays(1): second.id});
  });

  test('logging the same day twice replaces the objective instead of duplicating', () async {
    final habitId = await repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'A', colorArgb: 1),
        ObjectiveDraft(id: null, title: 'B', colorArgb: 2),
      ]),
    );
    final [first, second] = (await repository.watchHabitWithObjectives(habitId).first)!.objectives;

    await repository.logObjectiveForDay(habitId: habitId, objectiveId: first.id, day: day);
    await repository.logObjectiveForDay(habitId: habitId, objectiveId: second.id, day: day);
    expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, {day: second.id});
    expect(await repository.watchLastLoggedDayByHabitId().first, {habitId: day});

    await repository.clearLogForDay(habitId: habitId, day: day);
    expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, isEmpty);
  });

  Future<int> saveHabitWithOneObjective(String title) => repository.saveHabit(
    HabitDraft(
      id: null,
      title: title,
      description: '',
      colorArgb: 1,
      iconName: 'pill',
      reminderMinuteOfDay: null,
      objectives: const [ObjectiveDraft(id: null, title: 'Yes', colorArgb: 1)],
    ),
  );

  test('the last logged day is the latest log, and a habit never logged is left out', () async {
    final loggedHabitId = await saveHabitWithOneObjective('Logged');
    await saveHabitWithOneObjective('Never logged');
    final objectiveId = (await repository.watchHabitWithObjectives(loggedHabitId).first)!.objectives.single.id;

    await repository.logObjectiveForDay(habitId: loggedHabitId, objectiveId: objectiveId, day: day.addDays(1));
    await repository.logObjectiveForDay(habitId: loggedHabitId, objectiveId: objectiveId, day: day);

    expect(await repository.watchLastLoggedDayByHabitId().first, {loggedHabitId: day.addDays(1)});
  });

  group('logObjectiveForDay invariants', () {
    test('throws InvalidLogException for a day after today and writes nothing', () async {
      final habitId = await saveHabitWithOneObjective('Running');
      final objective = (await repository.watchHabitWithObjectives(habitId).first)!.objectives.single;

      await expectLater(
        repository.logObjectiveForDay(habitId: habitId, objectiveId: objective.id, day: day.addDays(2)),
        throwsA(isA<InvalidLogException>()),
      );
      expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, isEmpty);

      await repository.logObjectiveForDay(habitId: habitId, objectiveId: objective.id, day: day);
      expect(await repository.watchObjectiveIdByDayForHabit(habitId).first, {day: objective.id});
    });

    test('throws InvalidLogException for an objective of another habit', () async {
      final runningId = await saveHabitWithOneObjective('Running');
      final readingId = await saveHabitWithOneObjective('Reading');
      final readingObjective = (await repository.watchHabitWithObjectives(readingId).first)!.objectives.single;

      await expectLater(
        repository.logObjectiveForDay(habitId: runningId, objectiveId: readingObjective.id, day: day),
        throwsA(isA<InvalidLogException>()),
      );
      expect(await repository.watchObjectiveIdByDayForHabit(runningId).first, isEmpty);
    });
  });

  test('reorderHabits persists the new order', () async {
    final firstId = await saveHabitWithOneObjective('A');
    final secondId = await saveHabitWithOneObjective('B');
    final thirdId = await saveHabitWithOneObjective('C');

    await repository.reorderHabits([thirdId, firstId, secondId]);

    final habits = await repository.watchActiveHabits().first;
    expect(habits.map((habit) => habit.habit.id), [thirdId, firstId, secondId]);
  });

  test('reorderObjectives persists the order, so the first objective is the one-tap default', () async {
    final habitId = await repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'A', colorArgb: 1),
        ObjectiveDraft(id: null, title: 'B', colorArgb: 2),
        ObjectiveDraft(id: null, title: 'C', colorArgb: 3),
      ]),
    );
    final otherHabitId = await saveHabitWithOneObjective('Other');
    final [a, b, c] = (await repository.watchHabitWithObjectives(habitId).first)!.objectives;
    final otherObjective = (await repository.watchHabitWithObjectives(otherHabitId).first)!.objectives.single;

    await repository.reorderObjectives(habitId: habitId, objectiveIdsInOrder: [c.id, a.id, b.id, otherObjective.id]);

    final reordered = (await repository.watchHabitWithObjectives(habitId).first)!.objectives;
    expect(reordered.map((objective) => objective.title), ['C', 'A', 'B']);
    // An objective of another habit is never touched.
    final other = (await repository.watchHabitWithObjectives(otherHabitId).first)!.objectives.single;
    expect(other.sortOrder, otherObjective.sortOrder);
  });

  test('archiving moves a habit out of the active list and back, keeping its logs', () async {
    final runningId = await saveHabitWithOneObjective('Running');
    final readingId = await saveHabitWithOneObjective('Reading');
    final objective = (await repository.watchHabitWithObjectives(runningId).first)!.objectives.single;
    await repository.logObjectiveForDay(habitId: runningId, objectiveId: objective.id, day: day);

    await repository.archiveHabit(runningId);
    expect((await repository.watchActiveHabits().first).map((habit) => habit.habit.id), [readingId]);
    final archived = await repository.watchArchivedHabits().first;
    expect(archived.single.habit.archivedAt, now);
    expect(await repository.watchObjectiveIdByDayForHabit(runningId).first, {day: objective.id});

    await repository.unarchiveHabit(runningId);
    expect(await repository.watchArchivedHabits().first, isEmpty);
    expect((await repository.watchActiveHabits().first).map((habit) => habit.habit.id), [runningId, readingId]);
  });

  test('saves the schedule, the weekly target and which objectives count as a success', () async {
    const mondayWednesdayFridayMask = 0x15;
    final habitId = await repository.saveHabit(
      const HabitDraft(
        id: null,
        title: 'Gym',
        description: '',
        colorArgb: 1,
        iconName: 'dumbbell',
        reminderMinuteOfDay: null,
        scheduledWeekdayMask: mondayWednesdayFridayMask,
        objectives: [
          ObjectiveDraft(id: null, title: 'Done', colorArgb: 1),
          ObjectiveDraft(id: null, title: 'Skipped', colorArgb: 2, countsAsSuccess: false),
        ],
      ),
    );
    var habit = (await repository.watchHabitWithObjectives(habitId).first)!;
    expect(habit.habit.scheduledWeekdayMask, mondayWednesdayFridayMask);
    expect(habit.habit.targetDaysPerWeek, isNull);
    expect(habit.objectives.map((objective) => objective.countsAsSuccess), [true, false]);

    await repository.saveHabit(
      HabitDraft(
        id: habitId,
        title: 'Gym',
        description: '',
        colorArgb: 1,
        iconName: 'dumbbell',
        reminderMinuteOfDay: null,
        targetDaysPerWeek: 3,
        objectives: [
          for (final objective in habit.objectives)
            ObjectiveDraft(id: objective.id, title: objective.title, colorArgb: objective.colorArgb),
        ],
      ),
    );
    habit = (await repository.watchHabitWithObjectives(habitId).first)!;
    expect(habit.habit.scheduledWeekdayMask, everyWeekdayMask);
    expect(habit.habit.targetDaysPerWeek, 3);
    expect(habit.objectives.map((objective) => objective.countsAsSuccess), [true, true]);
  });

  group('pauses', () {
    // "Now" is May 2; [day] is May 1.
    final today = CalendarDay.fromDateTime(now);

    Future<int> createHabit() => repository.saveHabit(
      draftWith(const [
        ObjectiveDraft(id: null, title: 'A', colorArgb: 1),
        ObjectiveDraft(id: null, title: 'B', colorArgb: 2),
      ]),
    );
    Future<HabitWithObjectives> read(int habitId) async => (await repository.watchHabitWithObjectives(habitId).first)!;

    test('a paused habit keeps one entry per objective and is not scheduled while paused', () async {
      final habitId = await createHabit();
      await repository.pauseHabit(habitId, startDay: today, endDay: today.addDays(6));
      await repository.pauseHabit(habitId, startDay: today.addDays(10));

      final habit = await read(habitId);
      expect(habit.objectives.map((objective) => objective.title), ['A', 'B']);
      expect(habit.pauses, [
        HabitPause(startDay: today, endDay: today.addDays(6)),
        HabitPause(startDay: today.addDays(10)),
      ]);
      expect(isHabitScheduledOn(habit, today), isFalse);
      expect(isHabitScheduledOn(habit, today.addDays(7)), isTrue);
      expect(isHabitScheduledOn(habit, today.addDays(400)), isFalse);
      expect((await repository.watchAllHabits().first).single.objectives, hasLength(2));
    });

    test('refuses a pause in the past, ending before it starts or overlapping another', () async {
      final habitId = await createHabit();
      await repository.pauseHabit(habitId, startDay: today.addDays(2), endDay: today.addDays(5));

      for (final (startDay, endDay) in [
        (today.addDays(-1), null),
        (today.addDays(3), today.addDays(1)),
        (today, today.addDays(2)),
        (today.addDays(5), null),
      ]) {
        await expectLater(
          repository.pauseHabit(habitId, startDay: startDay, endDay: endDay),
          throwsA(isA<InvalidPauseException>()),
        );
      }
    });

    test('resuming ends only the current pause on yesterday, keeping past and planned ones', () async {
      final habitId = await createHabit();
      // Inserted directly: the repository refuses pauses that start in the past.
      for (final (startDay, endDay) in [(today.addDays(-30), today.addDays(-20)), (today.addDays(-3), null)]) {
        await database
            .into(database.habitPauses)
            .insert(
              HabitPausesCompanion.insert(
                habitId: habitId,
                startDay: startDay.daysSinceEpoch,
                endDay: Value(endDay?.daysSinceEpoch),
              ),
            );
      }
      await database
          .into(database.habitPauses)
          .insert(HabitPausesCompanion.insert(habitId: habitId, startDay: today.addDays(5).daysSinceEpoch));

      await repository.resumeHabit(habitId);

      expect((await read(habitId)).pauses, [
        HabitPause(startDay: today.addDays(-30), endDay: today.addDays(-20)),
        HabitPause(startDay: today.addDays(-3), endDay: today.addDays(-1)),
        HabitPause(startDay: today.addDays(5)),
      ]);

      // With no pause holding today, resuming cancels the earliest planned one.
      await repository.resumeHabit(habitId);
      expect((await read(habitId)).pauses, hasLength(2));
    });

    test('resuming a pause that starts today removes it', () async {
      final habitId = await createHabit();
      await repository.pauseHabit(habitId, startDay: today);
      await repository.resumeHabit(habitId);
      expect((await read(habitId)).pauses, isEmpty);
    });

    test('rest days are saved for a daily habit and dropped with a weekly target', () async {
      final habitId = await repository.saveHabit(
        const HabitDraft(
          id: null,
          title: 'Walk',
          description: '',
          colorArgb: 1,
          iconName: 'footprints',
          reminderMinuteOfDay: null,
          objectives: [ObjectiveDraft(id: null, title: 'Done', colorArgb: 1)],
          restDaysPerWeek: 2,
        ),
      );
      expect((await read(habitId)).habit.restDaysPerWeek, 2);

      await repository.saveHabit(
        HabitDraft(
          id: habitId,
          title: 'Walk',
          description: '',
          colorArgb: 1,
          iconName: 'footprints',
          reminderMinuteOfDay: null,
          objectives: [ObjectiveDraft(id: (await read(habitId)).objectives.single.id, title: 'Done', colorArgb: 1)],
          targetDaysPerWeek: 3,
          restDaysPerWeek: 2,
        ),
      );
      expect((await read(habitId)).habit.restDaysPerWeek, 0);
    });
  });

  test('watchHabitWithObjectives returns null for an unknown habit', () async {
    expect(await repository.watchHabitWithObjectives(42).first, isNull);
  });

  group('quantity habits', () {
    HabitDraft quantityDraft({int? id, double target = 8, List<ObjectiveDraft> objectives = const []}) => HabitDraft(
      id: id,
      title: 'Water',
      description: '',
      colorArgb: 0xFF2196F3,
      iconName: 'glassWater',
      reminderMinuteOfDay: null,
      objectives: objectives,
      quantityGoal: QuantityGoal(unit: ' glasses ', target: target, step: 1),
    );

    test('keeps one hidden objective named after the unit, in the habit color', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      final habit = (await repository.watchHabitWithObjectives(habitId).first)!;
      expect(habit.quantityGoal?.unit, 'glasses');
      expect(habit.objectives.single.title, 'glasses');
      expect(habit.objectives.single.colorArgb, 0xFF2196F3);
    });

    test('a day counts only once its amount reaches the target, re-read when the target changes', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      await repository.logQuantityForDay(habitId: habitId, quantity: 5, day: day);
      await repository.logQuantityForDay(habitId: habitId, quantity: 8, day: day.addDays(1));

      expect(await repository.watchQuantityByDayForHabit(habitId).first, {day: 5, day.addDays(1): 8});
      expect((await repository.watchObjectiveIdByDayForHabit(habitId).first).keys, [day.addDays(1)]);
      expect((await repository.watchObjectiveIdByDayForAllHabitsSince(day).first)[habitId]?.keys, [day.addDays(1)]);
      var habit = (await repository.watchHabitWithObjectives(habitId).first)!;
      var streak = streakSummaryOf(
        habit,
        await repository.watchObjectiveIdByDayForHabit(habitId).first,
        today: day.addDays(1),
      );
      expect((streak.currentStreakLength, streak.bestStreakLength), (1, 1));

      await repository.saveHabit(
        quantityDraft(
          id: habitId,
          target: 5,
          objectives: [ObjectiveDraft(id: habit.objectives.single.id, title: 'glasses', colorArgb: 1)],
        ),
      );
      habit = (await repository.watchHabitWithObjectives(habitId).first)!;
      streak = streakSummaryOf(
        habit,
        await repository.watchObjectiveIdByDayForHabit(habitId).first,
        today: day.addDays(1),
      );
      expect((streak.currentStreakLength, streak.bestStreakLength), (2, 2));
      expect(habit.objectives, hasLength(1));
    });

    test('rounds amounts so repeated small steps reach the target exactly', () async {
      final habitId = await repository.saveHabit(quantityDraft(target: 0.3));
      var amount = 0.0;
      for (var step = 0; step < 3; step++) {
        amount += 0.1;
        await repository.logQuantityForDay(habitId: habitId, quantity: amount, day: day);
      }
      expect((await repository.watchQuantityByDayForHabit(habitId).first)[day], 0.3);
      expect((await repository.watchObjectiveIdByDayForHabit(habitId).first).keys, [day]);
    });

    test('two steps added without waiting both count, and each returns the amount before it', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      await repository.logQuantityForDay(habitId: habitId, quantity: 3, day: day);

      final previousQuantities = await Future.wait([
        repository.addQuantityStepForDay(habitId: habitId, day: day),
        repository.addQuantityStepForDay(habitId: habitId, day: day.addDays(1)),
        repository.addQuantityStepForDay(habitId: habitId, day: day),
      ]);

      expect(previousQuantities, [3, null, 4]);
      expect(await repository.watchQuantityByDayForHabit(habitId).first, {day: 5, day.addDays(1): 1});
      await expectLater(
        repository.addQuantityStepForDay(habitId: habitId, day: day.addDays(2)),
        throwsA(isA<InvalidLogException>()),
      );
    });

    test('"Done" raises the amount to the target and never lowers a bigger one', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      final objectiveId = (await repository.watchHabitWithObjectives(habitId).first)!.objectives.single.id;
      await repository.logQuantityForDay(habitId: habitId, quantity: 3, day: day);
      await repository.logObjectiveForDay(habitId: habitId, objectiveId: objectiveId, day: day);
      await repository.logQuantityForDay(habitId: habitId, quantity: 11, day: day.addDays(1));
      await repository.logObjectiveForDay(habitId: habitId, objectiveId: objectiveId, day: day.addDays(1));

      expect(await repository.watchQuantityByDayForHabit(habitId).first, {day: 8, day.addDays(1): 11});
    });

    test('refuses a future day, an amount not above zero and an objectives habit', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      final objectivesHabitId = await repository.saveHabit(
        draftWith(const [ObjectiveDraft(id: null, title: 'Yes', colorArgb: 1)]),
      );
      for (final write in [
        () => repository.logQuantityForDay(habitId: habitId, quantity: 1, day: day.addDays(2)),
        () => repository.logQuantityForDay(habitId: habitId, quantity: 0, day: day),
        () => repository.logQuantityForDay(habitId: habitId, quantity: maximumQuantityValue * 2, day: day),
        () => repository.logQuantityForDay(habitId: objectivesHabitId, quantity: 1, day: day),
      ]) {
        await expectLater(write(), throwsA(isA<InvalidLogException>()));
      }
      expect(await database.select(database.habitLogs).get(), isEmpty);
    });

    test('a habit keeps its kind once it has a log, and may change it before', () async {
      final habitId = await repository.saveHabit(quantityDraft());
      final objectiveDraft = [const ObjectiveDraft(id: null, title: 'Yes', colorArgb: 1)];
      await repository.saveHabit(draftWith(objectiveDraft, id: habitId));
      expect((await repository.watchHabitWithObjectives(habitId).first)!.quantityGoal, isNull);

      final objectiveId = (await repository.watchHabitWithObjectives(habitId).first)!.objectives.single.id;
      await repository.logObjectiveForDay(habitId: habitId, objectiveId: objectiveId, day: day);
      await expectLater(repository.saveHabit(quantityDraft(id: habitId)), throwsA(isA<HabitKindChangeException>()));
      expect((await repository.watchHabitWithObjectives(habitId).first)!.quantityGoal, isNull);
    });
  });
}
