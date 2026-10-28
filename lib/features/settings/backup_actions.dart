import 'dart:convert';
import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/backup/backup_json_codec.dart';
import '../../data/backup/backup_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';

/// Guards against loading an unrelated huge file in memory; real backups are a few hundred KB.
const int _maximumBackupFileSizeBytes = 20 * 1024 * 1024;

Future<void> exportBackupToUserChosenFile(BuildContext context, WidgetRef ref) async {
  final localizations = AppLocalizations.of(context);
  try {
    final now = DateTime.now();
    final snapshot = await ref
        .read(backupRepositoryProvider)
        .readSnapshot(userName: ref.read(settingsControllerProvider).userName);
    final jsonText = encodeBackupSnapshotToJson(snapshot, exportedAt: now);
    await FilePicker.saveFile(
      fileName: 'komit_backup_${DateFormat('yyyyMMdd_HHmm').format(now)}.json',
      bytes: utf8.encode(jsonText),
      mimeType: 'application/json',
    );
  } on Object catch (error) {
    developer.log('Backup export failed', name: 'komit.backup', error: error);
    if (context.mounted) showMessageSnackBar(context, localizations.exportFailed);
  }
}

/// Returns true when data was imported.
Future<bool> importBackupFromUserChosenFile(BuildContext context, WidgetRef ref) async {
  final localizations = AppLocalizations.of(context);
  final BackupSnapshot snapshot;
  try {
    final pickedFile = await FilePicker.pickFile();
    if (pickedFile == null) return false;
    if (await pickedFile.xFile.length() > _maximumBackupFileSizeBytes) {
      throw const InvalidBackupException('file too large');
    }
    snapshot = decodeBackupSnapshotFromJson(await pickedFile.xFile.readAsString());
  } on InvalidBackupException catch (error) {
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(error.message));
    return false;
  } on Object catch (error) {
    developer.log('Backup file could not be read', name: 'komit.backup', error: error);
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
    return false;
  }
  if (!context.mounted) return false;

  final isConfirmed = await showDestructiveConfirmationDialog(
    context,
    title: localizations.importConfirmationTitle,
    message: localizations.importConfirmationMessage(snapshot.habits.length, snapshot.logCount, snapshot.notes.length),
    confirmLabel: localizations.replace,
  );
  if (!isConfirmed || !context.mounted) return false;

  try {
    await ref.read(backupRepositoryProvider).replaceAllDataWith(snapshot);
    if (snapshot.userName != null) {
      await ref.read(settingsControllerProvider.notifier).updateUserName(snapshot.userName);
    }
    if (context.mounted) showMessageSnackBar(context, localizations.importSucceeded(snapshot.logCount));
    return true;
  } on Object catch (error) {
    developer.log('Backup import failed, database rolled back', name: 'komit.backup', error: error);
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
    return false;
  }
}
