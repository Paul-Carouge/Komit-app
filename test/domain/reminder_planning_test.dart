import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/habit_pause.dart';
import 'package:komit/domain/reminder_planning.dart';
import 'package:timezone/data/latest_10y.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;

const int _eightPm = 20 * Duration.minutesPerHour;
const int _mondayAndWednesdayMask = 1 << (DateTime.monday - 1) | 1 << (DateTime.wednesday - 1);

ReminderPlanningHabit _habit({
  int habitId = 1,
  int? reminderMinuteOfDay = _eightPm,
  int scheduledWeekdayMask = everyWeekdayMask,
  bool isArchived = false,
  bool isLoggedToday = false,
  List<HabitPause> pauses = const [],
}) => ReminderPlanningHabit(
  habitId: habitId,
  reminderMinuteOfDay: reminderMinuteOfDay,
  scheduledWeekdayMask: scheduledWeekdayMask,
  isArchived: isArchived,
  isLoggedToday: isLoggedToday,
  pauses: pauses,
);

void main() {
  time_zone_data.initializeTimeZones();
  final paris = tz.getLocation('Europe/Paris');
  // A Wednesday morning.
  final wednesdayMorning = tz.TZDateTime(paris, 2026, 10, 28, 10);
  final wednesday = CalendarDay.fromDate(2026, 10, 28);

  group('planUpcomingReminders', () {
    test('plans one reminder a day for seven days, today included', () {
      final reminders = planUpcomingReminders([_habit()], now: wednesdayMorning);

      expect(reminders.map((reminder) => reminder.day), [
        for (var offset = 0; offset < 7; offset++) wednesday.addDays(offset),
      ]);
      expect(reminders.first.scheduledAt, tz.TZDateTime(paris, 2026, 10, 28, 20));
      expect(reminders.map((reminder) => reminder.notificationId).toSet(), hasLength(7));
    });

    test('skips today once it is logged', () {
      final reminders = planUpcomingReminders([_habit(isLoggedToday: true)], now: wednesdayMorning);

      expect(reminders.first.day, wednesday.addDays(1));
      expect(reminders, hasLength(6));
    });

    test('skips today once the reminder time has passed', () {
      final reminders = planUpcomingReminders([_habit()], now: tz.TZDateTime(paris, 2026, 10, 28, 20));

      expect(reminders.first.day, wednesday.addDays(1));
    });

    test('skips paused days, an open pause included', () {
      final reminders = planUpcomingReminders([
        _habit(
          pauses: [HabitPause(startDay: wednesday.addDays(1), endDay: wednesday.addDays(2))],
        ),
        _habit(habitId: 2, pauses: [HabitPause(startDay: wednesday.addDays(4))]),
      ], now: wednesdayMorning);

      expect(reminders.where((reminder) => reminder.habitId == 1).map((reminder) => reminder.day), [
        wednesday,
        for (var offset = 3; offset < 7; offset++) wednesday.addDays(offset),
      ]);
      expect(reminders.where((reminder) => reminder.habitId == 2).map((reminder) => reminder.day), [
        for (var offset = 0; offset < 4; offset++) wednesday.addDays(offset),
      ]);
    });

    test('skips the weekdays off the habit schedule', () {
      final reminders = planUpcomingReminders([
        _habit(scheduledWeekdayMask: _mondayAndWednesdayMask),
      ], now: wednesdayMorning);

      expect(reminders.map((reminder) => reminder.day), [wednesday, CalendarDay.fromDate(2026, 11, 2)]);
    });

    test('plans nothing for archived habits or habits without a reminder', () {
      final reminders = planUpcomingReminders([
        _habit(isArchived: true),
        _habit(habitId: 2, reminderMinuteOfDay: null),
      ], now: wednesdayMorning);

      expect(reminders, isEmpty);
    });

    test('gives the same ids on every rebuild and distinct ids to habits and the snooze', () {
      final firstPlan = planUpcomingReminders([_habit(), _habit(habitId: 2)], now: wednesdayMorning);
      final secondPlan = planUpcomingReminders([_habit(), _habit(habitId: 2)], now: wednesdayMorning);

      expect(secondPlan, firstPlan);
      final ids = {
        for (final reminder in firstPlan) reminder.notificationId,
        snoozedReminderNotificationIdFor(1),
        snoozedReminderNotificationIdFor(2),
      };
      expect(ids, hasLength(firstPlan.length + 2));
      for (final reminder in firstPlan) {
        expect(habitIdOfReminderNotification(reminder.notificationId), reminder.habitId);
        expect(isSnoozedReminderNotificationId(reminder.notificationId), isFalse);
      }
      expect(isSnoozedReminderNotificationId(snoozedReminderNotificationIdFor(2)), isTrue);
    });

    test('keeps the wall-clock time across the autumn DST change', () {
      // Paris leaves summer time on Sunday 2026-10-25 at 03:00.
      final reminders = planUpcomingReminders([_habit()], now: tz.TZDateTime(paris, 2026, 10, 23, 10));

      expect(reminders.map((reminder) => reminder.scheduledAt.hour).toSet(), {20});
      expect(reminders.first.scheduledAt.timeZoneOffset, const Duration(hours: 2));
      expect(reminders.last.scheduledAt.timeZoneOffset, const Duration(hours: 1));
    });

    test('moves a time inside the spring-forward gap to just after it', () {
      // Paris skips from 02:00 to 03:00 on Sunday 2026-03-29.
      final reminders = planUpcomingReminders([
        _habit(reminderMinuteOfDay: 2 * Duration.minutesPerHour + 30),
      ], now: tz.TZDateTime(paris, 2026, 3, 28, 10));

      final sundayReminder = reminders.singleWhere((reminder) => reminder.day == CalendarDay.fromDate(2026, 3, 29));
      expect(sundayReminder.scheduledAt.hour, 3);
      expect(sundayReminder.scheduledAt.minute, 30);
    });

    test('follows the time zone it is given', () {
      final newYork = tz.getLocation('America/New_York');
      final reminders = planUpcomingReminders([_habit()], now: tz.TZDateTime(newYork, 2026, 10, 28, 10));

      expect(reminders.first.scheduledAt, tz.TZDateTime(newYork, 2026, 10, 28, 20));
      expect(reminders.first.day, wednesday);
    });
  });

  group('diffReminderNotifications', () {
    final habits = [_habit(), _habit(habitId: 2)];
    final plannedPayloads = {
      for (final reminder in planUpcomingReminders(habits, now: wednesdayMorning))
        reminder.notificationId: 'reminder:${reminder.habitId}:${reminder.day.daysSinceEpoch}:a',
    };

    test('changes nothing when nothing changed', () {
      final changes = diffReminderNotifications(
        plannedPayloadByNotificationId: plannedPayloads,
        pendingPayloadByNotificationId: plannedPayloads,
        displayedNotificationIds: const {},
        habits: habits,
        today: wednesday,
      );

      expect(changes.notificationIdsToCancel, isEmpty);
      expect(changes.notificationIdsToSchedule, isEmpty);
    });

    test('replaces only a changed reminder, without cancelling anything', () {
      final changedId = plannedPayloads.keys.first;
      final changes = diffReminderNotifications(
        plannedPayloadByNotificationId: {...plannedPayloads, changedId: 'reminder:1:0:b'},
        pendingPayloadByNotificationId: plannedPayloads,
        displayedNotificationIds: const {},
        habits: habits,
        today: wednesday,
      );

      expect(changes.notificationIdsToCancel, isEmpty);
      expect(changes.notificationIdsToSchedule, {changedId});
    });

    test('cancels only the reminders of a habit that lost its reminder', () {
      final habitTwoIds = {
        for (final id in plannedPayloads.keys)
          if (habitIdOfReminderNotification(id) == 2) id,
      };
      final changes = diffReminderNotifications(
        plannedPayloadByNotificationId: {
          for (final entry in plannedPayloads.entries)
            if (!habitTwoIds.contains(entry.key)) entry.key: entry.value,
        },
        pendingPayloadByNotificationId: plannedPayloads,
        displayedNotificationIds: const {},
        habits: [_habit(), _habit(habitId: 2, reminderMinuteOfDay: null)],
        today: wednesday,
      );

      expect(changes.notificationIdsToCancel, habitTwoIds);
      expect(changes.notificationIdsToSchedule, isEmpty);
    });

    test('keeps a snoozed reminder until its habit is logged, then dismisses it', () {
      final snoozedId = snoozedReminderNotificationIdFor(1);
      final todayId = reminderNotificationIdFor(habitId: 1, day: wednesday);
      final pending = {...plannedPayloads, snoozedId: 'reminder:1:0:a'};

      final whileDue = diffReminderNotifications(
        plannedPayloadByNotificationId: plannedPayloads,
        pendingPayloadByNotificationId: pending,
        displayedNotificationIds: {todayId},
        habits: habits,
        today: wednesday,
      );
      expect(whileDue.notificationIdsToCancel, isEmpty);

      final afterLog = diffReminderNotifications(
        plannedPayloadByNotificationId: {
          for (final entry in plannedPayloads.entries)
            if (entry.key != todayId) entry.key: entry.value,
        },
        pendingPayloadByNotificationId: pending,
        displayedNotificationIds: {todayId},
        habits: [_habit(isLoggedToday: true), _habit(habitId: 2)],
        today: wednesday,
      );
      expect(afterLog.notificationIdsToCancel, {snoozedId, todayId});
    });
  });

  group('reminderResponseCommandFor', () {
    final payload = reminderPayloadFor(habitId: 3, day: wednesday, contentFingerprint: 'f00d');

    test('maps a tap, the snooze and an objective button', () {
      expect(reminderResponseCommandFor(payload: payload, actionId: null), const OpenHabitFromReminder(habitId: 3));
      expect(
        reminderResponseCommandFor(payload: payload, actionId: snoozeReminderActionId),
        const SnoozeReminder(habitId: 3),
      );
      expect(
        reminderResponseCommandFor(payload: payload, actionId: logObjectiveActionIdFor(9)),
        LogObjectiveFromReminder(habitId: 3, objectiveId: 9, day: wednesday),
      );
    });

    test('rejects malformed payloads and actions', () {
      for (final (badPayload, actionId) in [
        (null, null),
        ('', null),
        ('reminder:3:20000', null),
        ('other:3:20000:f', null),
        ('reminder:x:20000:f', null),
        ('reminder:0:20000:f', null),
        (payload, 'log:'),
        (payload, 'log:-1'),
        (payload, 'delete'),
      ]) {
        expect(
          reminderResponseCommandFor(payload: badPayload, actionId: actionId),
          isNull,
          reason: '$badPayload $actionId',
        );
      }
    });

    group('the log draft still goes through the repository invariants', () {
      late AppDatabase database;
      late HabitRepository repository;
      setUp(() {
        database = AppDatabase(NativeDatabase.memory());
        repository = HabitRepository(database, now: () => DateTime(2026, 10, 28, 21));
      });
      tearDown(() => database.close());

      Future<HabitWithObjectives> saveHabit(String title) async {
        final habitId = await repository.saveHabit(
          HabitDraft(
            id: null,
            title: title,
            description: '',
            colorArgb: 1,
            iconName: 'footprints',
            reminderMinuteOfDay: _eightPm,
            objectives: const [ObjectiveDraft(id: null, title: 'Done', colorArgb: 1)],
          ),
        );
        return (await repository.watchHabitWithObjectives(habitId).first)!;
      }

      Future<void> logFrom(LogObjectiveFromReminder command) =>
          repository.logObjectiveForDay(habitId: command.habitId, objectiveId: command.objectiveId, day: command.day);

      test('logs the day of the reminder', () async {
        final habit = await saveHabit('Run');
        final command =
            reminderResponseCommandFor(
                  payload: reminderPayloadFor(habitId: habit.habit.id, day: wednesday, contentFingerprint: 'a'),
                  actionId: logObjectiveActionIdFor(habit.objectives.single.id),
                )!
                as LogObjectiveFromReminder;

        await logFrom(command);

        expect(await repository.watchObjectiveIdByDayForHabit(habit.habit.id).first, {
          wednesday: habit.objectives.single.id,
        });
      });

      test('refuses a future day', () async {
        final habit = await saveHabit('Run');
        final command =
            reminderResponseCommandFor(
                  payload: reminderPayloadFor(
                    habitId: habit.habit.id,
                    day: wednesday.addDays(1),
                    contentFingerprint: 'a',
                  ),
                  actionId: logObjectiveActionIdFor(habit.objectives.single.id),
                )!
                as LogObjectiveFromReminder;

        await expectLater(logFrom(command), throwsA(isA<InvalidLogException>()));
      });

      test('refuses an objective of another habit', () async {
        final habit = await saveHabit('Run');
        final otherHabit = await saveHabit('Read');
        final command =
            reminderResponseCommandFor(
                  payload: reminderPayloadFor(habitId: habit.habit.id, day: wednesday, contentFingerprint: 'a'),
                  actionId: logObjectiveActionIdFor(otherHabit.objectives.single.id),
                )!
                as LogObjectiveFromReminder;

        await expectLater(logFrom(command), throwsA(isA<InvalidLogException>()));
      });
    });
  });

  test('contentFingerprintOf is stable and sensitive to any change', () {
    expect(contentFingerprintOf('Run\n20:00'), contentFingerprintOf('Run\n20:00'));
    expect(contentFingerprintOf('Run\n20:00'), isNot(contentFingerprintOf('Run\n20:01')));
    // FNV-1a reference value for the empty string.
    expect(contentFingerprintOf(''), '811c9dc5');
  });
}
