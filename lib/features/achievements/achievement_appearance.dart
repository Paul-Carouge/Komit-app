import 'package:flutter/widgets.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../domain/achievements.dart';

/// Families of achievements; each has its own color, so the grid reads as groups at a glance.
enum AchievementFamily {
  beginnings(AchievementFamilyColors.beginnings),
  streaks(AchievementFamilyColors.streaks),
  perfection(AchievementFamilyColors.perfection),
  totals(AchievementFamilyColors.totals),
  variety(AchievementFamilyColors.variety),
  calendar(AchievementFamilyColors.calendar),
  resilience(AchievementFamilyColors.resilience);

  const AchievementFamily(this.color);

  final Color color;
}

AchievementFamily achievementFamily(Achievement achievement) => switch (achievement) {
  Achievement.firstStep ||
  Achievement.firstMonthWithKomit ||
  Achievement.oneYearVeteran ||
  Achievement.twoYearVeteran => AchievementFamily.beginnings,
  Achievement.firstWeek ||
  Achievement.twoWeekStreak ||
  Achievement.monthStreak ||
  Achievement.hundredDayStreak ||
  Achievement.twoHundredDayStreak ||
  Achievement.yearStreak => AchievementFamily.streaks,
  Achievement.perfectDay ||
  Achievement.tenPerfectDays ||
  Achievement.fiftyPerfectDays ||
  Achievement.perfectWeek ||
  Achievement.perfectMonth => AchievementFamily.perfection,
  Achievement.hundredTotalSuccessDays ||
  Achievement.hundredSuccessDays ||
  Achievement.yearOfSuccessDays ||
  Achievement.fiveHundredTotalSuccessDays ||
  Achievement.thousandTotalSuccessDays ||
  Achievement.twoThousandFiveHundredTotalSuccessDays => AchievementFamily.totals,
  Achievement.threeHabits ||
  Achievement.fiveHabits ||
  Achievement.threeObjectivesOnOneHabit => AchievementFamily.variety,
  Achievement.weekendWarrior ||
  Achievement.newYearsDay ||
  Achievement.halloween ||
  Achievement.christmasDay ||
  Achievement.easterSunday ||
  Achievement.leapDay => AchievementFamily.calendar,
  Achievement.comeback || Achievement.phoenix => AchievementFamily.resilience,
};

IconData achievementIcon(Achievement achievement) => switch (achievement) {
  Achievement.firstStep => KomitIcons.footprints,
  Achievement.firstMonthWithKomit => KomitIcons.sprout,
  Achievement.firstWeek => KomitIcons.flame,
  Achievement.twoWeekStreak => KomitIcons.zap,
  Achievement.monthStreak => KomitIcons.rocket,
  Achievement.hundredDayStreak => KomitIcons.mountain,
  Achievement.twoHundredDayStreak => KomitIcons.mountainSnow,
  Achievement.yearStreak => KomitIcons.crown,
  Achievement.perfectDay => KomitIcons.star,
  Achievement.tenPerfectDays => KomitIcons.sparkles,
  Achievement.fiftyPerfectDays => KomitIcons.gem,
  Achievement.perfectWeek => KomitIcons.calendarCheck,
  Achievement.perfectMonth => KomitIcons.award,
  Achievement.hundredTotalSuccessDays => KomitIcons.target,
  Achievement.hundredSuccessDays => KomitIcons.medal,
  Achievement.yearOfSuccessDays => KomitIcons.trophy,
  Achievement.fiveHundredTotalSuccessDays => KomitIcons.trendingUp,
  Achievement.thousandTotalSuccessDays => KomitIcons.chartNoAxesColumn,
  Achievement.twoThousandFiveHundredTotalSuccessDays => KomitIcons.infinity,
  Achievement.threeHabits => KomitIcons.layers,
  Achievement.fiveHabits => KomitIcons.layoutGrid,
  Achievement.threeObjectivesOnOneHabit => KomitIcons.palette,
  Achievement.weekendWarrior => KomitIcons.sun,
  Achievement.newYearsDay => KomitIcons.partyPopper,
  Achievement.halloween => KomitIcons.ghost,
  Achievement.christmasDay => KomitIcons.gift,
  Achievement.easterSunday => KomitIcons.egg,
  Achievement.leapDay => KomitIcons.rabbit,
  Achievement.comeback => KomitIcons.rotateCcw,
  Achievement.phoenix => KomitIcons.bird,
  Achievement.oneYearVeteran => KomitIcons.cake,
  Achievement.twoYearVeteran => KomitIcons.hourglass,
};
