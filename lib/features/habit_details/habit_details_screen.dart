import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_pause.dart';
import '../../domain/habit_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/day_grid.dart';
import '../shared/habit_icon_hero.dart';
import '../shared/shared_widgets.dart';
import 'habit_actions_sheet.dart';
import 'log_day_sheet.dart';
import 'pause_habit_sheet.dart';
import 'streak_cards.dart';
import 'yearly_grid.dart';

class HabitDetailsScreen extends ConsumerStatefulWidget {
  const HabitDetailsScreen({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

/// The hero card's height: once scrolled past it, the habit title moves into the bar.
const double _heroCardScrollExtent = AppSizes.heroBadge + 2 * AppSpacing.extraLarge;

class _HabitDetailsScreenState extends ConsumerState<HabitDetailsScreen> {
  int _selectedYear = DateTime.now().year;

  /// Read by the bar title only, so scrolling never rebuilds the screen.
  final ValueNotifier<bool> _isHeroCardScrolledAway = ValueNotifier(false);

  @override
  void dispose() {
    _isHeroCardScrolledAway.dispose();
    super.dispose();
  }

  bool _updateHeroCardVisibility(ScrollNotification notification) {
    if (notification.depth == 0) {
      _isHeroCardScrolledAway.value = notification.metrics.pixels > _heroCardScrollExtent;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final habitProvider = habitWithObjectivesProvider(widget.habitId);
    final objectiveIdByDayProvider = objectiveIdByDayForHabitProvider(widget.habitId);
    final habit = ref.watch(habitProvider);
    final today = ref.watch(currentCalendarDayProvider);
    final objectiveIdByDay = ref.watch(objectiveIdByDayProvider);
    final loadedHabit = habit.value;
    final loadedObjectiveIdByDay = objectiveIdByDay.value;
    final Widget content = switch ((habit, objectiveIdByDay)) {
      (AsyncData(value: final habit?), AsyncData(value: final objectiveIdByDay)) => _buildContent(
        context,
        habit,
        objectiveIdByDay,
        today,
      ),
      (AsyncData(value: null), _) => SliverFillRemaining(
        hasScrollBody: false,
        child: KomoEmptyState(mood: KomoMood.sleepy, title: localizations.habitNotFound),
      ),
      (AsyncData(), _) => SliverFillRemaining(
        hasScrollBody: false,
        child: AsyncValueView(
          value: objectiveIdByDay,
          retryProvider: objectiveIdByDayProvider,
          builder: (_) => const SizedBox(),
        ),
      ),
      _ => SliverFillRemaining(
        hasScrollBody: false,
        child: AsyncValueView(value: habit, retryProvider: habitProvider, builder: (_) => const SizedBox()),
      ),
    };
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _updateHeroCardVisibility,
        child: CustomScrollView(
          slivers: [
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: AppTextScaling.appBarMaximumScaleFactor,
              child: SliverAppBar(
                pinned: true,
                toolbarHeight: AppSizes.topAppBarHeight,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: const FrostedGlass(child: SizedBox.expand()),
                actionsPadding: const EdgeInsetsDirectional.only(end: AppSpacing.appBarActionsEndInset),
                title: loadedHabit == null
                    ? null
                    : ValueListenableBuilder(
                        valueListenable: _isHeroCardScrolledAway,
                        builder: (context, isHeroCardScrolledAway, title) => AnimatedOpacity(
                          opacity: isHeroCardScrolledAway ? 1 : 0,
                          duration: motionAwareDuration(context, AppDurations.standard),
                          curve: AppCurves.standard,
                          child: title,
                        ),
                        child: Text(loadedHabit.habit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                actions: [
                  if (loadedHabit != null && loadedObjectiveIdByDay != null) ...[
                    _YearChip(
                      year: _selectedYear,
                      onPressed: () => _chooseYear(
                        firstYear: _firstYearWithData(loadedHabit, loadedObjectiveIdByDay),
                        lastYear: today.year,
                      ),
                    ),
                    IconButton(
                      tooltip: localizations.statisticsTooltip,
                      icon: const Icon(KomitIcons.chartNoAxesColumn),
                      onPressed: () => context.push(AppRoutes.habitStatistics(loadedHabit.habit.id, _selectedYear)),
                    ),
                    IconButton(
                      tooltip: localizations.moreActionsTooltip,
                      icon: const Icon(KomitIcons.ellipsis),
                      onPressed: () => showHabitActionsSheet(
                        context,
                        ref,
                        loadedHabit,
                        onHabitRemoved: () {
                          if (context.mounted) context.pop();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  int _firstYearWithData(HabitWithObjectives habit, Map<CalendarDay, int> objectiveIdByDay) => [
    habit.habit.createdAt.year,
    ...objectiveIdByDay.keys.map((day) => day.year),
  ].reduce((earliest, year) => year < earliest ? year : earliest);

  Widget _buildContent(
    BuildContext context,
    HabitWithObjectives habit,
    Map<CalendarDay, int> objectiveIdByDay,
    CalendarDay today,
  ) {
    final localizations = AppLocalizations.of(context);
    final streaks = streakSummaryOf(habit, objectiveIdByDay, today: today);
    // An imported habit may hold more rest days than its schedule allows; show what applies.
    final allowedRestDaysPerWeek = math.min(
      habit.habit.restDaysPerWeek,
      maximumRestDaysFor(habit.habit.scheduledWeekdayMask),
    );
    final firstYear = _firstYearWithData(habit, objectiveIdByDay);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.small,
        AppSpacing.screenGutter,
        AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.list(
        children: [
          _HabitHeroCard(habit: habit),
          // Archived habits offer no pause, here as in the actions sheet.
          if (habit.currentOrPlannedPause(today) case final pause? when habit.habit.archivedAt == null) ...[
            const SizedBox(height: AppSpacing.medium),
            _PauseCard(key: ValueKey(pause), habit: habit, pause: pause, today: today),
          ],
          const SizedBox(height: AppSpacing.extraLarge),
          StreakCards(streaks: streaks),
          // Rest days only apply to daily and weekday habits (docs/adr/0007).
          if (allowedRestDaysPerWeek > 0 && habit.habit.targetDaysPerWeek == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.medium),
              child: Row(
                children: [
                  Icon(KomitIcons.bed, size: AppSizes.iconSmall, color: KomitColors.of(context).mutedText),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      localizations.restDaysAllowance(allowedRestDaysPerWeek),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
                    ),
                  ),
                ],
              ),
            ),
          SectionTitle(
            localizations.yearlyProgress,
            trailing: _selectedYear == today.year
                ? FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.minimumTouchTarget),
                      // Explicit, because the tonal default is the secondary (violet) container.
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: KomitColors.of(context).accentText,
                    ),
                    onPressed: () => _openLogSheet(habit, today, objectiveIdByDay[today]),
                    icon: const Icon(KomitIcons.plus),
                    label: Text(localizations.logToday),
                  )
                : null,
          ),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: YearlyGrid(
                year: _selectedYear,
                today: today,
                habit: habit,
                objectiveIdByDay: objectiveIdByDay,
                onDayTapped: (day) => _openLogSheet(habit, day, objectiveIdByDay[day]),
              ),
            ),
          ),
          // Grid cells are below the 48 dp touch target size; this is the accessible equivalent.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _pickDayToLog(habit, objectiveIdByDay, firstYear: firstYear, today: today),
              icon: const Icon(KomitIcons.calendarPlus),
              label: Text(localizations.logAnotherDay),
            ),
          ),
          SectionTitle(localizations.objectivesLegend),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final objective in habit.objectives)
                Chip(
                  avatar: ColorDot(color: Color(objective.colorArgb)),
                  label: Text(objective.title),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDayToLog(
    HabitWithObjectives habit,
    Map<CalendarDay, int> objectiveIdByDay, {
    required int firstYear,
    required CalendarDay today,
  }) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(firstYear),
      lastDate: today.asLocalDate,
      initialDate: today.asLocalDate,
    );
    if (pickedDate == null || !mounted) return;
    final pickedDay = CalendarDay.fromDateTime(pickedDate);
    await _openLogSheet(habit, pickedDay, objectiveIdByDay[pickedDay]);
  }

  Future<void> _openLogSheet(HabitWithObjectives habit, CalendarDay day, int? currentObjectiveId) =>
      logDayFromSheet(context, ref, habit: habit, day: day, currentObjectiveId: currentObjectiveId);

  Future<void> _chooseYear({required int firstYear, required int lastYear}) async {
    final chosenYear = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      builder: (context) => _YearPickerSheet(firstYear: firstYear, lastYear: lastYear, selectedYear: _selectedYear),
    );
    if (chosenYear == null || !mounted) return;
    unawaited(KomitHaptics.selection());
    setState(() => _selectedYear = chosenYear);
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year, required this.onPressed});

  final int year;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).chooseYear,
      child: ActionChip(
        onPressed: onPressed,
        avatar: Icon(KomitIcons.calendar, color: colorScheme.onSurfaceVariant),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$year', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.extraSmall),
            Icon(KomitIcons.chevronDown, size: AppSizes.iconSmall, color: KomitColors.of(context).accentText),
          ],
        ),
        backgroundColor: colorScheme.surfaceContainerLowest,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _YearPickerSheet extends StatelessWidget {
  const _YearPickerSheet({required this.firstYear, required this.lastYear, required this.selectedYear});

  final int firstYear;
  final int lastYear;
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.extraLarge),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (var year = lastYear; year >= firstYear; year--)
              ChoiceChip(
                label: Text('$year'),
                selected: year == selectedYear,
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(color: year == selectedYear ? colorScheme.onPrimary : colorScheme.onSurface),
                onSelected: (_) => Navigator.of(context).pop(year),
              ),
          ],
        ),
      ),
    );
  }
}

/// The current or planned pause, with the one action that ends it: the habit page is where
/// people come to check on a paused habit, so "Resume" is not hidden in the menu.
/// Keyed by its pause, so a new pause gets a fresh, enabled button.
class _PauseCard extends ConsumerStatefulWidget {
  const _PauseCard({required this.habit, required this.pause, required this.today, super.key});

  final HabitWithObjectives habit;
  final HabitPause pause;
  final CalendarDay today;

  @override
  ConsumerState<_PauseCard> createState() => _PauseCardState();
}

class _PauseCardState extends ConsumerState<_PauseCard> {
  /// A second tap before the card rebuilds would resume again and cancel the next planned pause.
  bool _isResuming = false;

  Future<void> _resume() async {
    // Two taps in one frame both reach the old callback, before the disabled button is built.
    if (_isResuming) return;
    setState(() => _isResuming = true);
    await resumeHabitWithMessage(context, ref, widget.habit);
  }

  @override
  Widget build(BuildContext context) {
    final pause = widget.pause;
    final today = widget.today;
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.large,
        AppSpacing.large,
        AppSpacing.small,
        AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                const PausedDaySwatch(),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(describeCurrentOrPlannedPause(context, pause, today: today), style: textTheme.titleMedium),
                      Text(
                        localizations.pauseCardHint,
                        style: textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _isResuming ? null : _resume,
              icon: const Icon(KomitIcons.play),
              label: Text(pause.startDay.isAfter(today) ? localizations.cancelPlannedPause : localizations.resumeHabit),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero gradient fades slightly toward the text color, which keeps that text readable.
const double _heroGradientForegroundBlend = 0.12;

class _HabitHeroCard extends StatelessWidget {
  const _HabitHeroCard({required this.habit});

  final HabitWithObjectives habit;

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(habit.habit.colorArgb);
    final foregroundColor = foregroundColorReadableOn(habitColor);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: LinearGradient(
          colors: [habitColor, Color.lerp(habitColor, foregroundColor, _heroGradientForegroundBlend)!],
        ),
      ),
      child: Row(
        children: [
          HabitIconHero(
            habitId: habit.habit.id,
            icon: habitIconForName(habit.habit.iconName),
            look: HabitIconLook.onHabitColor(habitColor),
          ),
          const SizedBox(width: AppSpacing.large),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(habit.habit.title, style: textTheme.headlineSmall?.copyWith(color: foregroundColor)),
                ),
                if (habit.habit.description.isNotEmpty)
                  Text(habit.habit.description, style: textTheme.bodyMedium?.copyWith(color: foregroundColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
