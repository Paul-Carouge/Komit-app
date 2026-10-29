import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import '../core/calendar_day.dart';
import '../data/backup/backup_json_codec.dart';
import '../data/backup/backup_snapshot.dart';
import '../data/repositories/backup_repository.dart';

/// Older automatic backups are deleted beyond this count: enough to go back a week or two of
/// daily copies, while a few hundred KB each keeps the folder small.
const int automaticBackupRetentionCount = 10;

/// The daily copy is skipped when the newest automatic backup is younger than this.
const Duration minimumIntervalBetweenDailyAutomaticBackups = Duration(hours: 24);

const String _automaticBackupFileNamePrefix = 'komit_auto_';
const String _automaticBackupFileNameSuffix = '.json';
final RegExp _automaticBackupFileNamePattern = RegExp(r'^komit_auto_(\d+)_([a-zA-Z]+)\.json$');

/// Why an automatic backup was written; its name is part of the file name.
enum AutomaticBackupReason { beforeImport, beforeUpdate, daily }

class AutomaticBackup {
  const AutomaticBackup({required this.file, required this.createdAt, required this.reason});

  final File file;
  final DateTime createdAt;
  final AutomaticBackupReason reason;
}

/// Writes v2 snapshots of every habit, log and note to a private folder of the app, so an
/// import, a restore or an update can always be undone. They never leave the device.
class AutomaticBackupService {
  AutomaticBackupService({
    required this._backupRepository,
    required this._readUserName,
    required this._now,
    this._resolveBackupDirectory = _resolveDefaultBackupDirectory,
  });

  final BackupRepository _backupRepository;
  final String? Function() _readUserName;
  final DateTime Function() _now;
  final Future<Directory> Function() _resolveBackupDirectory;

  static Future<Directory> _resolveDefaultBackupDirectory() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/backups');

  /// Writes a snapshot of the current data, then deletes the oldest beyond the retention count.
  Future<AutomaticBackup> writeSnapshot(AutomaticBackupReason reason) async {
    final snapshot = await _backupRepository.readSnapshot(userName: _readUserName());
    return _writeEncodedSnapshot(snapshot, reason);
  }

  /// Writes the daily copy when there is data, the newest backup is a day old and the data
  /// changed since.
  /// Returns true when a copy was written.
  Future<bool> writeDailySnapshotIfDataChanged() async {
    final now = _now();
    final newestBackup = (await listBackupsNewestFirst()).firstOrNull;
    if (newestBackup != null &&
        !newestBackup.createdAt.isAfter(now) &&
        now.difference(newestBackup.createdAt) < minimumIntervalBetweenDailyAutomaticBackups) {
      return false;
    }
    final snapshot = await _backupRepository.readSnapshot(userName: _readUserName());
    // A copy of nothing would only push a useful older copy out of the list.
    if (snapshot.habits.isEmpty && snapshot.notes.isEmpty) return false;
    if (newestBackup != null) {
      final newestBackupPath = newestBackup.file.path;
      final isUnchanged = await Isolate.run(() {
        final newestBackupContent = _withoutExportDate(File(newestBackupPath).readAsStringSync());
        return newestBackupContent != null &&
            newestBackupContent == _withoutExportDate(encodeBackupSnapshotToJson(snapshot, exportedAt: now));
      });
      if (isUnchanged) return false;
    }
    await _writeEncodedSnapshot(snapshot, AutomaticBackupReason.daily);
    return true;
  }

  Future<List<AutomaticBackup>> listBackupsNewestFirst() async {
    final directory = await _resolveBackupDirectory();
    if (!await directory.exists()) return const [];
    final backups = <AutomaticBackup>[];
    await for (final entity in directory.list()) {
      final match = _automaticBackupFileNamePattern.firstMatch(entity.uri.pathSegments.last);
      final reason = AutomaticBackupReason.values.asNameMap()[match?.group(2)];
      if (entity is! File || match == null || reason == null) continue;
      final createdAt = DateTime.fromMillisecondsSinceEpoch(int.parse(match.group(1)!));
      backups.add(AutomaticBackup(file: entity, createdAt: createdAt, reason: reason));
    }
    return backups..sort((first, second) => second.createdAt.compareTo(first.createdAt));
  }

  /// Throws [InvalidBackupException] when the file is damaged.
  Future<BackupSnapshot> readSnapshot(AutomaticBackup backup, {required CalendarDay today}) {
    final path = backup.file.path;
    return Isolate.run(() => decodeBackupSnapshotFromJson(File(path).readAsStringSync(), today: today));
  }

  Future<AutomaticBackup> _writeEncodedSnapshot(BackupSnapshot snapshot, AutomaticBackupReason reason) async {
    final directory = await _resolveBackupDirectory();
    final createdAt = _now();
    final fileName =
        '$_automaticBackupFileNamePrefix${createdAt.millisecondsSinceEpoch}_${reason.name}$_automaticBackupFileNameSuffix';
    final file = File('${directory.path}/$fileName');
    final directoryPath = directory.path;
    final filePath = file.path;
    // Encoding a long history and writing it must not freeze the UI. Written next to its final
    // name first, so a crash midway never leaves a truncated backup in the list.
    await Isolate.run(() {
      Directory(directoryPath).createSync(recursive: true);
      final partialFile = File('$filePath.partial')
        ..writeAsStringSync(encodeBackupSnapshotToJson(snapshot, exportedAt: createdAt), flush: true);
      partialFile.renameSync(filePath);
    });
    await _deleteBackupsBeyondRetention();
    return AutomaticBackup(file: file, createdAt: createdAt, reason: reason);
  }

  Future<void> _deleteBackupsBeyondRetention() async {
    final backups = await listBackupsNewestFirst();
    for (final backup in backups.skip(automaticBackupRetentionCount)) {
      await backup.file.delete();
    }
  }
}

/// The backup JSON without its export date, so two copies of the same data compare equal.
/// Null for a damaged file, which then never matches and is replaced by a fresh copy.
String? _withoutExportDate(String backupJson) {
  try {
    final Object? root = jsonDecode(backupJson);
    if (root is! Map<String, Object?>) return null;
    return jsonEncode(root..remove('exportedAt'));
  } on FormatException {
    return null;
  }
}
