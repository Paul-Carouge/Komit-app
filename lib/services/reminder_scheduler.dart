import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/repositories/habit_repository.dart';
import '../l10n/app_localizations.dart';

const String _reminderChannelId = 'habit_reminders';

/// Schedules one repeating daily notification per habit that has a reminder.
class ReminderScheduler {
  ReminderScheduler._(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<ReminderScheduler> initialize() async {
    time_zone_data.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } on Object catch (error) {
      // Falls back to UTC: reminders may shift by the UTC offset, but the app keeps working.
      developer.log('Unknown local time zone, using UTC', name: 'komit.reminders', error: error);
    }
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return ReminderScheduler._(plugin);
  }

  /// Returns false when the user refused notifications.
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final isGranted =
        await android?.requestNotificationsPermission() ??
        await ios?.requestPermissions(alert: true, sound: true) ??
        true;
    return isGranted;
  }

  /// Rebuilds every reminder from the current habits, so no stale reminder can survive
  /// a habit deletion, a time change or an import.
  Future<void> replaceAllReminders(List<HabitWithObjectives> habits, AppLocalizations localizations) async {
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    for (final HabitWithObjectives(:habit) in habits) {
      final reminderMinuteOfDay = habit.reminderMinuteOfDay;
      if (reminderMinuteOfDay == null) continue;
      var nextReminder = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        reminderMinuteOfDay ~/ Duration.minutesPerHour,
        reminderMinuteOfDay % Duration.minutesPerHour,
      );
      if (!nextReminder.isAfter(now)) nextReminder = nextReminder.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: habit.id,
        scheduledDate: nextReminder,
        title: localizations.reminderNotificationTitle(habit.title),
        body: localizations.reminderNotificationBody,
        matchDateTimeComponents: DateTimeComponents.time,
        // Inexact is enough for a daily nudge and needs no exact-alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(_reminderChannelId, localizations.reminderChannelName),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }
}
