import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_logger.dart';
import '../../core/calendar_day.dart';
import '../../core/current_calendar_day.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/celebrations.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../achievements/achievement_texts.dart';
import 'celebration_overlay.dart';

/// Reads everything [celebrateLog] needs while the caller's context is still valid: the log
/// write that comes first may outlive the row or sheet that asked for it.
class LogCelebrator {
  LogCelebrator.of(BuildContext context, WidgetRef ref)
    : _overlay = Overlay.of(context, rootOverlay: true),
      _localizations = AppLocalizations.of(context),
      _achievementColor = Theme.of(context).colorScheme.primary,
      _habitRepository = ref.read(habitRepositoryProvider),
      _settingsRepository = ref.read(settingsRepositoryProvider),
      _logger = ref.read(appLoggerProvider),
      _today = ref.read(currentCalendarDayProvider);

  final OverlayState _overlay;
  final AppLocalizations _localizations;
  final Color _achievementColor;
  final HabitRepository _habitRepository;
  final SettingsRepository _settingsRepository;
  final AppLogger _logger;
  final CalendarDay _today;

  /// Celebrates what logging [day] as [objectiveId] just earned, each celebration once ever.
  /// Call it after the log is saved; [previousObjectiveId] is what the day held before.
  Future<void> celebrateLog({
    required HabitWithObjectives habit,
    required CalendarDay day,
    required int? previousObjectiveId,
    required int objectiveId,
  }) async {
    try {
      final (habits, logsByHabitId) = await (
        _habitRepository.watchAllHabits().first,
        _habitRepository.watchObjectiveIdByDayForAllHabits().first,
      ).wait;
      final habitId = habit.habit.id;
      // The saved state, with the logged day put back as it was: the history before the log.
      final historiesBeforeLog = [
        for (final eachHabit in habits)
          eachHabit.habit.id == habitId
              ? habitHistoryOf(eachHabit, logsByHabitId[habitId] ?? const {}).withDayLogged(day, previousObjectiveId)
              : habitHistoryOf(eachHabit, logsByHabitId[eachHabit.habit.id] ?? const {}),
      ];
      final shownCelebrationIds = _settingsRepository.readShownCelebrationIds();
      final newCelebrations = computeCelebrationsEarnedByLog(
        historiesBeforeLog: historiesBeforeLog,
        habitId: habitId,
        day: day,
        objectiveId: objectiveId,
        today: _today,
      ).where((celebration) => !shownCelebrationIds.contains(celebration.id)).toList();
      if (newCelebrations.isEmpty) return;
      await _settingsRepository.markCelebrationsShown(newCelebrations.map((celebration) => celebration.id));
      if (!_overlay.mounted) return;
      showCelebrationCards(_overlay, [for (final celebration in newCelebrations) _cardFor(celebration, habit)]);
    } on Object catch (error, stackTrace) {
      // A celebration is a bonus: the log is saved, so only record why it did not play.
      await _logger.logError(event: 'celebration_failed', error: error, stackTrace: stackTrace);
    }
  }

  CelebrationCardContent _cardFor(Celebration celebration, HabitWithObjectives habit) {
    final localizations = _localizations;
    final habitColor = Color(habit.habit.colorArgb);
    return switch (celebration) {
      FirstLogCelebration() => CelebrationCardContent(
        eyebrow: habit.habit.title,
        title: localizations.celebrationFirstLogTitle,
        message: localizations.celebrationFirstLogMessage,
        burstColor: habitColor,
      ),
      StreakMilestoneCelebration(:final streakLength, unit: StreakUnit.days) => CelebrationCardContent(
        eyebrow: habit.habit.title,
        title: localizations.celebrationStreakDaysTitle(streakLength),
        message: localizations.celebrationKeepGoingTomorrow,
        burstColor: habitColor,
      ),
      StreakMilestoneCelebration(:final streakLength, unit: StreakUnit.weeks) => CelebrationCardContent(
        eyebrow: habit.habit.title,
        title: localizations.celebrationStreakWeeksTitle(streakLength),
        message: localizations.celebrationKeepGoingNextWeek,
        burstColor: habitColor,
      ),
      AchievementCelebration(:final achievement) => CelebrationCardContent(
        eyebrow: localizations.achievementUnlocked,
        title: achievementTitle(localizations, achievement),
        message: achievementDescription(localizations, achievement),
        burstColor: _achievementColor,
      ),
    };
  }
}
