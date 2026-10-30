import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_pause.dart';
import '../../l10n/app_localizations.dart';
import '../shared/day_grid.dart';
import '../shared/shared_widgets.dart';

/// How far ahead the date pickers reach: a pause is a holiday or an illness, not a year off.
const int _pauseDatePickerLookaheadDays = 365;

enum _PauseStartChoice { today, tomorrow, pickedDay }

enum _PauseEndChoice { untilResumed, oneWeek, twoWeeks, pickedDay }

/// "Paused until Nov 12", "Paused until you resume" or "Pause starts Nov 3": the pause "Resume"
/// would end, in the words of the actions sheet and the habit page.
String describeCurrentOrPlannedPause(BuildContext context, HabitPause pause, {required CalendarDay today}) {
  final localizations = AppLocalizations.of(context);
  if (pause.startDay.isAfter(today)) return localizations.pausePlannedFrom(formatShortDate(context, pause.startDay));
  final endDay = pause.endDay;
  return endDay == null
      ? localizations.pausedUntilResumed
      : localizations.pausedUntil(formatShortDate(context, endDay));
}

/// Asks when [habit]'s pause starts (today by default) and ends (when resumed by default).
/// Returns null when dismissed.
Future<HabitPause?> showPauseHabitSheet(
  BuildContext context, {
  required HabitWithObjectives habit,
  required CalendarDay today,
}) => showModalBottomSheet<HabitPause>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (context) => _PauseHabitSheet(habit: habit, today: today),
);

class _PauseHabitSheet extends StatefulWidget {
  const _PauseHabitSheet({required this.habit, required this.today});

  final HabitWithObjectives habit;
  final CalendarDay today;

  @override
  State<_PauseHabitSheet> createState() => _PauseHabitSheetState();
}

class _PauseHabitSheetState extends State<_PauseHabitSheet> {
  _PauseStartChoice _startChoice = _PauseStartChoice.today;
  late CalendarDay _startDay = widget.today;
  _PauseEndChoice _endChoice = _PauseEndChoice.untilResumed;

  /// Set together with [_PauseEndChoice.pickedDay].
  CalendarDay? _pickedEndDay;

  /// Included: one week from Monday ends on Sunday.
  CalendarDay? get _endDay => switch (_endChoice) {
    _PauseEndChoice.untilResumed => null,
    _PauseEndChoice.oneWeek => _startDay.addDays(DateTime.daysPerWeek - 1),
    _PauseEndChoice.twoWeeks => _startDay.addDays(2 * DateTime.daysPerWeek - 1),
    _PauseEndChoice.pickedDay => _pickedEndDay,
  };

  void _chooseStart(_PauseStartChoice choice, CalendarDay startDay) {
    unawaited(KomitHaptics.selection());
    setState(() {
      _startChoice = choice;
      _startDay = startDay;
      // A chosen end before the new start would be no pause at all: back to the open default.
      final pickedEndDay = _pickedEndDay;
      if (_endChoice == _PauseEndChoice.pickedDay && pickedEndDay != null && startDay.isAfter(pickedEndDay)) {
        _endChoice = _PauseEndChoice.untilResumed;
        _pickedEndDay = null;
      }
    });
  }

  void _chooseEnd(_PauseEndChoice choice, {CalendarDay? pickedEndDay}) {
    unawaited(KomitHaptics.selection());
    setState(() {
      _endChoice = choice;
      _pickedEndDay = pickedEndDay;
    });
  }

  Future<void> _pickStartDay() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: widget.today.asLocalDate,
      lastDate: widget.today.addDays(_pauseDatePickerLookaheadDays).asLocalDate,
      initialDate: _startDay.asLocalDate,
    );
    if (pickedDate == null || !mounted) return;
    final pickedDay = CalendarDay.fromDateTime(pickedDate);
    final choice = switch (pickedDay.daysSinceEpoch - widget.today.daysSinceEpoch) {
      0 => _PauseStartChoice.today,
      1 => _PauseStartChoice.tomorrow,
      _ => _PauseStartChoice.pickedDay,
    };
    _chooseStart(choice, pickedDay);
  }

  Future<void> _pickEndDay() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: _startDay.asLocalDate,
      lastDate: _startDay.addDays(_pauseDatePickerLookaheadDays).asLocalDate,
      // A later start can leave a chosen end beyond the picker's range; showDatePicker asserts on it.
      initialDate: CalendarDay(
        math.min(
          (_endDay ?? _startDay.addDays(DateTime.daysPerWeek - 1)).daysSinceEpoch,
          _startDay.addDays(_pauseDatePickerLookaheadDays).daysSinceEpoch,
        ),
      ).asLocalDate,
    );
    if (pickedDate == null || !mounted) return;
    _chooseEnd(_PauseEndChoice.pickedDay, pickedEndDay: CalendarDay.fromDateTime(pickedDate));
  }

  String _summary(AppLocalizations localizations) {
    final start = formatShortDate(context, _startDay);
    final endDay = _endDay;
    if (endDay == null) return localizations.pauseSummaryOpenEnded(start);
    return localizations.pauseSummaryRange(
      start,
      formatShortDate(context, endDay),
      localizations.dayCount(endDay.daysSinceEpoch - _startDay.daysSinceEpoch + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mutedText = KomitColors.of(context).mutedText;
    final habit = widget.habit.habit;
    final today = widget.today;
    final tomorrow = today.addDays(1);
    final pickedEndDay = _pickedEndDay;
    // The summary and the button stay put under the choices: on a compact phone the choices
    // scroll, and the action they lead to never falls below the fold.
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      HabitIconBadge(icon: habitIconForName(habit.iconName), color: Color(habit.colorArgb)),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(localizations.pauseSheetTitle(habit.title), style: textTheme.titleLarge),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(localizations.pauseExplanation, style: textTheme.bodyMedium?.copyWith(color: mutedText)),
                  const SizedBox(height: AppSpacing.extraLarge),
                  _PauseChoiceGroup(
                    label: localizations.pauseStartsLabel,
                    choices: [
                      _PauseChoice(
                        label: localizations.relativeToday,
                        isSelected: _startChoice == _PauseStartChoice.today,
                        onSelected: () => _chooseStart(_PauseStartChoice.today, today),
                      ),
                      _PauseChoice(
                        label: localizations.relativeTomorrow,
                        isSelected: _startChoice == _PauseStartChoice.tomorrow,
                        onSelected: () => _chooseStart(_PauseStartChoice.tomorrow, tomorrow),
                      ),
                      _PauseChoice(
                        label: _startChoice == _PauseStartChoice.pickedDay
                            ? formatShortDate(context, _startDay)
                            : localizations.pickADay,
                        icon: KomitIcons.calendar,
                        isSelected: _startChoice == _PauseStartChoice.pickedDay,
                        onSelected: _pickStartDay,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _PauseChoiceGroup(
                    label: localizations.pauseEndsLabel,
                    choices: [
                      _PauseChoice(
                        label: localizations.pauseUntilIResume,
                        isSelected: _endChoice == _PauseEndChoice.untilResumed,
                        onSelected: () => _chooseEnd(_PauseEndChoice.untilResumed),
                      ),
                      _PauseChoice(
                        label: localizations.pauseForWeeks(1),
                        isSelected: _endChoice == _PauseEndChoice.oneWeek,
                        onSelected: () => _chooseEnd(_PauseEndChoice.oneWeek),
                      ),
                      _PauseChoice(
                        label: localizations.pauseForWeeks(2),
                        isSelected: _endChoice == _PauseEndChoice.twoWeeks,
                        onSelected: () => _chooseEnd(_PauseEndChoice.twoWeeks),
                      ),
                      _PauseChoice(
                        label: _endChoice == _PauseEndChoice.pickedDay && pickedEndDay != null
                            ? formatShortDate(context, pickedEndDay)
                            : localizations.pickADay,
                        icon: KomitIcons.calendar,
                        isSelected: _endChoice == _PauseEndChoice.pickedDay,
                        onSelected: _pickEndDay,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenGutter,
              AppSpacing.extraLarge,
              AppSpacing.screenGutter,
              AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The hatched cell is what these days will look like on the grids.
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      const PausedDaySwatch(),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: Text(_summary(localizations), style: textTheme.titleSmall)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight)),
                  onPressed: () => Navigator.of(context).pop(HabitPause(startDay: _startDay, endDay: _endDay)),
                  icon: const Icon(KomitIcons.pause),
                  label: Text(localizations.confirmPauseHabit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseChoice {
  const _PauseChoice({required this.label, required this.isSelected, required this.onSelected, this.icon});

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;
}

/// A label over chips that wrap: quick picks fit a compact phone and still wrap at 200 % text.
class _PauseChoiceGroup extends StatelessWidget {
  const _PauseChoiceGroup({required this.label, required this.choices});

  final String label;
  final List<_PauseChoice> choices;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(label, style: textTheme.labelLarge?.copyWith(color: KomitColors.of(context).mutedText)),
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final choice in choices)
              ChoiceChip(
                label: Text(choice.label),
                avatar: choice.isSelected || choice.icon == null ? null : Icon(choice.icon),
                selected: choice.isSelected,
                // Explicit, because the default selected chip is the secondary (violet) container.
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.onPrimaryContainer,
                labelStyle: TextStyle(
                  color: choice.isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                ),
                onSelected: (_) => choice.onSelected(),
              ),
          ],
        ),
      ],
    );
  }
}
