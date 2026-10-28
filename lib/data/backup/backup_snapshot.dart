import '../../core/calendar_day.dart';

/// Storage-independent copy of all user data, used for import and export.
///
/// Logs are nested under their objective, so a log can never reference
/// a missing habit or objective.
class BackupSnapshot {
  const BackupSnapshot({required this.habits, required this.notes, required this.userName});

  final List<BackupHabit> habits;
  final List<BackupNote> notes;
  final String? userName;

  int get logCount => habits.fold(0, (total, habit) => total + habit.logCount);
}

class BackupHabit {
  const BackupHabit({
    required this.title,
    required this.description,
    required this.colorArgb,
    required this.iconName,
    required this.reminderMinuteOfDay,
    required this.createdAt,
    required this.objectives,
  });

  final String title;
  final String description;
  final int colorArgb;
  final String iconName;
  final int? reminderMinuteOfDay;
  final DateTime createdAt;
  final List<BackupObjective> objectives;

  int get logCount => objectives.fold(0, (total, objective) => total + objective.loggedDays.length);
}

class BackupObjective {
  const BackupObjective({required this.title, required this.colorArgb, required this.loggedDays});

  final String title;
  final int colorArgb;
  final List<CalendarDay> loggedDays;
}

class BackupNote {
  const BackupNote({required this.content, required this.createdAt, required this.updatedAt});

  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class InvalidBackupException implements Exception {
  const InvalidBackupException(this.message);

  final String message;

  @override
  String toString() => 'InvalidBackupException: $message';
}
