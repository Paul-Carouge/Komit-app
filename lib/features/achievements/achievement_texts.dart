import '../../domain/achievements.dart';
import '../../l10n/app_localizations.dart';

String achievementTitle(AppLocalizations localizations, Achievement achievement) => switch (achievement) {
  Achievement.firstWeek => localizations.achievementFirstWeekTitle,
  Achievement.perfectWeek => localizations.achievementPerfectWeekTitle,
  Achievement.hundredSuccessDays => localizations.achievementHundredSuccessDaysTitle,
  Achievement.comeback => localizations.achievementComebackTitle,
  Achievement.oneYearVeteran => localizations.achievementOneYearVeteranTitle,
};

String achievementDescription(AppLocalizations localizations, Achievement achievement) => switch (achievement) {
  Achievement.firstWeek => localizations.achievementFirstWeekDescription,
  Achievement.perfectWeek => localizations.achievementPerfectWeekDescription,
  Achievement.hundredSuccessDays => localizations.achievementHundredSuccessDaysDescription,
  Achievement.comeback => localizations.achievementComebackDescription,
  Achievement.oneYearVeteran => localizations.achievementOneYearVeteranDescription,
};
