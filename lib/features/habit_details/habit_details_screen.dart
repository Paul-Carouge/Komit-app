import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
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
    final objectiveIdByDay = ref.watch(objectiveIdByDayForHabitProvider(widget.habitId));
    return Scaffold(
      body: SafeArea(
        child: AsyncValueView(
          value: habit,
          builder: (habit) {
            if (habit == null) return Center(child: Text(localizations.habitNotFound));
            return AsyncValueView(
              value: objectiveIdByDay,
              builder: (objectiveIdByDay) => _buildContent(context, habit, objectiveIdByDay),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HabitWithObjectives habit, Map<CalendarDay, int> objectiveIdByDay) {
    final localizations = AppLocalizations.of(context);
    final today = CalendarDay.today();
    final streaks = computeStreakSummary(objectiveIdByDay.keys, today: today);
    final firstYear = [
      habit.habit.createdAt.year,
      ...objectiveIdByDay.keys.map((day) => day.year),
    ].reduce((earliest, year) => year < earliest ? year : earliest);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.small),
            child: Row(
              children: [
                BackButton(onPressed: () => context.pop()),
                const Spacer(),
                _YearChip(
                  year: _selectedYear,
                  onPressed: () => _chooseYear(firstYear: firstYear, lastYear: today.year),
                ),
                const Spacer(),
                IconButton(
                  tooltip: localizations.statisticsTooltip,
                  icon: const Icon(LucideIcons.chartNoAxesColumn),
                  onPressed: () => context.push(AppRoutes.habitStatistics(habit.habit.id, _selectedYear)),
                ),
                IconButton(
                  tooltip: localizations.moreActionsTooltip,
                  icon: const Icon(LucideIcons.ellipsis),
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
                    ? FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppSizes.minimumTouchTarget),
                          foregroundColor: KomitColors.of(context).accentText,
                        ),
                        onPressed: () => _openLogSheet(habit, today, objectiveIdByDay[today]),
                        icon: const Icon(LucideIcons.plus),
                        label: Text(localizations.logToday),
                      )
                    : null,
              ),
              Card(
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
        ),
      ],
    );
  }

  Future<void> _openLogSheet(HabitWithObjectives habit, CalendarDay day, int? currentObjectiveId) async {
    final choice = await showLogDaySheet(context, habit: habit, day: day, currentObjectiveId: currentObjectiveId);
    if (choice == null || !mounted) return;
    final repository = ref.read(habitRepositoryProvider);
    try {
      switch (choice) {
        case LogDayChoiceObjective(:final objectiveId):
          await repository.logObjectiveForDay(habitId: habit.habit.id, objectiveId: objectiveId, day: day);
        case LogDayChoiceClear():
          await repository.clearLogForDay(habitId: habit.habit.id, day: day);
      }
      unawaited(HapticFeedback.selectionClick());
    } on Object {
      if (mounted) showMessageSnackBar(context, AppLocalizations.of(context).genericError);
    }
  }

  Future<void> _chooseYear({required int firstYear, required int lastYear}) async {
    final chosenYear = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => _YearPickerSheet(firstYear: firstYear, lastYear: lastYear, selectedYear: _selectedYear),
    );
    if (chosenYear != null && mounted) setState(() => _selectedYear = chosenYear);
  }

  Future<void> _showMoreActions(HabitWithObjectives habit) async {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleteRequested = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text(localizations.editHabit),
              onTap: () {
                Navigator.of(context).pop(false);
                unawaited(GoRouter.of(context).push(AppRoutes.habitEditor(habit.habit.id)));
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: colorScheme.error),
              title: Text(localizations.deleteHabit, style: TextStyle(color: colorScheme.error)),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
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
    await ref.read(habitRepositoryProvider).deleteHabit(habit.habit.id);
    if (mounted) context.pop();
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
        avatar: Icon(LucideIcons.calendar, color: colorScheme.onSurfaceVariant),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$year', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.extraSmall),
            Icon(LucideIcons.chevronDown, size: AppSpacing.large, color: KomitColors.of(context).accentText),
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

class _HabitHeroCard extends StatelessWidget {
  const _HabitHeroCard({required this.habit});

  final HabitWithObjectives habit;

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(habit.habit.colorArgb);
    // Picks black or white text depending on the habit color, so any color stays readable.
    final foregroundColor = ThemeData.estimateBrightnessForColor(habitColor) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.large),
        gradient: LinearGradient(colors: [habitColor, Color.lerp(habitColor, Colors.white, 0.12)!]),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.minimumTouchTarget * 1.2,
            height: AppSizes.minimumTouchTarget * 1.2,
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Icon(habitIconForName(habit.habit.iconName), color: foregroundColor, size: AppSpacing.huge),
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

String formatFullDate(BuildContext context, CalendarDay day) =>
    DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(day.asLocalDate);
