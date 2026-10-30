// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'migration from v1 to v2 keeps every row and applies the new defaults',
    () async {
      // v1 stores dates as Unix seconds; the v2 snapshot classes read them back as DateTime.
      const createdAt = 1767200328;
      DateTime asDateTime(int unixSeconds) =>
          DateTime.fromMillisecondsSinceEpoch(
            unixSeconds * Duration.millisecondsPerSecond,
          );
      final oldHabitsData = <v1.HabitsData>[
        const v1.HabitsData(
          id: 1,
          title: 'Running',
          description: 'Outside',
          colorArgb: 0xFFF141CE,
          iconName: 'footprints',
          reminderMinuteOfDay: 19 * 60,
          sortOrder: 0,
          createdAt: createdAt,
        ),
        const v1.HabitsData(
          id: 2,
          title: 'Reading',
          description: '',
          colorArgb: 0xFF7E57C2,
          iconName: 'book',
          sortOrder: 1,
          createdAt: createdAt,
        ),
      ];
      final expectedNewHabitsData = <v2.HabitsData>[
        for (final habit in oldHabitsData)
          v2.HabitsData(
            id: habit.id,
            title: habit.title,
            description: habit.description,
            colorArgb: habit.colorArgb,
            iconName: habit.iconName,
            reminderMinuteOfDay: habit.reminderMinuteOfDay,
            sortOrder: habit.sortOrder,
            createdAt: asDateTime(habit.createdAt),
            scheduledWeekdayMask: everyWeekdayMask,
          ),
      ];

      final oldObjectivesData = <v1.ObjectivesData>[
        const v1.ObjectivesData(
          id: 1,
          habitId: 1,
          title: 'Nothing',
          colorArgb: 1,
          sortOrder: 0,
        ),
        const v1.ObjectivesData(
          id: 2,
          habitId: 1,
          title: '5km',
          colorArgb: 2,
          sortOrder: 1,
        ),
        const v1.ObjectivesData(
          id: 3,
          habitId: 2,
          title: 'Yes',
          colorArgb: 3,
          sortOrder: 0,
        ),
      ];
      final expectedNewObjectivesData = <v2.ObjectivesData>[
        for (final objective in oldObjectivesData)
          v2.ObjectivesData(
            id: objective.id,
            habitId: objective.habitId,
            title: objective.title,
            colorArgb: objective.colorArgb,
            sortOrder: objective.sortOrder,
            countsAsSuccess: true,
          ),
      ];

      final oldHabitLogsData = <v1.HabitLogsData>[
        const v1.HabitLogsData(id: 1, habitId: 1, objectiveId: 1, day: 20000),
        const v1.HabitLogsData(id: 2, habitId: 1, objectiveId: 2, day: 20001),
        const v1.HabitLogsData(id: 3, habitId: 2, objectiveId: 3, day: 20001),
      ];
      final expectedNewHabitLogsData = <v2.HabitLogsData>[
        for (final log in oldHabitLogsData)
          v2.HabitLogsData(
            id: log.id,
            habitId: log.habitId,
            objectiveId: log.objectiveId,
            day: log.day,
          ),
      ];

      final oldNotesData = <v1.NotesData>[
        const v1.NotesData(
          id: 1,
          content: 'Felt great',
          createdAt: createdAt,
          updatedAt: createdAt + 60,
        ),
      ];
      final expectedNewNotesData = <v2.NotesData>[
        for (final note in oldNotesData)
          v2.NotesData(
            id: note.id,
            content: note.content,
            createdAt: asDateTime(note.createdAt),
            updatedAt: asDateTime(note.updatedAt),
          ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: 2,
        createOld: v1.DatabaseAtV1.new,
        createNew: v2.DatabaseAtV2.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.habits, oldHabitsData);
          batch.insertAll(oldDb.objectives, oldObjectivesData);
          batch.insertAll(oldDb.habitLogs, oldHabitLogsData);
          batch.insertAll(oldDb.notes, oldNotesData);
        },
        validateItems: (newDb) async {
          final habits = await newDb.select(newDb.habits).get();
          expect(habits, expectedNewHabitsData);
          expect(
            habits.map((habit) => habit.targetDaysPerWeek),
            everyElement(isNull),
          );
          expect(habits.map((habit) => habit.archivedAt), everyElement(isNull));
          expect(
            await newDb.select(newDb.objectives).get(),
            expectedNewObjectivesData,
          );
          expect(
            await newDb.select(newDb.habitLogs).get(),
            expectedNewHabitLogsData,
          );
          expect(await newDb.select(newDb.notes).get(), expectedNewNotesData);
        },
      );
    },
  );

  test(
    'migration from v2 to v3 keeps every habit, with no rest day and no pause',
    () async {
      final createdAt = DateTime(2026, 1, 1);
      final oldHabitsData = <v2.HabitsData>[
        v2.HabitsData(
          id: 1,
          title: 'Morning run',
          description: '',
          colorArgb: 1,
          iconName: 'run',
          reminderMinuteOfDay: 480,
          sortOrder: 0,
          createdAt: createdAt,
          scheduledWeekdayMask: 0x15,
          targetDaysPerWeek: null,
          archivedAt: null,
        ),
        v2.HabitsData(
          id: 2,
          title: 'Read',
          description: 'Before bed',
          colorArgb: 2,
          iconName: 'book',
          reminderMinuteOfDay: null,
          sortOrder: 1,
          createdAt: createdAt,
          scheduledWeekdayMask: 0x7F,
          targetDaysPerWeek: 3,
          archivedAt: createdAt,
        ),
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.habits, oldHabitsData);
        },
        validateItems: (newDb) async {
          final habits = await newDb.select(newDb.habits).get();
          expect(habits.map((habit) => habit.id), [1, 2]);
          expect(habits.map((habit) => habit.title), ['Morning run', 'Read']);
          expect(habits.map((habit) => habit.targetDaysPerWeek), [null, 3]);
          expect(habits.map((habit) => habit.restDaysPerWeek), [0, 0]);
          expect(await newDb.select(newDb.habitPauses).get(), isEmpty);
        },
      );
    },
  );
}
