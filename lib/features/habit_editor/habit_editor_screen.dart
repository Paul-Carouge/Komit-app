import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';
import 'appearance_pickers.dart';

const int _defaultReminderMinuteOfDay = 20 * Duration.minutesPerHour;

class HabitEditorScreen extends ConsumerStatefulWidget {
  const HabitEditorScreen({required this.habitId, super.key});

  /// Null creates a new habit.
  final int? habitId;

  @override
  ConsumerState<HabitEditorScreen> createState() => _HabitEditorScreenState();
}

class _EditableObjective {
  _EditableObjective({required this.id, required String title, required this.colorArgb})
    : titleController = TextEditingController(text: title);

  final int? id;
  final TextEditingController titleController;
  int colorArgb;

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
  bool _isLoading = true;
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
    final existingHabit = await ref.read(habitRepositoryProvider).watchHabitWithObjectives(habitId).first;
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
      _objectives.addAll([
        for (final objective in objectives)
          _EditableObjective(id: objective.id, title: objective.title, colorArgb: objective.colorArgb),
      ]);
      _isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habitId == null ? localizations.createHabit : localizations.editHabit),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.small),
            child: IconButton.filled(
              tooltip: localizations.save,
              onPressed: _isLoading || _isSaving ? null : _save,
              icon: const Icon(LucideIcons.check),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(semanticsLabel: localizations.loading))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.small,
                AppSpacing.screenGutter,
                AppSpacing.huge,
              ),
              children: [
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
                Row(
                  children: [
                    Expanded(
                      child: _AppearanceTile(
                        leading: ColorDot(color: Color(_colorArgb), size: AppSizes.colorDotLarge),
                        label: localizations.color,
                        onTap: _chooseColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: _AppearanceTile(
                        leading: HabitIconBadge(icon: habitIconForName(_iconName), color: Color(_colorArgb)),
                        label: localizations.icon,
                        onTap: _chooseIcon,
                      ),
                    ),
                  ],
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
    );
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
              objectives: [
                for (final objective in _objectives)
                  ObjectiveDraft(
                    id: objective.id,
                    title: objective.titleController.text,
                    colorArgb: objective.colorArgb,
                  ),
              ],
            ),
          );
      unawaited(KomitHaptics.success());
      if (mounted) context.pop();
    } on Object {
      unawaited(KomitHaptics.error());
      if (mounted) {
        setState(() => _isSaving = false);
        showMessageSnackBar(context, localizations.genericError);
      }
    }
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
    super.key,
  });

  final int index;
  final _EditableObjective objective;
  final VoidCallback onColorTapped;
  final VoidCallback onRemoved;

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
          child: Row(
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
                  decoration: InputDecoration(
                    hintText: localizations.objectiveName,
                    counterText: '',
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: localizations.removeObjective,
                onPressed: onRemoved,
                icon: Icon(LucideIcons.x, color: komitColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
