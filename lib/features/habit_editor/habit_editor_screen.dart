import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_schedule.dart' show maximumRestDaysFor;
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../services/notification_permission_service.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';
import 'appearance_pickers.dart';
import 'schedule_picker.dart';

const int _defaultReminderMinuteOfDay = 20 * Duration.minutesPerHour;

/// Offered when switching to a weekly target: most people aim for about half the week.
const int _defaultTargetDaysPerWeek = 3;

/// The first objective of a new habit: green, the color of a day that went well.
const int _firstObjectiveColorIndex = 9;

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
  final _titleFocusNode = FocusNode();
  final _descriptionController = TextEditingController();
  final List<_EditableObjective> _objectives = [];
  int _colorArgb = habitColorPaletteArgb.first;
  String _iconName = defaultHabitIconName;
  int? _reminderMinuteOfDay;
  int? _initialReminderMinuteOfDay;
  HabitScheduleKind _scheduleKind = HabitScheduleKind.everyDay;
  int _scheduledWeekdayMask = everyWeekdayMask;
  int _targetDaysPerWeek = _defaultTargetDaysPerWeek;

  /// As chosen; [_restDaysPerWeekForSchedule] caps it for the chosen days without forgetting it
  /// while weekdays are toggled.
  int _restDaysPerWeek = 0;
  bool _isLoading = true;
  bool _hasLoadFailed = false;
  bool _isSaving = false;

  /// Shown on the name field itself, where the fix happens.
  String? _titleErrorMessage;

  /// Every other problem, shown right above the save button that revealed it.
  String? _formErrorMessage;

  /// The form as loaded, to tell whether leaving would lose anything.
  List<Object?> _loadedFormSnapshot = const [];

  @override
  void initState() {
    super.initState();
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    final habitId = widget.habitId;
    if (habitId == null) {
      _objectives.add(
        _EditableObjective(id: null, title: '', colorArgb: habitColorPaletteArgb[_firstObjectiveColorIndex]),
      );
      setState(() {
        _isLoading = false;
        _loadedFormSnapshot = _formSnapshot();
      });
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
      _restDaysPerWeek = habit.restDaysPerWeek;
      _scheduleKind = switch ((habit.targetDaysPerWeek, habit.scheduledWeekdayMask)) {
        (_?, _) => HabitScheduleKind.perWeek,
        (null, everyWeekdayMask) => HabitScheduleKind.everyDay,
        (null, _) => HabitScheduleKind.someDays,
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
      _loadedFormSnapshot = _formSnapshot();
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
    _titleFocusNode.dispose();
    _descriptionController.dispose();
    for (final objective in _objectives) {
      objective.titleController.dispose();
    }
    super.dispose();
  }

  int get _scheduledWeekdayMaskToSave =>
      _scheduleKind == HabitScheduleKind.someDays ? _scheduledWeekdayMask : everyWeekdayMask;

  /// What gets saved: none with a weekly target, and never more than the chosen days allow.
  int get _restDaysPerWeekForSchedule => _scheduleKind == HabitScheduleKind.perWeek
      ? 0
      : math.min(_restDaysPerWeek, maximumRestDaysFor(_scheduledWeekdayMaskToSave));

  /// Everything the save would write, in a comparable form.
  List<Object?> _formSnapshot() => [
    _titleController.text,
    _descriptionController.text,
    _colorArgb,
    _iconName,
    _reminderMinuteOfDay,
    _scheduleKind,
    _scheduledWeekdayMask,
    _targetDaysPerWeek,
    _restDaysPerWeekForSchedule,
    for (final objective in _objectives) ...[
      objective.id,
      objective.titleController.text,
      objective.colorArgb,
      objective.countsAsSuccess,
    ],
  ];

  bool get _hasUnsavedChanges => !listEquals(_formSnapshot(), _loadedFormSnapshot);

  /// Back, the back gesture and the app bar button all land here while the form is shown.
  Future<void> _onPopBlocked() async {
    if (_isSaving) return;
    final localizations = AppLocalizations.of(context);
    final shouldLeave =
        !_hasUnsavedChanges ||
        await showDestructiveConfirmationDialog(
          context,
          title: localizations.habitEditorDiscardTitle,
          message: localizations.habitEditorDiscardMessage,
          confirmLabel: localizations.habitEditorDiscardConfirm,
          cancelLabel: localizations.habitEditorKeepEditing,
        );
    if (shouldLeave && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isNewHabit = widget.habitId == null;
    final isFormShown = !_isLoading && !_hasLoadFailed;
    final title = isNewHabit ? localizations.createHabit : localizations.editHabit;
    return PopScope(
      canPop: !isFormShown,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onPopBlocked());
      },
      child: Scaffold(
        // The list scrolls under the frosted save bar; its bottom padding includes the bar.
        extendBody: true,
        bottomNavigationBar: isFormShown
            ? _SaveBar(
                label: isNewHabit ? localizations.createHabitAction : localizations.saveHabit,
                isSaving: _isSaving,
                errorMessage: _formErrorMessage,
                onPressed: _save,
              )
            : null,
        body: CustomScrollView(
          slivers: [
            LargeTitleSliverAppBar(title: title),
            if (_isLoading)
              const SliverFillRemaining(hasScrollBody: false, child: DelayedLoadingSkeleton())
            else if (_hasLoadFailed)
              SliverFillRemaining(
                hasScrollBody: false,
                child: KomoEmptyState(
                  mood: KomoMood.sleepy,
                  title: localizations.loadErrorTitle,
                  message: localizations.loadErrorMessage,
                  action: FilledButton.tonalIcon(
                    onPressed: _retryLoading,
                    icon: const Icon(KomitIcons.rotateCw),
                    label: Text(localizations.retryLoading),
                  ),
                ),
              )
            else
              _FormColumn(children: _buildFormSections(localizations)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormSections(AppLocalizations localizations) => [
    const SizedBox(height: AppSpacing.small),
    _IdentityCard(
      titleField: _LabeledField(
        label: localizations.habitName,
        field: TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          maxLength: maximumHabitTitleLength,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          style: Theme.of(context).textTheme.titleLarge,
          onChanged: (_) {
            if (_titleErrorMessage != null) setState(() => _titleErrorMessage = null);
          },
          decoration: _identityFieldDecoration(context, label: localizations.habitName, errorText: _titleErrorMessage),
        ),
      ),
      descriptionField: _LabeledField(
        label: localizations.descriptionOptional,
        field: TextField(
          controller: _descriptionController,
          minLines: 1,
          maxLines: 4,
          maxLength: maximumHabitDescriptionLength,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          decoration: _identityFieldDecoration(context, label: localizations.descriptionOptional),
        ),
      ),
      iconButton: HabitIdentityIconButton(iconName: _iconName, colorArgb: _colorArgb, onPressed: _chooseIcon),
      colorStrip: HabitColorStrip(
        selectedColorArgb: _colorArgb,
        onColorSelected: (colorArgb) {
          unawaited(KomitHaptics.selection());
          setState(() => _colorArgb = colorArgb);
        },
      ),
    ),
    SectionTitle(localizations.schedule),
    HabitSchedulePicker(
      habitColor: Color(_colorArgb),
      scheduleKind: _scheduleKind,
      scheduledWeekdayMask: _scheduledWeekdayMask,
      targetDaysPerWeek: _targetDaysPerWeek,
      onScheduleKindChanged: (scheduleKind) {
        unawaited(KomitHaptics.selection());
        setState(() {
          // All seven days ticked would just mean "Every day": start from the working week.
          if (scheduleKind == HabitScheduleKind.someDays && _scheduledWeekdayMask == everyWeekdayMask) {
            _scheduledWeekdayMask = mondayToFridayWeekdayMask;
          }
          _scheduleKind = scheduleKind;
        });
      },
      onWeekdayToggled: (weekday) {
        unawaited(KomitHaptics.selection());
        setState(() => _scheduledWeekdayMask ^= 1 << (weekday - DateTime.monday));
      },
      onTargetDaysPerWeekChanged: (targetDaysPerWeek) {
        unawaited(KomitHaptics.selection());
        setState(() => _targetDaysPerWeek = targetDaysPerWeek);
      },
      restDaysPerWeek: _restDaysPerWeekForSchedule,
      onRestDaysPerWeekChanged: (restDaysPerWeek) {
        unawaited(KomitHaptics.selection());
        setState(() => _restDaysPerWeek = restDaysPerWeek);
      },
    ),
    const SizedBox(height: AppSpacing.medium),
    _ReminderCard(
      reminderMinuteOfDay: _reminderMinuteOfDay,
      onToggled: _onReminderToggled,
      onTimeTapped: _chooseReminderTime,
    ),
    SectionTitle(localizations.objectives),
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Text(
        localizations.habitEditorObjectivesHelp,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
      ),
    ),
    _ObjectivesCard(
      objectives: _objectives,
      onReordered: (oldIndex, newIndex) => setState(() {
        _objectives.insert(newIndex, _objectives.removeAt(oldIndex));
      }),
      onColorTapped: _chooseObjectiveColor,
      onRemoved: _removeObjective,
      onCountsAsSuccessChanged: (objective, countsAsSuccess) {
        unawaited(KomitHaptics.selection());
        setState(() => objective.countsAsSuccess = countsAsSuccess);
      },
      onAdded: _addObjective,
    ),
  ];

  void _addObjective() {
    unawaited(KomitHaptics.selection());
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

  Future<void> _chooseObjectiveColor(_EditableObjective objective) async {
    final chosenColor = await showColorPickerSheet(context, selectedColorArgb: objective.colorArgb);
    if (chosenColor != null && mounted) setState(() => objective.colorArgb = chosenColor);
  }

  Future<void> _chooseIcon() async {
    final chosenIconName = await showIconPickerSheet(context, selectedIconName: _iconName, colorArgb: _colorArgb);
    if (chosenIconName != null && mounted) {
      unawaited(KomitHaptics.selection());
      setState(() => _iconName = chosenIconName);
    }
  }

  /// Turning a reminder on is the moment Komit asks for notifications: the switch moves at
  /// once, a sheet explains what this reminder will do, then Android asks. Any refusal puts
  /// the switch back and says how to allow notifications later.
  Future<void> _onReminderToggled(bool isEnabled) async {
    unawaited(KomitHaptics.selection());
    final reminderMinuteOfDay = _initialReminderMinuteOfDay ?? _defaultReminderMinuteOfDay;
    setState(() => _reminderMinuteOfDay = isEnabled ? reminderMinuteOfDay : null);
    if (!isEnabled) return;
    final localizations = AppLocalizations.of(context);
    final permissionService = ref.read(notificationPermissionServiceProvider);
    final NotificationStatus status;
    try {
      status = await permissionService.readNotificationStatus();
    } on Object catch (error, stackTrace) {
      // The reminder stays on: the settings screen shows the status if it cannot be read here.
      unawaited(
        ref.read(appLoggerProvider).logError(event: 'notification_status_failed', error: error, stackTrace: stackTrace),
      );
      return;
    }
    if (status != NotificationStatus.disabled || !mounted) return;
    final habitTitle = _titleController.text.trim();
    final isRationaleAccepted = await showPermissionRationaleSheet(
      context,
      icon: KomitIcons.bellRing,
      title: localizations.reminderPermissionTitle(habitTitle.isEmpty ? localizations.thisHabit : habitTitle),
      message: localizations.reminderPermissionMessage(_formatMinuteOfDay(context, reminderMinuteOfDay)),
      confirmLabel: localizations.continueAction,
    );
    var isGranted = false;
    if (isRationaleAccepted) {
      try {
        isGranted = await permissionService.requestPermission();
      } on Object catch (error, stackTrace) {
        unawaited(
          ref
              .read(appLoggerProvider)
              .logError(event: 'notification_request_failed', error: error, stackTrace: stackTrace),
        );
      }
      ref.invalidate(notificationStatusProvider);
    }
    if (isGranted || !mounted) return;
    setState(() => _reminderMinuteOfDay = null);
    if (!isRationaleAccepted) return;
    unawaited(KomitHaptics.error());
    showMessageSnackBar(
      context,
      localizations.notificationsDenied,
      action: SnackBarAction(
        label: localizations.openSettings,
        onPressed: () => _openNotificationSettings(localizations),
      ),
    );
  }

  Future<void> _openNotificationSettings(AppLocalizations localizations) async {
    try {
      await ref.read(notificationPermissionServiceProvider).openNotificationSettings();
    } on Object catch (error, stackTrace) {
      unawaited(
        ref
            .read(appLoggerProvider)
            .logError(event: 'notification_settings_failed', error: error, stackTrace: stackTrace),
      );
      if (mounted) showMessageSnackBar(context, localizations.settingsUnavailable);
    }
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

  String? _findTitleError(AppLocalizations localizations) {
    final title = _titleController.text.trim();
    if (title.isEmpty) return localizations.habitNameRequired;
    // The field counts characters as displayed; the database counts UTF-16 units (an emoji counts twice).
    if (title.length > maximumHabitTitleLength) return localizations.habitNameTooLong;
    return null;
  }

  String? _findFormError(AppLocalizations localizations) {
    if (_scheduleKind == HabitScheduleKind.someDays && _scheduledWeekdayMask == 0) {
      return localizations.pickAtLeastOneDay;
    }
    if (_objectives.isEmpty) return localizations.objectiveRequired;
    final objectiveTitles = _objectives.map((objective) => objective.titleController.text.trim()).toList();
    final hasEmptyOrDuplicateTitle =
        objectiveTitles.any((title) => title.isEmpty || title.length > maximumObjectiveTitleLength) ||
        objectiveTitles.toSet().length != objectiveTitles.length;
    return hasEmptyOrDuplicateTitle ? localizations.objectiveNamesMustBeFilledAndUnique : null;
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    final titleError = _findTitleError(localizations);
    final formError = _findFormError(localizations);
    setState(() {
      _titleErrorMessage = titleError;
      _formErrorMessage = formError;
    });
    if (titleError != null || formError != null) {
      unawaited(KomitHaptics.error());
      // Focusing the name scrolls it into view and opens the keyboard to fix it.
      if (titleError != null) _titleFocusNode.requestFocus();
      return;
    }

    setState(() => _isSaving = true);
    try {
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
              scheduledWeekdayMask: _scheduledWeekdayMaskToSave,
              targetDaysPerWeek: _scheduleKind == HabitScheduleKind.perWeek ? _targetDaysPerWeek : null,
              restDaysPerWeek: _restDaysPerWeekForSchedule,
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
      // A direct pop: the unsaved-changes guard only stands in the way of leaving without saving.
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

/// Lines a placeholder may wrap to at large font sizes, instead of being cut.
const int _identityFieldHintMaximumLines = 3;

/// A field inside a card: a pill sunk to the page color, centered like the habit's name under
/// its icon. The name is a placeholder, not a floating label: once there is text, the text speaks
/// for itself, and screen readers still hear the name through [_LabeledField].
InputDecoration _identityFieldDecoration(BuildContext context, {required String label, String? errorText}) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: label,
    hintMaxLines: _identityFieldHintMaximumLines,
    errorText: errorText,
    errorMaxLines: 2,
    counterText: '',
    fillColor: colorScheme.surface,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      borderSide: BorderSide.none,
    ),
  );
}

/// A field whose name screen readers hear even once the placeholder is replaced by text.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(label: label, child: field),
  );
}

/// The list column: gutters on phones, a centered readable column on tablets, and room at the
/// end for the frosted save bar.
class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = math.max(
          AppSpacing.screenGutter,
          (constraints.crossAxisExtent - AppSizes.formMaximumWidth) / 2,
        );
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            MediaQuery.paddingOf(context).bottom + AppSpacing.extraLarge,
          ),
          sliver: SliverList.list(children: children),
        );
      },
    );
  }
}

/// The habit's face: its icon in its color, its name and description, and the color strip.
/// Changing any of them is visible here at once, so the card is its own preview.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.iconButton,
    required this.titleField,
    required this.descriptionField,
    required this.colorStrip,
  });

  final Widget iconButton;
  final Widget titleField;
  final Widget descriptionField;
  final Widget colorStrip;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.only(top: AppSpacing.extraLarge, bottom: AppSpacing.medium),
      child: Column(
        children: [
          iconButton,
          const SizedBox(height: AppSpacing.extraLarge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
            child: Column(
              children: [
                titleField,
                const SizedBox(height: AppSpacing.small),
                descriptionField,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          colorStrip,
        ],
      ),
    );
  }
}

/// The primary action, always in reach over the scrolling form, with the reason it did not save.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.label, required this.isSaving, required this.errorMessage, required this.onPressed});

  final String label;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorMessage = this.errorMessage;
    return FrostedGlass(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.medium,
          AppSpacing.screenGutter,
          AppSpacing.large,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formMaximumWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: motionAwareDuration(context, AppDurations.standard),
                  curve: AppCurves.standard,
                  child: errorMessage == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                          child: Semantics(
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.large,
                                vertical: AppSpacing.medium,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadii.medium),
                              ),
                              child: Row(
                                children: [
                                  Icon(KomitIcons.info, size: AppSizes.iconMedium, color: colorScheme.onErrorContainer),
                                  const SizedBox(width: AppSpacing.medium),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: Theme.of(context).textTheme.bodyMedium
                                          ?.copyWith(color: colorScheme.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
                FilledButton(
                  onPressed: isSaving ? null : onPressed,
                  child: isSaving
                      ? SizedBox.square(
                          dimension: AppSizes.inlineProgressIndicator,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.inlineProgressIndicatorStroke,
                            semanticsLabel: label,
                          ),
                        )
                      : Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMinuteOfDay(BuildContext context, int minuteOfDay) => MaterialLocalizations.of(context).formatTimeOfDay(
  TimeOfDay(hour: minuteOfDay ~/ Duration.minutesPerHour, minute: minuteOfDay % Duration.minutesPerHour),
  alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
);

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
    final formattedTime = reminderMinute == null ? null : _formatMinuteOfDay(context, reminderMinute);
    return SoftCard(
      padding: EdgeInsets.zero,
      child: AnimatedSize(
        duration: motionAwareDuration(context, AppDurations.standard),
        curve: AppCurves.standard,
        alignment: AlignmentDirectional.topCenter,
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.small),
              secondary: HabitIconBadge(
                icon: formattedTime == null ? KomitIcons.bellOff : KomitIcons.bell,
                color: colorScheme.primary,
              ),
              title: Text(localizations.dailyReminder, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(
                formattedTime == null ? localizations.reminderDisabled : localizations.reminderEnabledAt(formattedTime),
                style: TextStyle(color: KomitColors.of(context).mutedText),
              ),
              value: reminderMinute != null,
              onChanged: onToggled,
            ),
            if (formattedTime != null) ...[
              const Divider(indent: AppSpacing.large, endIndent: AppSpacing.large),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
                title: Text(localizations.reminderTime),
                trailing: OutlinedButton(onPressed: onTimeTapped, child: Text(formattedTime)),
                onTap: onTimeTapped,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// All objectives in one grouped card, in logging order, with an "Add objective" row at the end.
class _ObjectivesCard extends StatelessWidget {
  const _ObjectivesCard({
    required this.objectives,
    required this.onReordered,
    required this.onColorTapped,
    required this.onRemoved,
    required this.onCountsAsSuccessChanged,
    required this.onAdded,
  });

  final List<_EditableObjective> objectives;
  final void Function(int oldIndex, int newIndex) onReordered;
  final ValueChanged<_EditableObjective> onColorTapped;
  final ValueChanged<_EditableObjective> onRemoved;
  final void Function(_EditableObjective objective, bool countsAsSuccess) onCountsAsSuccessChanged;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final accentText = KomitColors.of(context).accentText;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderStart: (_) => unawaited(KomitHaptics.lift()),
            onReorderItem: onReordered,
            proxyDecorator: _liftedObjectiveRow,
            children: [
              for (final (index, objective) in objectives.indexed)
                _ObjectiveRowEditor(
                  key: objective.key,
                  index: index,
                  objective: objective,
                  onColorTapped: () => onColorTapped(objective),
                  onRemoved: () => onRemoved(objective),
                  onCountsAsSuccessChanged: (countsAsSuccess) => onCountsAsSuccessChanged(objective, countsAsSuccess),
                ),
            ],
          ),
          InkWell(
            onTap: onAdded,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.primaryButtonHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppSizes.minimumTouchTarget - AppSpacing.small,
                      child: Icon(KomitIcons.plus, color: accentText),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        localizations.addObjective,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: accentText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The dragged objective lifts off the card: its own card color, a little larger, a deeper shadow.
  static Widget _liftedObjectiveRow(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final liftProgress = AppCurves.standard.transform(animation.value);
        final shadowColor = Theme.of(context).colorScheme.shadow.withValues(alpha: AppOpacity.liftedShadow);
        final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.tile));
        return Transform.scale(
          scale: lerpDouble(1, liftedScale, liftProgress),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              color: Theme.of(context).cardTheme.color,
              shadows: AppShadows.lifted(shadowColor.withValues(alpha: shadowColor.a * liftProgress)),
            ),
            child: child,
          ),
        );
      },
      // The dragged copy floats in an overlay, outside the card's Material.
      child: Material(type: MaterialType.transparency, child: child),
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
    final mutedText = KomitColors.of(context).mutedText;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.small,
            end: AppSpacing.extraSmall,
            top: AppSpacing.small,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: localizations.chooseColor,
                onPressed: onColorTapped,
                icon: ColorDot(color: Color(objective.colorArgb), size: AppSizes.colorDotLarge),
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
                icon: Icon(KomitIcons.x, color: mutedText),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: localizations.reorderObjective,
                  child: SizedBox.square(
                    dimension: AppSizes.minimumTouchTarget,
                    child: Icon(KomitIcons.gripVertical, color: mutedText),
                  ),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          // Lines the label up with the objective name, past the color button.
          contentPadding: const EdgeInsetsDirectional.only(
            start: AppSpacing.small + AppSizes.minimumTouchTarget,
            end: AppSpacing.large,
          ),
          title: Text(
            localizations.countsTowardStreak,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedText),
          ),
          value: objective.countsAsSuccess,
          onChanged: onCountsAsSuccessChanged,
        ),
        const Divider(indent: AppSpacing.large, endIndent: AppSpacing.large),
      ],
    );
  }
}
