import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_logger.dart';
import 'core/calendar_day.dart';
import 'core/current_calendar_day.dart';
import 'data/database/app_database.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'domain/achievements.dart';
import 'domain/habit_history.dart';
import 'domain/habit_statistics.dart';
import 'domain/weekly_recap.dart';
import 'services/app_update_service.dart';
import 'services/notification_permission_service.dart';
import 'services/reminder_scheduler.dart';

/// Overridden in `main` once the database and preferences are opened.
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override in main'));
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => throw UnimplementedError('Override in main'));
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => throw UnimplementedError('Override in main'));
final appLoggerProvider = Provider<AppLogger>((ref) => throw UnimplementedError('Override in main'));

final habitRepositoryProvider = Provider(
  (ref) => HabitRepository(ref.watch(appDatabaseProvider), now: ref.watch(clockProvider)),
);
final noteRepositoryProvider = Provider((ref) => NoteRepository(ref.watch(appDatabaseProvider)));
final backupRepositoryProvider = Provider((ref) => BackupRepository(ref.watch(appDatabaseProvider)));
final appUpdateServiceProvider = Provider((ref) => AppUpdateService());
final notificationPermissionServiceProvider = Provider(
  (ref) => NotificationPermissionService(ref.watch(reminderSchedulerProvider)),
);

/// Invalidated when the app resumes: the user may have changed it in the system settings.
final notificationStatusProvider = FutureProvider(
  (ref) => ref.watch(notificationPermissionServiceProvider).readNotificationStatus(),
);

class SettingsController extends Notifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).readSettings();

  Future<void> completeOnboarding({required String userName}) async {
    await _repository.saveUserName(userName);
    await _repository.markOnboardingComplete();
    state = _repository.readSettings();
  }

  Future<void> updateUserName(String? userName) async {
    await _repository.saveUserName(userName);
    state = _repository.readSettings();
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    await _repository.saveThemeMode(themeMode);
    state = _repository.readSettings();
  }

  Future<void> updateLanguageCode(String? languageCode) async {
    await _repository.saveLanguageCode(languageCode);
    state = _repository.readSettings();
  }

  Future<void> updateAutomaticUpdateCheckEnabled({required bool isEnabled}) async {
    await _repository.saveAutomaticUpdateCheckEnabled(isEnabled: isEnabled);
    state = _repository.readSettings();
  }
}

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final activeHabitsProvider = StreamProvider((ref) => ref.watch(habitRepositoryProvider).watchActiveHabits());

final archivedHabitsProvider = StreamProvider((ref) => ref.watch(habitRepositoryProvider).watchArchivedHabits());

final habitWithObjectivesProvider = StreamProvider.autoDispose.family<HabitWithObjectives?, int>(
  (ref, habitId) => ref.watch(habitRepositoryProvider).watchHabitWithObjectives(habitId),
);

final objectiveIdByDayForHabitProvider = StreamProvider.autoDispose.family<Map<CalendarDay, int>, int>(
  (ref, habitId) => ref.watch(habitRepositoryProvider).watchObjectiveIdByDayForHabit(habitId),
);

/// Days shown on each dashboard row: last week and this week, Monday first. Two weeks fit on
/// one row at a readable cell size on a phone, weekly targets read week by week, and every
/// row's columns are the same weekdays.
const int recentDayCountShownOnDashboard = 2 * DateTime.daysPerWeek;

/// The Monday of last week: the first day of every dashboard row.
CalendarDay firstDayShownOnDashboard(CalendarDay today) => today.mondayOfWeek.addDays(-DateTime.daysPerWeek);

final recentObjectiveIdByDayByHabitIdProvider = StreamProvider((ref) {
  final firstDay = firstDayShownOnDashboard(ref.watch(currentCalendarDayProvider));
  return ref.watch(habitRepositoryProvider).watchObjectiveIdByDayForAllHabitsSince(firstDay);
});

/// The habit's current and best streak, null while its history loads. Memoized per habit, so a
/// dashboard row does not walk the whole history again on every rebuild.
final streakSummaryForHabitProvider = Provider.autoDispose.family<StreakSummary?, int>((ref, habitId) {
  final habit = ref.watch(habitWithObjectivesProvider(habitId)).value;
  final objectiveIdByDay = ref.watch(objectiveIdByDayForHabitProvider(habitId)).value;
  if (habit == null || objectiveIdByDay == null) return null;
  return computeScheduledStreakSummary(
    objectiveIdByDay,
    successObjectiveIds: habit.successObjectiveIds,
    scheduledWeekdayMask: habit.habit.scheduledWeekdayMask,
    targetDaysPerWeek: habit.habit.targetDaysPerWeek,
    today: ref.watch(currentCalendarDayProvider),
  );
});

/// Today's progress over the habits scheduled today; null while habits or logs load.
final todayProgressProvider = Provider<({int doneCount, int scheduledCount})?>((ref) {
  final habits = ref.watch(activeHabitsProvider).value;
  final logsByHabitId = ref.watch(recentObjectiveIdByDayByHabitIdProvider).value;
  if (habits == null || logsByHabitId == null) return null;
  final today = ref.watch(currentCalendarDayProvider);
  final scheduledHabits = habits.where((habit) => isHabitScheduledOn(habit, today));
  return (
    doneCount: scheduledHabits.where((habit) => logsByHabitId[habit.habit.id]?.containsKey(today) ?? false).length,
    scheduledCount: scheduledHabits.length,
  );
});

final lastLoggedDayByHabitIdProvider = StreamProvider(
  (ref) => ref.watch(habitRepositoryProvider).watchLastLoggedDayByHabitId(),
);

final notesProvider = StreamProvider((ref) => ref.watch(noteRepositoryProvider).watchNotesMostRecentlyUpdatedFirst());

/// The domain view of [habit] and its logs, for recaps, achievements and celebrations.
HabitHistory habitHistoryOf(HabitWithObjectives habit, Map<CalendarDay, int> objectiveIdByDay) {
  final createdDay = CalendarDay.fromDateTime(habit.habit.createdAt);
  final firstLoggedDay = objectiveIdByDay.keys.fold(
    createdDay,
    (earliest, day) => day.isAfter(earliest) ? earliest : day,
  );
  final archivedAt = habit.habit.archivedAt;
  return HabitHistory(
    habitId: habit.habit.id,
    objectiveIdByDay: objectiveIdByDay,
    successObjectiveIds: habit.successObjectiveIds,
    startDay: firstLoggedDay,
    scheduledWeekdayMask: habit.habit.scheduledWeekdayMask,
    targetDaysPerWeek: habit.habit.targetDaysPerWeek,
    archivedDay: archivedAt == null ? null : CalendarDay.fromDateTime(archivedAt),
  );
}

final allHabitsProvider = StreamProvider((ref) => ref.watch(habitRepositoryProvider).watchAllHabits());

final allObjectiveIdByDayByHabitIdProvider = StreamProvider(
  (ref) => ref.watch(habitRepositoryProvider).watchObjectiveIdByDayForAllHabits(),
);

/// Every habit's history, archived ones included; null while habits or logs load.
final habitHistoriesProvider = Provider<List<HabitHistory>?>((ref) {
  final habits = ref.watch(allHabitsProvider).value;
  final logsByHabitId = ref.watch(allObjectiveIdByDayByHabitIdProvider).value;
  if (habits == null || logsByHabitId == null) return null;
  return [for (final habit in habits) habitHistoryOf(habit, logsByHabitId[habit.habit.id] ?? const {})];
});

final unlockedAchievementsProvider = Provider<Set<Achievement>?>((ref) {
  final histories = ref.watch(habitHistoriesProvider);
  if (histories == null) return null;
  return computeUnlockedAchievements(histories, today: ref.watch(currentCalendarDayProvider));
});

final weeklyRecapProvider = Provider<WeeklyRecap?>((ref) {
  final histories = ref.watch(habitHistoriesProvider);
  if (histories == null) return null;
  return computeWeeklyRecap(histories, today: ref.watch(currentCalendarDayProvider));
});

class DismissedWeeklyRecapWeekController extends Notifier<CalendarDay?> {
  @override
  CalendarDay? build() => ref.watch(settingsRepositoryProvider).readDismissedWeeklyRecapWeek();

  Future<void> dismiss(CalendarDay weekMonday) async {
    state = weekMonday;
    await ref.read(settingsRepositoryProvider).saveDismissedWeeklyRecapWeek(weekMonday);
  }
}

final dismissedWeeklyRecapWeekProvider = NotifierProvider<DismissedWeeklyRecapWeekController, CalendarDay?>(
  DismissedWeeklyRecapWeekController.new,
);
