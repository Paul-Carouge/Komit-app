import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.steps.dart';

part 'app_database.g.dart';

const int maximumHabitTitleLength = 80;
const int maximumObjectiveTitleLength = 60;
const int maximumHabitDescriptionLength = 1000;
const int maximumNoteContentLength = 20000;

/// Bit `weekday - 1` is set for each scheduled [DateTime.monday]..[DateTime.sunday].
const int everyWeekdayMask = 0x7F;
const int minimumTargetDaysPerWeek = 1;
const int maximumTargetDaysPerWeek = DateTime.daysPerWeek;

/// How long a connection waits for another isolate's write lock before failing.
const Duration databaseBusyTimeout = Duration(seconds: 5);

@DataClassName('HabitRow')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: maximumHabitTitleLength)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get colorArgb => integer()();
  TextColumn get iconName => text()();

  /// Minutes after local midnight; null when the daily reminder is off.
  IntColumn get reminderMinuteOfDay =>
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      integer().nullable().check(reminderMinuteOfDay.isBetweenValues(0, 1439))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  IntColumn get scheduledWeekdayMask => integer()
      // Literal [everyWeekdayMask]: drift copies defaults verbatim into the versioned schema files.
      .withDefault(const Constant(0x7F))
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      .check(scheduledWeekdayMask.isBetweenValues(1, everyWeekdayMask))();

  /// Null for a daily habit; otherwise the habit succeeds on weeks with this many success days.
  IntColumn get targetDaysPerWeek =>
      integer().nullable()
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      .check(targetDaysPerWeek.isBetweenValues(minimumTargetDaysPerWeek, maximumTargetDaysPerWeek))();

  /// Null while the habit is active.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

/// The possible outcomes of a habit for one day (e.g. "2-5km", "Tired").
@DataClassName('ObjectiveRow')
class Objectives extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: maximumObjectiveTitleLength)();
  IntColumn get colorArgb => integer()();
  IntColumn get sortOrder => integer()();

  /// False for outcomes such as "Skipped" that are logged but must not extend a streak.
  BoolColumn get countsAsSuccess => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, title},
  ];
}

@DataClassName('HabitLogRow')
@TableIndex(name: 'habit_logs_day', columns: {#day})
// Speeds up the cascade and the log count when an objective is deleted.
@TableIndex(name: 'habit_logs_objective', columns: {#objectiveId})
class HabitLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  IntColumn get objectiveId => integer().references(Objectives, #id, onDelete: KeyAction.cascade)();

  /// A [CalendarDay], so one log per habit per calendar day.
  IntColumn get day => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [Habits, Objectives, HabitLogs, Notes])
class AppDatabase extends _$AppDatabase {
  /// Background isolates (reminder actions, widgets) must open the database through this
  /// constructor too, so every isolate shares one connection (see docs/adr/0004).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'komit', native: const DriftNativeOptions(shareAcrossIsolates: true)));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.addColumn(schema.objectives, schema.objectives.countsAsSuccess);
        await migrator.addColumn(schema.habits, schema.habits.scheduledWeekdayMask);
        await migrator.addColumn(schema.habits, schema.habits.targetDaysPerWeek);
        await migrator.addColumn(schema.habits, schema.habits.archivedAt);
        await migrator.create(schema.habitLogsObjective);
      },
    ),
    beforeOpen: (details) async {
      // SQLite ships with foreign keys disabled; cascades and integrity rely on them.
      await customStatement('PRAGMA foreign_keys = ON');
      // WAL lets a background isolate read while the UI writes; the timeout waits out its lock.
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA busy_timeout = ${databaseBusyTimeout.inMilliseconds}');
    },
  );
}
