import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_logger.dart';
import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_pause.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../archived_habits/archived_habits_screen.dart';
import '../shared/shared_widgets.dart';
import 'pause_habit_sheet.dart';

enum _HabitAction { edit, pause, resume, archive, unarchive, delete }

/// Offers to edit, pause (or resume), archive (or bring back) and delete [habit], then does what
/// the user chose.
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
  final today = ref.read(currentCalendarDayProvider);
  final currentOrPlannedPause = habit.currentOrPlannedPause(today);
  final chosenAction = await showModalBottomSheet<_HabitAction>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      // Scrolls at large text sizes: five actions do not fit the sheet's height on a compact phone.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(KomitIcons.pencil),
              title: Text(localizations.editHabit),
              onTap: () => Navigator.of(context).pop(_HabitAction.edit),
            ),
            // An archived habit has no reminder and no dashboard row: nothing to pause.
            if (!isArchived)
              if (currentOrPlannedPause == null)
                ListTile(
                  leading: const Icon(KomitIcons.pause),
                  title: Text(localizations.pauseHabit),
                  onTap: () => Navigator.of(context).pop(_HabitAction.pause),
                )
              else
                ListTile(
                  leading: const Icon(KomitIcons.play),
                  title: Text(
                    currentOrPlannedPause.startDay.isAfter(today)
                        ? localizations.cancelPlannedPause
                        : localizations.resumeHabit,
                  ),
                  subtitle: Text(describeCurrentOrPlannedPause(context, currentOrPlannedPause, today: today)),
                  onTap: () => Navigator.of(context).pop(_HabitAction.resume),
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
    ),
  );
  if (!context.mounted) return;
  switch (chosenAction) {
    case null:
      return;
    case _HabitAction.edit:
      unawaited(context.push(AppRoutes.habitEditor(habit.habit.id)));
    case _HabitAction.pause:
      await _pause(context, ref, habit, today);
    case _HabitAction.resume:
      await resumeHabitWithMessage(context, ref, habit);
    case _HabitAction.archive:
      await _archive(context, ref, habit, onHabitRemoved);
    case _HabitAction.unarchive:
      await unarchiveHabitWithMessage(context, ref, habit);
    case _HabitAction.delete:
      await _delete(context, ref, habit, onHabitRemoved);
  }
}

/// Asks for the pause's dates, then saves it with a way to take it back at once.
Future<void> _pause(BuildContext context, WidgetRef ref, HabitWithObjectives habit, CalendarDay today) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final repository = ref.read(habitRepositoryProvider);
  final logger = ref.read(appLoggerProvider);
  final chosenPause = await showPauseHabitSheet(context, habit: habit, today: today);
  if (chosenPause == null || !context.mounted) return;
  // The sheet may have stayed open past midnight: "today" then means the new day, not a past one.
  final currentDay = ref.read(currentCalendarDayProvider);
  final pause = currentDay.isAfter(chosenPause.startDay)
      ? HabitPause(startDay: currentDay, endDay: chosenPause.endDay)
      : chosenPause;
  if (pause.endDay case final endDay? when pause.startDay.isAfter(endDay)) return;
  final title = habit.habit.title;
  final message = pause.startDay.isAfter(today)
      ? localizations.habitPausePlannedMessage(title, formatShortDate(context, pause.startDay))
      : localizations.habitPausedMessage(title);
  try {
    await repository.pauseHabit(habit.habit.id, startDay: pause.startDay, endDay: pause.endDay);
  } on InvalidPauseException catch (error, stackTrace) {
    unawaited(KomitHaptics.error());
    unawaited(logger.logError(event: 'habit_pause_rejected', error: error, stackTrace: stackTrace));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizations.pauseOverlapError)));
    return;
  } on Object catch (error, stackTrace) {
    _reportActionFailure(messenger, localizations, logger, 'habit_pause_failed', error, stackTrace);
    return;
  }
  unawaited(KomitHaptics.success());
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        persist: false,
        duration: AppDurations.undoSnackBar,
        action: SnackBarAction(
          label: localizations.undo,
          // Exact: "Pause" is only offered with no current or planned pause, and the new one starts
          // today or later, so resuming deletes just this pause.
          onPressed: () => unawaited(
            repository
                .resumeHabit(habit.habit.id)
                .catchError(
                  (Object error, StackTrace stackTrace) =>
                      logger.logError(event: 'habit_pause_undo_failed', error: error, stackTrace: stackTrace),
                ),
          ),
        ),
      ),
    );
}

/// Ends [habit]'s current pause on yesterday, or cancels its planned one, and says so.
///
/// No "Undo": a pause that started before today cannot be written again, since pauses start
/// today or later.
Future<void> resumeHabitWithMessage(BuildContext context, WidgetRef ref, HabitWithObjectives habit) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final repository = ref.read(habitRepositoryProvider);
  final logger = ref.read(appLoggerProvider);
  final today = ref.read(currentCalendarDayProvider);
  final isPausePlanned = habit.currentOrPlannedPause(today)?.startDay.isAfter(today) ?? false;
  try {
    await repository.resumeHabit(habit.habit.id);
  } on Object catch (error, stackTrace) {
    _reportActionFailure(messenger, localizations, logger, 'habit_resume_failed', error, stackTrace);
    return;
  }
  unawaited(KomitHaptics.success());
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          isPausePlanned
              ? localizations.plannedPauseCancelledMessage(habit.habit.title)
              : localizations.habitResumedMessage(habit.habit.title),
        ),
      ),
    );
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
