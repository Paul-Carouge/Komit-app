import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/calendar_day.dart';
import '../core/sequential_task_runner.dart';
import '../core/theme/app_theme.dart';
import '../data/repositories/habit_repository.dart';
import '../domain/habit_statistics.dart';
import '../domain/reminder_planning.dart';
import '../l10n/app_localizations.dart';
import 'reminder_background_work.dart';

const String _reminderChannelId = 'habit_reminders';

/// Groups Komit's reminders into one stack in the notification shade.
const String _reminderGroupKey = 'com.paulcarouge.komit.HABIT_REMINDERS';

/// "Later" on a reminder brings it back after this long.
const Duration reminderSnoozeDuration = Duration(hours: 1);

/// Android shows three buttons at most; "Later" takes the third.
const int _maximumObjectiveButtonsOnReminder = 2;

/// Opens the notifications plugin; [onForegroundResponse] receives taps while the app runs.
typedef NotificationsPluginInitializer = Future<FlutterLocalNotificationsPlugin> Function(
  DidReceiveNotificationResponseCallback onForegroundResponse,
);

/// Thrown when Android refuses to set up notifications.
class ReminderSchedulerUnavailableException implements Exception {
  const ReminderSchedulerUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ReminderSchedulerUnavailableException: $message';
}

/// Plans one-shot reminders for the next [reminderPlanningDayCount] days of every habit.
///
/// Initialization runs in the background: until it finishes every call waits for it, and if
/// it fails the scheduler stays unavailable (every call does nothing) instead of stopping the
/// app from starting.
class ReminderScheduler {
  ReminderScheduler._(this._pluginWhenReady, this._habitIdsOpenedFromReminders);

  /// Starts initializing after [startAfter] without waiting for it. Never throws:
  /// [onInitializationFailed] receives the error and the scheduler becomes unavailable.
  factory ReminderScheduler.startInitializing({
    Future<void>? startAfter,
    NotificationsPluginInitializer initializePlugin = initializeNotificationsPlugin,
    void Function(Object error, StackTrace stackTrace)? onInitializationFailed,
  }) {
    // Single-subscription, so a tap that launched the app waits until the app listens.
    final habitIdsOpenedFromReminders = StreamController<int>();
    void onForegroundResponse(NotificationResponse response) {
      if (reminderResponseCommandFor(payload: response.payload, actionId: response.actionId) case OpenHabitFromReminder(
        :final habitId,
      )) {
        habitIdsOpenedFromReminders.add(habitId);
      }
    }

    Future<FlutterLocalNotificationsPlugin?> initialize() async {
      try {
        await startAfter;
        final plugin = await initializePlugin(onForegroundResponse);
        final launchDetails = await plugin.getNotificationAppLaunchDetails();
        final launchResponse = launchDetails?.notificationResponse;
        if (launchDetails?.didNotificationLaunchApp == true && launchResponse != null) {
          onForegroundResponse(launchResponse);
        }
        return plugin;
      } on Object catch (error, stackTrace) {
        onInitializationFailed?.call(error, stackTrace);
        return null;
      }
    }

    return ReminderScheduler._(initialize(), habitIdsOpenedFromReminders);
  }

  final Future<FlutterLocalNotificationsPlugin?> _pluginWhenReady;
  final StreamController<int> _habitIdsOpenedFromReminders;
  final SequentialTaskRunner _reminderRebuilds = SequentialTaskRunner();

  /// False once initialization failed: reminders cannot be shown on this device.
  Future<bool> get isAvailable async => await _pluginWhenReady != null;

  /// Habits whose reminder the user tapped, including the one that launched the app.
  /// Listen at most once.
  Stream<int> get habitIdsOpenedFromReminders => _habitIdsOpenedFromReminders.stream;

  /// Returns false when the user refused notifications or reminders are unavailable.
  Future<bool> requestPermission() async {
    final plugin = await _pluginWhenReady;
    final android = plugin?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Reads the device time zone again, e.g. when the app resumes after travelling.
  Future<void> refreshLocalTimeZone() async {
    if (await _pluginWhenReady == null) return;
    await useDeviceTimeZone();
  }

  /// Brings the system's reminders in line with the database. Only new or changed reminders
  /// are scheduled and only obsolete ones cancelled, so a displayed reminder survives.
  ///
  /// Calls run one at a time: two overlapping rebuilds could otherwise interleave their
  /// cancel and schedule steps and resurrect the reminder of a deleted habit.
  ///
  /// With [isAppLockEnabled] reminders name no habit and offer no log button: the notification
  /// shade of an unlocked phone is open to whoever holds it, and a tap opens the locked app.
  Future<void> rebuildReminders(
    HabitRepository repository,
    AppLocalizations localizations, {
    required bool isAppLockEnabled,
  }) => _reminderRebuilds.run(() async {
    final plugin = await _pluginWhenReady;
    if (plugin == null) return;
    await _rebuildRemindersNow(plugin, repository, localizations, isAppLockEnabled: isAppLockEnabled);
  });

  /// Shows the reminder of [habitId] again after [reminderSnoozeDuration].
  Future<void> snoozeReminder(
    HabitRepository repository,
    AppLocalizations localizations, {
    required int habitId,
    required bool isAppLockEnabled,
  }) => _reminderRebuilds.run(() async {
    final plugin = await _pluginWhenReady;
    if (plugin == null) return;
    final habit = await repository.watchHabitWithObjectives(habitId).first;
    if (habit == null || habit.habit.archivedAt != null) return;
    final now = tz.TZDateTime.now(tz.local);
    final content = await _reminderContentFor(
      habit,
      repository,
      localizations,
      day: CalendarDay.fromDate(now.year, now.month, now.day),
      scheduledAt: now.add(reminderSnoozeDuration),
      isAppLockEnabled: isAppLockEnabled,
    );
    await _schedule(plugin, snoozedReminderNotificationIdFor(habitId), content);
  });

  Future<void> _rebuildRemindersNow(
    FlutterLocalNotificationsPlugin plugin,
    HabitRepository repository,
    AppLocalizations localizations, {
    required bool isAppLockEnabled,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final today = CalendarDay.fromDate(now.year, now.month, now.day);
    final (activeHabits, archivedHabits, logsSinceToday) = await (
      repository.watchActiveHabits().first,
      repository.watchArchivedHabits().first,
      repository.watchObjectiveIdByDayForAllHabitsSince(today).first,
    ).wait;
    final habitById = {
      for (final habit in [...activeHabits, ...archivedHabits]) habit.habit.id: habit,
    };
    final planningHabits = [
      for (final HabitWithObjectives(:habit, :pauses) in habitById.values)
        ReminderPlanningHabit(
          habitId: habit.id,
          reminderMinuteOfDay: habit.reminderMinuteOfDay,
          scheduledWeekdayMask: habit.scheduledWeekdayMask,
          isArchived: habit.archivedAt != null,
          isLoggedToday: logsSinceToday[habit.id]?.containsKey(today) ?? false,
          pauses: pauses,
        ),
    ];
    final contentByNotificationId = <int, _ReminderContent>{
      for (final reminder in planUpcomingReminders(planningHabits, now: now))
        reminder.notificationId: await _reminderContentFor(
          habitById[reminder.habitId]!,
          repository,
          localizations,
          day: reminder.day,
          scheduledAt: reminder.scheduledAt,
          isAppLockEnabled: isAppLockEnabled,
        ),
    };
    final (pendingRequests, displayedNotifications) = await (
      plugin.pendingNotificationRequests(),
      plugin.getActiveNotifications(),
    ).wait;
    final changes = diffReminderNotifications(
      plannedPayloadByNotificationId: {
        for (final MapEntry(key: notificationId, value: content) in contentByNotificationId.entries)
          notificationId: content.payload,
      },
      pendingPayloadByNotificationId: {for (final request in pendingRequests) request.id: request.payload},
      displayedNotificationIds: {
        for (final notification in displayedNotifications)
          if (notification.channelId == _reminderChannelId) ?notification.id,
      },
      habits: planningHabits,
      today: today,
    );
    for (final notificationId in changes.notificationIdsToCancel) {
      await plugin.cancel(id: notificationId);
    }
    for (final notificationId in changes.notificationIdsToSchedule) {
      await _schedule(plugin, notificationId, contentByNotificationId[notificationId]!);
    }
  }

  Future<_ReminderContent> _reminderContentFor(
    HabitWithObjectives habit,
    HabitRepository repository,
    AppLocalizations localizations, {
    required CalendarDay day,
    required tz.TZDateTime scheduledAt,
    required bool isAppLockEnabled,
  }) async {
    final streak = streakSummaryOf(
      habit,
      await repository.watchObjectiveIdByDayForHabit(habit.habit.id).first,
      today: day,
    );
    final title = isAppLockEnabled
        ? localizations.reminderLockedNotificationTitle
        : localizations.reminderNotificationTitle(habit.habit.title);
    final body = switch ((streak.currentStreakLength, streak.unit)) {
      _ when isAppLockEnabled => localizations.reminderLockedNotificationBody,
      (0, _) => localizations.reminderNotificationBody,
      (final length, StreakUnit.days) => localizations.reminderNotificationBodyWithDayStreak(length),
      (final length, StreakUnit.weeks) => localizations.reminderNotificationBodyWithWeekStreak(length),
    };
    final actions = [
      // Objective titles may say as much as the habit's, and logging must go through the lock.
      if (!isAppLockEnabled) ...[
        if (habit.objectives.length == 1)
          AndroidNotificationAction(
            logObjectiveActionIdFor(habit.objectives.single.id),
            localizations.reminderActionDone,
          )
        else
          for (final objective in habit.objectives.take(_maximumObjectiveButtonsOnReminder))
            AndroidNotificationAction(logObjectiveActionIdFor(objective.id), objective.title),
      ],
      AndroidNotificationAction(snoozeReminderActionId, localizations.reminderActionLater),
    ];
    final fingerprint = contentFingerprintOf(
      [
        title,
        body,
        scheduledAt.toIso8601String(),
        scheduledAt.location.name,
        localizations.reminderChannelDescription,
        for (final action in actions) '${action.id}=${action.title}',
      ].join('\n'),
    );
    return _ReminderContent(
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: reminderPayloadFor(habitId: habit.habit.id, day: day, contentFingerprint: fingerprint),
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          localizations.reminderChannelName,
          channelDescription: localizations.reminderChannelDescription,
          category: AndroidNotificationCategory.reminder,
          // The lock screen shows only "Komit" and Android's "Contents hidden", never the
          // habit name: the plugin offers no custom public version, and this neutral one fits.
          visibility: NotificationVisibility.private,
          color: komitBrandOrange,
          groupKey: _reminderGroupKey,
          actions: actions,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _schedule(FlutterLocalNotificationsPlugin plugin, int notificationId, _ReminderContent content) =>
      plugin.zonedSchedule(
        id: notificationId,
        scheduledDate: content.scheduledAt,
        title: content.title,
        body: content.body,
        payload: content.payload,
        notificationDetails: content.details,
        // Inexact is enough for a daily nudge and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
}

class _ReminderContent {
  const _ReminderContent({
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
    required this.details,
  });

  final String title;
  final String body;
  final tz.TZDateTime scheduledAt;
  final String payload;
  final NotificationDetails details;
}

/// Loads the time-zone rules and the notifications plugin. Used by the app and by the
/// background isolates that handle reminder buttons and system events.
Future<FlutterLocalNotificationsPlugin> initializeNotificationsPlugin(
  DidReceiveNotificationResponseCallback onForegroundResponse,
) async {
  // The 10-year rules cover every reminder Komit plans and load faster than the full history.
  time_zone_data.initializeTimeZones();
  await useDeviceTimeZone();
  final plugin = FlutterLocalNotificationsPlugin();
  final isInitialized = await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_komo'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
    onDidReceiveNotificationResponse: onForegroundResponse,
    onDidReceiveBackgroundNotificationResponse: handleReminderResponseInBackground,
  );
  if (isInitialized == false) throw const ReminderSchedulerUnavailableException('plugin initialization refused');
  return plugin;
}

/// Points the time-zone library at the device's zone.
Future<void> useDeviceTimeZone() async {
  try {
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
  } on Object catch (error) {
    // Falls back to UTC: reminders may shift by the UTC offset, but the app keeps working.
    developer.log('Unknown local time zone, using UTC', name: 'komit.reminders', error: error);
  }
}
