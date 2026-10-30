import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../domain/habit_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../shared/shared_widgets.dart';

enum HabitScheduleKind { everyDay, someDays, perWeek }

/// Monday to Friday, the mask the summary calls "Weekdays".
const int mondayToFridayWeekdayMask = 0x1F;

/// Saturday and Sunday, the mask the summary calls "Weekends".
const int _saturdayAndSundayMask = 0x60;

/// Weekday toggles shown on the first line when seven full touch targets do not fit side by side.
const int _weekdayTogglesOnFirstLineWhenWrapped = 4;

/// 2024-01-01 was a Monday: adding `weekday - 1` days gives a date to format any weekday's name.
final DateTime _referenceMonday = DateTime(2024);

DateTime _dateOfWeekday(int weekday) => _referenceMonday.add(Duration(days: weekday - DateTime.monday));

/// One line a person would say: "Every day", "Weekdays", "Mon, Wed, Fri", "3 days per week".
String describeHabitSchedule(
  BuildContext context, {
  required HabitScheduleKind scheduleKind,
  required int scheduledWeekdayMask,
  required int targetDaysPerWeek,
}) {
  final localizations = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  return switch (scheduleKind) {
    HabitScheduleKind.everyDay => localizations.scheduleEveryDay,
    HabitScheduleKind.perWeek => localizations.targetDaysPerWeek(targetDaysPerWeek),
    HabitScheduleKind.someDays => switch (scheduledWeekdayMask) {
      0 => localizations.pickAtLeastOneDay,
      everyWeekdayMask => localizations.scheduleEveryDay,
      mondayToFridayWeekdayMask => localizations.habitEditorWeekdaysOnly,
      _saturdayAndSundayMask => localizations.habitEditorWeekendsOnly,
      _ => [
        for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
          if (isWeekdayScheduled(scheduledWeekdayMask, weekday)) DateFormat.E(locale).format(_dateOfWeekday(weekday)),
      ].join(', '),
    },
  };
}

/// Every day, chosen weekdays, or a number of days per week: three rows in one card, where the
/// chosen row takes the habit's color and opens to show its own setting.
///
/// Rows instead of a segmented button: three labels side by side do not fit a compact phone in
/// French ("Tous les jours", "Certains jours"), and a row has room to explain each choice.
class HabitSchedulePicker extends StatelessWidget {
  const HabitSchedulePicker({
    required this.habitColor,
    required this.scheduleKind,
    required this.scheduledWeekdayMask,
    required this.targetDaysPerWeek,
    required this.onScheduleKindChanged,
    required this.onWeekdayToggled,
    required this.onTargetDaysPerWeekChanged,
    required this.restDaysPerWeek,
    required this.onRestDaysPerWeekChanged,
    super.key,
  });

  final Color habitColor;
  final HabitScheduleKind scheduleKind;
  final int scheduledWeekdayMask;
  final int targetDaysPerWeek;
  final ValueChanged<HabitScheduleKind> onScheduleKindChanged;
  final ValueChanged<int> onWeekdayToggled;
  final ValueChanged<int> onTargetDaysPerWeekChanged;

  /// Already capped for the chosen days by the editor; see [maximumRestDaysFor].
  final int restDaysPerWeek;
  final ValueChanged<int> onRestDaysPerWeekChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final summary = describeHabitSchedule(
      context,
      scheduleKind: scheduleKind,
      scheduledWeekdayMask: scheduledWeekdayMask,
      targetDaysPerWeek: targetDaysPerWeek,
    );
    Widget optionRow(HabitScheduleKind kind, IconData icon, String title, String hint, {Widget? setting}) =>
        _ScheduleOptionRow(
          icon: icon,
          title: title,
          // The chosen row says what was chosen; the others say what they would mean.
          subtitle: kind == scheduleKind && kind != HabitScheduleKind.everyDay ? summary : hint,
          isSubtitleAnError: kind == HabitScheduleKind.someDays && kind == scheduleKind && scheduledWeekdayMask == 0,
          isSelected: kind == scheduleKind,
          habitColor: habitColor,
          onSelected: () => onScheduleKindChanged(kind),
          setting: kind == scheduleKind ? setting : null,
        );
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Column(
        children: [
          optionRow(
            HabitScheduleKind.everyDay,
            KomitIcons.repeat,
            localizations.scheduleEveryDay,
            localizations.habitEditorEveryDayHint,
          ),
          optionRow(
            HabitScheduleKind.someDays,
            KomitIcons.calendarDays,
            localizations.scheduleSomeDays,
            localizations.habitEditorSomeDaysHint,
            setting: _WeekdayToggles(
              scheduledWeekdayMask: scheduledWeekdayMask,
              habitColor: habitColor,
              onWeekdayToggled: onWeekdayToggled,
            ),
          ),
          optionRow(
            HabitScheduleKind.perWeek,
            KomitIcons.target,
            localizations.schedulePerWeek,
            localizations.habitEditorPerWeekHint,
            setting: _DaysPerWeekStepper(targetDaysPerWeek: targetDaysPerWeek, onChanged: onTargetDaysPerWeekChanged),
          ),
          // A weekly target already lets the user pick their days: rest days would mean nothing.
          AnimatedSize(
            duration: motionAwareDuration(context, AppDurations.standard),
            curve: AppCurves.standard,
            alignment: AlignmentDirectional.topCenter,
            child: scheduleKind == HabitScheduleKind.perWeek
                ? const SizedBox(width: double.infinity)
                : _RestDaysSetting(
                    habitColor: habitColor,
                    restDaysPerWeek: restDaysPerWeek,
                    allowedRestDaysPerWeek: maximumRestDaysFor(
                      scheduleKind == HabitScheduleKind.someDays ? scheduledWeekdayMask : everyWeekdayMask,
                    ),
                    onChanged: onRestDaysPerWeekChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

/// None, one or two rest days a week, below the schedule rows it qualifies. Values the chosen
/// days cannot allow (one rest day on a Monday-only habit) are disabled, not hidden, so the
/// control keeps its shape while weekdays are toggled.
class _RestDaysSetting extends StatelessWidget {
  const _RestDaysSetting({
    required this.habitColor,
    required this.restDaysPerWeek,
    required this.allowedRestDaysPerWeek,
    required this.onChanged,
  });

  final Color habitColor;
  final int restDaysPerWeek;

  /// The most the chosen days allow, at most [maximumRestDaysPerWeek].
  final int allowedRestDaysPerWeek;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(indent: AppSpacing.large, endIndent: AppSpacing.large),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.medium, AppSpacing.large, AppSpacing.small),
          child: Row(
            children: [
              Container(
                width: AppSizes.iconBadge,
                height: AppSizes.iconBadge,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadii.badge),
                ),
                child: Icon(KomitIcons.bed, size: AppSizes.iconMedium, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(localizations.restDaysTitle, style: textTheme.titleMedium)),
                    Text(
                      localizations.restDaysHelp,
                      style: textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.small, AppSpacing.large, AppSpacing.medium),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: habitColor,
              selectedForegroundColor: foregroundColorReadableOn(habitColor),
            ),
            segments: [
              for (var restDayCount = 0; restDayCount <= maximumRestDaysPerWeek; restDayCount++)
                ButtonSegment(
                  value: restDayCount,
                  // Shrinks rather than wraps at large text: "Aucun" split over two lines reads as two words.
                  label: FittedBox(fit: BoxFit.scaleDown, child: Text(localizations.restDaysOption(restDayCount))),
                  enabled: restDayCount <= allowedRestDaysPerWeek,
                ),
            ],
            selected: {restDaysPerWeek},
            onSelectionChanged: (selection) => onChanged(selection.single),
          ),
        ),
      ],
    );
  }
}

class _ScheduleOptionRow extends StatelessWidget {
  const _ScheduleOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSubtitleAnError,
    required this.isSelected,
    required this.habitColor,
    required this.onSelected,
    required this.setting,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSubtitleAnError;
  final bool isSelected;
  final Color habitColor;
  final VoidCallback onSelected;

  /// Shown under the row while it is selected.
  final Widget? setting;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final setting = this.setting;
    final stateChangeDuration = motionAwareDuration(context, AppDurations.standard);
    return Column(
      children: [
        Semantics(
          inMutuallyExclusiveGroup: true,
          checked: isSelected,
          child: InkWell(
            onTap: isSelected ? null : onSelected,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: stateChangeDuration,
                    curve: AppCurves.standard,
                    width: AppSizes.iconBadge,
                    height: AppSizes.iconBadge,
                    decoration: BoxDecoration(
                      color: isSelected ? habitColor : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadii.badge),
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconMedium,
                      color: isSelected ? foregroundColorReadableOn(habitColor) : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        Text(
                          subtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: isSubtitleAnError ? colorScheme.error : komitColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  AnimatedScale(
                    scale: isSelected ? 1 : 0,
                    duration: motionAwareDuration(context, isSelected ? AppDurations.emphasized : AppDurations.quick),
                    curve: isSelected ? AppCurves.spring : AppCurves.standard,
                    child: Icon(KomitIcons.check, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: stateChangeDuration,
          curve: AppCurves.standard,
          alignment: AlignmentDirectional.topCenter,
          child: setting == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                  child: setting,
                ),
        ),
      ],
    );
  }
}

/// Seven round weekday initials on one line, or Monday to Thursday then Friday to Sunday when
/// seven full touch targets do not fit (phones narrower than about 380 dp).
class _WeekdayToggles extends StatelessWidget {
  const _WeekdayToggles({required this.scheduledWeekdayMask, required this.habitColor, required this.onWeekdayToggled});

  final int scheduledWeekdayMask;
  final Color habitColor;
  final ValueChanged<int> onWeekdayToggled;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    Widget toggle(int weekday) => _WeekdayToggle(
      date: _dateOfWeekday(weekday),
      locale: locale,
      habitColor: habitColor,
      isSelected: isWeekdayScheduled(scheduledWeekdayMask, weekday),
      onPressed: () => onWeekdayToggled(weekday),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final weekdays = [for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) weekday];
        if (constraints.maxWidth >= DateTime.daysPerWeek * AppSizes.minimumTouchTarget) {
          return Row(children: [for (final weekday in weekdays) Expanded(child: toggle(weekday))]);
        }
        return Column(
          children: [
            for (final line in [
              weekdays.take(_weekdayTogglesOnFirstLineWhenWrapped),
              weekdays.skip(_weekdayTogglesOnFirstLineWhenWrapped),
            ])
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final weekday in line) toggle(weekday)]),
          ],
        );
      },
    );
  }
}

/// A round weekday initial; the full name is what screen readers announce.
class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({
    required this.date,
    required this.locale,
    required this.habitColor,
    required this.isSelected,
    required this.onPressed,
  });

  final DateTime date;
  final String locale;
  final Color habitColor;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      toggled: isSelected,
      label: DateFormat.EEEE(locale).format(date),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: AppSizes.minimumTouchTarget / 2,
        child: SizedBox(
          height: AppSizes.minimumTouchTarget,
          width: AppSizes.minimumTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: motionAwareDuration(context, AppDurations.quick),
              curve: AppCurves.standard,
              width: AppSizes.weekdayToggle,
              height: AppSizes.weekdayToggle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? habitColor : colorScheme.surfaceContainerHigh,
              ),
              // One letter must stay inside its circle, whatever the font size.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: AppTextScaling.appBarMaximumScaleFactor,
                child: Text(
                  // The narrow form ("M"), the way calendars label their columns.
                  DateFormat.EEEEE(locale).format(date),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: isSelected ? foregroundColorReadableOn(habitColor) : colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The weekly target as a large number between two round buttons.
class _DaysPerWeekStepper extends StatelessWidget {
  const _DaysPerWeekStepper({required this.targetDaysPerWeek, required this.onChanged});

  final int targetDaysPerWeek;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stepButtonStyle = IconButton.styleFrom(
      minimumSize: const Size.square(AppSizes.primaryButtonHeight),
      backgroundColor: colorScheme.surfaceContainerHigh,
      foregroundColor: colorScheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Row(
        children: [
          IconButton(
            style: stepButtonStyle,
            tooltip: localizations.fewerDaysPerWeek,
            onPressed: targetDaysPerWeek > minimumTargetDaysPerWeek ? () => onChanged(targetDaysPerWeek - 1) : null,
            icon: const Icon(KomitIcons.minus),
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label: localizations.targetDaysPerWeek(targetDaysPerWeek),
              excludeSemantics: true,
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: motionAwareDuration(context, AppDurations.standard),
                    switchInCurve: AppCurves.emphasized,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Text(
                      '$targetDaysPerWeek',
                      key: ValueKey(targetDaysPerWeek),
                      style: textTheme.headlineLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  Text(
                    localizations.habitEditorDaysPerWeekUnit(targetDaysPerWeek),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            style: stepButtonStyle,
            tooltip: localizations.moreDaysPerWeek,
            onPressed: targetDaysPerWeek < maximumTargetDaysPerWeek ? () => onChanged(targetDaysPerWeek + 1) : null,
            icon: const Icon(KomitIcons.plus),
          ),
        ],
      ),
    );
  }
}
