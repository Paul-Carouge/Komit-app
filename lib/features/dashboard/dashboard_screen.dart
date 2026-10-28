import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/day_grid.dart';
import '../shared/shared_widgets.dart';

const int _cardsPerRow = 2;
const int _daysPerGridRow = 7;
const double _cardAspectRatio = 0.86;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final userName = ref.watch(settingsControllerProvider.select((settings) => settings.userName));
    final habits = ref.watch(allHabitsProvider);
    final hasHabits = habits.value?.isNotEmpty ?? false;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.extraLarge,
                AppSpacing.small,
                AppSpacing.large,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    if (hasHabits) ...[const _DashboardKomo(), const SizedBox(width: AppSpacing.medium)],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          userName == null ? localizations.greetingWithoutName : localizations.greeting(userName),
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: localizations.settingsTooltip,
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(LucideIcons.settings),
                    ),
                  ],
                ),
              ),
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
              AsyncData(value: final habits) => _HabitCardGrid(habits: habits),
              _ => SliverFillRemaining(
                hasScrollBody: false,
                child: AsyncValueView(value: habits, builder: (_) => const SizedBox()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Komo celebrates once every habit is logged today, and keeps calm company otherwise.
class _DashboardKomo extends ConsumerWidget {
  const _DashboardKomo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentCalendarDayProvider);
    final habits = ref.watch(allHabitsProvider).value ?? const [];
    final recentLogsByHabitId = ref.watch(recentLogsForAllHabitsProvider).value ?? const {};
    final isEveryHabitLoggedToday =
        habits.isNotEmpty && habits.every((habit) => recentLogsByHabitId[habit.habit.id]?.containsKey(today) ?? false);
    return KomoMascot(mood: isEveryHabitLoggedToday ? KomoMood.happy : KomoMood.idle, size: AppSizes.mascotSmall);
  }
}

class _HabitCardGrid extends ConsumerWidget {
  const _HabitCardGrid({required this.habits});

  final List<HabitWithObjectives> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLogsByHabitId = ref.watch(recentLogsForAllHabitsProvider).value ?? const {};
    final lastLoggedDayByHabitId = ref.watch(lastLoggedDayByHabitIdProvider).value ?? const {};
    final today = ref.watch(currentCalendarDayProvider);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.extraLarge),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _cardsPerRow,
          mainAxisSpacing: AppSpacing.large,
          crossAxisSpacing: AppSpacing.large,
          childAspectRatio: _cardAspectRatio,
        ),
        itemCount: habits.length + 1,
        itemBuilder: (context, index) {
          if (index == habits.length) return const _NewHabitCard();
          final habit = habits[index];
          return _HabitCard(
            habit: habit,
            today: today,
            recentObjectiveIdByDay: recentLogsByHabitId[habit.habit.id] ?? const {},
            lastLoggedDay: lastLoggedDayByHabitId[habit.habit.id],
          );
        },
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.today,
    required this.recentObjectiveIdByDay,
    required this.lastLoggedDay,
  });

  final HabitWithObjectives habit;
  final CalendarDay today;
  final Map<CalendarDay, int> recentObjectiveIdByDay;
  final CalendarDay? lastLoggedDay;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag());
    final lastLoggedDateText = lastLoggedDay == null ? null : dateFormat.format(lastLoggedDay!.asLocalDate);
    // Cards are narrow: show the bare date next to the history icon, and the full sentence to screen readers.
    final lastActivityText = lastLoggedDateText ?? localizations.noActivityYet;
    final lastActivitySemanticLabel = lastLoggedDateText == null
        ? localizations.noActivityYet
        : localizations.lastActivity(lastLoggedDateText);
    final firstDay = today.addDays(-(dashboardRecentDayCount - 1));
    final cells = [
      for (var offset = 0; offset < dashboardRecentDayCount; offset++)
        _recentDayCell(firstDay.addDays(offset), komitColors, dateFormat),
    ];
    return PressableCard(
      onTap: () => context.push(AppRoutes.habitDetails(habit.habit.id)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitIconBadge(icon: habitIconForName(habit.habit.iconName), color: Color(habit.habit.colorArgb)),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Text(
                    habit.habit.title,
                    style: textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ExcludeSemantics(
              child: DayGrid(columnCount: _daysPerGridRow, cells: cells),
            ),
            const Spacer(),
            Semantics(
              label: lastActivitySemanticLabel,
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(LucideIcons.history, size: textTheme.bodySmall?.fontSize, color: komitColors.mutedText),
                  const SizedBox(width: AppSpacing.extraSmall),
                  Expanded(
                    child: Text(
                      lastActivityText,
                      style: textTheme.bodySmall?.copyWith(color: komitColors.mutedText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DayGridCell _recentDayCell(CalendarDay day, KomitColors komitColors, DateFormat dateFormat) {
    final objective = recentObjectiveIdByDay[day] == null ? null : habit.objectiveWithId(recentObjectiveIdByDay[day]!);
    return DayGridCell(
      color: objective == null ? komitColors.emptyCell : Color(objective.colorArgb),
      semanticLabel: '${dateFormat.format(day.asLocalDate)}: ${objective?.title ?? '-'}',
    );
  }
}

class _NewHabitCard extends StatelessWidget {
  const _NewHabitCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    return PressableCard(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
        side: BorderSide(color: colorScheme.outlineVariant, width: AppSizes.emphasisBorderWidth),
      ),
      onTap: () => context.push(AppRoutes.newHabit),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: AppSizes.minimumTouchTarget / 2,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(LucideIcons.plus, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            AppLocalizations.of(context).newHabit,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: komitColors.accentText),
          ),
        ],
      ),
    );
  }
}
