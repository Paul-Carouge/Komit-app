import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/calendar_day.dart';
import 'core/current_calendar_day.dart';
import 'data/database/app_database.dart';
import 'data/repositories/backup_repository.dart';
import 'data/repositories/habit_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'services/app_update_service.dart';
import 'services/reminder_scheduler.dart';

/// Overridden in `main` once the database and preferences are opened.
final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override in main'));
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => throw UnimplementedError('Override in main'));
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => throw UnimplementedError('Override in main'));

final habitRepositoryProvider = Provider(
  (ref) => HabitRepository(ref.watch(appDatabaseProvider), now: ref.watch(clockProvider)),
);
final noteRepositoryProvider = Provider((ref) => NoteRepository(ref.watch(appDatabaseProvider)));
final backupRepositoryProvider = Provider((ref) => BackupRepository(ref.watch(appDatabaseProvider)));
final appUpdateServiceProvider = Provider((ref) => AppUpdateService());

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
}

final settingsControllerProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final activeHabitsProvider = StreamProvider((ref) => ref.watch(habitRepositoryProvider).watchActiveHabits());

final habitWithObjectivesProvider = StreamProvider.autoDispose.family<HabitWithObjectives?, int>(
  (ref, habitId) => ref.watch(habitRepositoryProvider).watchHabitWithObjectives(habitId),
);

final objectiveIdByDayForHabitProvider = StreamProvider.autoDispose.family<Map<CalendarDay, int>, int>(
  (ref, habitId) => ref.watch(habitRepositoryProvider).watchObjectiveIdByDayForHabit(habitId),
);

/// Days shown on each dashboard row, today included: two weeks fit on one row at a readable
/// cell size on a phone, and the logs query loads no more than that.
const int recentDayCountShownOnDashboard = 14;

final recentObjectiveIdByDayByHabitIdProvider = StreamProvider((ref) {
  final firstDay = ref.watch(currentCalendarDayProvider).addDays(-(recentDayCountShownOnDashboard - 1));
  return ref.watch(habitRepositoryProvider).watchObjectiveIdByDayForAllHabitsSince(firstDay);
});

final lastLoggedDayByHabitIdProvider = StreamProvider(
  (ref) => ref.watch(habitRepositoryProvider).watchLastLoggedDayByHabitId(),
);

final notesProvider = StreamProvider((ref) => ref.watch(noteRepositoryProvider).watchNotesMostRecentlyUpdatedFirst());
