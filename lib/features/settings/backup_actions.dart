import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/current_calendar_day.dart';
import '../../data/backup/backup_json_codec.dart';
import '../../data/backup/backup_snapshot.dart';
import '../../data/backup/encrypted_backup_envelope.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/automatic_backup_service.dart';
import '../../services/backup_encryption_service.dart';
import '../shared/shared_widgets.dart';
import 'backup_passphrase_dialog.dart';

/// Returns true when the user saved the file. With a [passphrase] the file is encrypted.
Future<bool> exportBackupToUserChosenFile(BuildContext context, WidgetRef ref, {String? passphrase}) async {
  final localizations = AppLocalizations.of(context);
  try {
    final now = ref.read(clockProvider)();
    final snapshot = await ref
        .read(backupRepositoryProvider)
        .readSnapshot(userName: ref.read(settingsControllerProvider).userName);
    // Encoding years of logs must not freeze the UI.
    final backupJson = await Isolate.run(() => encodeBackupSnapshotToJson(snapshot, exportedAt: now));
    final fileContent = passphrase == null
        ? backupJson
        : await ref.read(backupEncryptionServiceProvider).encryptBackupJson(backupJson, passphrase: passphrase);
    final fileBytes = await Isolate.run(() => Uint8List.fromList(utf8.encode(fileContent)));
    final encryptedSuffix = passphrase == null ? '' : '_encrypted';
    final savedPath = await FilePicker.saveFile(
      fileName: 'komit_backup_${DateFormat('yyyyMMdd_HHmm').format(now)}$encryptedSuffix.json',
      bytes: fileBytes,
      mimeType: 'application/json',
    );
    if (savedPath == null) return false;
    await ref.read(settingsControllerProvider.notifier).recordExport(now);
    return true;
  } on Object catch (error, stackTrace) {
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'backup_export_failed', error: error, stackTrace: stackTrace),
    );
    if (context.mounted) showMessageSnackBar(context, localizations.exportFailed);
    return false;
  }
}

/// Returns true when data was imported. An encrypted file asks for its passphrase first.
Future<bool> importBackupFromUserChosenFile(BuildContext context, WidgetRef ref) async {
  final localizations = AppLocalizations.of(context);
  final String fileContent;
  final EncryptedBackupEnvelope? envelope;
  try {
    final pickedFile = await FilePicker.pickFile();
    if (pickedFile == null) return false;
    if (await pickedFile.xFile.length() > maximumBackupFileSizeBytes) {
      throw const InvalidBackupException('file too large');
    }
    fileContent = await pickedFile.xFile.readAsString();
    envelope = await Isolate.run(() => decodeEncryptedBackupEnvelopeIfPresent(fileContent));
  } on InvalidBackupException catch (error) {
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(error.message));
    return false;
  } on Object catch (error, stackTrace) {
    unawaited(ref.read(appLoggerProvider).logError(event: 'backup_read_failed', error: error, stackTrace: stackTrace));
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
    return false;
  }

  final String backupJson;
  if (envelope == null) {
    backupJson = fileContent;
  } else {
    if (!context.mounted) return false;
    final decryptedJson = await _decryptWithPassphraseFromUser(context, ref, envelope);
    if (decryptedJson == null) return false;
    backupJson = decryptedJson;
  }

  final BackupSnapshot snapshot;
  try {
    final today = ref.read(currentCalendarDayProvider);
    // Decoding and validating a large file must not freeze the UI.
    snapshot = await Isolate.run(() => decodeBackupSnapshotFromJson(backupJson, today: today));
  } on InvalidBackupException catch (error) {
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(error.message));
    return false;
  } on Object catch (error, stackTrace) {
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'backup_decode_failed', error: error, stackTrace: stackTrace),
    );
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
  return _replaceAllDataKeepingACopy(context, ref, snapshot);
}

/// Asks for confirmation, then replaces everything with [backup]; returns true when restored.
Future<bool> restoreAutomaticBackup(BuildContext context, WidgetRef ref, AutomaticBackup backup) async {
  final localizations = AppLocalizations.of(context);
  final isConfirmed = await showDestructiveConfirmationDialog(
    context,
    title: localizations.restoreAutomaticBackupConfirmationTitle,
    message: localizations.restoreAutomaticBackupConfirmationMessage(formatAutomaticBackupDate(context, backup)),
    confirmLabel: localizations.replace,
  );
  if (!isConfirmed || !context.mounted) return false;
  final BackupSnapshot snapshot;
  try {
    snapshot = await ref
        .read(automaticBackupServiceProvider)
        .readSnapshot(backup, today: ref.read(currentCalendarDayProvider));
  } on Object catch (error, stackTrace) {
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'automatic_backup_read_failed', error: error, stackTrace: stackTrace),
    );
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
    return false;
  }
  if (!context.mounted) return false;
  return _replaceAllDataKeepingACopy(context, ref, snapshot);
}

/// Asks for the passphrase until it opens [envelope]; null when the user gives up.
Future<String?> _decryptWithPassphraseFromUser(
  BuildContext context,
  WidgetRef ref,
  EncryptedBackupEnvelope envelope,
) async {
  final localizations = AppLocalizations.of(context);
  var isPreviousPassphraseWrong = false;
  while (context.mounted) {
    final passphrase = await showBackupPassphraseDialog(
      context,
      purpose: BackupPassphrasePurpose.decrypt,
      errorText: isPreviousPassphraseWrong ? localizations.wrongBackupPassphrase : null,
    );
    if (passphrase == null) return null;
    try {
      return await ref.read(backupEncryptionServiceProvider).decryptBackupEnvelope(envelope, passphrase: passphrase);
    } on WrongBackupPassphraseException {
      isPreviousPassphraseWrong = true;
    } on Object catch (error, stackTrace) {
      unawaited(
        ref.read(appLoggerProvider).logError(event: 'backup_decrypt_failed', error: error, stackTrace: stackTrace),
      );
      if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
      return null;
    }
  }
  return null;
}

/// "Oct 28, 2026 14:05" in the user's language.
String formatAutomaticBackupDate(BuildContext context, AutomaticBackup backup) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(backup.createdAt);

/// Keeps an automatic copy of the current data first, so any import can be undone from
/// Settings. Without that copy nothing is replaced.
Future<bool> _replaceAllDataKeepingACopy(BuildContext context, WidgetRef ref, BackupSnapshot snapshot) async {
  final localizations = AppLocalizations.of(context);
  final logger = ref.read(appLoggerProvider);
  try {
    await ref.read(automaticBackupServiceProvider).writeSnapshot(AutomaticBackupReason.beforeImport);
  } on Object catch (error, stackTrace) {
    unawaited(logger.logError(event: 'pre_import_backup_failed', error: error, stackTrace: stackTrace));
    if (context.mounted) showMessageSnackBar(context, localizations.preImportBackupFailed);
    return false;
  }

  try {
    await ref.read(backupRepositoryProvider).replaceAllDataWith(snapshot);
  } on Object catch (error, stackTrace) {
    unawaited(logger.logError(event: 'backup_import_failed', error: error, stackTrace: stackTrace));
    if (context.mounted) showMessageSnackBar(context, localizations.importFailed(localizations.genericError));
    return false;
  }

  // The data is in: a name that fails to save must not report the whole import as failed.
  if (snapshot.userName != null) {
    try {
      await ref.read(settingsControllerProvider.notifier).updateUserName(snapshot.userName);
    } on Object catch (error, stackTrace) {
      unawaited(logger.logError(event: 'imported_name_save_failed', error: error, stackTrace: stackTrace));
    }
  }
  if (context.mounted) showMessageSnackBar(context, localizations.importSucceeded(snapshot.logCount));

  // Imported reminders would otherwise be scheduled but silently never shown.
  final hasImportedReminders = snapshot.habits.any((habit) => habit.reminderMinuteOfDay != null);
  if (hasImportedReminders) {
    final isNotificationAllowed = await ref.read(reminderSchedulerProvider).requestPermission();
    if (!isNotificationAllowed && context.mounted) {
      showMessageSnackBar(context, localizations.notificationsDenied);
    }
  }
  return true;
}
