import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/theme/app_theme.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
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
    final habitProvider = habitWithObjectivesProvider(habitId);
    final objectiveIdByDayProvider = objectiveIdByDayForHabitProvider(habitId);
    final habit = ref.watch(habitProvider);
    final objectiveIdByDay = ref.watch(objectiveIdByDayProvider);
    final Widget content = switch ((habit, objectiveIdByDay)) {
      (AsyncData(value: final habit?), AsyncData(value: final objectiveIdByDay)) => _StatisticsContent(
        habit: habit,
        objectiveIdByDay: objectiveIdByDay,
        year: year,
        today: ref.watch(currentCalendarDayProvider),
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
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(title: localizations.statisticsTitle(year)),
          content,
        ],
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
    final textTheme = Theme.of(context).textTheme;
    final statistics = computeYearStatistics(objectiveIdByDay, year: year);
    final streaks = streakSummaryOf(habit, objectiveIdByDay, today: today);
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.small,
        AppSpacing.screenGutter,
        AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.list(
        children: [
          MergeSemantics(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.extraLarge),
              decoration: BoxDecoration(
                color: komitColors.highlightContainer,
                borderRadius: BorderRadius.circular(AppRadii.large),
              ),
              child: Row(
                children: [
                  HabitIconBadge(
                    icon: KomitIcons.calendarCheck,
                    color: komitColors.onHighlightContainer,
                    size: AppSizes.heroBadge,
                  ),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.daysLogged,
                          style: textTheme.bodyLarge?.copyWith(color: komitColors.onHighlightContainer),
                        ),
                        AnimatedCount(
                          value: statistics.totalLogCount,
                          style: textTheme.displaySmall?.copyWith(color: komitColors.onHighlightContainer),
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
            _MonthlyActivityChart(
              statistics: statistics,
              year: year,
              habitColor: Color(habit.habit.colorArgb),
              currentMonth: today.year == year ? today.asUtcDate.month : null,
            ),
          ],
          const _YearInReviewRow(),
        ],
      ),
    );
  }
}

/// From December 1 to January 15, a way back into the year in review, even once its dashboard
/// card is dismissed.
class _YearInReviewRow extends ConsumerWidget {
  const _YearInReviewRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(yearInReviewYearProvider);
    if (year == null) return const SizedBox.shrink();
    final komitColors = KomitColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.extraLarge),
      child: PressableCard(
        onTap: () => context.push(AppRoutes.yearInReview),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              HabitIconBadge(icon: KomitIcons.sparkles, color: komitColors.accentText),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).yearInReviewStatisticsRow(year),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(KomitIcons.chevronRight, color: komitColors.mutedText),
            ],
          ),
        ),
      ),
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraSmall),
              child: Row(
                children: [
                  ColorDot(color: Color(objective.colorArgb)),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(child: Text(objective.title, style: textTheme.bodyLarge)),
                  Text(
                    '${statistics.logCountByObjectiveId[objective.id]} · '
                    '${(statistics.logCountByObjectiveId[objective.id]! * 100 / statistics.totalLogCount).round()} %',
                    style: textTheme.bodyLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The busiest possible month, so bars of different years compare at the same scale.
const double _monthlyChartMaximumY = 31;

class _MonthlyActivityChart extends StatelessWidget {
  const _MonthlyActivityChart({
    required this.statistics,
    required this.year,
    required this.habitColor,
    required this.currentMonth,
  });

  final YearStatistics statistics;
  final int year;
  final Color habitColor;

  /// 1 to 12 when [year] is this year: that month's column is highlighted. Null otherwise.
  final int? currentMonth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    final localizations = AppLocalizations.of(context);
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
              maxY: _monthlyChartMaximumY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              // Touching a bar shows its month and count; the summary above tells screen readers.
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => colorScheme.inverseSurface,
                  tooltipBorderRadius: BorderRadius.circular(AppRadii.small),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    '${fullMonthFormat.format(DateTime(year, group.x + 1))}\n'
                    '${localizations.dayCount(rod.toY.round())}',
                    textTheme.labelMedium!.copyWith(color: colorScheme.onInverseSurface),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final isCurrentMonth = value.toInt() + 1 == currentMonth;
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.small),
                        child: Text(
                          monthFormat.format(DateTime(year, value.toInt() + 1)),
                          style: textTheme.labelMedium?.copyWith(
                            color: isCurrentMonth ? colorScheme.onSurface : komitColors.mutedText,
                            fontWeight: isCurrentMonth ? FontWeight.w800 : null,
                          ),
                        ),
                      );
                    },
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
                        color: habitColor,
                        width: _monthBarWidth,
                        borderRadius: BorderRadius.circular(AppRadii.gridCell),
                        // The current month stands on a full-height track: where the year is now.
                        backDrawRodData: BackgroundBarChartRodData(
                          show: monthIndex + 1 == currentMonth,
                          toY: _monthlyChartMaximumY,
                          color: komitColors.emptyCell,
                        ),
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
