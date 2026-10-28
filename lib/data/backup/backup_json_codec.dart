import 'dart:convert';

import '../../core/calendar_day.dart';
import '../database/app_database.dart';
import 'backup_snapshot.dart';

const String backupFormatName = 'komit-backup';
const int currentBackupFormatVersion = 2;

/// Versions written by the first Komit app (Isar based) have no `format` key.
const int legacyBackupFormatVersion = 1;

String encodeBackupSnapshotToJson(BackupSnapshot snapshot, {required DateTime exportedAt}) {
  return const JsonEncoder.withIndent(' ').convert({
    'format': backupFormatName,
    'version': currentBackupFormatVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'userName': snapshot.userName,
    'habits': [
      for (final habit in snapshot.habits)
        {
          'title': habit.title,
          'description': habit.description,
          'colorArgb': habit.colorArgb,
          'iconName': habit.iconName,
          'reminderMinuteOfDay': habit.reminderMinuteOfDay,
          'createdAt': habit.createdAt.toUtc().toIso8601String(),
          'objectives': [
            for (final objective in habit.objectives)
              {
                'title': objective.title,
                'colorArgb': objective.colorArgb,
                'loggedDays': [for (final day in objective.loggedDays) _formatIsoDate(day)],
              },
          ],
        },
    ],
    'notes': [
      for (final note in snapshot.notes)
        {
          'content': note.content,
          'createdAt': note.createdAt.toUtc().toIso8601String(),
          'updatedAt': note.updatedAt.toUtc().toIso8601String(),
        },
    ],
  });
}

/// Decodes a backup written by this app (v2) or by the original Komit app (v1).
///
/// Throws [InvalidBackupException] with a readable reason on any malformed input:
/// nothing must be written to the database from a half-understood file.
BackupSnapshot decodeBackupSnapshotFromJson(String jsonText) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } on FormatException catch (error) {
    throw InvalidBackupException('File is not valid JSON: ${error.message}');
  }
  final root = _asMap(decoded, 'root');
  final version = root['version'];
  final snapshot = switch (version) {
    currentBackupFormatVersion when root['format'] == backupFormatName => _decodeCurrentFormat(root),
    legacyBackupFormatVersion => _decodeLegacyFormat(root),
    _ => throw InvalidBackupException('Unsupported backup version: $version'),
  };
  _validateSnapshot(snapshot);
  return snapshot;
}

BackupSnapshot _decodeCurrentFormat(Map<String, Object?> root) {
  return BackupSnapshot(
    userName: _optionalString(root['userName'], 'userName'),
    habits: [
      for (final (index, rawHabit) in _asList(root['habits'], 'habits').indexed)
        _decodeCurrentHabit(_asMap(rawHabit, 'habits[$index]'), 'habits[$index]'),
    ],
    notes: [
      for (final (index, rawNote) in _asList(root['notes'], 'notes').indexed)
        _decodeNote(_asMap(rawNote, 'notes[$index]'), 'notes[$index]'),
    ],
  );
}

BackupHabit _decodeCurrentHabit(Map<String, Object?> habit, String path) {
  return BackupHabit(
    title: _requiredTrimmedString(habit['title'], '$path.title'),
    description: _optionalString(habit['description'], '$path.description') ?? '',
    colorArgb: _requiredInt(habit['colorArgb'], '$path.colorArgb'),
    iconName: _requiredTrimmedString(habit['iconName'], '$path.iconName'),
    reminderMinuteOfDay: habit['reminderMinuteOfDay'] == null
        ? null
        : _requiredInt(habit['reminderMinuteOfDay'], '$path.reminderMinuteOfDay'),
    createdAt: _requiredDateTime(habit['createdAt'], '$path.createdAt'),
    objectives: [
      for (final (index, rawObjective) in _asList(habit['objectives'], '$path.objectives').indexed)
        _decodeCurrentObjective(_asMap(rawObjective, '$path.objectives[$index]'), '$path.objectives[$index]'),
    ],
  );
}

BackupObjective _decodeCurrentObjective(Map<String, Object?> objective, String path) {
  return BackupObjective(
    title: _requiredTrimmedString(objective['title'], '$path.title'),
    colorArgb: _requiredInt(objective['colorArgb'], '$path.colorArgb'),
    loggedDays: [
      for (final (index, rawDay) in _asList(objective['loggedDays'], '$path.loggedDays').indexed)
        _requiredCalendarDay(rawDay, '$path.loggedDays[$index]'),
    ],
  );
}

/// The v1 format stores logs flat, pointing at their objective by title and color.
BackupSnapshot _decodeLegacyFormat(Map<String, Object?> root) {
  final legacyHabitsById = <int, _LegacyHabit>{};
  for (final (index, rawHabit) in _asList(root['habits'], 'habits').indexed) {
    final path = 'habits[$index]';
    final habit = _asMap(rawHabit, path);
    final legacyId = _requiredInt(habit['id'], '$path.id');
    if (legacyHabitsById.containsKey(legacyId)) {
      throw InvalidBackupException('$path.id: duplicate habit id $legacyId');
    }
    final legacyHabit = _LegacyHabit(
      title: _requiredTrimmedString(habit['title'], '$path.title'),
      description: _optionalString(habit['description'], '$path.description')?.trim() ?? '',
      colorArgb: _requiredHexColor(habit['colorHex'], '$path.colorHex'),
      iconName: _requiredTrimmedString(habit['iconCode'], '$path.iconCode'),
      reminderMinuteOfDay: _legacyReminderMinuteOfDay(habit['reminderTime'], '$path.reminderTime'),
      createdAt: _requiredDateTime(habit['createdAt'], '$path.createdAt'),
    );
    for (final (objectiveIndex, rawObjective) in _asList(habit['objectives'], '$path.objectives').indexed) {
      final objectivePath = '$path.objectives[$objectiveIndex]';
      final objective = _asMap(rawObjective, objectivePath);
      legacyHabit.objectiveFor(
        title: _requiredTrimmedString(objective['title'], '$objectivePath.title'),
        colorArgb: _requiredHexColor(objective['colorHex'], '$objectivePath.colorHex'),
      );
    }
    legacyHabitsById[legacyId] = legacyHabit;
  }

  for (final (index, rawLog) in _asList(root['logs'], 'logs').indexed) {
    final path = 'logs[$index]';
    final log = _asMap(rawLog, path);
    final habitId = _requiredInt(log['habitId'], '$path.habitId');
    final habit = legacyHabitsById[habitId];
    if (habit == null) {
      throw InvalidBackupException('$path.habitId: no habit with id $habitId');
    }
    // An objective deleted in the old app left its logs behind: recreate it rather than lose them.
    habit
        .objectiveFor(
          title: _requiredTrimmedString(log['objectiveTitle'], '$path.objectiveTitle'),
          colorArgb: _requiredHexColor(log['objectiveColorHex'], '$path.objectiveColorHex'),
        )
        .loggedDays
        .add(_requiredCalendarDay(log['date'], '$path.date'));
  }

  final prefs = root['prefs'] == null ? const <String, Object?>{} : _asMap(root['prefs'], 'prefs');
  return BackupSnapshot(
    userName: _optionalString(prefs['user_name'], 'prefs.user_name')?.trim(),
    habits: [for (final habit in legacyHabitsById.values) habit.toBackupHabit()],
    notes: [
      for (final (index, rawNote) in _asList(root['notes'] ?? const <Object?>[], 'notes').indexed)
        _decodeNote(_asMap(rawNote, 'notes[$index]'), 'notes[$index]'),
    ],
  );
}

class _LegacyHabit {
  _LegacyHabit({
    required this.title,
    required this.description,
    required this.colorArgb,
    required this.iconName,
    required this.reminderMinuteOfDay,
    required this.createdAt,
  });

  final String title;
  final String description;
  final int colorArgb;
  final String iconName;
  final int? reminderMinuteOfDay;
  final DateTime createdAt;
  final Map<String, _LegacyObjective> objectivesByTitle = {};

  _LegacyObjective objectiveFor({required String title, required int colorArgb}) =>
      objectivesByTitle.putIfAbsent(title, () => _LegacyObjective(title, colorArgb));

  BackupHabit toBackupHabit() => BackupHabit(
    title: title,
    description: description,
    colorArgb: colorArgb,
    iconName: iconName,
    reminderMinuteOfDay: reminderMinuteOfDay,
    createdAt: createdAt,
    objectives: [
      for (final objective in objectivesByTitle.values)
        BackupObjective(title: objective.title, colorArgb: objective.colorArgb, loggedDays: objective.loggedDays),
    ],
  );
}

class _LegacyObjective {
  _LegacyObjective(this.title, this.colorArgb);

  final String title;
  final int colorArgb;
  final List<CalendarDay> loggedDays = [];
}

BackupNote _decodeNote(Map<String, Object?> note, String path) {
  final createdAt = _requiredDateTime(note['createdAt'] ?? note['date'], '$path.createdAt');
  return BackupNote(
    content:
        _optionalString(note['content'], '$path.content') ?? (throw InvalidBackupException('$path.content: missing')),
    createdAt: createdAt,
    updatedAt: note['updatedAt'] == null ? createdAt : _requiredDateTime(note['updatedAt'], '$path.updatedAt'),
  );
}

void _validateSnapshot(BackupSnapshot snapshot) {
  for (final habit in snapshot.habits) {
    if (habit.title.length > maximumHabitTitleLength) {
      throw InvalidBackupException('Habit "${habit.title}": title longer than $maximumHabitTitleLength characters');
    }
    if (habit.reminderMinuteOfDay case final minute? when minute < 0 || minute >= Duration.minutesPerDay) {
      throw InvalidBackupException('Habit "${habit.title}": invalid reminder minute $minute');
    }
    if (habit.objectives.isEmpty) {
      throw InvalidBackupException('Habit "${habit.title}": has no objective');
    }
    final objectiveTitles = <String>{};
    final loggedDays = <CalendarDay>{};
    for (final objective in habit.objectives) {
      if (objective.title.length > maximumObjectiveTitleLength) {
        throw InvalidBackupException('Objective "${objective.title}": title too long');
      }
      if (!objectiveTitles.add(objective.title)) {
        throw InvalidBackupException('Habit "${habit.title}": duplicate objective "${objective.title}"');
      }
      for (final day in objective.loggedDays) {
        if (!loggedDays.add(day)) {
          throw InvalidBackupException('Habit "${habit.title}": two logs on ${_formatIsoDate(day)}');
        }
      }
    }
  }
}

Map<String, Object?> _asMap(Object? value, String path) =>
    value is Map<String, Object?> ? value : throw InvalidBackupException('$path: expected an object');

List<Object?> _asList(Object? value, String path) =>
    value is List<Object?> ? value : throw InvalidBackupException('$path: expected a list');

int _requiredInt(Object? value, String path) =>
    value is int ? value : throw InvalidBackupException('$path: expected an integer');

String? _optionalString(Object? value, String path) =>
    value == null || value is String ? value as String? : throw InvalidBackupException('$path: expected a string');

String _requiredTrimmedString(Object? value, String path) {
  final trimmed = _optionalString(value, path)?.trim() ?? '';
  return trimmed.isNotEmpty ? trimmed : throw InvalidBackupException('$path: must not be empty');
}

DateTime _requiredDateTime(Object? value, String path) =>
    DateTime.tryParse(_requiredTrimmedString(value, path)) ??
    (throw InvalidBackupException('$path: invalid date "$value"'));

/// Reads the calendar date as written, ignoring any time part, so no time zone can shift it.
CalendarDay _requiredCalendarDay(Object? value, String path) {
  final text = _requiredTrimmedString(value, path);
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
  if (match == null) throw InvalidBackupException('$path: invalid date "$text"');
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final calendarDay = CalendarDay.fromDate(year, month, day);
  // DateTime silently rolls 2025-02-30 over to March; reject it instead.
  final roundTrip = calendarDay.asUtcDate;
  if (roundTrip.month != month || roundTrip.day != day) {
    throw InvalidBackupException('$path: invalid date "$text"');
  }
  return calendarDay;
}

int _requiredHexColor(Object? value, String path) {
  final text = _requiredTrimmedString(value, path);
  final hasEightHexDigits = RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(text);
  return hasEightHexDigits ? int.parse(text, radix: 16) : throw InvalidBackupException('$path: invalid color "$text"');
}

/// The old app stored the reminder as a full date-time; only the time of day matters.
int? _legacyReminderMinuteOfDay(Object? value, String path) {
  if (value == null) return null;
  final reminder = _requiredDateTime(value, path);
  return reminder.hour * Duration.minutesPerHour + reminder.minute;
}

String _formatIsoDate(CalendarDay day) => day.asUtcDate.toIso8601String().substring(0, 10);
