import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/backup/backup_json_codec.dart';
import 'package:komit/data/backup/backup_snapshot.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/backup_repository.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/achievements.dart';
import 'package:komit/domain/habit_statistics.dart';
import 'package:komit/domain/weekly_recap.dart';
import 'package:komit/providers.dart';

/// Far more than anyone tracks: 50 habits logged every day for ten years.
const int _largeDatasetHabitCount = 50;
const int _largeDatasetDayCount = 3650;
const int _objectiveCountPerHabit = 3;

/// Seeded, so every run measures the same data.
const int _largeDatasetRandomSeed = 20261029;

/// Each budget is at least ten times what a laptop measures, so a slow CI machine stays green
/// while an accidental O(n²) query or a lost index still fails. Set KOMIT_PRINT_TIMINGS=1 to
/// print the medians.
const Duration _dashboardQueryBudget = Duration(milliseconds: 100);
const Duration _habitDetailsBudget = Duration(milliseconds: 50);
const Duration _allHabitsStatisticsBudget = Duration(seconds: 2);
const Duration _exportBudget = Duration(seconds: 3);
const Duration _importBudget = Duration(seconds: 8);
const Duration _maximumSizeFileDecodeBudget = Duration(seconds: 3);

/// Runs before measuring, so the first-call costs (statement preparation, JIT) are not counted.
const int _warmUpRunCount = 1;
const int _measuredRunCount = 5;

final CalendarDay _today = CalendarDay.fromDate(2026, 10, 29);

void main() {
  late AppDatabase database;
  late HabitRepository habitRepository;
  late BackupRepository backupRepository;

  setUpAll(() async {
    database = AppDatabase(NativeDatabase.memory());
    habitRepository = HabitRepository(database, now: () => _today.asLocalDate);
    backupRepository = BackupRepository(database);
    await _insertLargeDataset(database);
  });
  tearDownAll(() => database.close());

  final dashboardQueryByName = <String, Future<Object> Function()>{
    'active habits': () => habitRepository.watchActiveHabits().first,
    'recent logs': () => habitRepository.watchObjectiveIdByDayForAllHabitsSince(firstDayShownOnDashboard(_today)).first,
    'last logged day by habit': () => habitRepository.watchLastLoggedDayByHabitId().first,
  };
  for (final MapEntry(key: queryName, value: runQuery) in dashboardQueryByName.entries) {
    test('the dashboard query "$queryName" stays within budget', () async {
      final elapsed = await _medianDurationOf(runQuery);
      _report('dashboard query "$queryName"', elapsed);
      expect(elapsed, lessThan(_dashboardQueryBudget));
    });
  }

  test('the last logged day of every habit is the most recent log', () async {
    final lastLoggedDayByHabitId = await habitRepository.watchLastLoggedDayByHabitId().first;
    expect(lastLoggedDayByHabitId, hasLength(_largeDatasetHabitCount));
    expect(lastLoggedDayByHabitId.values.toSet(), {_today});
  });

  test('one habit\'s details and statistics stay within budget', () async {
    final habit = (await habitRepository.watchActiveHabits().first).first;
    final elapsed = await _medianDurationOf(() async {
      final objectiveIdByDay = await habitRepository.watchObjectiveIdByDayForHabit(habit.habit.id).first;
      computeScheduledStreakSummary(
        objectiveIdByDay,
        successObjectiveIds: habit.successObjectiveIds,
        scheduledWeekdayMask: habit.habit.scheduledWeekdayMask,
        targetDaysPerWeek: habit.habit.targetDaysPerWeek,
        today: _today,
      );
      computeYearStatistics(objectiveIdByDay, year: _today.year);
    });
    _report('habit details and statistics', elapsed);
    expect(elapsed, lessThan(_habitDetailsBudget));
  });

  test('achievements and the weekly recap over every habit stay within budget', () async {
    final elapsed = await _medianDurationOf(() async {
      final (habits, logsByHabitId) = await (
        habitRepository.watchAllHabits().first,
        habitRepository.watchObjectiveIdByDayForAllHabits().first,
      ).wait;
      final histories = [for (final habit in habits) habitHistoryOf(habit, logsByHabitId[habit.habit.id] ?? const {})];
      computeUnlockedAchievements(histories, today: _today);
      computeWeeklyRecap(histories, today: _today);
    });
    _report('achievements and weekly recap', elapsed);
    expect(elapsed, lessThan(_allHabitsStatisticsBudget));
  });

  test('export then import round-trips every log within budget', () async {
    final exportStopwatch = Stopwatch()..start();
    final snapshot = await backupRepository.readSnapshot(userName: 'Paul');
    final backupJson = encodeBackupSnapshotToJson(snapshot, exportedAt: _today.asUtcDate);
    exportStopwatch.stop();

    final importStopwatch = Stopwatch()..start();
    final decodedSnapshot = decodeBackupSnapshotFromJson(backupJson, today: _today);
    await backupRepository.replaceAllDataWith(decodedSnapshot);
    importStopwatch.stop();

    _report('export (${utf8.encode(backupJson).length} bytes)', exportStopwatch.elapsed);
    _report('import', importStopwatch.elapsed);
    expect(decodedSnapshot.logCount, _largeDatasetHabitCount * _largeDatasetDayCount);
    expect((await backupRepository.readSnapshot(userName: 'Paul')).logCount, decodedSnapshot.logCount);
    expect(exportStopwatch.elapsed, lessThan(_exportBudget));
    expect(importStopwatch.elapsed, lessThan(_importBudget));
  });

  test('a backup of the maximum accepted size decodes within budget', () async {
    final largeDatasetSnapshot = await backupRepository.readSnapshot(userName: 'Paul');
    final largeDatasetJson = encodeBackupSnapshotToJson(largeDatasetSnapshot, exportedAt: _today.asUtcDate);
    // The largest dataset above is a fraction of the cap: the cap only rejects unrelated files.
    expect(utf8.encode(largeDatasetJson).length, lessThan(maximumBackupFileSizeBytes ~/ 4));

    final maximumSizeJson = _paddedWithNotesUpTo(largeDatasetSnapshot, maximumBackupFileSizeBytes);
    expect(
      utf8.encode(maximumSizeJson).length,
      inInclusiveRange(maximumBackupFileSizeBytes * 0.95, maximumBackupFileSizeBytes),
    );

    final stopwatch = Stopwatch()..start();
    final decodedSnapshot = decodeBackupSnapshotFromJson(maximumSizeJson, today: _today);
    stopwatch.stop();
    _report('decode of a ${maximumBackupFileSizeBytes ~/ (1024 * 1024)} MiB backup', stopwatch.elapsed);
    expect(decodedSnapshot.logCount, largeDatasetSnapshot.logCount);
    expect(stopwatch.elapsed, lessThan(_maximumSizeFileDecodeBudget));
  });
}

Future<void> _insertLargeDataset(AppDatabase database) async {
  final random = Random(_largeDatasetRandomSeed);
  final firstDay = _today.addDays(-(_largeDatasetDayCount - 1));
  await database.batch((batch) {
    batch.insertAll(database.habits, [
      for (var habitIndex = 0; habitIndex < _largeDatasetHabitCount; habitIndex++)
        HabitsCompanion.insert(
          title: 'Habit $habitIndex',
          colorArgb: 0xFFFF8C1A,
          iconName: 'footprints',
          createdAt: firstDay.asLocalDate,
        ),
    ]);
  });
  final habitIds = [for (final habit in await database.select(database.habits).get()) habit.id];
  await database.batch((batch) {
    batch.insertAll(database.objectives, [
      for (final habitId in habitIds)
        for (var objectiveIndex = 0; objectiveIndex < _objectiveCountPerHabit; objectiveIndex++)
          ObjectivesCompanion.insert(
            habitId: habitId,
            title: 'Objective $objectiveIndex',
            colorArgb: 0xFF7E57C2,
            sortOrder: objectiveIndex,
          ),
    ]);
  });
  final objectiveIdsByHabitId = <int, List<int>>{};
  for (final objective in await database.select(database.objectives).get()) {
    objectiveIdsByHabitId.putIfAbsent(objective.habitId, () => []).add(objective.id);
  }
  await database.batch((batch) {
    batch.insertAll(database.habitLogs, [
      for (final habitId in habitIds)
        for (var dayOffset = 0; dayOffset < _largeDatasetDayCount; dayOffset++)
          HabitLogsCompanion.insert(
            habitId: habitId,
            objectiveId: objectiveIdsByHabitId[habitId]![random.nextInt(_objectiveCountPerHabit)],
            day: firstDay.addDays(dayOffset).daysSinceEpoch,
          ),
    ]);
  });
}

/// The same backup plus long notes, until it is just under [maximumSizeBytes].
String _paddedWithNotesUpTo(BackupSnapshot snapshot, int maximumSizeBytes) {
  final baseSizeBytes = utf8.encode(encodeBackupSnapshotToJson(snapshot, exportedAt: _today.asUtcDate)).length;
  final noteContent = 'x' * maximumNoteContentLength;
  // Each encoded note also carries its two dates and the JSON punctuation around them.
  const encodedNoteOverheadBytes = 120;
  final noteCount = (maximumSizeBytes - baseSizeBytes) ~/ (maximumNoteContentLength + encodedNoteOverheadBytes);
  final note = BackupNote(content: noteContent, createdAt: _today.asUtcDate, updatedAt: _today.asUtcDate);
  return encodeBackupSnapshotToJson(
    BackupSnapshot(habits: snapshot.habits, notes: List.filled(noteCount, note), userName: snapshot.userName),
    exportedAt: _today.asUtcDate,
  );
}

Future<Duration> _medianDurationOf(Future<void> Function() measuredWork) async {
  for (var run = 0; run < _warmUpRunCount; run++) {
    await measuredWork();
    await pumpEventQueue();
  }
  final durations = <Duration>[];
  for (var run = 0; run < _measuredRunCount; run++) {
    final stopwatch = Stopwatch()..start();
    await measuredWork();
    durations.add(stopwatch.elapsed);
    // Drift shares a stream query until a microtask after its last listener left: without this
    // pause the next run would read the cached rows instead of running the query.
    await pumpEventQueue();
  }
  durations.sort();
  return durations[durations.length ~/ 2];
}

void _report(String measurement, Duration elapsed) {
  final line = '$measurement: ${elapsed.inMicroseconds / Duration.microsecondsPerMillisecond} ms';
  printOnFailure(line);
  if (Platform.environment['KOMIT_PRINT_TIMINGS'] != null) stdout.writeln(line);
}
