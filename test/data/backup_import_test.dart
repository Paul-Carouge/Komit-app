import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/backup/backup_json_codec.dart';
import 'package:komit/data/backup/backup_snapshot.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/backup_repository.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/habit_statistics.dart';

/// Same shape as a file exported by the original Komit app (format v1).
String buildLegacyBackupJson({List<Map<String, Object?>>? extraLogs}) => jsonEncode({
  'version': 1,
  'timestamp': '2026-10-28T21:41:45.654700',
  'habits': [
    {
      'id': 1,
      'title': 'Running',
      'description': '',
      'createdAt': '2025-12-31T16:58:48.460911',
      'colorHex': 'FFF141CE',
      'iconCode': 'footprints',
      'reminderTime': '2024-01-01T19:00:00.000',
      'objectives': [
        {'title': 'Nothing', 'colorHex': 'FF7E57C2'},
        {'title': '2-5km', 'colorHex': 'FFD4E157'},
      ],
    },
    {
      'id': 8,
      'title': 'No spend challenge ',
      'description': '',
      'createdAt': '2026-03-21T10:00:00.000',
      'colorHex': 'FFF9B125',
      'iconCode': 'dollar',
      'reminderTime': null,
      'objectives': [
        {'title': 'Spend ', 'colorHex': 'FFEF5350'},
      ],
    },
  ],
  'logs': [
    {
      'id': 1,
      'date': '2025-12-31T00:00:00.000',
      'habitId': 1,
      'objectiveTitle': 'Nothing',
      'objectiveColorHex': 'FF7E57C2',
    },
    {
      'id': 2,
      'date': '2026-01-01T00:00:00.000',
      'habitId': 1,
      'objectiveTitle': '2-5km',
      'objectiveColorHex': 'FFD4E157',
    },
    {
      'id': 3,
      'date': '2026-03-21T00:00:00.000',
      'habitId': 8,
      'objectiveTitle': 'Spend ',
      'objectiveColorHex': 'FFEF5350',
    },
    // Objective deleted in the old app after being logged.
    {
      'id': 4,
      'date': '2026-01-02T00:00:00.000',
      'habitId': 1,
      'objectiveTitle': 'Marathon',
      'objectiveColorHex': 'FF000000',
    },
    ...?extraLogs,
  ],
  'notes': <Object?>[],
  'prefs': {'user_name': 'Alex', 'onboarding_complete': true},
});

/// A v2 file written before the schedule, archive and success keys existed.
String buildOldCurrentBackupJson({String loggedDay = '2026-10-01', String? description, String? noteContent}) =>
    jsonEncode({
      'format': 'komit-backup',
      'version': 2,
      'exportedAt': '2026-10-28T21:41:45.000Z',
      'userName': 'Alex',
      'habits': [
        {
          'title': 'Running',
          'description': description ?? '',
          'colorArgb': 0xFFF141CE,
          'iconName': 'footprints',
          'reminderMinuteOfDay': null,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'objectives': [
            {
              'title': '5km',
              'colorArgb': 0xFFD4E157,
              'loggedDays': [loggedDay],
            },
          ],
        },
      ],
      'notes': [
        {
          'content': noteContent ?? 'Felt great',
          'createdAt': '2026-10-01T08:00:00.000Z',
          'updatedAt': '2026-10-01T08:00:00.000Z',
        },
      ],
    });

final today = CalendarDay.fromDate(2026, 10, 29);

void main() {
  group('decodeBackupSnapshotFromJson with a legacy v1 file', () {
    test('keeps every habit, objective and log, with trimmed titles', () {
      final snapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson(), today: today);

      expect(snapshot.userName, 'Alex');
      expect(snapshot.habits.map((habit) => habit.title), ['Running', 'No spend challenge']);
      expect(snapshot.logCount, 4);

      final running = snapshot.habits.first;
      expect(running.colorArgb, 0xFFF141CE);
      expect(running.iconName, 'footprints');
      expect(running.reminderMinuteOfDay, 19 * 60);
      expect(running.objectives.map((objective) => objective.title), ['Nothing', '2-5km', 'Marathon']);
      expect(running.objectives.first.loggedDays, [CalendarDay.fromDate(2025, 12, 31)]);
      expect(snapshot.habits.last.objectives.single.title, 'Spend');
      expect(snapshot.habits.last.reminderMinuteOfDay, isNull);
    });

    test('maps every habit and objective to the v2 defaults', () {
      final snapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson(), today: today);

      for (final habit in snapshot.habits) {
        expect(habit.scheduledWeekdayMask, everyWeekdayMask);
        expect(habit.targetDaysPerWeek, isNull);
        expect(habit.archivedAt, isNull);
        expect(habit.objectives.map((objective) => objective.countsAsSuccess), everyElement(isTrue));
      }
    });

    test('keeps a log dated after today, which the original app allowed', () {
      final futureLog = {
        'id': 9,
        'date': '2026-12-12T00:00:00.000',
        'habitId': 8,
        'objectiveTitle': 'Spend ',
        'objectiveColorHex': 'FFEF5350',
      };
      final snapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [futureLog]), today: today);
      expect(snapshot.logCount, 5);
    });

    test('rejects two logs on the same day for one habit', () {
      final duplicate = {
        'id': 9,
        'date': '2026-01-01T00:00:00.000',
        'habitId': 1,
        'objectiveTitle': 'Nothing',
        'objectiveColorHex': 'FF7E57C2',
      };
      expect(
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [duplicate]), today: today),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects a log pointing to an unknown habit', () {
      final orphan = {
        'id': 9,
        'date': '2026-01-05T00:00:00.000',
        'habitId': 42,
        'objectiveTitle': 'Nothing',
        'objectiveColorHex': 'FF7E57C2',
      };
      expect(
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [orphan]), today: today),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects an impossible date instead of rolling it over', () {
      final impossibleDate = {
        'id': 9,
        'date': '2026-02-30T00:00:00.000',
        'habitId': 1,
        'objectiveTitle': 'Nothing',
        'objectiveColorHex': 'FF7E57C2',
      };
      expect(
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [impossibleDate]), today: today),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects non-JSON and unknown versions', () {
      expect(() => decodeBackupSnapshotFromJson('not json', today: today), throwsA(isA<InvalidBackupException>()));
      expect(
        () => decodeBackupSnapshotFromJson('{"version": 99}', today: today),
        throwsA(isA<InvalidBackupException>()),
      );
    });
  });

  group('decodeBackupSnapshotFromJson with a v2 file', () {
    test('imports a file written before the new keys with their defaults', () {
      final snapshot = decodeBackupSnapshotFromJson(buildOldCurrentBackupJson(), today: today);

      final habit = snapshot.habits.single;
      expect(habit.scheduledWeekdayMask, everyWeekdayMask);
      expect(habit.targetDaysPerWeek, isNull);
      expect(habit.archivedAt, isNull);
      expect(habit.objectives.single.countsAsSuccess, isTrue);
      expect(habit.objectives.single.loggedDays, [CalendarDay.fromDate(2026, 10, 1)]);
      expect(snapshot.notes.single.content, 'Felt great');
    });

    test('round-trips the schedule, weekly target, archive date and success flag', () {
      final archivedAt = DateTime.utc(2026, 10, 20, 9, 30);
      final snapshot = BackupSnapshot(
        userName: null,
        notes: const [],
        habits: [
          BackupHabit(
            title: 'Gym',
            description: '',
            colorArgb: 1,
            iconName: 'dumbbell',
            reminderMinuteOfDay: null,
            createdAt: DateTime.utc(2026),
            scheduledWeekdayMask: 0x15,
            targetDaysPerWeek: 3,
            archivedAt: archivedAt,
            objectives: [
              BackupObjective(title: 'Done', colorArgb: 2, loggedDays: [CalendarDay.fromDate(2026, 10, 5)]),
              const BackupObjective(title: 'Skipped', colorArgb: 3, loggedDays: [], countsAsSuccess: false),
            ],
          ),
        ],
      );

      final decoded = decodeBackupSnapshotFromJson(
        encodeBackupSnapshotToJson(snapshot, exportedAt: DateTime.utc(2026, 10, 28)),
        today: today,
      );

      final habit = decoded.habits.single;
      expect(habit.scheduledWeekdayMask, 0x15);
      expect(habit.targetDaysPerWeek, 3);
      expect(habit.archivedAt, archivedAt);
      expect(habit.objectives.map((objective) => objective.countsAsSuccess), [true, false]);
    });

    test('rejects a log dated after today', () {
      expect(
        () => decodeBackupSnapshotFromJson(buildOldCurrentBackupJson(loggedDay: '2026-10-30'), today: today),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(
        decodeBackupSnapshotFromJson(buildOldCurrentBackupJson(loggedDay: '2026-10-29'), today: today).logCount,
        1,
      );
    });

    test('rejects a description or a note longer than the limits', () {
      expect(
        () => decodeBackupSnapshotFromJson(
          buildOldCurrentBackupJson(description: 'a' * (maximumHabitDescriptionLength + 1)),
          today: today,
        ),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(
        () => decodeBackupSnapshotFromJson(
          buildOldCurrentBackupJson(noteContent: 'a' * (maximumNoteContentLength + 1)),
          today: today,
        ),
        throwsA(isA<InvalidBackupException>()),
      );
      expect(
        decodeBackupSnapshotFromJson(
          buildOldCurrentBackupJson(
            description: 'a' * maximumHabitDescriptionLength,
            noteContent: 'a' * maximumNoteContentLength,
          ),
          today: today,
        ).habits,
        hasLength(1),
      );
    });

    test('rejects an out-of-range weekly target', () {
      final json = buildOldCurrentBackupJson().replaceFirst(
        '"title":"Running",',
        '"title":"Running","targetDaysPerWeek":8,',
      );
      expect(() => decodeBackupSnapshotFromJson(json, today: today), throwsA(isA<InvalidBackupException>()));
    });
  });

  group('BackupRepository', () {
    late AppDatabase database;
    late BackupRepository backupRepository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      backupRepository = BackupRepository(database);
    });
    tearDown(() => database.close());

    test('imports a legacy file, then exports and re-imports it without loss', () async {
      final legacySnapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson(), today: today);
      await backupRepository.replaceAllDataWith(legacySnapshot);

      expect(await database.select(database.habitLogs).get(), hasLength(4));

      final exportedJson = encodeBackupSnapshotToJson(
        await backupRepository.readSnapshot(userName: 'Alex'),
        exportedAt: DateTime.utc(2026, 10, 28),
      );
      final reimportedSnapshot = decodeBackupSnapshotFromJson(exportedJson, today: today);
      expect(encodeBackupSnapshotToJson(reimportedSnapshot, exportedAt: DateTime.utc(2026, 10, 28)), exportedJson);

      await backupRepository.replaceAllDataWith(reimportedSnapshot);
      expect(await database.select(database.habitLogs).get(), hasLength(4));
      expect(await database.select(database.objectives).get(), hasLength(4));
    });

    test('stores and reads back the schedule, weekly target, archive date and success flag', () async {
      final archivedAt = DateTime.utc(2026, 10, 20, 9, 30);
      await backupRepository.replaceAllDataWith(
        BackupSnapshot(
          userName: null,
          notes: const [],
          habits: [
            BackupHabit(
              title: 'Gym',
              description: '',
              colorArgb: 1,
              iconName: 'dumbbell',
              reminderMinuteOfDay: null,
              createdAt: DateTime.utc(2026),
              scheduledWeekdayMask: 0x15,
              targetDaysPerWeek: 3,
              archivedAt: archivedAt,
              objectives: const [
                BackupObjective(title: 'Skipped', colorArgb: 3, loggedDays: [], countsAsSuccess: false),
              ],
            ),
          ],
        ),
      );

      final habit = (await backupRepository.readSnapshot(userName: null)).habits.single;
      expect(habit.scheduledWeekdayMask, 0x15);
      expect(habit.targetDaysPerWeek, 3);
      expect(habit.archivedAt?.toUtc(), archivedAt);
      expect(habit.objectives.single.countsAsSuccess, isFalse);
    });

    test('leaves existing data untouched when an import fails midway', () async {
      await backupRepository.replaceAllDataWith(decodeBackupSnapshotFromJson(buildLegacyBackupJson(), today: today));
      final brokenSnapshot = BackupSnapshot(
        userName: null,
        notes: const [],
        habits: [
          BackupHabit(
            title: 'Reading',
            description: '',
            colorArgb: 0,
            iconName: 'pill',
            reminderMinuteOfDay: null,
            createdAt: DateTime(2026),
            // Violates the (habit, title) unique key, after the delete statements already ran.
            objectives: const [
              BackupObjective(title: 'Yes', colorArgb: 0, loggedDays: []),
              BackupObjective(title: 'Yes', colorArgb: 0, loggedDays: []),
            ],
          ),
        ],
      );

      await expectLater(backupRepository.replaceAllDataWith(brokenSnapshot), throwsA(anything));
      expect(await database.select(database.habitLogs).get(), hasLength(4));
    });

    test('deleting a habit cascades to its objectives and logs', () async {
      await backupRepository.replaceAllDataWith(decodeBackupSnapshotFromJson(buildLegacyBackupJson(), today: today));
      await (database.delete(database.habits)..where((habit) => habit.title.equals('Running'))).go();

      expect(await database.select(database.objectives).get(), hasLength(1));
      expect(await database.select(database.habitLogs).get(), hasLength(1));
    });
  });

  // Optional check against a real export, kept out of the repository because it holds personal data:
  // KOMIT_LEGACY_BACKUP=/path/to/komit_backup.json flutter test
  final realBackupPath = Platform.environment['KOMIT_LEGACY_BACKUP'];
  test(
    'imports the real legacy backup without losing a single log',
    skip: realBackupPath == null ? 'KOMIT_LEGACY_BACKUP not set' : false,
    () async {
      final jsonText = File(realBackupPath!).readAsStringSync();
      final rawLogCount = ((jsonDecode(jsonText) as Map<String, Object?>)['logs']! as List<Object?>).length;
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await BackupRepository(database).replaceAllDataWith(decodeBackupSnapshotFromJson(jsonText, today: today));

      final importedLogCount = await database.habitLogs.count().getSingle();
      expect(importedLogCount, rawLogCount);
      expect(await database.habits.count().getSingle(), 8);

      // The v2 defaults (every objective a success, every day scheduled) keep the v1 streaks.
      final habitRepository = HabitRepository(database);
      final realToday = CalendarDay.fromDateTime(DateTime.now());
      for (final habit in await habitRepository.watchActiveHabits().first) {
        final objectiveIdByDay = await habitRepository.watchObjectiveIdByDayForHabit(habit.habit.id).first;
        final everyLoggedDayStreak = computeStreakSummary(
          objectiveIdByDay,
          successObjectiveIds: {for (final objective in habit.objectives) objective.id},
          today: realToday,
        );
        final scheduledStreak = computeScheduledStreakSummary(
          objectiveIdByDay,
          successObjectiveIds: habit.successObjectiveIds,
          scheduledWeekdayMask: habit.habit.scheduledWeekdayMask,
          targetDaysPerWeek: habit.habit.targetDaysPerWeek,
          today: realToday,
        );
        expect(
          (scheduledStreak.currentStreakLength, scheduledStreak.bestStreakLength),
          (everyLoggedDayStreak.currentStreakLength, everyLoggedDayStreak.bestStreakLength),
        );
      }
    },
  );
}
