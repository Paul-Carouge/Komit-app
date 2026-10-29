import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/backup/backup_json_codec.dart';
import 'package:komit/data/backup/backup_snapshot.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/backup_repository.dart';
import 'package:komit/services/automatic_backup_service.dart';

final DateTime _firstBackupTime = DateTime(2026, 10, 28, 9);
final CalendarDay _today = CalendarDay.fromDateTime(_firstBackupTime);

BackupSnapshot _snapshotWithOneHabit(String title, {required List<CalendarDay> loggedDays}) => BackupSnapshot(
  userName: 'Paul',
  habits: [
    BackupHabit(
      title: title,
      description: 'Every morning',
      colorArgb: 0xFFFF8C1A,
      iconName: 'footprints',
      reminderMinuteOfDay: 7 * 60,
      createdAt: DateTime.utc(2026),
      objectives: [BackupObjective(title: 'Done', colorArgb: 0xFF4CAF50, loggedDays: loggedDays)],
    ),
  ],
  notes: [BackupNote(content: 'A note', createdAt: DateTime.utc(2026, 2), updatedAt: DateTime.utc(2026, 3))],
);

void main() {
  late AppDatabase database;
  late BackupRepository backupRepository;
  late Directory backupDirectory;
  late DateTime now;
  late AutomaticBackupService service;

  Future<String> currentDataJson() async =>
      encodeBackupSnapshotToJson(await backupRepository.readSnapshot(userName: 'Paul'), exportedAt: _firstBackupTime);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    backupRepository = BackupRepository(database);
    backupDirectory = Directory.systemTemp.createTempSync('komit_automatic_backups');
    now = _firstBackupTime;
    service = AutomaticBackupService(
      backupRepository: backupRepository,
      readUserName: () => 'Paul',
      now: () => now,
      resolveBackupDirectory: () async => backupDirectory,
    );
    await backupRepository.replaceAllDataWith(
      _snapshotWithOneHabit('Run', loggedDays: [_today.addDays(-2), _today.addDays(-1)]),
    );
  });

  tearDown(() async {
    await database.close();
    backupDirectory.deleteSync(recursive: true);
  });

  test('restoring the pre-import backup brings the data back exactly', () async {
    final dataBeforeImport = await currentDataJson();

    await service.writeSnapshot(AutomaticBackupReason.beforeImport);
    await backupRepository.replaceAllDataWith(_snapshotWithOneHabit('Imported', loggedDays: [_today]));
    expect(await currentDataJson(), isNot(dataBeforeImport));

    final preImportBackup = (await service.listBackupsNewestFirst()).single;
    expect(preImportBackup.reason, AutomaticBackupReason.beforeImport);
    await backupRepository.replaceAllDataWith(await service.readSnapshot(preImportBackup));

    expect(await currentDataJson(), dataBeforeImport);
  });

  test('keeps only the most recent backups', () async {
    for (var index = 0; index < automaticBackupRetentionCount + 3; index++) {
      now = _firstBackupTime.add(Duration(minutes: index));
      await service.writeSnapshot(AutomaticBackupReason.beforeUpdate);
    }

    final backups = await service.listBackupsNewestFirst();
    expect(backups, hasLength(automaticBackupRetentionCount));
    expect(backups.first.createdAt, now);
    expect(backupDirectory.listSync(), hasLength(automaticBackupRetentionCount));
  });

  test('writes the daily copy only after a day and only when the data changed', () async {
    expect(await service.writeDailySnapshotIfDataChanged(), isTrue);

    now = _firstBackupTime.add(const Duration(hours: 23));
    await backupRepository.replaceAllDataWith(_snapshotWithOneHabit('Changed', loggedDays: [_today]));
    expect(await service.writeDailySnapshotIfDataChanged(), isFalse, reason: 'less than a day since the last copy');

    now = _firstBackupTime.add(const Duration(days: 1));
    expect(await service.writeDailySnapshotIfDataChanged(), isTrue);

    now = _firstBackupTime.add(const Duration(days: 2));
    expect(await service.writeDailySnapshotIfDataChanged(), isFalse, reason: 'nothing changed since yesterday');
    expect(await service.listBackupsNewestFirst(), hasLength(2));
  });

  test('skips the daily copy while the app holds no data', () async {
    await backupRepository.replaceAllDataWith(const BackupSnapshot(userName: null, habits: [], notes: []));

    expect(await service.writeDailySnapshotIfDataChanged(), isFalse);
  });

  test('ignores unrelated and half-written files in the folder', () async {
    File('${backupDirectory.path}/notes.txt').writeAsStringSync('hello');
    File('${backupDirectory.path}/komit_auto_1_daily.json.partial').writeAsStringSync('{');

    expect(await service.listBackupsNewestFirst(), isEmpty);
  });
}
