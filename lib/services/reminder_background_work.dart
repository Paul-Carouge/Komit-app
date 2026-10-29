import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_logger.dart';
import '../core/calendar_day.dart';
import '../data/database/app_database.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/reminder_planning.dart';
import '../l10n/app_localizations.dart';
import 'home_widget_service.dart';
import 'reminder_scheduler.dart';

/// The Android receiver that starts [rebuildRemindersAfterSystemEvent] waits for this call
/// to stop its engine (see ReminderRebuildReceiver.kt).
const MethodChannel _reminderRebuildChannel = MethodChannel('com.paulcarouge.komit/reminder_rebuild');

/// One per background isolate: the plugin keeps its isolate alive between button taps.
final ReminderScheduler _backgroundReminderScheduler = ReminderScheduler.startInitializing(
  onInitializationFailed: (error, _) =>
      developer.log('Reminders unavailable in the background', name: 'komit.reminders', error: error.runtimeType),
);

/// Handles the "Done", objective and "Later" buttons of a reminder in a background isolate,
/// whether or not the app is running. Logs go through [HabitRepository], so a future day or
/// an objective of another habit is refused there like anywhere else.
@pragma('vm:entry-point')
Future<void> handleReminderResponseInBackground(NotificationResponse response) async {
  final command = reminderResponseCommandFor(payload: response.payload, actionId: response.actionId);
  if (command == null) {
    developer.log('Ignored a malformed reminder response', name: 'komit.reminders');
    return;
  }
  await _runWithDatabase(event: 'reminder_action_failed', (repository, localizations, settings) async {
    final isAppLockEnabled = settings.isAppLockEnabled;
    switch (command) {
      // A reminder shown before the lock was turned on still has log buttons: they must not bypass it.
      case LogObjectiveFromReminder() when isAppLockEnabled:
        developer.log('Ignored a log from a reminder while the app lock is on', name: 'komit.reminders');
      case LogObjectiveFromReminder(:final habitId, :final objectiveId, :final day):
        await repository.logObjectiveForDay(habitId: habitId, objectiveId: objectiveId, day: day);
        // Dismisses a snoozed copy and refreshes the streak shown in the next reminders.
        await _backgroundReminderScheduler.rebuildReminders(
          repository,
          localizations,
          isAppLockEnabled: isAppLockEnabled,
        );
      case SnoozeReminder(:final habitId):
        await _backgroundReminderScheduler.snoozeReminder(
          repository,
          localizations,
          habitId: habitId,
          isAppLockEnabled: isAppLockEnabled,
        );
      case OpenHabitFromReminder():
        // A plain tap opens the app, which navigates; nothing to do in the background.
        break;
    }
  });
}

/// Started by ReminderRebuildReceiver.kt in a headless engine after a reboot, an app update or
/// a time-zone change, so the one-shot reminders keep coming without opening the app.
@pragma('vm:entry-point')
Future<void> rebuildRemindersAfterSystemEvent() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await _runWithDatabase(
      event: 'reminder_system_rebuild_failed',
      (repository, localizations, settings) => _backgroundReminderScheduler.rebuildReminders(
        repository,
        localizations,
        isAppLockEnabled: settings.isAppLockEnabled,
      ),
    );
  } finally {
    await _reminderRebuildChannel.invokeMethod<void>('finished');
  }
}

/// The TodayWidgetProvider.kt engine waits for this call to stop (see HeadlessDartRunner.kt).
const MethodChannel _homeWidgetBackgroundChannel = MethodChannel('com.paulcarouge.komit/home_widget');

/// Started by TodayWidgetProvider.kt in a headless engine. With a habit id in [arguments] (a
/// tap on a row's button) it logs that habit's first objective today, as one tap on the
/// dashboard does; with none (a new day began) it only writes today's checklist again.
@pragma('vm:entry-point')
Future<void> updateHomeWidgetInBackground(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await _runWithDatabase(event: 'home_widget_background_failed', (repository, localizations, settings) async {
      final today = CalendarDay.fromDateTime(DateTime.now());
      final isAppLockEnabled = settings.isAppLockEnabled;
      // A widget drawn before the lock was turned on still has log buttons: they must not bypass it.
      final habitIdToLog = arguments.isEmpty || isAppLockEnabled ? null : int.tryParse(arguments.first);
      if (habitIdToLog != null) {
        await _logFirstObjectiveTodayUnlessLogged(repository, habitId: habitIdToLog, today: today);
      }
      // Saved even when nothing was logged, so the widget drops its optimistic check mark, and
      // before the reminders, so the widget is right even if rebuilding them fails.
      await saveTodayWidgetSnapshot(
        encodeTodayWidgetSnapshot(
          habits: await repository.watchActiveHabits().first,
          objectiveIdByDayByHabitId: await repository.watchObjectiveIdByDayForAllHabitsSince(today).first,
          today: today,
          isAppLockEnabled: isAppLockEnabled,
        ),
      );
      // Dismisses today's reminder of the logged habit and refreshes the streaks of the others.
      if (habitIdToLog != null) {
        await _backgroundReminderScheduler.rebuildReminders(
          repository,
          localizations,
          isAppLockEnabled: isAppLockEnabled,
        );
      }
    });
  } finally {
    await _homeWidgetBackgroundChannel.invokeMethod<void>('finished');
  }
}

/// A widget showing an old state may send a tap for a habit since archived, deleted or logged
/// in the app: those are left as they are rather than overwritten.
Future<void> _logFirstObjectiveTodayUnlessLogged(
  HabitRepository repository, {
  required int habitId,
  required CalendarDay today,
}) async {
  final habit = await repository.watchHabitWithObjectives(habitId).first;
  if (habit == null || habit.habit.archivedAt != null || habit.objectives.isEmpty) return;
  final objectiveIdByDay = await repository.watchObjectiveIdByDayForHabit(habitId).first;
  if (objectiveIdByDay.containsKey(today)) return;
  await repository.logObjectiveForDay(habitId: habitId, objectiveId: habit.objectives.first.id, day: today);
}

/// Opens the database through [AppDatabase], which shares the app's connection when it runs
/// (see docs/adr/0004), and records failures in the private error log instead of losing them.
Future<void> _runWithDatabase(
  Future<void> Function(HabitRepository repository, AppLocalizations localizations, AppSettings settings) work, {
  required String event,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  try {
    final preferences = await SharedPreferences.getInstance();
    // The app may have changed the language since this isolate cached the preferences.
    await preferences.reload();
    final settings = SettingsRepository(preferences).readSettings();
    await work(HabitRepository(database), appLocalizationsFor(settings.languageCode), settings);
  } on Object catch (error, stackTrace) {
    final logger = await AppLogger.openInApplicationSupportDirectory();
    await logger.logError(event: event, error: error, stackTrace: stackTrace);
  } finally {
    await database.close();
  }
}

/// The user's chosen language, else the device's, else English: outside the widget tree there
/// is no Localizations widget to resolve it.
AppLocalizations appLocalizationsFor(String? languageCode) {
  final wantedLanguageCode = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  final locale = AppLocalizations.supportedLocales.firstWhere(
    (supportedLocale) => supportedLocale.languageCode == wantedLanguageCode,
    orElse: () => AppLocalizations.supportedLocales.first,
  );
  return lookupAppLocalizations(locale);
}
