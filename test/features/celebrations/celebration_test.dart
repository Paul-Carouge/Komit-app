import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/haptics.dart';
import 'package:komit/core/theme/app_motion.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/features/celebrations/celebration_overlay.dart';
import 'package:komit/features/shared/habit_icon_hero.dart';
import 'package:komit/features/shared/shared_widgets.dart';

import '../../support/komit_test_app.dart';

final CalendarDay _today = CalendarDay.fromDateTime(komitTestNow);
const String _freshHabitTitle = 'Drink water';
const String _sevenDayMilestoneTitle = '7 days in a row';

HabitRepository _repositoryOf(KomitTestEnvironment environment) =>
    HabitRepository(environment.database, now: () => komitTestNow);

/// Logs the six days before today on the habit without history, one day short of a week.
Future<HabitWithObjectives> _logSixDaysBeforeToday(WidgetTester tester, KomitTestEnvironment environment) async {
  final repository = _repositoryOf(environment);
  return (await tester.runAsync(() async {
    final habits = await repository.watchActiveHabits().first;
    final habit = habits.firstWhere((habit) => habit.habit.title == _freshHabitTitle);
    for (var daysAgo = 1; daysAgo <= 6; daysAgo++) {
      await repository.logObjectiveForDay(
        habitId: habit.habit.id,
        objectiveId: habit.objectives.first.id,
        day: _today.addDays(-daysAgo),
      );
    }
    return habit;
  }))!;
}

Finder _logTodayButtonOf(String habitTitle) => find.descendant(
  of: find.ancestor(of: find.text(habitTitle), matching: find.byType(PressableCard)).first,
  matching: find.byTooltip('Log today'),
);

Future<void> _logTodayOn(WidgetTester tester, String habitTitle) async {
  await tester.ensureVisible(_logTodayButtonOf(habitTitle));
  await tester.pumpAndSettle();
  await tester.tap(_logTodayButtonOf(habitTitle));
  await settleWithDatabaseWork(tester);
}

/// Waits until every queued celebration card has come and gone.
Future<void> _letCelebrationsFinish(WidgetTester tester) async {
  while (find.byType(CelebrationCard).evaluate().isNotEmpty) {
    await tester.pump(AppDurations.celebrationVisible);
    await tester.pumpAndSettle();
  }
}

/// The second tap of a celebration haptic waits on a timer, started once the platform answers
/// the first tap, which can be as late as the database closing.
Future<void> _disposeAfterCelebrations(WidgetTester tester, KomitTestEnvironment environment) async {
  await environment.dispose(tester);
  await tester.pump(KomitHaptics.celebrationTapGap);
}

void main() {
  testWidgets('crossing seven days celebrates once; clearing and logging again does not', (tester) async {
    final environment = await KomitTestEnvironment.create(tester, additionalHabitTitles: [_freshHabitTitle]);
    final habit = await _logSixDaysBeforeToday(tester, environment);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await _logTodayOn(tester, _freshHabitTitle);

    expect(find.text(_sevenDayMilestoneTitle), findsOneWidget);
    expect(find.descendant(of: find.byType(CelebrationCard), matching: find.text(_freshHabitTitle)), findsOneWidget);
    expect(find.byType(CelebrationBurst), findsOneWidget);
    // The card never blocks the screen: the undo message stays reachable.
    expect(find.text('Undo').hitTestable(), findsOneWidget);
    await _letCelebrationsFinish(tester);

    await tester.runAsync(() => _repositoryOf(environment).clearLogForDay(habitId: habit.habit.id, day: _today));
    await settleWithDatabaseWork(tester);
    await _logTodayOn(tester, _freshHabitTitle);

    expect(find.byType(CelebrationCard), findsNothing);
    await _disposeAfterCelebrations(tester, environment);
  });

  testWidgets('with animations off, the milestone is a static card without a burst', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final environment = await KomitTestEnvironment.create(tester, additionalHabitTitles: [_freshHabitTitle]);
    await _logSixDaysBeforeToday(tester, environment);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await _logTodayOn(tester, _freshHabitTitle);

    expect(find.text(_sevenDayMilestoneTitle), findsOneWidget);
    expect(find.byType(CelebrationBurst), findsNothing);
    final cardOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text(_sevenDayMilestoneTitle), matching: find.byType(Opacity)).first,
    );
    expect(cardOpacity.opacity, 1, reason: 'the card appears at once, without fading in');
    await _letCelebrationsFinish(tester);
    await _disposeAfterCelebrations(tester, environment);
  });

  for (final isMotionReduced in [false, true]) {
    testWidgets('the habit icon ${isMotionReduced ? 'stays in place' : 'flies'} to the habit page '
        '${isMotionReduced ? 'with animations off' : ''}', (tester) async {
      if (isMotionReduced) {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      }
      final environment = await KomitTestEnvironment.create(tester);
      await pumpKomitApp(tester, environment, theme: lightAppTheme);

      await tester.tap(find.text('Morning run'));
      await tester.pump();
      await tester.pump(AppDurations.standard ~/ 2);

      expect(find.byType(HabitIconHeroShuttle), isMotionReduced ? findsNothing : findsOneWidget);
      await settleWithDatabaseWork(tester);
      expect(find.byType(HabitIconHero), findsWidgets);
      await environment.dispose(tester);
    });
  }
}
