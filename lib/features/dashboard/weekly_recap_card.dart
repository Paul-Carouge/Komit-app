import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/current_calendar_day.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../domain/weekly_recap.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../shared/shared_widgets.dart';

/// On Mondays, how last week went, until the user dismisses it for that week.
class WeeklyRecapSection extends ConsumerWidget {
  const WeeklyRecapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentCalendarDayProvider);
    final recap = today.weekday == DateTime.monday ? ref.watch(weeklyRecapProvider) : null;
    final dismissedWeek = ref.watch(dismissedWeeklyRecapWeekProvider);
    final habitsById = {
      for (final habit in ref.watch(allHabitsProvider).value ?? const <HabitWithObjectives>[]) habit.habit.id: habit,
    };
    final isShown = recap != null && recap.hasActivity && dismissedWeek != recap.weekMonday;
    return AnimatedSwitcher(
      duration: motionAwareDuration(context, AppDurations.standard),
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: isShown
          ? Padding(
              key: ValueKey(recap.weekMonday),
              padding: const EdgeInsets.only(bottom: AppSpacing.large),
              child: WeeklyRecapCard(
                recap: recap,
                habitsById: habitsById,
                onDismissed: () {
                  unawaited(KomitHaptics.selection());
                  unawaited(ref.read(dismissedWeeklyRecapWeekProvider.notifier).dismiss(recap.weekMonday));
                },
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({required this.recap, required this.habitsById, required this.onDismissed, super.key});

  final WeeklyRecap recap;
  final Map<int, HabitWithObjectives> habitsById;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    final change = recap.successDayCountChange;
    final changeText = switch (change) {
      > 0 => localizations.weeklyRecapMoreThanWeekBefore(change),
      < 0 => localizations.weeklyRecapFewerThanWeekBefore(-change),
      _ => localizations.weeklyRecapSameAsWeekBefore,
    };
    final bestStreak = recap.bestStreak;
    final bestStreakHabit = habitsById[recap.bestStreakHabitId];
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.small, AppSpacing.small, AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(localizations.weeklyRecapTitle, style: textTheme.titleMedium),
                ),
              ),
              IconButton(
                tooltip: localizations.dismissWeeklyRecap,
                onPressed: onDismissed,
                icon: Icon(LucideIcons.x, color: komitColors.mutedText),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.weeklyRecapSuccessDays(recap.successDayCount)} · $changeText',
                  style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
                ),
                const SizedBox(height: AppSpacing.medium),
                for (final result in recap.habitResults)
                  if (habitsById[result.habitId] case final habit?) _HabitWeekRow(habit: habit, result: result),
                if (bestStreak != null && bestStreakHabit != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Icon(LucideIcons.flame, size: AppSizes.iconSmall, color: komitColors.accentText),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Text(
                          localizations.weeklyRecapBestStreak(bestStreakHabit.habit.title, switch (bestStreak.unit) {
                            StreakUnit.days => localizations.dayCount(bestStreak.currentStreakLength),
                            StreakUnit.weeks => localizations.weekCount(bestStreak.currentStreakLength),
                          }),
                          style: textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitWeekRow extends StatelessWidget {
  const _HabitWeekRow({required this.habit, required this.result});

  final HabitWithObjectives habit;
  final HabitWeekResult result;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    final expected = result.expectedSuccessDayCount;
    return MergeSemantics(
      child: Semantics(
        label: localizations.weeklyRecapHabitProgressSemantics(habit.habit.title, result.successDayCount, expected),
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      habit.habit.title,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    localizations.weeklyRecapHabitProgress(result.successDayCount, expected),
                    style: textTheme.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraSmall),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.gridCell),
                child: LinearProgressIndicator(
                  value: expected == 0 ? 0 : (result.successDayCount / expected).clamp(0, 1),
                  minHeight: AppSizes.recapProgressBarHeight,
                  color: Color(habit.habit.colorArgb),
                  backgroundColor: komitColors.emptyCell,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
