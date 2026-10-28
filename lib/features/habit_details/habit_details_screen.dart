import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/haptics.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/game_badges.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_card.dart';
import '../../core/ui/game_text.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';
import 'log_day_sheet.dart';
import 'streak_cards.dart';
import 'yearly_grid.dart';

class HabitDetailsScreen extends ConsumerStatefulWidget {
  const HabitDetailsScreen({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends ConsumerState<HabitDetailsScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final habit = ref.watch(habitProvider(widget.habitId));
    final today = ref.watch(currentCalendarDayProvider);
    final objectiveIdByDay = ref.watch(objectiveIdByDayForHabitProvider(widget.habitId));
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView(
          value: habit,
          builder: (habit) {
            if (habit == null) return KomoEmptyState(mood: KomoMood.sleepy, title: localizations.habitNotFound);
            return AsyncValueView(
              value: objectiveIdByDay,
              builder: (objectiveIdByDay) => _buildContent(context, habit, objectiveIdByDay, today),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HabitWithObjectives habit,
    Map<CalendarDay, int> objectiveIdByDay,
    CalendarDay today,
  ) {
    final localizations = AppLocalizations.of(context);
    final streaks = computeStreakSummary(objectiveIdByDay.keys, today: today);
    final firstYear = [
      habit.habit.createdAt.year,
      ...objectiveIdByDay.keys.map((day) => day.year),
    ].reduce((earliest, year) => year < earliest ? year : earliest);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
            child: Row(
              children: [
                GameBackButton(onPressed: () => context.pop()),
                const Spacer(),
                _YearChip(
                  year: _selectedYear,
                  onPressed: () => _chooseYear(firstYear: firstYear, lastYear: today.year),
                ),
                const Spacer(),
                GameIconButton(
                  tooltip: localizations.statisticsTooltip,
                  icon: LucideIcons.chartNoAxesColumn,
                  onPressed: () => context.push(AppRoutes.habitStatistics(habit.habit.id, _selectedYear)),
                ),
                const SizedBox(width: AppSpacing.small),
                GameIconButton(
                  tooltip: localizations.moreActionsTooltip,
                  icon: LucideIcons.ellipsis,
                  onPressed: () => _showMoreActions(habit),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.small,
            AppSpacing.screenGutter,
            AppSpacing.huge,
          ),
          sliver: SliverList.list(
            children: [
              _HabitHeroCard(habit: habit),
              const SizedBox(height: AppSpacing.extraLarge),
              StreakCards(streaks: streaks),
              SectionTitle(
                localizations.yearlyProgress,
                trailing: _selectedYear == today.year
                    ? GameButton(
                        isCompact: true,
                        onPressed: () => _openLogSheet(habit, today, objectiveIdByDay[today]),
                        icon: LucideIcons.plus,
                        label: localizations.logToday,
                      )
                    : null,
              ),
              GameCard(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: YearlyGrid(
                  year: _selectedYear,
                  today: today,
                  habit: habit,
                  objectiveIdByDay: objectiveIdByDay,
                  onDayTapped: (day) => _openLogSheet(habit, day, objectiveIdByDay[day]),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Grid cells are below the 48 dp touch target size; this is the accessible equivalent.
              Align(
                alignment: Alignment.centerRight,
                child: GameButton(
                  isCompact: true,
                  tone: GameButtonTone.neutral,
                  onPressed: () => _pickDayToLog(habit, objectiveIdByDay, firstYear: firstYear, today: today),
                  icon: LucideIcons.calendarPlus,
                  label: localizations.logAnotherDay,
                ),
              ),
              SectionTitle(localizations.objectivesLegend),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final objective in habit.objectives)
                    GameTag(
                      leading: ColorDot(color: Color(objective.colorArgb)),
                      label: objective.title,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
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

  Future<void> _openLogSheet(HabitWithObjectives habit, CalendarDay day, int? currentObjectiveId) async {
    final choice = await showLogDaySheet(
      context,
      habit: habit,
      day: day,
      currentObjectiveId: currentObjectiveId,
      canLogObjective: !day.isAfter(ref.read(currentCalendarDayProvider)),
    );
    if (choice == null || !mounted) return;
    final repository = ref.read(habitRepositoryProvider);
    final today = ref.read(currentCalendarDayProvider);
    // Read before writing: the log about to be added is the one that may complete the day.
    final completesTheDay =
        day == today &&
        currentObjectiveId == null &&
        isEveryHabitLoggedOn(
          today,
          habitIds: [
            for (final other in ref.read(allHabitsProvider).value ?? const <HabitWithObjectives>[])
              if (other.habit.id != habit.habit.id) other.habit.id,
          ],
          objectiveIdByDayByHabitId: ref.read(recentLogsForAllHabitsProvider).value ?? const {},
        );
    try {
      switch (choice) {
        case LogDayChoiceObjective(:final objectiveId):
          await repository.logObjectiveForDay(habitId: habit.habit.id, objectiveId: objectiveId, day: day);
          unawaited(completesTheDay ? KomitHaptics.celebration() : KomitHaptics.success());
        case LogDayChoiceClear():
          await repository.clearLogForDay(habitId: habit.habit.id, day: day);
          unawaited(KomitHaptics.warning());
      }
    } on Object {
      unawaited(KomitHaptics.error());
      if (mounted) showMessageSnackBar(context, AppLocalizations.of(context).genericError);
    }
  }

  Future<void> _chooseYear({required int firstYear, required int lastYear}) async {
    final chosenYear = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => _YearPickerSheet(firstYear: firstYear, lastYear: lastYear, selectedYear: _selectedYear),
    );
    if (chosenYear == null || !mounted) return;
    unawaited(KomitHaptics.selection());
    setState(() => _selectedYear = chosenYear);
  }

  Future<void> _showMoreActions(HabitWithObjectives habit) async {
    final localizations = AppLocalizations.of(context);
    final isDeleteRequested = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            0,
            AppSpacing.screenGutter,
            AppSpacing.extraLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameButton(
                tone: GameButtonTone.neutral,
                icon: LucideIcons.pencil,
                label: localizations.editHabit,
                onPressed: () {
                  Navigator.of(context).pop(false);
                  unawaited(GoRouter.of(context).push(AppRoutes.habitEditor(habit.habit.id)));
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              GameButton(
                tone: GameButtonTone.danger,
                icon: LucideIcons.trash2,
                label: localizations.deleteHabit,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (isDeleteRequested != true || !mounted) return;
    final isConfirmed = await showDestructiveConfirmationDialog(
      context,
      message: localizations.deleteHabitConfirmation(habit.habit.title),
      confirmLabel: localizations.delete,
    );
    if (!isConfirmed || !mounted) return;
    try {
      await ref.read(habitRepositoryProvider).deleteHabit(habit.habit.id);
      unawaited(KomitHaptics.warning());
      if (mounted) context.pop();
    } on Object {
      unawaited(KomitHaptics.error());
      if (mounted) showMessageSnackBar(context, localizations.genericError);
    }
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({required this.year, required this.onPressed});

  final int year;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      isCompact: true,
      tone: GameButtonTone.neutral,
      icon: LucideIcons.calendar,
      trailing: const Icon(LucideIcons.chevronDown, size: AppSizes.iconSmall),
      label: '$year',
      semanticLabel: '${AppLocalizations.of(context).chooseYear}, $year',
      onPressed: onPressed,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.extraLarge),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (var year = lastYear; year >= firstYear; year--)
              GameButton(
                isCompact: true,
                tone: year == selectedYear ? GameButtonTone.primary : GameButtonTone.neutral,
                isSelected: year == selectedYear,
                label: '$year',
                onPressed: () => Navigator.of(context).pop(year),
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitHeroCard extends StatelessWidget {
  const _HabitHeroCard({required this.habit});

  final HabitWithObjectives habit;

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(habit.habit.colorArgb);
    final foregroundColor = foregroundColorReadableOn(habitColor);
    final textTheme = Theme.of(context).textTheme;
    final isLargeText = isLargeTextScale(context);
    final titleAndDescription = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameTitle(habit.habit.title, style: textTheme.headlineMedium, onColor: habitColor),
        if (habit.habit.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.extraSmall),
          Text(habit.habit.description, style: textTheme.bodyLarge?.copyWith(color: foregroundColor)),
        ],
      ],
    );
    return GameCard(
      color: habitColor,
      isHero: true,
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      child: Flex(
        // Large text needs the full card width for the title.
        direction: isLargeText ? Axis.vertical : Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isLargeText ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        spacing: AppSpacing.large,
        children: [
          GameBadge(
            icon: habitIconForName(habit.habit.iconName),
            color: depthShadeOf(habitColor),
            size: AppSizes.heroBadge,
          ),
          if (isLargeText) titleAndDescription else Expanded(child: titleAndDescription),
        ],
      ),
    );
  }
}
