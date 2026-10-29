import '../core/calendar_day.dart';
import 'achievements.dart';
import 'habit_history.dart';
import 'habit_statistics.dart';

/// A moment worth a celebration, earned by one log.
sealed class Celebration {
  const Celebration();

  /// Stable across launches: a celebration already shown under this id is never shown again,
  /// even after the day is cleared and logged once more.
  String get id;
}

class FirstLogCelebration extends Celebration {
  const FirstLogCelebration({required this.habitId});

  final int habitId;

  @override
  String get id => 'habit:$habitId:first_log';
}

class StreakMilestoneCelebration extends Celebration {
  const StreakMilestoneCelebration({required this.habitId, required this.streakLength, required this.unit});

  final int habitId;
  final int streakLength;
  final StreakUnit unit;

  @override
  String get id => 'habit:$habitId:streak:$streakLength:${unit.name}';
}

class AchievementCelebration extends Celebration {
  const AchievementCelebration(this.achievement);

  final Achievement achievement;

  @override
  String get id => 'achievement:${achievement.name}';
}

/// The celebrations earned by logging [day] as [objectiveId] on [habitId], from every
/// habit's history before the log: the first log of a habit, a streak milestone (the very
/// first day is already the first log), then each newly unlocked achievement.
List<Celebration> computeCelebrationsEarnedByLog({
  required List<HabitHistory> historiesBeforeLog,
  required int habitId,
  required CalendarDay day,
  required int objectiveId,
  required CalendarDay today,
}) {
  final historiesAfterLog = [
    for (final history in historiesBeforeLog)
      history.habitId == habitId ? history.withDayLogged(day, objectiveId) : history,
  ];
  final habitBeforeLog = historiesBeforeLog.where((history) => history.habitId == habitId).firstOrNull;
  if (habitBeforeLog == null) return const [];
  final habitAfterLog = habitBeforeLog.withDayLogged(day, objectiveId);
  final streakBeforeLog = habitBeforeLog.streakSummaryOn(today);
  final streakAfterLog = habitAfterLog.streakSummaryOn(today);
  final milestone = milestoneReachedBetween(streakBeforeLog.currentStreakLength, streakAfterLog.currentStreakLength);
  final unlockedBeforeLog = computeUnlockedAchievements(historiesBeforeLog, today: today);
  return [
    if (habitBeforeLog.objectiveIdByDay.isEmpty)
      FirstLogCelebration(habitId: habitId)
    else if (milestone != null && milestone > streakMilestoneDays.first)
      StreakMilestoneCelebration(habitId: habitId, streakLength: milestone, unit: streakAfterLog.unit),
    for (final achievement in computeUnlockedAchievements(historiesAfterLog, today: today))
      if (!unlockedBeforeLog.contains(achievement)) AchievementCelebration(achievement),
  ];
}
