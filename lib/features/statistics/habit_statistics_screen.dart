import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/game_badges.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_card.dart';
import '../../core/ui/game_text.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../habit_details/streak_cards.dart';
import '../shared/shared_widgets.dart';

const double _chartHeight = 220;
const double _donutRadius = 56;
const double _donutHoleRadius = 44;
const double _monthBarWidth = 14;
const double _donutSectionGap = 2;

class HabitStatisticsScreen extends ConsumerWidget {
  const HabitStatisticsScreen({required this.habitId, required this.year, super.key});

  final int habitId;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final habit = ref.watch(habitProvider(habitId));
    final objectiveIdByDay = ref.watch(objectiveIdByDayForHabitProvider(habitId));
    return Scaffold(
      appBar: AppBar(leading: const GameBackButton(), title: Text(localizations.statisticsTitle(year))),
      body: AsyncValueView(
        value: habit,
        builder: (habit) => habit == null
            ? KomoEmptyState(mood: KomoMood.sleepy, title: localizations.habitNotFound)
            : AsyncValueView(
                value: objectiveIdByDay,
                builder: (objectiveIdByDay) => _StatisticsContent(
                  habit: habit,
                  objectiveIdByDay: objectiveIdByDay,
                  year: year,
                  today: ref.watch(currentCalendarDayProvider),
                ),
              ),
      ),
    );
  }
}

class _StatisticsContent extends StatelessWidget {
  const _StatisticsContent({
    required this.habit,
    required this.objectiveIdByDay,
    required this.year,
    required this.today,
  });

  final HabitWithObjectives habit;
  final Map<CalendarDay, int> objectiveIdByDay;
  final int year;
  final CalendarDay today;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statistics = computeYearStatistics(objectiveIdByDay, year: year);
    final streaks = computeStreakSummary(objectiveIdByDay.keys, today: today);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.small,
        AppSpacing.screenGutter,
        AppSpacing.huge,
      ),
      children: [
        MergeSemantics(
          child: GameCard(
            color: komitColors.notesFace,
            isHero: true,
            padding: const EdgeInsets.all(AppSpacing.extraLarge),
            child: Row(
              children: [
                GameBadge(icon: LucideIcons.trophy, color: colorScheme.primary, size: AppSizes.heroBadge),
                const SizedBox(width: AppSpacing.large),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.daysLogged,
                        style: textTheme.titleMedium?.copyWith(color: komitColors.onNotesFace),
                      ),
                      GameTitle(
                        '${statistics.totalLogCount}',
                        isHeader: false,
                        onColor: komitColors.notesFace,
                        style: textTheme.displayMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        StreakCards(streaks: streaks),
        if (statistics.totalLogCount == 0)
          KomoEmptyState(mood: KomoMood.sleepy, title: localizations.noLogsThisYear, mascotSize: AppSizes.mascotSmall)
        else ...[
          SectionTitle(localizations.objectiveDistribution),
          _ObjectiveDistributionChart(habit: habit, statistics: statistics),
          SectionTitle(localizations.monthlyActivity),
          _MonthlyActivityChart(statistics: statistics, year: year),
        ],
      ],
    );
  }
}

class _ObjectiveDistributionChart extends StatelessWidget {
  const _ObjectiveDistributionChart({required this.habit, required this.statistics});

  final HabitWithObjectives habit;
  final YearStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final loggedObjectives = [
      for (final objective in habit.objectives)
        if ((statistics.logCountByObjectiveId[objective.id] ?? 0) > 0) objective,
    ];
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: _chartHeight,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: _donutHoleRadius,
                sectionsSpace: _donutSectionGap,
                sections: [
                  for (final objective in loggedObjectives)
                    PieChartSectionData(
                      value: statistics.logCountByObjectiveId[objective.id]!.toDouble(),
                      color: Color(objective.colorArgb),
                      radius: _donutRadius,
                      showTitle: false,
                      borderSide: BorderSide(color: KomitColors.of(context).outline, width: AppOutline.regular),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        for (final objective in loggedObjectives)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ColorDot(color: Color(objective.colorArgb)),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: Text(objective.title, style: textTheme.titleMedium)),
                      Text(
                        '${statistics.logCountByObjectiveId[objective.id]} · '
                        '${(statistics.logCountByObjectiveId[objective.id]! * 100 / statistics.totalLogCount).round()} %',
                        style: textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  // The share is already written above; the bar only draws it.
                  GameProgressBar(
                    value: statistics.logCountByObjectiveId[objective.id]! / statistics.totalLogCount,
                    color: Color(objective.colorArgb),
                    height: AppSizes.compactProgressBarHeight,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthlyActivityChart extends StatelessWidget {
  const _MonthlyActivityChart({required this.statistics, required this.year});

  final YearStatistics statistics;
  final int year;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final monthFormat = DateFormat('MMMMM', Localizations.localeOf(context).toLanguageTag());
    final fullMonthFormat = DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag());
    final summary = [
      for (var month = 1; month <= DateTime.monthsPerYear; month++)
        '${fullMonthFormat.format(DateTime(year, month))}: ${statistics.logCountByMonth[month - 1]}',
    ].join(', ');
    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: SizedBox(
          height: _chartHeight,
          child: BarChart(
            BarChartData(
              maxY: 31,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: const BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.small),
                      child: Text(
                        monthFormat.format(DateTime(year, value.toInt() + 1)),
                        style: TextStyle(color: komitColors.mutedText),
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: [
                for (var monthIndex = 0; monthIndex < DateTime.monthsPerYear; monthIndex++)
                  BarChartGroupData(
                    x: monthIndex,
                    barRods: [
                      BarChartRodData(
                        toY: statistics.logCountByMonth[monthIndex].toDouble(),
                        color: colorScheme.primary,
                        width: _monthBarWidth,
                        borderRadius: BorderRadius.circular(AppRadii.gridCell),
                        borderSide: BorderSide(color: komitColors.outline, width: AppOutline.thin),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
