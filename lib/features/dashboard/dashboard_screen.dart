import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../habit_details/log_day_sheet.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/day_grid.dart';
import '../shared/shared_widgets.dart';

const double _todayButtonSize = 44;

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final userName = ref.watch(settingsControllerProvider.select((settings) => settings.userName));
    final habits = ref.watch(activeHabitsProvider);
    final hasHabits = habits.value?.isNotEmpty ?? false;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(
            title: userName == null ? localizations.greetingWithoutName : localizations.greeting(userName),
            // Komo sits with the actions, so the collapsed title never slides under it.
            actions: [
              if (hasHabits) const _DashboardKomo(),
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
            AsyncData(value: final habits) => _HabitList(habits: habits),
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
}

/// Komo celebrates once every habit is logged today, and keeps calm company otherwise.
class _DashboardKomo extends ConsumerWidget {
  const _DashboardKomo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentCalendarDayProvider);
    final habits = ref.watch(activeHabitsProvider).value ?? const [];
    final recentLogsByHabitId = ref.watch(recentObjectiveIdByDayByHabitIdProvider).value ?? const {};
    final isEveryHabitLoggedToday =
        habits.isNotEmpty && habits.every((habit) => recentLogsByHabitId[habit.habit.id]?.containsKey(today) ?? false);
    return KomoMascot(mood: isEveryHabitLoggedToday ? KomoMood.happy : KomoMood.idle, size: AppSizes.iconBadge);
  }
}

class _HabitList extends ConsumerWidget {
  const _HabitList({required this.habits});

  final List<HabitWithObjectives> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLogsByHabitId = ref.watch(recentObjectiveIdByDayByHabitIdProvider).value ?? const {};
    final lastLoggedDayByHabitId = ref.watch(lastLoggedDayByHabitIdProvider).value ?? const {};
    final today = ref.watch(currentCalendarDayProvider);
    return SliverPadding(
      // The bottom inset is the frosted navigation bar the list scrolls under.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.small,
        AppSpacing.screenGutter,
        AppSpacing.extraLarge + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.separated(
        itemCount: habits.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.medium),
        itemBuilder: (context, index) {
          if (index == habits.length) return const _NewHabitRow();
          final habit = habits[index];
          return _HabitRow(
            key: ValueKey(habit.habit.id),
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

class _HabitRow extends ConsumerWidget {
  const _HabitRow({
    required this.habit,
    required this.today,
    required this.recentObjectiveIdByDay,
    required this.lastLoggedDay,
    super.key,
  });

  final HabitWithObjectives habit;
  final CalendarDay today;
  final Map<CalendarDay, int> recentObjectiveIdByDay;
  final CalendarDay? lastLoggedDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag());
    final lastLoggedDateText = lastLoggedDay == null ? null : dateFormat.format(lastLoggedDay!.asLocalDate);
    final firstShownDay = today.addDays(-(recentDayCountShownOnDashboard - 1));
    final todayObjectiveId = recentObjectiveIdByDay[today];
    final todayObjective = todayObjectiveId == null ? null : habit.objectiveWithId(todayObjectiveId);
    final cells = [
      for (var offset = 0; offset < recentDayCountShownOnDashboard; offset++)
        _recentDayCell(firstShownDay.addDays(offset), komitColors, dateFormat),
    ];
    return PressableCard(
      onTap: () => context.push(AppRoutes.habitDetails(habit.habit.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.large, AppSpacing.small, AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HabitIconBadge(icon: habitIconForName(habit.habit.iconName), color: Color(habit.habit.colorArgb)),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.habit.title,
                        style: textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lastLoggedDateText == null
                            ? localizations.noActivityYet
                            : localizations.lastActivity(lastLoggedDateText),
                        style: textTheme.bodySmall?.copyWith(color: komitColors.mutedText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _TodayLogButton(
                  objectiveColor: todayObjective == null ? null : Color(todayObjective.colorArgb),
                  onPressed: () =>
                      logDayFromSheet(context, ref, habit: habit, day: today, currentObjectiveId: todayObjectiveId),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
              child: ExcludeSemantics(
                child: DayGrid(columnCount: recentDayCountShownOnDashboard, cells: cells),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DayGridCell _recentDayCell(CalendarDay day, KomitColors komitColors, DateFormat dateFormat) {
    final objectiveId = recentObjectiveIdByDay[day];
    final objective = objectiveId == null ? null : habit.objectiveWithId(objectiveId);
    return DayGridCell(
      color: objective == null ? komitColors.emptyCell : Color(objective.colorArgb),
      semanticLabel: '${dateFormat.format(day.asLocalDate)}: ${objective?.title ?? '-'}',
    );
  }
}

/// Logs today without opening the habit; filled with today's objective color once logged.
class _TodayLogButton extends StatelessWidget {
  const _TodayLogButton({required this.objectiveColor, required this.onPressed});

  final Color? objectiveColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final objectiveColor = this.objectiveColor;
    return IconButton(
      tooltip: AppLocalizations.of(context).logToday,
      onPressed: onPressed,
      icon: AnimatedContainer(
        duration: motionAwareDuration(context, AppDurations.standard),
        curve: AppCurves.emphasized,
        width: _todayButtonSize,
        height: _todayButtonSize,
        decoration: BoxDecoration(shape: BoxShape.circle, color: objectiveColor ?? colorScheme.surfaceContainerHigh),
        child: Icon(
          objectiveColor == null ? LucideIcons.plus : LucideIcons.check,
          color: objectiveColor == null ? colorScheme.onSurfaceVariant : foregroundColorReadableOn(objectiveColor),
        ),
      ),
    );
  }
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
