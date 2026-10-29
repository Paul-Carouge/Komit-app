import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/calendar_day.dart';
import '../../core/date_formatting.dart';
import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';

/// Habits put aside: their history is kept, and each one can come back to the dashboard.
class ArchivedHabitsScreen extends ConsumerWidget {
  const ArchivedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final habits = ref.watch(archivedHabitsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(title: localizations.archivedHabitsTitle),
          switch (habits) {
            AsyncData(value: final habits) when habits.isEmpty => SliverFillRemaining(
              hasScrollBody: false,
              child: KomoEmptyState(
                mood: KomoMood.sleepy,
                title: localizations.noArchivedHabitsTitle,
                message: localizations.noArchivedHabitsMessage,
              ),
            ),
            AsyncData(value: final habits) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                0,
                AppSpacing.screenGutter,
                AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList.separated(
                itemCount: habits.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.medium),
                itemBuilder: (context, index) =>
                    _ArchivedHabitRow(key: ValueKey(habits[index].habit.id), habit: habits[index]),
              ),
            ),
            _ => SliverFillRemaining(
              hasScrollBody: false,
              child: AsyncValueView(
                value: habits,
                retryProvider: archivedHabitsProvider,
                builder: (_) => const SizedBox(),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _ArchivedHabitRow extends ConsumerWidget {
  const _ArchivedHabitRow({required this.habit, super.key});

  final HabitWithObjectives habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final archivedAt = habit.habit.archivedAt;
    return PressableCard(
      onTap: () => context.push(AppRoutes.habitDetails(habit.habit.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.large, AppSpacing.medium, AppSpacing.small, AppSpacing.medium),
        child: Row(
          children: [
            HabitIconBadge(icon: habitIconForName(habit.habit.iconName), color: Color(habit.habit.colorArgb)),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.habit.title, style: textTheme.titleMedium),
                  if (archivedAt != null)
                    Text(
                      localizations.archivedOn(formatShortDate(context, CalendarDay.fromDateTime(archivedAt))),
                      style: textTheme.bodySmall?.copyWith(color: KomitColors.of(context).mutedText),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: localizations.unarchiveHabit,
              onPressed: () => unarchiveHabitWithMessage(context, ref, habit),
              icon: const Icon(KomitIcons.archiveRestore),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moves [habit] back to the dashboard and says so; failures are logged and explained.
Future<void> unarchiveHabitWithMessage(BuildContext context, WidgetRef ref, HabitWithObjectives habit) async {
  final messenger = ScaffoldMessenger.of(context);
  final localizations = AppLocalizations.of(context);
  try {
    await ref.read(habitRepositoryProvider).unarchiveHabit(habit.habit.id);
    unawaited(KomitHaptics.success());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizations.habitUnarchivedMessage(habit.habit.title))));
  } on Object catch (error, stackTrace) {
    unawaited(KomitHaptics.error());
    unawaited(
      ref.read(appLoggerProvider).logError(event: 'habit_unarchive_failed', error: error, stackTrace: stackTrace),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizations.genericError)));
  }
}
