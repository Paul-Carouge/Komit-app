import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_text.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';

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
    isScrollControlled: true,
    builder: (context) {
      final localizations = AppLocalizations.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameTitle(
                localizations.logForDate(formatFullDate(context, day)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.large),
              if (canLogObjective)
                for (final objective in habit.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: GameButton(
                      label: objective.title,
                      faceColor: Color(objective.colorArgb),
                      isSelected: objective.id == currentObjectiveId,
                      // The check, not the color alone, tells which objective is logged.
                      trailing: objective.id == currentObjectiveId ? const Icon(LucideIcons.circleCheckBig) : null,
                      onPressed: () => Navigator.of(context).pop(LogDayChoiceObjective(objective.id)),
                    ),
                  ),
              if (currentObjectiveId != null) ...[
                const SizedBox(height: AppSpacing.small),
                GameButton(
                  isCompact: true,
                  tone: GameButtonTone.danger,
                  onPressed: () => Navigator.of(context).pop(const LogDayChoiceClear()),
                  icon: LucideIcons.eraser,
                  label: localizations.clearLog,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
