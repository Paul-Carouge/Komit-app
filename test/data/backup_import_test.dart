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

void main() {
  group('decodeBackupSnapshotFromJson with a legacy v1 file', () {
    test('keeps every habit, objective and log, with trimmed titles', () {
      final snapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson());

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

    test('rejects two logs on the same day for one habit', () {
      final duplicate = {
        'id': 9,
        'date': '2026-01-01T00:00:00.000',
        'habitId': 1,
        'objectiveTitle': 'Nothing',
        'objectiveColorHex': 'FF7E57C2',
      };
      expect(
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [duplicate])),
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
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [orphan])),
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
        () => decodeBackupSnapshotFromJson(buildLegacyBackupJson(extraLogs: [impossibleDate])),
        throwsA(isA<InvalidBackupException>()),
      );
    });

    test('rejects non-JSON and unknown versions', () {
      expect(() => decodeBackupSnapshotFromJson('not json'), throwsA(isA<InvalidBackupException>()));
      expect(() => decodeBackupSnapshotFromJson('{"version": 99}'), throwsA(isA<InvalidBackupException>()));
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
      final legacySnapshot = decodeBackupSnapshotFromJson(buildLegacyBackupJson());
      await backupRepository.replaceAllDataWith(legacySnapshot);

      expect(await database.select(database.habitLogs).get(), hasLength(4));

      final exportedJson = encodeBackupSnapshotToJson(
        await backupRepository.readSnapshot(userName: 'Alex'),
        exportedAt: DateTime.utc(2026, 10, 28),
      );
      final reimportedSnapshot = decodeBackupSnapshotFromJson(exportedJson);
      expect(encodeBackupSnapshotToJson(reimportedSnapshot, exportedAt: DateTime.utc(2026, 10, 28)), exportedJson);

      await backupRepository.replaceAllDataWith(reimportedSnapshot);
      expect(await database.select(database.habitLogs).get(), hasLength(4));
      expect(await database.select(database.objectives).get(), hasLength(4));
    });

    test('leaves existing data untouched when an import fails midway', () async {
      await backupRepository.replaceAllDataWith(decodeBackupSnapshotFromJson(buildLegacyBackupJson()));
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
      await backupRepository.replaceAllDataWith(decodeBackupSnapshotFromJson(buildLegacyBackupJson()));
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

      await BackupRepository(database).replaceAllDataWith(decodeBackupSnapshotFromJson(jsonText));

      final importedLogCount = await database.habitLogs.count().getSingle();
      expect(importedLogCount, rawLogCount);
    },
  );
}
