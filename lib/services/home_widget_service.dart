import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../core/calendar_day.dart';
import '../data/repositories/habit_repository.dart';

/// Bumped with TodayWidgetSnapshot.kt whenever the snapshot shape changes.
const int todayWidgetSnapshotFormatVersion = 1;

/// Handled by MainActivity.kt in the app and by TodayWidgetProvider.kt in the background.
const MethodChannel _homeWidgetChannel = MethodChannel('com.paulcarouge.komit/home_widget');

/// The "Today" widget's checklist as JSON: the active habits scheduled on [today], in the
/// dashboard's order, with whether each is logged. Only titles and colors leave the database,
/// never descriptions or notes, as the file lives outside it.
String encodeTodayWidgetSnapshot({
  required List<HabitWithObjectives> habits,
  required Map<int, Map<CalendarDay, int>> objectiveIdByDayByHabitId,
  required CalendarDay today,
}) {
  final scheduledHabits = habits.where(
    // A habit without objectives cannot be logged with one tap, so the widget leaves it to the app.
    (habit) => habit.habit.archivedAt == null && habit.objectives.isNotEmpty && isHabitScheduledOn(habit, today),
  );
  return jsonEncode({
    'version': todayWidgetSnapshotFormatVersion,
    'day': today.daysSinceEpoch,
    'habits': [
      for (final habit in scheduledHabits)
        {
          'id': habit.habit.id,
          'title': habit.habit.title,
          'colorArgb': habit.habit.colorArgb,
          'isLoggedToday': objectiveIdByDayByHabitId[habit.habit.id]?.containsKey(today) ?? false,
        },
    ],
  });
}

/// Hands [snapshotJson] to Android, which saves it in the app's private files and redraws the
/// widget. Does nothing off Android, where there is no widget (tests included).
Future<void> saveTodayWidgetSnapshot(String snapshotJson) async {
  if (!Platform.isAndroid) return;
  final isSaved = await _homeWidgetChannel.invokeMethod<bool>('saveSnapshot', snapshotJson);
  if (isSaved != true) throw StateError('Android refused the widget snapshot');
}
