import 'package:timezone/timezone.dart' as tz;

import '../core/calendar_day.dart';
import 'habit_pause.dart';
import 'habit_schedule.dart';

/// Reminders are planned as one-shot notifications for this many calendar days, today
/// included. The plan is rebuilt on every launch, resume, log, boot and time-zone change, so a
/// week ahead keeps reminders coming even for someone who rarely opens the app.
const int reminderPlanningDayCount = DateTime.daysPerWeek;

/// One notification id per planned day of the week cycle, plus one for the snoozed reminder.
/// Ids stay below 2^31 (Android's int) for any habit id under 268 million.
const int _notificationIdSlotsPerHabit = reminderPlanningDayCount + 1;
const int _snoozedReminderSlot = reminderPlanningDayCount;

/// The same habit and day always get the same id, so a rebuild can compare plans by id.
int reminderNotificationIdFor({required int habitId, required CalendarDay day}) =>
    habitId * _notificationIdSlotsPerHabit + day.daysSinceEpoch % reminderPlanningDayCount;

int snoozedReminderNotificationIdFor(int habitId) => habitId * _notificationIdSlotsPerHabit + _snoozedReminderSlot;

bool isSnoozedReminderNotificationId(int notificationId) =>
    notificationId % _notificationIdSlotsPerHabit == _snoozedReminderSlot;

int habitIdOfReminderNotification(int notificationId) => notificationId ~/ _notificationIdSlotsPerHabit;

/// What the planner needs to know about one habit.
class ReminderPlanningHabit {
  const ReminderPlanningHabit({
    required this.habitId,
    required this.reminderMinuteOfDay,
    required this.scheduledWeekdayMask,
    required this.isArchived,
    required this.isLoggedToday,
    this.pauses = const [],
  });

  final int habitId;

  /// Null when the habit has no reminder.
  final int? reminderMinuteOfDay;
  final int scheduledWeekdayMask;
  final bool isArchived;
  final bool isLoggedToday;

  /// A paused habit sends no reminder (docs/adr/0007).
  final List<HabitPause> pauses;

  /// Whether a reminder about this habit may still be shown on [today].
  bool isDueOn(CalendarDay today) =>
      reminderMinuteOfDay != null && !isArchived && !isLoggedToday && !isPausedOn(pauses, today);
}

class PlannedReminder {
  const PlannedReminder({
    required this.notificationId,
    required this.habitId,
    required this.day,
    required this.scheduledAt,
  });

  final int notificationId;
  final int habitId;
  final CalendarDay day;
  final tz.TZDateTime scheduledAt;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.notificationId == notificationId &&
      other.habitId == habitId &&
      other.day == day &&
      other.scheduledAt == scheduledAt;

  @override
  int get hashCode => Object.hash(notificationId, habitId, day, scheduledAt);

  @override
  String toString() => 'PlannedReminder(habit $habitId, day ${day.daysSinceEpoch}, $scheduledAt)';
}

/// Every reminder due strictly after [now] over the next [reminderPlanningDayCount] days,
/// skipping archived habits, days off the habit's schedule, paused days and today once it is
/// logged.
List<PlannedReminder> planUpcomingReminders(Iterable<ReminderPlanningHabit> habits, {required tz.TZDateTime now}) {
  final today = CalendarDay.fromDate(now.year, now.month, now.day);
  return [
    for (final habit in habits)
      if (habit.reminderMinuteOfDay case final reminderMinuteOfDay? when !habit.isArchived)
        for (var dayOffset = 0; dayOffset < reminderPlanningDayCount; dayOffset++)
          ?_plannedReminderOn(habit, today.addDays(dayOffset), reminderMinuteOfDay, now: now, today: today),
  ];
}

PlannedReminder? _plannedReminderOn(
  ReminderPlanningHabit habit,
  CalendarDay day,
  int reminderMinuteOfDay, {
  required tz.TZDateTime now,
  required CalendarDay today,
}) {
  if (!isWeekdayScheduled(habit.scheduledWeekdayMask, day.weekday) || isPausedOn(habit.pauses, day)) return null;
  if (day == today && habit.isLoggedToday) return null;
  final date = day.asUtcDate;
  // Built from calendar fields, not by adding 24 hours, so a DST change keeps the wall-clock
  // time; a time inside a spring-forward gap moves to just after it.
  final scheduledAt = tz.TZDateTime(
    now.location,
    date.year,
    date.month,
    date.day,
    reminderMinuteOfDay ~/ Duration.minutesPerHour,
    reminderMinuteOfDay % Duration.minutesPerHour,
  );
  if (!scheduledAt.isAfter(now)) return null;
  return PlannedReminder(
    notificationId: reminderNotificationIdFor(habitId: habit.habitId, day: day),
    habitId: habit.habitId,
    day: day,
    scheduledAt: scheduledAt,
  );
}

/// What a rebuild must change in the system's notifications.
class ReminderNotificationChanges {
  const ReminderNotificationChanges({required this.notificationIdsToSchedule, required this.notificationIdsToCancel});

  /// New or changed reminders; scheduling an existing id replaces it.
  final Set<int> notificationIdsToSchedule;

  /// Never contains an unchanged reminder, so displayed notifications survive a rebuild.
  final Set<int> notificationIdsToCancel;
}

/// Compares the wanted reminders with what the system holds, by id and payload (which carries
/// a fingerprint of the content), instead of cancelling everything and starting again.
///
/// A snoozed reminder stays while its habit is still due today. A displayed reminder for
/// today, or a snoozed one, is dismissed once its habit is logged, archived or loses its
/// reminder.
ReminderNotificationChanges diffReminderNotifications({
  required Map<int, String> plannedPayloadByNotificationId,
  required Map<int, String?> pendingPayloadByNotificationId,
  required Set<int> displayedNotificationIds,
  required Iterable<ReminderPlanningHabit> habits,
  required CalendarDay today,
}) {
  final habitIdsDueToday = {
    for (final habit in habits)
      if (habit.isDueOn(today)) habit.habitId,
  };
  final notificationIdsNoLongerDueToday = {
    for (final habit in habits)
      if (!habit.isDueOn(today)) ...[
        reminderNotificationIdFor(habitId: habit.habitId, day: today),
        snoozedReminderNotificationIdFor(habit.habitId),
      ],
  };
  bool isKeptSnooze(int notificationId) =>
      isSnoozedReminderNotificationId(notificationId) &&
      habitIdsDueToday.contains(habitIdOfReminderNotification(notificationId));
  return ReminderNotificationChanges(
    notificationIdsToSchedule: {
      for (final MapEntry(key: notificationId, value: payload) in plannedPayloadByNotificationId.entries)
        if (pendingPayloadByNotificationId[notificationId] != payload) notificationId,
    },
    notificationIdsToCancel: {
      for (final notificationId in pendingPayloadByNotificationId.keys)
        if (!plannedPayloadByNotificationId.containsKey(notificationId) && !isKeptSnooze(notificationId))
          notificationId,
      for (final notificationId in displayedNotificationIds)
        if (notificationIdsNoLongerDueToday.contains(notificationId) &&
            !plannedPayloadByNotificationId.containsKey(notificationId))
          notificationId,
    },
  );
}

/// What a tap on a reminder, or on one of its buttons, asks for.
sealed class ReminderResponseCommand {
  const ReminderResponseCommand();
}

/// The log draft of a "Done" or objective button; [HabitRepository.logObjectiveForDay] still
/// checks that the day is not in the future and that the objective belongs to the habit.
final class LogObjectiveFromReminder extends ReminderResponseCommand {
  const LogObjectiveFromReminder({required this.habitId, required this.objectiveId, required this.day});

  final int habitId;
  final int objectiveId;
  final CalendarDay day;

  @override
  bool operator ==(Object other) =>
      other is LogObjectiveFromReminder &&
      other.habitId == habitId &&
      other.objectiveId == objectiveId &&
      other.day == day;

  @override
  int get hashCode => Object.hash(habitId, objectiveId, day);
}

final class SnoozeReminder extends ReminderResponseCommand {
  const SnoozeReminder({required this.habitId});

  final int habitId;

  @override
  bool operator ==(Object other) => other is SnoozeReminder && other.habitId == habitId;

  @override
  int get hashCode => habitId.hashCode;
}

final class OpenHabitFromReminder extends ReminderResponseCommand {
  const OpenHabitFromReminder({required this.habitId});

  final int habitId;

  @override
  bool operator ==(Object other) => other is OpenHabitFromReminder && other.habitId == habitId;

  @override
  int get hashCode => habitId.hashCode;
}

const String snoozeReminderActionId = 'snooze';
const String _logObjectiveActionIdPrefix = 'log:';
const String _reminderPayloadPrefix = 'reminder';
const String _reminderPayloadSeparator = ':';

String logObjectiveActionIdFor(int objectiveId) => '$_logObjectiveActionIdPrefix$objectiveId';

/// `reminder:<habitId>:<day>:<contentFingerprint>`. The fingerprint changes whenever the
/// title, body, time or buttons change, so comparing payloads tells whether a reminder changed.
String reminderPayloadFor({required int habitId, required CalendarDay day, required String contentFingerprint}) =>
    [_reminderPayloadPrefix, habitId, day.daysSinceEpoch, contentFingerprint].join(_reminderPayloadSeparator);

/// Null for anything that is not a well-formed Komit reminder: the payload and action come
/// back from the system and are validated like any other input.
ReminderResponseCommand? reminderResponseCommandFor({required String? payload, required String? actionId}) {
  final parts = payload?.split(_reminderPayloadSeparator);
  if (parts == null || parts.length != 4 || parts[0] != _reminderPayloadPrefix) return null;
  final habitId = int.tryParse(parts[1]);
  final daysSinceEpoch = int.tryParse(parts[2]);
  if (habitId == null || habitId <= 0 || daysSinceEpoch == null) return null;
  if (actionId == null || actionId.isEmpty) return OpenHabitFromReminder(habitId: habitId);
  if (actionId == snoozeReminderActionId) return SnoozeReminder(habitId: habitId);
  if (!actionId.startsWith(_logObjectiveActionIdPrefix)) return null;
  final objectiveId = int.tryParse(actionId.substring(_logObjectiveActionIdPrefix.length));
  if (objectiveId == null || objectiveId <= 0) return null;
  return LogObjectiveFromReminder(habitId: habitId, objectiveId: objectiveId, day: CalendarDay(daysSinceEpoch));
}

const int _fnvOffsetBasis = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _thirtyTwoBitMask = 0xFFFFFFFF;

/// A stable FNV-1a hash: unlike [Object.hash], it is the same on every launch, which the
/// comparison with notifications scheduled by an earlier launch needs.
String contentFingerprintOf(String content) {
  var hash = _fnvOffsetBasis;
  for (final codeUnit in content.codeUnits) {
    hash = ((hash ^ codeUnit) * _fnvPrime) & _thirtyTwoBitMask;
  }
  return hash.toRadixString(16);
}
