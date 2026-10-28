import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/game_badges.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_card.dart';
import '../../core/ui/game_text.dart';
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

/// With large text the cards stack in one column, which is wider than tall.
const double _singleColumnCardAspectRatio = 1.1;

/// Share of a card's height taken by text; only that share grows with the user's font size.
const double _textShareOfCardHeight = 0.5;

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
                AppSpacing.screenGutter,
                AppSpacing.large,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    if (hasHabits) ...[const _DashboardKomo(), const SizedBox(width: AppSpacing.medium)],
                    Expanded(
                      child: GameTitle(
                        userName == null ? localizations.greetingWithoutName : localizations.greeting(userName),
                        style: Theme.of(context).textTheme.headlineMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GameIconButton(
                      icon: LucideIcons.settings,
                      tooltip: localizations.settingsTooltip,
                      onPressed: () => context.push(AppRoutes.settings),
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
                  action: GameButton(
                    onPressed: () => context.push(AppRoutes.newHabit),
                    icon: LucideIcons.plus,
                    label: localizations.createFirstHabit,
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
    final isEveryHabitLoggedToday = ref.watch(isEveryHabitLoggedTodayProvider);
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
    final isLargeText = isLargeTextScale(context);
    final textScale = bodyTextScaleOf(context);
    final baseAspectRatio = isLargeText ? _singleColumnCardAspectRatio : _cardAspectRatio;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.extraLarge),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLargeText ? 1 : _cardsPerRow,
          mainAxisSpacing: AppSpacing.large,
          crossAxisSpacing: AppSpacing.large,
          childAspectRatio: baseAspectRatio / (1 + (textScale - 1) * _textShareOfCardHeight),
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
    return GameCard(
      onTap: () => context.push(AppRoutes.habitDetails(habit.habit.id)),
      // Tighter than other cards: two fit side by side and each needs room for its title.
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GameBadge(
                icon: habitIconForName(habit.habit.iconName),
                color: Color(habit.habit.colorArgb),
                size: AppSizes.smallBadge,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                // Lilita One is condensed: long single words such as "Meditation" fit a narrow card.
                child: Text(
                  habit.habit.title,
                  style: textTheme.titleLarge?.copyWith(fontSize: textTheme.titleMedium?.fontSize),
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
    );
  }

  DayGridCell _recentDayCell(CalendarDay day, KomitColors komitColors, DateFormat dateFormat) {
    final objective = recentObjectiveIdByDay[day] == null ? null : habit.objectiveWithId(recentObjectiveIdByDay[day]!);
    return DayGridCell(
      color: objective == null ? komitColors.emptyCell : Color(objective.colorArgb),
      isLogged: objective != null,
      semanticLabel: '${dateFormat.format(day.asLocalDate)}: ${objective?.title ?? '-'}',
    );
  }
}

class _NewHabitCard extends StatelessWidget {
  const _NewHabitCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GameCard(
      color: colorScheme.surfaceContainerHigh,
      onTap: () => context.push(AppRoutes.newHabit),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameBadge(icon: LucideIcons.plus, color: colorScheme.primary, size: AppSizes.heroBadge),
            const SizedBox(height: AppSpacing.medium),
            Text(
              AppLocalizations.of(context).newHabit,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
