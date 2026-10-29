import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/habit_schedule.dart';
import '../../providers.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';
import 'appearance_pickers.dart';

const int _defaultReminderMinuteOfDay = 20 * Duration.minutesPerHour;

/// Offered when switching to a weekly target: most people aim for about half the week.
const int _defaultTargetDaysPerWeek = 3;

/// 2024-01-01 was a Monday: adding `weekday - 1` days gives a date to format any weekday's name.
final DateTime _referenceMonday = DateTime(2024);

enum _ScheduleKind { everyDay, someDays, perWeek }

class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({required this.habitId, super.key});

  /// Null creates a new habit.
  final int? habitId;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _EditableObjective {
  _EditableObjective({required this.id, required String title, required this.colorArgb, this.countsAsSuccess = true})
    : titleController = TextEditingController(text: title);

  final int? id;
  final TextEditingController titleController;
  int colorArgb;
  bool countsAsSuccess;

  /// Stable across reorders, unlike the index.
  final Key key = UniqueKey();
}

class _HabitEditorScreenState extends ConsumerState<HabitEditorScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_EditableObjective> _objectives = [];
  int _colorArgb = habitColorPaletteArgb.first;
  String _iconName = defaultHabitIconName;
  int? _reminderMinuteOfDay;
  int? _initialReminderMinuteOfDay;
  _ScheduleKind _scheduleKind = _ScheduleKind.everyDay;
  int _scheduledWeekdayMask = everyWeekdayMask;
  int _targetDaysPerWeek = _defaultTargetDaysPerWeek;
  bool _isLoading = true;
  bool _hasLoadFailed = false;
  bool _isSaving = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    final habitId = widget.habitId;
    if (habitId == null) {
      _objectives.add(_EditableObjective(id: null, title: '', colorArgb: habitColorPaletteArgb[9]));
      setState(() => _isLoading = false);
      return;
    }
    final HabitWithObjectives? existingHabit;
    try {
      existingHabit = await ref.read(habitRepositoryProvider).watchHabitWithObjectives(habitId).first;
    } on Object catch (error, stackTrace) {
      unawaited(
        ref.read(appLoggerProvider).logError(event: 'habit_editor_load_failed', error: error, stackTrace: stackTrace),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    if (existingHabit == null) {
      context.pop();
      return;
    }
    final HabitWithObjectives(:habit, :objectives) = existingHabit;
    setState(() {
      _titleController.text = habit.title;
      _descriptionController.text = habit.description;
      _colorArgb = habit.colorArgb;
      _iconName = habit.iconName;
      _reminderMinuteOfDay = habit.reminderMinuteOfDay;
      _initialReminderMinuteOfDay = habit.reminderMinuteOfDay;
      _scheduledWeekdayMask = habit.scheduledWeekdayMask;
      _targetDaysPerWeek = habit.targetDaysPerWeek ?? _defaultTargetDaysPerWeek;
      _scheduleKind = switch ((habit.targetDaysPerWeek, habit.scheduledWeekdayMask)) {
        (_?, _) => _ScheduleKind.perWeek,
        (null, everyWeekdayMask) => _ScheduleKind.everyDay,
        (null, _) => _ScheduleKind.someDays,
      };
      _objectives.addAll([
        for (final objective in objectives)
          _EditableObjective(
            id: objective.id,
            title: objective.title,
            colorArgb: objective.colorArgb,
            countsAsSuccess: objective.countsAsSuccess,
          ),
      ]);
      _isLoading = false;
    });
  }

  void _retryLoading() {
    setState(() {
      _hasLoadFailed = false;
      _isLoading = true;
    });
    _loadHabit();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final objective in _objectives) {
      objective.titleController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isNewHabit = widget.habitId == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNewHabit ? localizations.createHabit : localizations.editHabit)),
      // The primary action sits where the thumb is, full width, once the habit is loaded.
      bottomNavigationBar: _isLoading || _hasLoadFailed
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.small,
                AppSpacing.screenGutter,
                AppSpacing.large,
              ),
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(isNewHabit ? localizations.createHabitAction : localizations.saveHabit),
              ),
            ),
      body: switch ((_isLoading, _hasLoadFailed)) {
        (true, _) => Center(child: CircularProgressIndicator(semanticsLabel: localizations.loading)),
        (_, true) => KomoEmptyState(
          mood: KomoMood.sleepy,
          title: localizations.loadErrorTitle,
          message: localizations.loadErrorMessage,
          action: FilledButton.tonalIcon(
            onPressed: _retryLoading,
            icon: const Icon(LucideIcons.rotateCw),
            label: Text(localizations.retryLoading),
          ),
        ),
        _ => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.small,
            AppSpacing.screenGutter,
            AppSpacing.extraLarge,
          ),
          children: [
            ExcludeSemantics(
              child: ListenableBuilder(
                listenable: _titleController,
                builder: (context, _) => _HabitRowPreview(
                  title: _titleController.text.trim(),
                  iconName: _iconName,
                  colorArgb: _colorArgb,
                  scheduleSummary: _scheduleSummary(localizations),
                  objectiveColorsArgb: [for (final objective in _objectives) objective.colorArgb],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            TextField(
              controller: _titleController,
              maxLength: maximumHabitTitleLength,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.titleMedium,
              decoration: InputDecoration(labelText: localizations.habitName, counterText: ''),
            ),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              maxLength: maximumHabitDescriptionLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: localizations.descriptionOptional, counterText: ''),
            ),
            SectionTitle(localizations.appearance),
            _AppearanceTiles(
              colorTile: _AppearanceTile(
                leading: ColorDot(color: Color(_colorArgb), size: AppSizes.colorDotLarge),
                label: localizations.color,
                onTap: _chooseColor,
              ),
              iconTile: _AppearanceTile(
                leading: HabitIconBadge(icon: habitIconForName(_iconName), color: Color(_colorArgb)),
                label: localizations.icon,
                onTap: _chooseIcon,
              ),
            ),
            SectionTitle(localizations.schedule),
            _SchedulePicker(
              scheduleKind: _scheduleKind,
              scheduledWeekdayMask: _scheduledWeekdayMask,
              targetDaysPerWeek: _targetDaysPerWeek,
              onScheduleKindChanged: (scheduleKind) {
                unawaited(KomitHaptics.selection());
                setState(() => _scheduleKind = scheduleKind);
              },
              onWeekdayToggled: (weekday) {
                unawaited(KomitHaptics.selection());
                setState(() => _scheduledWeekdayMask ^= 1 << (weekday - DateTime.monday));
              },
              onTargetDaysPerWeekChanged: (targetDaysPerWeek) {
                unawaited(KomitHaptics.selection());
                setState(() => _targetDaysPerWeek = targetDaysPerWeek);
              },
            ),
            const SizedBox(height: AppSpacing.large),
            _ReminderCard(
              reminderMinuteOfDay: _reminderMinuteOfDay,
              onToggled: (isEnabled) => setState(
                () => _reminderMinuteOfDay = isEnabled
                    ? _initialReminderMinuteOfDay ?? _defaultReminderMinuteOfDay
                    : null,
              ),
              onTimeTapped: _chooseReminderTime,
            ),
            SectionTitle(
              localizations.objectives,
              trailing: TextButton.icon(
                onPressed: _addObjective,
                icon: const Icon(LucideIcons.plus),
                label: Text(localizations.addObjective),
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _objectives.insert(newIndex, _objectives.removeAt(oldIndex));
              }),
              children: [
                for (final (index, objective) in _objectives.indexed)
                  _ObjectiveRowEditor(
                    key: objective.key,
                    index: index,
                    objective: objective,
                    onColorTapped: () => _chooseObjectiveColor(objective),
                    onRemoved: () => _removeObjective(objective),
                    onCountsAsSuccessChanged: (countsAsSuccess) {
                      unawaited(KomitHaptics.selection());
                      setState(() => objective.countsAsSuccess = countsAsSuccess);
                    },
                  ),
              ],
            ),
            if (_validationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.medium),
                child: Semantics(
                  liveRegion: true,
                  child: Text(_validationMessage!, style: TextStyle(color: colorScheme.error)),
                ),
              ),
          ],
        ),
      },
    );
  }

  String _scheduleSummary(AppLocalizations localizations) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return switch (_scheduleKind) {
      _ScheduleKind.everyDay => localizations.scheduleEveryDay,
      _ScheduleKind.perWeek => localizations.targetDaysPerWeek(_targetDaysPerWeek),
      _ScheduleKind.someDays => [
        for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
          if (isWeekdayScheduled(_scheduledWeekdayMask, weekday))
            DateFormat.E(locale).format(_referenceMonday.add(Duration(days: weekday - DateTime.monday))),
      ].join(', '),
    };
  }

  void _addObjective() {
    final usedColors = _objectives.map((objective) => objective.colorArgb).toSet();
    final nextColor = habitColorPaletteArgb.firstWhere(
      (color) => !usedColors.contains(color),
      orElse: () => _colorArgb,
    );
    setState(() => _objectives.add(_EditableObjective(id: null, title: '', colorArgb: nextColor)));
  }

  Future<void> _removeObjective(_EditableObjective objective) async {
    final localizations = AppLocalizations.of(context);
    if (objective.id case final objectiveId?) {
      final logCount = await ref.read(habitRepositoryProvider).countLogsForObjective(objectiveId);
      if (!mounted) return;
      if (logCount > 0) {
        final isConfirmed = await showDestructiveConfirmationDialog(
          context,
          message: localizations.removeObjectiveWithLogsConfirmation(logCount),
          confirmLabel: localizations.remove,
        );
        if (!isConfirmed || !mounted) return;
      }
    }
    unawaited(KomitHaptics.warning());
    setState(() => _objectives.remove(objective));
    objective.titleController.dispose();
  }

  Future<void> _chooseColor() async {
    final chosenColor = await showColorPickerSheet(context, selectedColorArgb: _colorArgb);
    if (chosenColor != null && mounted) setState(() => _colorArgb = chosenColor);
  }

  Future<void> _chooseObjectiveColor(_EditableObjective objective) async {
    final chosenColor = await showColorPickerSheet(context, selectedColorArgb: objective.colorArgb);
    if (chosenColor != null && mounted) setState(() => objective.colorArgb = chosenColor);
  }

  Future<void> _chooseIcon() async {
    final chosenIconName = await showIconPickerSheet(context, selectedIconName: _iconName, colorArgb: _colorArgb);
    if (chosenIconName != null && mounted) setState(() => _iconName = chosenIconName);
  }

  Future<void> _chooseReminderTime() async {
    final currentMinute = _reminderMinuteOfDay ?? _defaultReminderMinuteOfDay;
    final chosenTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentMinute ~/ Duration.minutesPerHour,
        minute: currentMinute % Duration.minutesPerHour,
      ),
    );
    if (chosenTime != null && mounted) {
      setState(() => _reminderMinuteOfDay = chosenTime.hour * Duration.minutesPerHour + chosenTime.minute);
    }
  }

  String? _findValidationError(AppLocalizations localizations) {
    final title = _titleController.text.trim();
    if (title.isEmpty) return localizations.habitNameRequired;
    // The field counts characters as displayed; the database counts UTF-16 units (an emoji counts twice).
    if (title.length > maximumHabitTitleLength) return localizations.habitNameTooLong;
    if (_scheduleKind == _ScheduleKind.someDays && _scheduledWeekdayMask == 0) return localizations.pickAtLeastOneDay;
    if (_objectives.isEmpty) return localizations.objectiveRequired;
    final objectiveTitles = _objectives.map((objective) => objective.titleController.text.trim()).toList();
    final hasEmptyOrDuplicateTitle =
        objectiveTitles.any((title) => title.isEmpty || title.length > maximumObjectiveTitleLength) ||
        objectiveTitles.toSet().length != objectiveTitles.length;
    return hasEmptyOrDuplicateTitle ? localizations.objectiveNamesMustBeFilledAndUnique : null;
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    final validationError = _findValidationError(localizations);
    setState(() => _validationMessage = validationError);
    if (validationError != null) {
      unawaited(KomitHaptics.error());
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Asked on every save with a reminder: the permission may have been revoked since.
      if (_reminderMinuteOfDay != null) {
        final isNotificationAllowed = await ref.read(reminderSchedulerProvider).requestPermission();
        if (!isNotificationAllowed && mounted) showMessageSnackBar(context, localizations.notificationsDenied);
      }
      await ref
          .read(habitRepositoryProvider)
          .saveHabit(
            HabitDraft(
              id: widget.habitId,
              title: _titleController.text,
              description: _descriptionController.text,
              colorArgb: _colorArgb,
              iconName: _iconName,
              reminderMinuteOfDay: _reminderMinuteOfDay,
              scheduledWeekdayMask: _scheduleKind == _ScheduleKind.someDays ? _scheduledWeekdayMask : everyWeekdayMask,
              targetDaysPerWeek: _scheduleKind == _ScheduleKind.perWeek ? _targetDaysPerWeek : null,
              objectives: [
                for (final objective in _objectives)
                  ObjectiveDraft(
                    id: objective.id,
                    title: objective.titleController.text,
                    colorArgb: objective.colorArgb,
                    countsAsSuccess: objective.countsAsSuccess,
                  ),
              ],
            ),
          );
      unawaited(KomitHaptics.success());
      if (mounted) context.pop();
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(ref.read(appLoggerProvider).logError(event: 'habit_save_failed', error: error, stackTrace: stackTrace));
      if (mounted) {
        setState(() => _isSaving = false);
        showMessageSnackBar(context, localizations.genericError);
      }
    }
  }
}

/// Above this font scale two tiles side by side leave too little room for their labels.
const double _appearanceTilesStackingTextScaleFactor = 1.3;

/// Color and icon side by side, stacked when the font is large.
class _AppearanceTiles extends StatelessWidget {
  const _AppearanceTiles({required this.colorTile, required this.iconTile});

  final Widget colorTile;
  final Widget iconTile;

  @override
  Widget build(BuildContext context) {
    if (bodyTextScaleOf(context) > _appearanceTilesStackingTextScaleFactor) {
      return Column(
        children: [
          colorTile,
          const SizedBox(height: AppSpacing.medium),
          iconTile,
        ],
      );
    }
    // Same height side by side, although the icon badge is taller than the color dot.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: colorTile),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: iconTile),
        ],
      ),
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({required this.leading, required this.label, required this.onTap});

  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.medium),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
              Icon(LucideIcons.chevronRight, color: KomitColors.of(context).mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminderMinuteOfDay, required this.onToggled, required this.onTimeTapped});

  final int? reminderMinuteOfDay;
  final ValueChanged<bool> onToggled;
  final VoidCallback onTimeTapped;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final reminderMinute = reminderMinuteOfDay;
    final formattedTime = reminderMinute == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(
              hour: reminderMinute ~/ Duration.minutesPerHour,
              minute: reminderMinute % Duration.minutesPerHour,
            ),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.small),
            secondary: HabitIconBadge(icon: LucideIcons.bell, color: colorScheme.primary),
            title: Text(localizations.dailyReminder, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              formattedTime == null ? localizations.reminderDisabled : localizations.reminderEnabledAt(formattedTime),
            ),
            value: reminderMinute != null,
            onChanged: onToggled,
          ),
          if (formattedTime != null) ...[
            Divider(
              height: AppSizes.hairline,
              indent: AppSpacing.large,
              endIndent: AppSpacing.large,
              color: colorScheme.outlineVariant,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              title: Text(localizations.reminderTime),
              trailing: OutlinedButton(onPressed: onTimeTapped, child: Text(formattedTime)),
              onTap: onTimeTapped,
            ),
          ],
        ],
      ),
    );
  }
}

class _ObjectiveRowEditor extends StatelessWidget {
  const _ObjectiveRowEditor({
    required this.index,
    required this.objective,
    required this.onColorTapped,
    required this.onRemoved,
    required this.onCountsAsSuccessChanged,
    super.key,
  });

  final int index;
  final _EditableObjective objective;
  final VoidCallback onColorTapped;
  final VoidCallback onRemoved;
  final ValueChanged<bool> onCountsAsSuccessChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.extraSmall),
          child: Column(
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Tooltip(
                      message: localizations.reorderObjective,
                      child: SizedBox.square(
                        dimension: AppSizes.minimumTouchTarget,
                        child: Icon(LucideIcons.gripVertical, color: komitColors.mutedText),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: localizations.chooseColor,
                    onPressed: onColorTapped,
                    icon: ColorDot(color: Color(objective.colorArgb), size: AppSizes.iconMedium),
                  ),
                  Expanded(
                    child: TextField(
                      controller: objective.titleController,
                      maxLength: maximumObjectiveTitleLength,
                      textCapitalization: TextCapitalization.sentences,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: borderlessInlineInputDecoration(hintText: localizations.objectiveName),
                    ),
                  ),
                  IconButton(
                    tooltip: localizations.removeObjective,
                    onPressed: onRemoved,
                    icon: Icon(LucideIcons.x, color: komitColors.mutedText),
                  ),
                ],
              ),
              SwitchListTile(
                dense: true,
                // Lines the label up with the objective name, past the handle and the color.
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 2 * AppSizes.minimumTouchTarget,
                  end: AppSpacing.extraSmall,
                ),
                title: Text(localizations.countsTowardStreak, style: Theme.of(context).textTheme.bodyMedium),
                value: objective.countsAsSuccess,
                onChanged: onCountsAsSuccessChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dashboard row as it will look, updated while typing: a name, an icon, a schedule.
class _HabitRowPreview extends StatelessWidget {
  const _HabitRowPreview({
    required this.title,
    required this.iconName,
    required this.colorArgb,
    required this.scheduleSummary,
    required this.objectiveColorsArgb,
  });

  final String title;
  final String iconName;
  final int colorArgb;
  final String scheduleSummary;
  final List<int> objectiveColorsArgb;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mutedText = KomitColors.of(context).mutedText;
    return SoftCard(
      child: Row(
        children: [
          HabitIconBadge(icon: habitIconForName(iconName), color: Color(colorArgb)),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? localizations.habitNamePlaceholder : title,
                  style: textTheme.titleMedium?.copyWith(color: title.isEmpty ? mutedText : null),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(scheduleSummary, style: textTheme.bodySmall?.copyWith(color: mutedText)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.extraSmall,
            children: [
              for (final objectiveColorArgb in objectiveColorsArgb) ColorDot(color: Color(objectiveColorArgb)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Every day, chosen weekdays, or a number of days per week.
class _SchedulePicker extends StatelessWidget {
  const _SchedulePicker({
    required this.scheduleKind,
    required this.scheduledWeekdayMask,
    required this.targetDaysPerWeek,
    required this.onScheduleKindChanged,
    required this.onWeekdayToggled,
    required this.onTargetDaysPerWeekChanged,
  });

  final _ScheduleKind scheduleKind;
  final int scheduledWeekdayMask;
  final int targetDaysPerWeek;
  final ValueChanged<_ScheduleKind> onScheduleKindChanged;
  final ValueChanged<int> onWeekdayToggled;
  final ValueChanged<int> onTargetDaysPerWeekChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_ScheduleKind>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _ScheduleKind.everyDay, label: Text(localizations.scheduleEveryDay)),
            ButtonSegment(value: _ScheduleKind.someDays, label: Text(localizations.scheduleSomeDays)),
            ButtonSegment(value: _ScheduleKind.perWeek, label: Text(localizations.schedulePerWeek)),
          ],
          selected: {scheduleKind},
          onSelectionChanged: (selection) => onScheduleKindChanged(selection.single),
        ),
        if (scheduleKind == _ScheduleKind.someDays) ...[
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
                _WeekdayToggle(
                  date: _referenceMonday.add(Duration(days: weekday - DateTime.monday)),
                  locale: locale,
                  isSelected: isWeekdayScheduled(scheduledWeekdayMask, weekday),
                  onPressed: () => onWeekdayToggled(weekday),
                ),
            ],
          ),
        ],
        if (scheduleKind == _ScheduleKind.perWeek) ...[
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              IconButton.outlined(
                tooltip: localizations.fewerDaysPerWeek,
                onPressed: targetDaysPerWeek > minimumTargetDaysPerWeek
                    ? () => onTargetDaysPerWeekChanged(targetDaysPerWeek - 1)
                    : null,
                icon: const Icon(LucideIcons.minus),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    localizations.targetDaysPerWeek(targetDaysPerWeek),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton.outlined(
                tooltip: localizations.moreDaysPerWeek,
                onPressed: targetDaysPerWeek < maximumTargetDaysPerWeek
                    ? () => onTargetDaysPerWeekChanged(targetDaysPerWeek + 1)
                    : null,
                icon: const Icon(LucideIcons.plus),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A round weekday initial; the full name is what screen readers announce.
class _WeekdayToggle extends StatelessWidget {
  const _WeekdayToggle({required this.date, required this.locale, required this.isSelected, required this.onPressed});

  final DateTime date;
  final String locale;
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
        child: SizedBox.square(
          dimension: AppSizes.minimumTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: motionAwareDuration(context, AppDurations.quick),
              curve: AppCurves.standard,
              width: AppSizes.weekdayToggle,
              height: AppSizes.weekdayToggle,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
              ),
              child: Text(
                // The narrow form ("M"), the way calendars label their columns.
                DateFormat.EEEEE(locale).format(date),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
