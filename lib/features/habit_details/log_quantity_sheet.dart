import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/quantity_formatting.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/database/app_database.dart' show maximumQuantityValue;
import '../../data/repositories/habit_repository.dart';
import '../../domain/quantity_goal.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../celebrations/log_celebrations.dart';
import '../shared/day_grid.dart';
import '../shared/shared_widgets.dart';

/// The quick button adding several steps at once, next to "Target".
const int _quickStepMultiplier = 5;

/// What the quantity sheet returns: the amount to save, or null to clear the day.
typedef LogQuantityChoice = ({double? quantity});

/// Opens the quantity sheet for [day], then saves or clears the amount, with an "Undo" message.
Future<void> logQuantityFromSheet(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required double? currentQuantity,
}) async {
  final today = ref.read(currentCalendarDayProvider);
  final choice = await showLogQuantitySheet(
    context,
    habit: habit,
    day: day,
    today: today,
    currentQuantity: currentQuantity,
    canLogQuantity: !day.isAfter(today),
  );
  if (choice == null || !context.mounted || choice.quantity == currentQuantity) return;
  await writeQuantityLogWithUndo(
    context,
    ref,
    habit: habit,
    day: day,
    change: (repository) async {
      await _writeQuantity(repository, habitId: habit.habit.id, day: day, quantity: choice.quantity);
      return (previousQuantity: currentQuantity, quantity: choice.quantity);
    },
  );
}

/// The amount a day held before a write, and the amount it holds after; null is no log.
typedef QuantityChange = ({double? previousQuantity, double? quantity});

/// Adds one step to [day] in the repository, which reads the amount in the same transaction, so
/// two fast taps both count.
Future<void> addQuantityStepWithUndo(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
}) => writeQuantityLogWithUndo(
  context,
  ref,
  habit: habit,
  day: day,
  change: (repository) async {
    final previousQuantity = await repository.addQuantityStepForDay(habitId: habit.habit.id, day: day);
    return (
      previousQuantity: previousQuantity,
      quantity: math.min(roundQuantity((previousQuantity ?? 0) + habit.quantityGoal!.step), maximumQuantityValue),
    );
  },
);

Future<void> _writeQuantity(
  HabitRepository repository, {
  required int habitId,
  required CalendarDay day,
  required double? quantity,
}) => quantity == null
    ? repository.clearLogForDay(habitId: habitId, day: day)
    : repository.logQuantityForDay(habitId: habitId, quantity: quantity, day: day);

/// Runs [change], then offers to restore the amount it replaced from a message, as
/// [writeDayLogWithUndo] does for objectives.
Future<void> writeQuantityLogWithUndo(
  BuildContext context,
  WidgetRef ref, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required Future<QuantityChange> Function(HabitRepository repository) change,
}) async {
  final goal = habit.quantityGoal!;
  // Captured before any await: the row or sheet that asked may be gone when the write ends.
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  final repository = ref.read(habitRepositoryProvider);
  final logger = ref.read(appLoggerProvider);
  final celebrator = LogCelebrator.of(context, ref);
  final localeTag = Localizations.localeOf(context).toLanguageTag();
  final habitId = habit.habit.id;

  Future<QuantityChange?> write(Future<QuantityChange> Function(HabitRepository repository) changeToWrite) async {
    try {
      return await changeToWrite(repository);
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(logger.logError(event: 'quantity_log_write_failed', error: error, stackTrace: stackTrace));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: SnackBarMessage(localizations.genericError, kind: SnackBarMessageKind.error)));
      return null;
    }
  }

  final written = await write(change);
  if (written == null) return;
  final (:previousQuantity, :quantity) = written;
  final progressText = localizations.quantityProgress(
    formatQuantityIn(localeTag, quantity ?? 0),
    formatQuantityIn(localeTag, goal.target),
    goal.unit,
  );
  final isReached = goal.isReachedBy(quantity);
  if (quantity == null) {
    unawaited(KomitHaptics.warning());
  } else {
    unawaited(KomitHaptics.success());
  }
  // Only the step that reaches the target makes the day a success worth celebrating.
  if (isReached && !goal.isReachedBy(previousQuantity)) {
    unawaited(
      celebrator.celebrateLog(
        habit: habit,
        day: day,
        previousObjectiveId: null,
        objectiveId: habit.objectives.first.id,
      ),
    );
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: SnackBarMessage(
          switch (quantity) {
            null => localizations.dayClearedMessage(habit.habit.title),
            _ when isReached => localizations.quantityTargetReachedMessage(habit.habit.title, progressText),
            _ => localizations.quantityDayMessage(habit.habit.title, progressText),
          },
          kind: quantity == null ? SnackBarMessageKind.information : SnackBarMessageKind.success,
          icon: quantity == null ? KomitIcons.eraser : null,
          color: quantity == null ? null : Color(habit.habit.colorArgb),
        ),
        // With an action a SnackBar stays until dismissed by default; an undo window should close.
        persist: false,
        duration: AppDurations.undoSnackBar,
        action: SnackBarAction(
          label: localizations.undo,
          onPressed: () {
            unawaited(KomitHaptics.selection());
            unawaited(
              write((repository) async {
                await _writeQuantity(repository, habitId: habitId, day: day, quantity: previousQuantity);
                return (previousQuantity: quantity, quantity: previousQuantity);
              }),
            );
          },
        ),
      ),
    );
}

/// Returns null when dismissed.
Future<LogQuantityChoice?> showLogQuantitySheet(
  BuildContext context, {
  required HabitWithObjectives habit,
  required CalendarDay day,
  required CalendarDay today,
  required double? currentQuantity,

  /// False for a future day: only an existing log can be cleared.
  required bool canLogQuantity,
}) {
  return showModalBottomSheet<LogQuantityChoice>(
    context: context,
    // Root navigator, like every Komit sheet: it covers the frosted navigation bar instead of sliding under it.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _LogQuantitySheet(
      habit: habit,
      day: day,
      today: today,
      currentQuantity: currentQuantity,
      canLogQuantity: canLogQuantity,
    ),
  );
}

class _LogQuantitySheet extends StatefulWidget {
  const _LogQuantitySheet({
    required this.habit,
    required this.day,
    required this.today,
    required this.currentQuantity,
    required this.canLogQuantity,
  });

  final HabitWithObjectives habit;
  final CalendarDay day;
  final CalendarDay today;
  final double? currentQuantity;
  final bool canLogQuantity;

  @override
  State<_LogQuantitySheet> createState() => _LogQuantitySheetState();
}

class _LogQuantitySheetState extends State<_LogQuantitySheet> {
  late final TextEditingController _amountController = TextEditingController();
  bool _isAmountInvalid = false;

  QuantityGoal get _goal => widget.habit.quantityGoal!;

  /// The typed amount, 0 while the field is empty or not a number.
  double get _typedQuantity => parseQuantity(_amountController.text) ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Formatting needs the locale, which is not available in initState.
    if (_amountController.text.isEmpty) {
      _amountController.text = formatQuantityForEditing(context, widget.currentQuantity ?? 0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setQuantity(double quantity) {
    unawaited(KomitHaptics.selection());
    setState(() {
      _isAmountInvalid = false;
      _amountController.text = formatQuantityForEditing(
        context,
        roundQuantity(quantity.clamp(0, maximumQuantityValue)),
      );
    });
  }

  void _save() {
    final typedQuantity = parseQuantity(_amountController.text);
    // Rounded first, as stored: an amount that rounds to zero is no amount at all.
    final quantity = typedQuantity == null ? null : roundQuantity(typedQuantity);
    if (typedQuantity == null || typedQuantity < 0 || quantity == null || quantity > maximumQuantityValue) {
      unawaited(KomitHaptics.error());
      setState(() => _isAmountInvalid = true);
      return;
    }
    // Zero clears the day rather than storing an empty log.
    Navigator.of(context).pop((quantity: quantity == 0 ? null : quantity));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    final habitColor = Color(widget.habit.habit.colorArgb);
    final goal = _goal;
    final typedQuantity = _typedQuantity;
    // The page color, sunk into the sheet in both themes (the dark sheet is surfaceContainerHigh).
    final wellColor = colorScheme.surface;
    final stepButtonStyle = IconButton.styleFrom(
      minimumSize: const Size.square(AppSizes.primaryButtonHeight),
      backgroundColor: wellColor,
      foregroundColor: colorScheme.onSurface,
    );
    return Padding(
      // The amount field opens the keyboard: the sheet rises above it.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HabitIconBadge(icon: habitIconForName(widget.habit.habit.iconName), color: habitColor),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(widget.habit.habit.title, style: textTheme.titleLarge)),
                        Text(
                          formatRelativeDay(context, widget.day, today: widget.today),
                          style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.habit.pauseOn(widget.day) != null) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    const PausedDaySwatch(),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        localizations.logDayPausedNote,
                        style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.extraLarge),
              if (widget.canLogQuantity) ...[
                Row(
                  children: [
                    IconButton(
                      style: stepButtonStyle,
                      tooltip: localizations.decreaseQuantity,
                      onPressed: typedQuantity > 0 ? () => _setQuantity(typedQuantity - goal.step) : null,
                      icon: const Icon(KomitIcons.minus),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      // The visible unit and progress line say what the number is; screen readers
                      // also hear the field's name.
                      child: Semantics(
                        label: localizations.quantityFieldLabel,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          onChanged: (_) => setState(() => _isAmountInvalid = false),
                          onSubmitted: (_) => _save(),
                          decoration: InputDecoration(
                            suffixText: goal.unit,
                            suffixStyle: textTheme.titleMedium?.copyWith(color: komitColors.mutedText),
                            errorText: _isAmountInvalid ? localizations.quantityMustBePositive : null,
                            errorMaxLines: 2,
                            fillColor: wellColor,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.medium),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    IconButton(
                      style: stepButtonStyle,
                      tooltip: localizations.increaseQuantity,
                      onPressed: () => _setQuantity(typedQuantity + goal.step),
                      icon: const Icon(KomitIcons.plus),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                _QuantityProgressBar(goal: goal, quantity: typedQuantity, habitColor: habitColor),
                const SizedBox(height: AppSpacing.medium),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    ActionChip(
                      label: Text('+${formatQuantity(context, goal.step * _quickStepMultiplier)}'),
                      onPressed: () => _setQuantity(typedQuantity + goal.step * _quickStepMultiplier),
                    ),
                    ActionChip(
                      avatar: const Icon(KomitIcons.target),
                      label: Text(localizations.setQuantityToTarget(formatQuantity(context, goal.target))),
                      onPressed: () => _setQuantity(goal.target),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.large),
                FilledButton(onPressed: _save, child: Text(localizations.saveQuantity)),
              ] else if (widget.currentQuantity != null)
                Text(
                  localizations.futureLogExplanation,
                  style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
                ),
              if (widget.currentQuantity != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.small),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
                    ),
                    onPressed: () => Navigator.of(context).pop((quantity: null)),
                    icon: const Icon(KomitIcons.eraser),
                    label: Text(localizations.clearLog),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "5/8 glasses" over a bar filling in the habit's color, with a check once the target is reached.
class _QuantityProgressBar extends StatelessWidget {
  const _QuantityProgressBar({required this.goal, required this.quantity, required this.habitColor});

  final QuantityGoal goal;
  final double quantity;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isReached = goal.isReachedBy(quantity);
    return Semantics(
      liveRegion: true,
      label: describeQuantityProgressForScreenReaders(context, goal, quantity),
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isReached) ...[
                Icon(KomitIcons.circleCheck, size: AppSizes.iconSmall, color: komitColors.accentText),
                const SizedBox(width: AppSpacing.extraSmall),
              ],
              Text(
                describeQuantityProgress(context, goal, quantity),
                style: textTheme.bodyMedium?.copyWith(
                  color: isReached ? komitColors.accentText : komitColors.mutedText,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.recapProgressBarHeight),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: goal.shareReachedBy(quantity)),
              duration: motionAwareDuration(context, AppDurations.standard),
              curve: AppCurves.standard,
              builder: (context, share, _) => LinearProgressIndicator(
                value: share,
                minHeight: AppSizes.recapProgressBarHeight,
                color: habitColor,
                // Visible on the sheet in both themes, where emptyCell is the dark sheet's own color.
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
