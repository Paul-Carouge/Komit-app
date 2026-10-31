import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../celebrations/log_celebrations.dart';
import '../shared/day_grid.dart';
import '../shared/shared_widgets.dart';

sealed class LogDayChoice {
  const LogDayChoice();
}

class LogDayChoiceObjective extends LogDayChoice {
  const LogDayChoiceObjective(this.objectiveId);

  final int objectiveId;
}

class LogDayChoiceClear extends LogDayChoice {
  const LogDayChoiceClear();
}

/// Opens the sheet for [day], then saves or clears the chosen log, with an "Undo" message.
Future<void> logDayFromSheet(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required int? currentObjectiveId,
}) async {
  final today = ref.read(currentCalendarDayProvider);
  final choice = await showLogDaySheet(
    context,
    habit: habit,
    day: day,
    today: today,
    currentObjectiveId: currentObjectiveId,
    canLogObjective: !day.isAfter(today),
    onObjectivesReordered: (objectiveIdsInOrder) => _saveObjectiveOrder(context, ref, habit, objectiveIdsInOrder),
  );
  if (choice == null || !context.mounted) return;
  final chosenObjectiveId = switch (choice) {
    LogDayChoiceObjective(:final objectiveId) => objectiveId,
    LogDayChoiceClear() => null,
  };
  if (chosenObjectiveId == currentObjectiveId) return;
  await writeDayLogWithUndo(
    context,
    ref,
    habit: habit,
    day: day,
    previousObjectiveId: currentObjectiveId,
    objectiveId: chosenObjectiveId,
  );
}

Future<void> _saveObjectiveOrder(
  BuildContext context,
  WidgetRef ref,
  HabitWithObjectives habit,
  List<int> objectiveIdsInOrder,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final logger = ref.read(appLoggerProvider);
  try {
    await ref
        .read(habitRepositoryProvider)
        .reorderObjectives(habitId: habit.habit.id, objectiveIdsInOrder: objectiveIdsInOrder);
  } on Object catch (error, stackTrace) {
    unawaited(KomitHaptics.error());
    unawaited(logger.logError(event: 'objective_reorder_failed', error: error, stackTrace: stackTrace));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: SnackBarMessage(localizations.genericError, kind: SnackBarMessageKind.error)));
  }
}

/// Logs [objectiveId] for [day], or clears the day when it is null, then offers to restore
/// [previousObjectiveId] from a message: every log is one tap away from being taken back.
Future<void> writeDayLogWithUndo(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required int? previousObjectiveId,
  required int? objectiveId,
}) async {
  // Captured before any await: the row or sheet that asked may be gone when the write ends.
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final repository = ref.read(habitRepositoryProvider);
  final logger = ref.read(appLoggerProvider);
  final celebrator = LogCelebrator.of(context, ref);
  final habitId = habit.habit.id;

  Future<bool> write(int? objectiveIdToWrite) async {
    try {
      if (objectiveIdToWrite == null) {
        await repository.clearLogForDay(habitId: habitId, day: day);
      } else {
        await repository.logObjectiveForDay(habitId: habitId, objectiveId: objectiveIdToWrite, day: day);
      }
      return true;
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(logger.logError(event: 'day_log_write_failed', error: error, stackTrace: stackTrace));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: SnackBarMessage(localizations.genericError, kind: SnackBarMessageKind.error)));
      return false;
    }
  }

  if (!await write(objectiveId)) return;
  if (objectiveId == null) {
    unawaited(KomitHaptics.warning());
  } else {
    unawaited(KomitHaptics.success());
    unawaited(
      celebrator.celebrateLog(
        habit: habit,
        day: day,
        previousObjectiveId: previousObjectiveId,
        objectiveId: objectiveId,
      ),
    );
  }
  final objective = objectiveId == null ? null : habit.objectiveWithId(objectiveId);
  final objectiveTitle = objective?.title;
  final objectiveColor = objective == null ? null : Color(objective.colorArgb);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: SnackBarMessage(
          objectiveTitle == null
              ? localizations.dayClearedMessage(habit.habit.title)
              : localizations.dayLoggedMessage(objectiveTitle, habit.habit.title),
          kind: objectiveTitle == null ? SnackBarMessageKind.information : SnackBarMessageKind.success,
          icon: objectiveTitle == null ? KomitIcons.eraser : null,
          color: objectiveColor,
        ),
        // With an action a SnackBar stays until dismissed by default; an undo window should close.
        persist: false,
        duration: AppDurations.undoSnackBar,
        action: SnackBarAction(
          label: localizations.undo,
          onPressed: () {
            unawaited(KomitHaptics.selection());
            unawaited(write(previousObjectiveId));
          },
        ),
      ),
    );
}

/// Returns null when dismissed.
Future<LogDayChoice?> showLogDaySheet(
  BuildContext context, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required CalendarDay today,
  required int? currentObjectiveId,

  /// False for a future day: only an existing log (imported from the old app) can be cleared.
  required bool canLogObjective,

  /// Called after a long-press drag; the first objective becomes the one-tap default.
  required void Function(List<int> objectiveIdsInOrder) onObjectivesReordered,
}) {
  var objectives = habit.objectives;
  return showModalBottomSheet<LogDayChoice>(
    context: context,
    // Root navigator, like every Komit sheet: it covers the frosted navigation bar instead of sliding under it.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        final localizations = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final mutedText = KomitColors.of(context).mutedText;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    HabitIconBadge(icon: habitIconForName(habit.habit.iconName), color: Color(habit.habit.colorArgb)),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(header: true, child: Text(habit.habit.title, style: textTheme.titleLarge)),
                          Text(
                            formatRelativeDay(context, day, today: today),
                            style: textTheme.bodyMedium?.copyWith(color: mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (habit.pauseOn(day) != null) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      const PausedDaySwatch(),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Text(
                          localizations.logDayPausedNote,
                          style: textTheme.bodyMedium?.copyWith(color: mutedText),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.extraLarge),
                if (canLogObjective) ...[
                  if (objectives.length > 1) ...[
                    Text(localizations.reorderObjectivesHint, style: textTheme.bodySmall?.copyWith(color: mutedText)),
                    const SizedBox(height: AppSpacing.medium),
                  ],
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // A long press anywhere on a pill picks it up; a tap still logs it.
                    buildDefaultDragHandles: false,
                    proxyDecorator: _liftedObjectivePill,
                    onReorderStart: (_) => unawaited(KomitHaptics.lift()),
                    onReorderItem: (oldIndex, newIndex) {
                      if (oldIndex == newIndex) return;
                      unawaited(KomitHaptics.selection());
                      setSheetState(() {
                        objectives = [...objectives];
                        objectives.insert(newIndex, objectives.removeAt(oldIndex));
                      });
                      onObjectivesReordered([for (final objective in objectives) objective.id]);
                    },
                    children: [
                      for (final (index, objective) in objectives.indexed)
                        ReorderableDelayedDragStartListener(
                          key: ValueKey(objective.id),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.small),
                            child: _ObjectivePill(
                              title: objective.title,
                              color: Color(objective.colorArgb),
                              isSelected: objective.id == currentObjectiveId,
                              onPressed: () {
                                unawaited(KomitHaptics.selection());
                                Navigator.of(context).pop(LogDayChoiceObjective(objective.id));
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else if (currentObjectiveId != null)
                  Text(localizations.futureLogExplanation, style: textTheme.bodyMedium?.copyWith(color: mutedText)),
                if (currentObjectiveId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
                      ),
                      onPressed: () => Navigator.of(context).pop(const LogDayChoiceClear()),
                      icon: const Icon(KomitIcons.eraser),
                      label: Text(localizations.clearLog),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// The picked-up pill grows a little and floats on a soft shadow, like a dragged habit row.
Widget _liftedObjectivePill(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final liftProgress = AppCurves.standard.transform(animation.value);
      final shadowColor = Theme.of(context).colorScheme.shadow.withValues(alpha: AppOpacity.liftedShadow);
      return Transform.scale(
        scale: lerpDouble(1, liftedScale, liftProgress),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            shadows: AppShadows.lifted(shadowColor.withValues(alpha: shadowColor.a * liftProgress)),
          ),
          child: child,
        ),
      );
    },
    // The dragged copy floats in an overlay, outside the sheet's Material.
    child: Material(type: MaterialType.transparency, child: child),
  );
}

/// A large pill filled with the objective's own color: the choice is the color the day takes.
class _ObjectivePill extends StatelessWidget {
  const _ObjectivePill({required this.title, required this.color, required this.isSelected, required this.onPressed});

  final String title;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = foregroundColorReadableOn(color);
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: color,
        // The ring in the text color marks the current choice without relying on the fill alone.
        shape: StadiumBorder(
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.onSurface, width: AppSizes.selectedSwatchBorderWidth)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.primaryButtonHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.extraLarge, vertical: AppSpacing.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    Icon(KomitIcons.check, color: foregroundColor, size: AppSizes.iconMedium),
                    const SizedBox(width: AppSpacing.small),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foregroundColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
