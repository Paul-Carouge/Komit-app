import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/greeting_period.dart';
import '../../domain/habit_schedule.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../habit_details/log_day_sheet.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/day_grid.dart';
import '../shared/entrance_animation.dart';
import '../shared/habit_icon_hero.dart';
import '../shared/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final userName = ref.watch(settingsControllerProvider.select((settings) => settings.userName));
    final habits = ref.watch(activeHabitsProvider);
    // shortcut: the period is read when the screen rebuilds (any log, the day changing), not on
    // the hour; add a timer if a greeting left on screen across 12:00 or 18:00 ever matters.
    final greetingPeriod = greetingPeriodForHour(ref.watch(clockProvider)().hour);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(
            title: _greeting(localizations, greetingPeriod, userName),
            actions: [
              IconButton(
                tooltip: localizations.achievementsTooltip,
                onPressed: () => context.push(AppRoutes.achievements),
                icon: const Icon(LucideIcons.trophy),
              ),
              IconButton(
                tooltip: localizations.settingsTooltip,
                onPressed: () => context.push(AppRoutes.settings),
                icon: const Icon(LucideIcons.settings),
              ),
            ],
          ),
          switch (habits) {
            AsyncData(value: final habits) when habits.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: KomoEmptyState(
                mood: KomoMood.waving,
                title: localizations.dashboardEmptyTitle,
                message: localizations.dashboardEmptyMessage,
                action: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.newHabit),
                  icon: const Icon(LucideIcons.plus),
                  label: Text(localizations.createFirstHabit),
                ),
              ),
            ),
            AsyncData(value: final habits) => SliverPadding(
              // The bottom inset is the frosted navigation bar the list scrolls under.
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                0,
                AppSpacing.screenGutter,
                AppSpacing.extraLarge + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(child: _TodayHeader()),
                  _ReorderableHabitList(habits: habits),
                  const SliverToBoxAdapter(child: _NewHabitRow()),
                  const SliverToBoxAdapter(child: _ArchivedHabitsRow()),
                ],
              ),
            ),
            _ => SliverFillRemaining(
              hasScrollBody: false,
              child: AsyncValueView(
                value: habits,
                retryProvider: activeHabitsProvider,
                builder: (_) => const SizedBox(),
              ),
            ),
          },
        ],
      ),
    );
  }

  String _greeting(AppLocalizations localizations, GreetingPeriod greetingPeriod, String? userName) =>
      switch ((greetingPeriod, userName)) {
        (GreetingPeriod.morning, final name?) => localizations.greetingMorning(name),
        (GreetingPeriod.afternoon, final name?) => localizations.greetingAfternoon(name),
        (GreetingPeriod.evening, final name?) => localizations.greetingEvening(name),
        (GreetingPeriod.morning, null) => localizations.greetingMorningWithoutName,
        (GreetingPeriod.afternoon, null) => localizations.greetingAfternoonWithoutName,
        (GreetingPeriod.evening, null) => localizations.greetingEveningWithoutName,
      };
}

/// Today at a glance: Komo, how many of today's habits are done, and a ring that fills up.
/// Komo hops once everything planned today is logged.
class _TodayHeader extends ConsumerWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final progress = ref.watch(todayProgressProvider);
    final today = ref.watch(currentCalendarDayProvider);
    final doneCount = progress?.doneCount ?? 0;
    final scheduledCount = progress?.scheduledCount ?? 0;
    final isEverythingDone = scheduledCount > 0 && doneCount == scheduledCount;
    final title = switch (progress) {
      null => '',
      _ when scheduledCount == 0 => localizations.nothingPlannedToday,
      _ when isEverythingDone => localizations.allDoneToday,
      _ => localizations.todayProgress(doneCount, scheduledCount),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Semantics(
        container: true,
        label: scheduledCount == 0 ? title : localizations.todayProgressSemantics(doneCount, scheduledCount),
        excludeSemantics: true,
        child: Row(
          children: [
            // Komo appears with today's mood once known, so loading never reads as a mood change.
            if (progress == null)
              const SizedBox.square(dimension: AppSizes.mascotSmall)
            else
              KomoMascot(
                mood: isEverythingDone ? KomoMood.happy : KomoMood.idle,
                size: AppSizes.mascotSmall,
                animationBudget: AppDurations.mascotHeaderAnimationBudget,
                isAnimatedOnMount: false,
              ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(
                    formatWeekdayAndDate(context, today),
                    style: textTheme.bodySmall?.copyWith(color: KomitColors.of(context).mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            _TodayProgressRing(
              completedShare: scheduledCount == 0 ? 0 : doneCount / scheduledCount,
              isComplete: isEverythingDone,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayProgressRing extends StatelessWidget {
  const _TodayProgressRing({required this.completedShare, required this.isComplete});

  final double completedShare;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppSizes.todayProgressRing,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: completedShare),
        duration: motionAwareDuration(context, AppDurations.emphasized),
        curve: AppCurves.standard,
        builder: (context, animatedShare, child) => CustomPaint(
          painter: _ProgressRingPainter(
            completedShare: animatedShare,
            trackColor: KomitColors.of(context).emptyCell,
            progressColor: colorScheme.primary,
          ),
          child: child,
        ),
        child: isComplete ? Icon(LucideIcons.check, color: KomitColors.of(context).accentText) : null,
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.completedShare, required this.trackColor, required this.progressColor});

  final double completedShare;
  final Color trackColor;
  final Color progressColor;

  /// The arc starts at 12 o'clock, like a clock hand.
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = AppSizes.todayProgressRingStrokeWidth;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    if (completedShare <= 0) return;
    paint.color = progressColor;
    canvas.drawArc(rect, _startAngle, 2 * math.pi * completedShare.clamp(0, 1), false, paint);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.completedShare != completedShare ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}

/// Long-press a row to drag it; screen readers get "Move up" and "Move down" actions instead.
class _ReorderableHabitList extends ConsumerStatefulWidget {
  const _ReorderableHabitList({required this.habits});

  final List<HabitWithObjectives> habits;

  @override
  ConsumerState<_ReorderableHabitList> createState() => _ReorderableHabitListState();
}

class _ReorderableHabitListState extends ConsumerState<_ReorderableHabitList> {
  /// The order just dropped, shown until the database stream echoes it back, so a dropped row
  /// never jumps back to its old place for a frame.
  List<HabitWithObjectives>? _droppedOrder;

  final ListEntranceChoreographer _entranceChoreographer = ListEntranceChoreographer();

  @override
  void didUpdateWidget(_ReorderableHabitList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.habits, widget.habits)) _droppedOrder = null;
  }

  /// [toIndex] is the row's index once moved.
  Future<void> _move(List<HabitWithObjectives> habits, int fromIndex, int toIndex) async {
    if (fromIndex == toIndex) return;
    final reordered = [...habits];
    reordered.insert(toIndex, reordered.removeAt(fromIndex));
    setState(() => _droppedOrder = reordered);
    try {
      await ref.read(habitRepositoryProvider).reorderHabits([for (final habit in reordered) habit.habit.id]);
    } on Object catch (error, stackTrace) {
      unawaited(KomitHaptics.error());
      unawaited(
        ref.read(appLoggerProvider).logError(event: 'habit_reorder_failed', error: error, stackTrace: stackTrace),
      );
      if (!mounted) return;
      setState(() => _droppedOrder = null);
      showMessageSnackBar(context, AppLocalizations.of(context).genericError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = _droppedOrder ?? widget.habits;
    final recentLogsByHabitId = ref.watch(recentObjectiveIdByDayByHabitIdProvider).value ?? const {};
    final lastLoggedDayByHabitId = ref.watch(lastLoggedDayByHabitIdProvider).value ?? const {};
    final today = ref.watch(currentCalendarDayProvider);
    _entranceChoreographer.updateRowIds(habits.map((habit) => habit.habit.id));
    return SliverReorderableList(
      itemCount: habits.length,
      onReorderStart: (_) => unawaited(KomitHaptics.lift()),
      onReorderItem: (fromIndex, toIndex) => _move(habits, fromIndex, toIndex),
      proxyDecorator: _liftedRow,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(habit.habit.id),
          index: index,
          child: RowEntranceAnimation(
            entrance: _entranceChoreographer.entranceFor(habit.habit.id, index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: _HabitRow(
                habit: habit,
                today: today,
                recentObjectiveIdByDay: recentLogsByHabitId[habit.habit.id] ?? const {},
                lastLoggedDay: lastLoggedDayByHabitId[habit.habit.id],
                onMoveUp: index == 0 ? null : () => _move(habits, index, index - 1),
                onMoveDown: index == habits.length - 1 ? null : () => _move(habits, index, index + 1),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The row being dragged grows a little and casts a deeper shadow, like a card picked up.
  Widget _liftedRow(Widget child, int index, Animation<double> animation) {
    final shadowColor = Theme.of(context).colorScheme.shadow.withValues(alpha: AppOpacity.liftedShadow);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final liftProgress = AppCurves.standard.transform(animation.value);
        return Transform.scale(
          scale: lerpDouble(1, liftedScale, liftProgress),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: Theme.of(context).cardTheme.shape!,
              shadows: AppShadows.lifted(shadowColor.withValues(alpha: shadowColor.a * liftProgress)),
            ),
            child: child,
          ),
        );
      },
      // The dragged copy floats in an overlay, outside the list's Material.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({
    required this.habit,
    required this.today,
    required this.recentObjectiveIdByDay,
    required this.lastLoggedDay,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final HabitWithObjectives habit;
  final CalendarDay today;
  final Map<CalendarDay, int> recentObjectiveIdByDay;
  final CalendarDay? lastLoggedDay;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = habit.habit.title;
    final streak = ref.watch(streakSummaryForHabitProvider(habit.habit.id));
    final isScheduledToday = isHabitScheduledOn(habit, today);
    final todayObjectiveId = recentObjectiveIdByDay[today];
    final todayObjective = todayObjectiveId == null ? null : habit.objectiveWithId(todayObjectiveId);
    final targetDaysPerWeek = habit.habit.targetDaysPerWeek;
    final currentStreakLength = streak?.currentStreakLength ?? 0;
    final streakText = switch (streak?.unit) {
      StreakUnit.weeks => localizations.weekCount(currentStreakLength),
      _ => localizations.dayCount(currentStreakLength),
    };
    final details = [
      if (!isScheduledToday && todayObjective == null) localizations.notToday,
      if (targetDaysPerWeek != null)
        localizations.weeklyProgress(
          countSuccessDaysInWeekOf(recentObjectiveIdByDay, successObjectiveIds: habit.successObjectiveIds, day: today),
          targetDaysPerWeek,
        ),
      _lastActivityText(context, localizations),
    ];
    final todayState = switch (todayObjective) {
      final objective? => localizations.habitRowLoggedToday(title, objective.title),
      null when !isScheduledToday => localizations.habitRowNotPlannedToday(title),
      null => localizations.habitRowNotLoggedToday(title),
    };
    return PressableCard(
      customSemanticsActions: {
        CustomSemanticsAction(label: localizations.moveUp): ?onMoveUp,
        CustomSemanticsAction(label: localizations.moveDown): ?onMoveDown,
      },
      onTap: () => context.push(AppRoutes.habitDetails(habit.habit.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.large, AppSpacing.medium, AppSpacing.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitIconHero(
                  habitId: habit.habit.id,
                  icon: habitIconForName(habit.habit.iconName),
                  look: HabitIconLook.onCard(context, Color(habit.habit.colorArgb)),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Semantics(
                    label: [
                      todayState,
                      if (currentStreakLength > 0) localizations.currentStreakSemantics(streakText),
                      ...details,
                    ].join(', '),
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: AppSpacing.extraSmall),
                        Wrap(
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.extraSmall,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (currentStreakLength > 0) _StreakChip(text: streakText),
                            Text(
                              details.join(' · '),
                              style: textTheme.bodySmall?.copyWith(color: komitColors.mutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                _TodayLogButton(
                  objectiveColor: todayObjective == null ? null : Color(todayObjective.colorArgb),
                  isScheduledToday: isScheduledToday,
                  semanticLabel: todayObjective == null
                      ? localizations.logHabitToday(title)
                      : localizations.changeTodayLog(title),
                  onTap: () => _logTodayWithOneTap(context, ref, todayObjectiveId),
                  onLongPress: () => _openLogSheet(context, ref, today, todayObjectiveId),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.extraSmall),
              child: DayGrid(
                columnCount: recentDayCountShownOnDashboard,
                minimumRowExtent: AppSizes.minimumTouchTarget,
                cellTapActionLabel: localizations.logThisDayAction,
                cells: _recentDayCells(context, localizations, komitColors, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The first objective is what the user chose to put first: the usual outcome of the day.
  void _logTodayWithOneTap(BuildContext context, WidgetRef ref, int? todayObjectiveId) {
    unawaited(KomitHaptics.selection());
    if (todayObjectiveId != null) {
      unawaited(logDayFromSheet(context, ref, habit: habit, day: today, currentObjectiveId: todayObjectiveId));
      return;
    }
    unawaited(
      writeDayLogWithUndo(
        context,
        ref,
        habit: habit,
        day: today,
        previousObjectiveId: null,
        objectiveId: habit.objectives.first.id,
      ),
    );
  }

  void _openLogSheet(BuildContext context, WidgetRef ref, CalendarDay day, int? currentObjectiveId) {
    unawaited(KomitHaptics.selection());
    unawaited(logDayFromSheet(context, ref, habit: habit, day: day, currentObjectiveId: currentObjectiveId));
  }

  String _lastActivityText(BuildContext context, AppLocalizations localizations) {
    final lastLoggedDay = this.lastLoggedDay;
    if (lastLoggedDay == null) return localizations.noActivityYet;
    final daysAgo = today.daysSinceEpoch - lastLoggedDay.daysSinceEpoch;
    return switch (daysAgo) {
      0 => localizations.lastLoggedToday,
      1 => localizations.lastLoggedYesterday,
      // Within a week, "3 days ago" reads faster than a date; a future day (imported) gets a date.
      > 1 && < DateTime.daysPerWeek => localizations.lastLoggedDaysAgo(daysAgo),
      _ => localizations.lastLoggedOn(formatShortDate(context, lastLoggedDay)),
    };
  }

  List<DayGridCell> _recentDayCells(
    BuildContext context,
    AppLocalizations localizations,
    KomitColors komitColors,
    WidgetRef ref,
  ) {
    final firstDay = firstDayShownOnDashboard(today);
    return [
      for (var offset = 0; offset < recentDayCountShownOnDashboard; offset++)
        _recentDayCell(context, localizations, komitColors, ref, firstDay.addDays(offset)),
    ];
  }

  DayGridCell _recentDayCell(
    BuildContext context,
    AppLocalizations localizations,
    KomitColors komitColors,
    WidgetRef ref,
    CalendarDay day,
  ) {
    final date = formatWeekdayAndDate(context, day);
    final objectiveId = recentObjectiveIdByDay[day];
    final objective = objectiveId == null ? null : habit.objectiveWithId(objectiveId);
    if (day.isAfter(today) && objective == null) {
      return DayGridCell(color: komitColors.futureCell, semanticLabel: localizations.stripDayNotAvailableYet(date));
    }
    final isScheduled = isWeekdayScheduled(habit.habit.scheduledWeekdayMask, day.weekday);
    return DayGridCell(
      // A day off the schedule is lighter than a missed one: nothing was expected that day.
      color: objective != null
          ? Color(objective.colorArgb)
          : (isScheduled ? komitColors.emptyCell : komitColors.futureCell),
      semanticLabel: objective == null
          ? localizations.stripDayNotLogged(date)
          : localizations.stripDayLogged(date, objective.title),
      isOutlined: day == today,
      onTap: () => _openLogSheet(context, ref, day, objectiveId),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(shape: const StadiumBorder(), color: komitColors.highlightContainer),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.extraSmall / 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.flame, size: AppSizes.iconSmall, color: komitColors.onHighlightContainer),
            const SizedBox(width: AppSpacing.extraSmall),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: komitColors.onHighlightContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logs today in one tap; filled with today's objective color once logged.
///
/// Logging springs the button back from a smaller size while the check mark draws itself.
class _TodayLogButton extends StatefulWidget {
  const _TodayLogButton({
    required this.objectiveColor,
    required this.isScheduledToday,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final Color? objectiveColor;
  final bool isScheduledToday;
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_TodayLogButton> createState() => _TodayLogButtonState();
}

class _TodayLogButtonState extends State<_TodayLogButton> with SingleTickerProviderStateMixin {
  /// At rest at 1: a button already logged when the screen opens shows its check without moving.
  late final AnimationController _logAnimation = AnimationController(
    vsync: this,
    duration: AppDurations.emphasized,
    value: 1,
  );

  @override
  void didUpdateWidget(_TodayLogButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasJustBeenLogged = oldWidget.objectiveColor == null && widget.objectiveColor != null;
    if (hasJustBeenLogged && !MediaQuery.disableAnimationsOf(context)) unawaited(_logAnimation.forward(from: 0));
  }

  @override
  void dispose() {
    _logAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final objectiveColor = widget.objectiveColor;
    final circle = objectiveColor == null
        ? CircleBorder(
            // Off schedule, an outline instead of a fill: available, but not expected today.
            side: widget.isScheduledToday
                ? BorderSide.none
                : BorderSide(color: colorScheme.outlineVariant, width: AppSizes.emphasisBorderWidth),
          )
        : const CircleBorder();
    return Semantics(
      container: true,
      button: true,
      label: widget.semanticLabel,
      onLongPressHint: localizations.chooseAnObjectiveHint,
      child: Tooltip(
        message: localizations.logToday,
        excludeFromSemantics: true,
        child: AnimatedBuilder(
          animation: _logAnimation,
          builder: (context, child) => Transform.scale(
            scale: objectiveColor == null
                ? 1
                : lerpDouble(loggedButtonInitialScale, 1, AppCurves.spring.transform(_logAnimation.value)),
            child: child,
          ),
          child: Material(
            color: objectiveColor ?? (widget.isScheduledToday ? colorScheme.surfaceContainerHigh : Colors.transparent),
            shape: circle,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: SizedBox.square(
                dimension: AppSizes.logButton,
                child: objectiveColor == null
                    ? Icon(LucideIcons.plus, color: colorScheme.onSurfaceVariant)
                    : CustomPaint(
                        painter: _CheckMarkPainter(
                          progress: _logAnimation,
                          color: foregroundColorReadableOn(objectiveColor),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A check mark drawn stroke by stroke as [progress] goes from 0 to 1.
class _CheckMarkPainter extends CustomPainter {
  _CheckMarkPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  /// The check's three points, as shares of the icon box: short stroke down, long stroke up.
  static const Offset _start = Offset(0.2, 0.52);
  static const Offset _corner = Offset(0.42, 0.72);
  static const Offset _end = Offset(0.8, 0.3);

  @override
  void paint(Canvas canvas, Size size) {
    const iconSize = AppSizes.iconMedium;
    final origin = size.center(Offset.zero) - const Offset(iconSize / 2, iconSize / 2);
    Offset point(Offset share) => origin + Offset(share.dx * iconSize, share.dy * iconSize);
    final path = Path()
      ..moveTo(point(_start).dx, point(_start).dy)
      ..lineTo(point(_corner).dx, point(_corner).dy)
      ..lineTo(point(_end).dx, point(_end).dy);
    final drawnShare = AppCurves.standard.transform(progress.value);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.checkMarkStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * drawnShare), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) => oldDelegate.color != color;
}

class _NewHabitRow extends StatelessWidget {
  const _NewHabitRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentText = KomitColors.of(context).accentText;
    return PressableCard(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
        side: BorderSide(color: colorScheme.outlineVariant, width: AppSizes.emphasisBorderWidth),
      ),
      onTap: () => context.push(AppRoutes.newHabit),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, color: accentText),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                AppLocalizations.of(context).newHabit,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accentText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet link to the archived habits, shown only when there are some.
class _ArchivedHabitsRow extends ConsumerWidget {
  const _ArchivedHabitsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedCount = ref.watch(archivedHabitsProvider.select((habits) => habits.value?.length ?? 0));
    if (archivedCount == 0) return const SizedBox.shrink();
    final mutedText = KomitColors.of(context).mutedText;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: mutedText),
        onPressed: () => context.push(AppRoutes.archivedHabits),
        icon: const Icon(LucideIcons.archive),
        label: Text(AppLocalizations.of(context).archivedHabitsRow(archivedCount)),
      ),
    );
  }
}
