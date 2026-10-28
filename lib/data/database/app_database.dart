import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

const int maximumHabitTitleLength = 80;
const int maximumObjectiveTitleLength = 60;

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
}

/// The possible outcomes of a habit for one day (e.g. "2-5km", "Tired").
@DataClassName('ObjectiveRow')
class Objectives extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: maximumObjectiveTitleLength)();
  IntColumn get colorArgb => integer()();
  IntColumn get sortOrder => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, title},
  ];
}

@DataClassName('HabitLogRow')
@TableIndex(name: 'habit_logs_day', columns: {#day})
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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'komit'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // SQLite ships with foreign keys disabled; cascades and integrity rely on them.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
