import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
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

/// Opens the sheet for [day], then saves or clears the chosen log with matching haptics.
Future<void> logDayFromSheet(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required int? currentObjectiveId,
}) async {
  final choice = await showLogDaySheet(
    context,
    habit: habit,
    day: day,
    currentObjectiveId: currentObjectiveId,
    canLogObjective: !day.isAfter(ref.read(currentCalendarDayProvider)),
  );
  if (choice == null || !context.mounted) return;
  final repository = ref.read(habitRepositoryProvider);
  try {
    switch (choice) {
      case LogDayChoiceObjective(:final objectiveId):
        await repository.logObjectiveForDay(habitId: habit.habit.id, objectiveId: objectiveId, day: day);
        unawaited(KomitHaptics.success());
      case LogDayChoiceClear():
        await repository.clearLogForDay(habitId: habit.habit.id, day: day);
        unawaited(KomitHaptics.warning());
    }
  } on Object {
    unawaited(KomitHaptics.error());
    if (context.mounted) showMessageSnackBar(context, AppLocalizations.of(context).genericError);
  }
}

/// Returns null when dismissed.
Future<LogDayChoice?> showLogDaySheet(
  BuildContext context, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required int? currentObjectiveId,

  /// False for a future day: only an existing log (imported from the old app) can be cleared.
  required bool canLogObjective,
}) {
  return showModalBottomSheet<LogDayChoice>(
    context: context,
    // Root navigator, like every Komit sheet: it covers the frosted navigation bar instead of sliding under it.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final localizations = AppLocalizations.of(context);
      final colorScheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.logForDate(formatFullDate(context, day)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.large),
              if (canLogObjective)
                for (final objective in habit.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: _ObjectiveButton(
                      title: objective.title,
                      color: Color(objective.colorArgb),
                      isSelected: objective.id == currentObjectiveId,
                      onPressed: () => Navigator.of(context).pop(LogDayChoiceObjective(objective.id)),
                    ),
                  ),
              if (currentObjectiveId != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
                  ),
                  onPressed: () => Navigator.of(context).pop(const LogDayChoiceClear()),
                  icon: const Icon(LucideIcons.eraser),
                  label: Text(localizations.clearLog),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ObjectiveButton extends StatelessWidget {
  const _ObjectiveButton({required this.title, required this.color, required this.isSelected, required this.onPressed});

  final String title;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget + AppSpacing.medium),
          backgroundColor: isSelected
              ? color.withValues(alpha: AppOpacity.selectedTint)
              : colorScheme.surfaceContainerLow,
          side: BorderSide(
            color: isSelected ? color : colorScheme.outlineVariant,
            width: isSelected ? AppSizes.emphasisBorderWidth : AppSizes.hairline,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium)),
          foregroundColor: colorScheme.onSurface,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorDot(color: color),
            const SizedBox(width: AppSpacing.medium),
            Flexible(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.small),
              Icon(LucideIcons.check, color: colorScheme.onSurface, size: AppSizes.iconMedium),
            ],
          ],
        ),
      ),
    );
  }
}
