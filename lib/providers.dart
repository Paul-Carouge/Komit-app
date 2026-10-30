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
import 'domain/seasons.dart';
import 'domain/weekly_recap.dart';
import 'domain/year_in_review.dart';
import 'services/app_lock_service.dart';
import 'services/app_update_service.dart';
import 'services/image_share_service.dart';
import 'services/automatic_backup_service.dart';
import 'services/backup_encryption_service.dart';
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
final automaticBackupServiceProvider = Provider(
  (ref) => AutomaticBackupService(
    backupRepository: ref.watch(backupRepositoryProvider),
    readUserName: () => ref.read(settingsControllerProvider).userName,
    now: ref.watch(clockProvider),
  ),
);

/// Refreshed each time the restore list opens, since backups are written in the background.
final automaticBackupsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(automaticBackupServiceProvider).listBackupsNewestFirst(),
);
final backupEncryptionServiceProvider = Provider((ref) => BackupEncryptionService());
final appLockServiceProvider = Provider((ref) => AppLockService());

/// Whether the phone has a screen lock; invalidated when the app resumes, since the user may
/// have just set one up in the system settings.
final canUseAppLockProvider = FutureProvider((ref) => ref.watch(appLockServiceProvider).canAuthenticate());
final appUpdateServiceProvider = Provider((ref) => AppUpdateService());

final imageShareServiceProvider = Provider((ref) => ImageShareService());
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

  Future<void> recordExport(DateTime exportedAt) async {
    await _repository.saveLastExportAt(exportedAt);
    state = _repository.readSettings();
  }

  /// [upToDateAt] is null when the check found a newer version.
  Future<void> recordUpdateCheckResult({required DateTime? upToDateAt}) async {
    await _repository.saveLastUpToDateCheckAt(upToDateAt);
    state = _repository.readSettings();
  }

  Future<void> updateAppLockEnabled({required bool isEnabled}) async {
    await _repository.saveAppLockEnabled(isEnabled: isEnabled);
    state = _repository.readSettings();
  }

  Future<void> updateScreenContentHidden({required bool isHidden}) async {
    await _repository.saveScreenContentHidden(isHidden: isHidden);
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

/// Null on an ordinary day; changes at midnight with the current day.
final currentSeasonProvider = Provider<Season?>((ref) => seasonOn(ref.watch(currentCalendarDayProvider)));

final unlockedAchievementsProvider = Provider<Set<Achievement>?>((ref) {
  final histories = ref.watch(habitHistoriesProvider);
  if (histories == null) return null;
  return computeUnlockedAchievements(histories, today: ref.watch(currentCalendarDayProvider));
});

/// The year the review is about today, or null outside December 1 to January 15. Cheap, unlike
/// [yearInReviewProvider], so entry points can watch it without recomputing a year of logs.
final yearInReviewYearProvider = Provider<int?>((ref) => yearInReviewYearOn(ref.watch(currentCalendarDayProvider)));

/// Whether the review's year holds at least one log, so the dashboard does not invite someone
/// who just started to read an empty year. A scan of the log days, not the full review.
final hasLogsInYearInReviewYearProvider = Provider<bool>((ref) {
  final year = ref.watch(yearInReviewYearProvider);
  final logsByHabitId = ref.watch(allObjectiveIdByDayByHabitIdProvider).value;
  if (year == null || logsByHabitId == null) return false;
  return logsByHabitId.values.any((objectiveIdByDay) => objectiveIdByDay.keys.any((day) => day.year == year));
});

/// Null outside December 1 to January 15, and while habits or logs load.
final yearInReviewProvider = Provider<YearInReview?>((ref) {
  final today = ref.watch(currentCalendarDayProvider);
  final year = ref.watch(yearInReviewYearProvider);
  final histories = ref.watch(habitHistoriesProvider);
  if (year == null || histories == null) return null;
  return computeYearInReview(histories, year: year, today: today);
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

class DismissedYearInReviewYearController extends Notifier<int?> {
  @override
  int? build() => ref.watch(settingsRepositoryProvider).readDismissedYearInReviewYear();

  Future<void> dismiss(int year) async {
    state = year;
    await ref.read(settingsRepositoryProvider).saveDismissedYearInReviewYear(year);
  }
}

final dismissedYearInReviewYearProvider = NotifierProvider<DismissedYearInReviewYearController, int?>(
  DismissedYearInReviewYearController.new,
);
