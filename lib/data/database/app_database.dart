import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/habit_schedule.dart';
import 'app_database.steps.dart';

export '../../domain/habit_schedule.dart'
    show everyWeekdayMask, maximumRestDaysPerWeek, maximumTargetDaysPerWeek, minimumTargetDaysPerWeek;

part 'app_database.g.dart';

const int maximumHabitTitleLength = 80;
const int maximumObjectiveTitleLength = 60;
const int maximumHabitDescriptionLength = 1000;
const int maximumNoteContentLength = 20000;

/// Long enough for "glasses" or "pages", short enough to sit next to a number on a row.
const int maximumQuantityUnitLength = 16;

/// Far above any daily amount a person logs; guards against a typo of extra digits.
const double maximumQuantityValue = 1000000;

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

  /// Missed scheduled days per ISO week that keep a daily or weekday streak alive (docs/adr/0007).
  IntColumn get restDaysPerWeek => integer()
      .withDefault(const Constant(0))
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      .check(restDaysPerWeek.isBetweenValues(0, maximumRestDaysPerWeek))();

  /// The three quantity columns are null for an objectives habit and all set for a quantity
  /// habit (docs/adr/0008).
  TextColumn get quantityUnit => text().nullable().withLength(min: 1, max: maximumQuantityUnitLength)();

  /// The daily amount that makes the day a success.
  RealColumn get quantityTarget =>
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      real().nullable().check(quantityTarget.isBiggerThanValue(0))();

  /// The amount one tap adds.
  RealColumn get quantityStep =>
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      real().nullable().check(quantityStep.isBiggerThanValue(0))();
}

/// Days a habit is on hold; past pauses stay so its history reads the same (docs/adr/0007).
@DataClassName('HabitPauseRow')
class HabitPauses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// A [CalendarDay], included.
  IntColumn get startDay => integer()();

  /// A [CalendarDay], included; null while the pause is open.
  IntColumn get endDay =>
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      integer().nullable().check(endDay.isBiggerOrEqual(startDay))();
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

  /// The amount logged on a quantity habit; null for an objectives habit (docs/adr/0008).
  RealColumn get quantity =>
      // ignore: recursive_getters, drift's documented way to reference the column in its own CHECK.
      real().nullable().check(quantity.isBiggerThanValue(0))();

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

@DriftDatabase(tables: [Habits, Objectives, HabitLogs, Notes, HabitPauses])
class AppDatabase extends _$AppDatabase {
  /// Background isolates (reminder actions, widgets) must open the database through this
  /// constructor too, so every isolate shares one connection (see docs/adr/0004).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'komit', native: const DriftNativeOptions(shareAcrossIsolates: true)));

  @override
  int get schemaVersion => 4;

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
      from2To3: (migrator, schema) async {
        await migrator.addColumn(schema.habits, schema.habits.restDaysPerWeek);
        await migrator.create(schema.habitPauses);
      },
      from3To4: (migrator, schema) async {
        await migrator.addColumn(schema.habits, schema.habits.quantityUnit);
        await migrator.addColumn(schema.habits, schema.habits.quantityTarget);
        await migrator.addColumn(schema.habits, schema.habits.quantityStep);
        await migrator.addColumn(schema.habitLogs, schema.habitLogs.quantity);
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
