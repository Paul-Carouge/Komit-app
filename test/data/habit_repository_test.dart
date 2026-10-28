import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';

void main() {
  late AppDatabase database;
  late HabitRepository repository;
  final day = CalendarDay.fromDate(2026, 5, 1);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = HabitRepository(database);
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
}
