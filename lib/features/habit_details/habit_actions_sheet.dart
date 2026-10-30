import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_logger.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../archived_habits/archived_habits_screen.dart';
import '../shared/shared_widgets.dart';

enum _HabitAction { edit, archive, unarchive, delete }

/// Offers to edit, archive (or bring back) and delete [habit], then does what the user chose.
///
/// [onHabitRemoved] runs once the habit has left the current list, archived or deleted: the
/// details screen closes itself there, the dashboard has nothing to do.
Future<void> showHabitActionsSheet(
  BuildContext context,
  WidgetRef ref,
  HabitWithObjectives habit, {
  VoidCallback? onHabitRemoved,
}) async {
  final localizations = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final isArchived = habit.habit.archivedAt != null;
  final chosenAction = await showModalBottomSheet<_HabitAction>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(KomitIcons.pencil),
            title: Text(localizations.editHabit),
            onTap: () => Navigator.of(context).pop(_HabitAction.edit),
          ),
          if (isArchived)
            ListTile(
              leading: const Icon(KomitIcons.archiveRestore),
              title: Text(localizations.unarchiveHabit),
              onTap: () => Navigator.of(context).pop(_HabitAction.unarchive),
            )
          else
            ListTile(
              leading: const Icon(KomitIcons.archive),
              title: Text(localizations.archiveHabit),
              onTap: () => Navigator.of(context).pop(_HabitAction.archive),
            ),
          ListTile(
            leading: Icon(KomitIcons.trash2, color: colorScheme.error),
            title: Text(localizations.deleteHabit, style: TextStyle(color: colorScheme.error)),
            onTap: () => Navigator.of(context).pop(_HabitAction.delete),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (chosenAction) {
    case null:
      return;
    case _HabitAction.edit:
      unawaited(context.push(AppRoutes.habitEditor(habit.habit.id)));
    case _HabitAction.archive:
      await _archive(context, ref, habit, onHabitRemoved);
    case _HabitAction.unarchive:
      await unarchiveHabitWithMessage(context, ref, habit);
    case _HabitAction.delete:
      await _delete(context, ref, habit, onHabitRemoved);
  }
}

/// Archives with a way to bring the habit back at once.
Future<void> _archive(
  BuildContext context,
  WidgetRef ref,
  HabitWithObjectives habit,
  VoidCallback? onHabitRemoved,
) async {
  // Captured first: the row asking may be gone from the tree once the habit is archived.
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final repository = ref.read(habitRepositoryProvider);
  final logger = ref.read(appLoggerProvider);
  try {
    await repository.archiveHabit(habit.habit.id);
  } on Object catch (error, stackTrace) {
    _reportActionFailure(messenger, localizations, logger, 'habit_archive_failed', error, stackTrace);
    return;
  }
  unawaited(KomitHaptics.warning());
  onHabitRemoved?.call();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(localizations.habitArchivedMessage(habit.habit.title)),
        persist: false,
        duration: AppDurations.undoSnackBar,
        action: SnackBarAction(
          label: localizations.undo,
          onPressed: () => unawaited(
            repository
                .unarchiveHabit(habit.habit.id)
                .catchError(
                  (Object error, StackTrace stackTrace) =>
                      logger.logError(event: 'habit_unarchive_failed', error: error, stackTrace: stackTrace),
                ),
          ),
        ),
      ),
    );
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  HabitWithObjectives habit,
  VoidCallback? onHabitRemoved,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final logger = ref.read(appLoggerProvider);
  final repository = ref.read(habitRepositoryProvider);
  final isConfirmed = await showDestructiveConfirmationDialog(
    context,
    message: localizations.deleteHabitConfirmation(habit.habit.title),
    confirmLabel: localizations.delete,
  );
  if (!isConfirmed) return;
  try {
    await repository.deleteHabit(habit.habit.id);
    unawaited(KomitHaptics.warning());
    onHabitRemoved?.call();
  } on Object catch (error, stackTrace) {
    _reportActionFailure(messenger, localizations, logger, 'habit_delete_failed', error, stackTrace);
  }
}

void _reportActionFailure(
  ScaffoldMessengerState messenger,
  AppLocalizations localizations,
  AppLogger logger,
  String event,
  Object error,
  StackTrace stackTrace,
) {
  unawaited(KomitHaptics.error());
  unawaited(logger.logError(event: event, error: error, stackTrace: stackTrace));
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(localizations.genericError)));
}
