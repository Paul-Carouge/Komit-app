import '../../domain/achievements.dart';
import '../../l10n/app_localizations.dart';

String achievementTitle(AppLocalizations localizations, Achievement achievement) => switch (achievement) {
  Achievement.firstStep => localizations.achievementFirstStepTitle,
  Achievement.firstWeek => localizations.achievementFirstWeekTitle,
  Achievement.monthStreak => localizations.achievementMonthStreakTitle,
  Achievement.hundredDayStreak => localizations.achievementHundredDayStreakTitle,
  Achievement.yearStreak => localizations.achievementYearStreakTitle,
  Achievement.perfectDay => localizations.achievementPerfectDayTitle,
  Achievement.perfectWeek => localizations.achievementPerfectWeekTitle,
  Achievement.hundredSuccessDays => localizations.achievementHundredSuccessDaysTitle,
  Achievement.fiveHundredTotalSuccessDays => localizations.achievementFiveHundredTotalSuccessDaysTitle,
  Achievement.thousandTotalSuccessDays => localizations.achievementThousandTotalSuccessDaysTitle,
  Achievement.threeHabits => localizations.achievementThreeHabitsTitle,
  Achievement.comeback => localizations.achievementComebackTitle,
  Achievement.oneYearVeteran => localizations.achievementOneYearVeteranTitle,
  Achievement.twoYearVeteran => localizations.achievementTwoYearVeteranTitle,
};

String achievementDescription(AppLocalizations localizations, Achievement achievement) => switch (achievement) {
  Achievement.firstStep => localizations.achievementFirstStepDescription,
  Achievement.firstWeek => localizations.achievementFirstWeekDescription,
  Achievement.monthStreak => localizations.achievementMonthStreakDescription,
  Achievement.hundredDayStreak => localizations.achievementHundredDayStreakDescription,
  Achievement.yearStreak => localizations.achievementYearStreakDescription,
  Achievement.perfectDay => localizations.achievementPerfectDayDescription,
  Achievement.perfectWeek => localizations.achievementPerfectWeekDescription,
  Achievement.hundredSuccessDays => localizations.achievementHundredSuccessDaysDescription,
  Achievement.fiveHundredTotalSuccessDays => localizations.achievementFiveHundredTotalSuccessDaysDescription,
  Achievement.thousandTotalSuccessDays => localizations.achievementThousandTotalSuccessDaysDescription,
  Achievement.threeHabits => localizations.achievementThreeHabitsDescription,
  Achievement.comeback => localizations.achievementComebackDescription,
  Achievement.oneYearVeteran => localizations.achievementOneYearVeteranDescription,
  Achievement.twoYearVeteran => localizations.achievementTwoYearVeteranDescription,
};
