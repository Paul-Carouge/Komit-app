import 'package:drift/drift.dart';

import '../../core/calendar_day.dart';
import '../backup/backup_snapshot.dart';
import '../database/app_database.dart';

class BackupRepository {
  BackupRepository(this._database);

  final AppDatabase _database;

  Future<BackupSnapshot> readSnapshot({required String? userName}) {
    return _database.transaction(() async {
      final habits = await (_database.select(
        _database.habits,
      )..orderBy([(habit) => OrderingTerm.asc(habit.sortOrder), (habit) => OrderingTerm.asc(habit.id)])).get();
      final objectives = await (_database.select(
        _database.objectives,
      )..orderBy([(objective) => OrderingTerm.asc(objective.sortOrder)])).get();
      final logs = await (_database.select(_database.habitLogs)..orderBy([(log) => OrderingTerm.asc(log.day)])).get();
      final notes = await (_database.select(
        _database.notes,
      )..orderBy([(note) => OrderingTerm.asc(note.createdAt)])).get();

      final loggedDaysByObjectiveId = <int, List<CalendarDay>>{};
      for (final log in logs) {
        loggedDaysByObjectiveId.putIfAbsent(log.objectiveId, () => []).add(CalendarDay(log.day));
      }
      return BackupSnapshot(
        userName: userName,
        habits: [
          for (final habit in habits)
            BackupHabit(
              title: habit.title,
              description: habit.description,
              colorArgb: habit.colorArgb,
              iconName: habit.iconName,
              reminderMinuteOfDay: habit.reminderMinuteOfDay,
              createdAt: habit.createdAt,
              objectives: [
                for (final objective in objectives.where((objective) => objective.habitId == habit.id))
                  BackupObjective(
                    title: objective.title,
                    colorArgb: objective.colorArgb,
                    loggedDays: loggedDaysByObjectiveId[objective.id] ?? const [],
                  ),
              ],
            ),
        ],
        notes: [
          for (final note in notes)
            BackupNote(content: note.content, createdAt: note.createdAt, updatedAt: note.updatedAt),
        ],
      );
    });
  }

  /// Replaces every habit, log and note in one transaction: on any failure nothing changes.
  Future<void> replaceAllDataWith(BackupSnapshot snapshot) {
    return _database.transaction(() async {
      await _database.delete(_database.habitLogs).go();
      await _database.delete(_database.objectives).go();
      await _database.delete(_database.habits).go();
      await _database.delete(_database.notes).go();

      for (final (habitSortOrder, habit) in snapshot.habits.indexed) {
        final habitId = await _database
            .into(_database.habits)
            .insert(
              HabitsCompanion.insert(
                title: habit.title,
                description: Value(habit.description),
                colorArgb: habit.colorArgb,
                iconName: habit.iconName,
                reminderMinuteOfDay: Value(habit.reminderMinuteOfDay),
                sortOrder: Value(habitSortOrder),
                createdAt: habit.createdAt,
              ),
            );
        for (final (objectiveSortOrder, objective) in habit.objectives.indexed) {
          final objectiveId = await _database
              .into(_database.objectives)
              .insert(
                ObjectivesCompanion.insert(
                  habitId: habitId,
                  title: objective.title,
                  colorArgb: objective.colorArgb,
                  sortOrder: objectiveSortOrder,
                ),
              );
          await _database.batch((batch) {
            batch.insertAll(_database.habitLogs, [
              for (final day in objective.loggedDays)
                HabitLogsCompanion.insert(habitId: habitId, objectiveId: objectiveId, day: day.daysSinceEpoch),
            ]);
          });
        }
      }
      await _database.batch((batch) {
        batch.insertAll(_database.notes, [
          for (final note in snapshot.notes)
            NotesCompanion.insert(content: note.content, createdAt: note.createdAt, updatedAt: note.updatedAt),
        ]);
      });
    });
  }
}
