import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/quantity_goal.dart';
import 'package:komit/router.dart';

import '../../support/komit_test_app.dart';

/// Scrolls [finder] to the middle of the form, clear of the large title and the save bar, then taps it.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<({GoRouter router, KomitTestEnvironment environment})> _openNewHabitEditor(WidgetTester tester) async {
  final environment = await KomitTestEnvironment.create(tester);
  final router = await pumpKomitApp(tester, environment, theme: lightAppTheme);
  unawaited(router.push(AppRoutes.newHabit));
  await settleWithDatabaseWork(tester);
  return (router: router, environment: environment);
}

Future<HabitWithObjectives> _savedHabitTitled(
  WidgetTester tester,
  KomitTestEnvironment environment,
  String title,
) async {
  final habits = await tester.runAsync(() => HabitRepository(environment.database).watchActiveHabits().first);
  return habits!.singleWhere((habit) => habit.habit.title == title);
}

Future<void> _fillNameAndObjective(WidgetTester tester) async {
  await tester.enterText(find.widgetWithText(TextField, 'Habit name'), 'Stretch');
  final objectiveField = find.widgetWithText(TextField, 'Objective name');
  // The objectives sit below the fold on a compact phone; the list only builds what is near.
  await tester.scrollUntilVisible(objectiveField, 200, scrollable: find.byType(Scrollable).first);
  await tester.enterText(objectiveField, 'Ten minutes');
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Create habit'));
  await settleWithDatabaseWork(tester);
}

void main() {
  group('habit editor', () {
    testWidgets('choosing some days starts from the working week and saves it', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);
      await _fillNameAndObjective(tester);

      await _scrollToAndTap(tester, find.text('Some days'));
      expect(find.text('Weekdays'), findsOneWidget);

      await _save(tester);
      final saved = await _savedHabitTitled(tester, environment, 'Stretch');
      expect(saved.habit.scheduledWeekdayMask, 0x1F);
      expect(saved.habit.targetDaysPerWeek, isNull);
      await environment.dispose(tester);
    });

    testWidgets('a weekly target saves the number chosen with the stepper', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);
      await _fillNameAndObjective(tester);

      await _scrollToAndTap(tester, find.text('Per week'));
      await _scrollToAndTap(tester, find.byTooltip('More days per week'));
      expect(find.text('4 days per week'), findsOneWidget);

      await _save(tester);
      final saved = await _savedHabitTitled(tester, environment, 'Stretch');
      expect(saved.habit.targetDaysPerWeek, 4);
      await environment.dispose(tester);
    });

    testWidgets('rest days are saved for a daily habit and hidden with a weekly target', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);
      await _fillNameAndObjective(tester);

      await _scrollToAndTap(tester, find.text('1 day'));
      await _save(tester);
      expect((await _savedHabitTitled(tester, environment, 'Stretch')).habit.restDaysPerWeek, 1);

      unawaited(router.push(AppRoutes.newHabit));
      await settleWithDatabaseWork(tester);
      await tester.scrollUntilVisible(find.text('Rest days'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Rest days'), findsOneWidget);
      await _scrollToAndTap(tester, find.text('Per week'));
      expect(find.text('Rest days'), findsNothing);
      await environment.dispose(tester);
    });

    testWidgets('rest days the chosen weekdays cannot allow are disabled and not saved', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);
      final semantics = tester.ensureSemantics();
      await _fillNameAndObjective(tester);
      await _scrollToAndTap(tester, find.text('2 days'));

      // Monday to Friday, then down to Monday and Tuesday: at most one rest day is left.
      await _scrollToAndTap(tester, find.text('Some days'));
      for (final weekday in ['Wednesday', 'Thursday', 'Friday']) {
        await _scrollToAndTap(tester, find.bySemanticsLabel(weekday));
      }
      final twoDaysSegment = find.ancestor(of: find.text('2 days'), matching: find.byType(TextButton));
      expect(tester.widget<TextButton>(twoDaysSegment).onPressed, isNull);

      await _save(tester);
      final saved = await _savedHabitTitled(tester, environment, 'Stretch');
      expect(saved.habit.scheduledWeekdayMask, 0x03);
      expect(saved.habit.restDaysPerWeek, 1);
      semantics.dispose();
      await environment.dispose(tester);
    });

    testWidgets('saving an empty form names the problems and stays open', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);

      await _save(tester);

      expect(find.text('Give your habit a name.'), findsOneWidget);
      expect(find.text('Each objective needs a unique name.'), findsOneWidget);
      expect(find.text('Create habit'), findsOneWidget);
      await environment.dispose(tester);
    });

    testWidgets('leaving with changes asks first; leaving untouched does not', (tester) async {
      final (:router, :environment) = await _openNewHabitEditor(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Habit name'), 'Stretch');
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Create habit'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Create habit'), findsNothing);

      unawaited(router.push(AppRoutes.newHabit));
      await settleWithDatabaseWork(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsNothing);
      expect(find.text('Create habit'), findsNothing);
      await environment.dispose(tester);
    });

    testWidgets('screen readers hear the field names once the fields are filled', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      final semantics = tester.ensureSemantics();
      await pumpKomitApp(
        tester,
        environment,
        theme: lightAppTheme,
        location: AppRoutes.habitEditor(environment.runningHabitId),
      );

      expect(find.bySemanticsLabel(RegExp('Habit name')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Description')), findsOneWidget);
      semantics.dispose();
      await environment.dispose(tester);
    });

    testWidgets('a new habit can track an amount: unit, daily target and step are saved', (tester) async {
      final (router: _, :environment) = await _openNewHabitEditor(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Habit name'), 'Drink water');
      await _scrollToAndTap(tester, find.text('An amount'));
      expect(find.text('Objective name'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'Unit'), 'glasses');
      await tester.enterText(find.widgetWithText(TextField, 'Daily target'), '8');
      await tester.enterText(find.widgetWithText(TextField, 'One tap adds'), '0,5');
      await tester.pumpAndSettle();
      expect(find.text('8 glasses a day · 0.5 per tap'), findsOneWidget);
      await _save(tester);

      final saved = await _savedHabitTitled(tester, environment, 'Drink water');
      expect((saved.quantityGoal?.unit, saved.quantityGoal?.target, saved.quantityGoal?.step), ('glasses', 8, 0.5));
      expect(saved.objectives.single.title, 'glasses');
      await environment.dispose(tester);
    });

    testWidgets('an amount without a unit or a target is not saved, and says why', (tester) async {
      final (router: _, :environment) = await _openNewHabitEditor(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Habit name'), 'Drink water');
      await _scrollToAndTap(tester, find.text('An amount'));
      await _save(tester);
      expect(find.text('Give the amount a unit'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Unit'), 'glasses');
      await _save(tester);
      expect(find.text('The daily target and the step must be numbers above 0'), findsOneWidget);
      // A target that rounds to 0 as stored is no target either.
      await tester.enterText(find.widgetWithText(TextField, 'Daily target'), '0.0004');
      await _save(tester);
      expect(find.text('The daily target and the step must be numbers above 0'), findsOneWidget);
      final habits = await tester.runAsync(() => HabitRepository(environment.database).watchActiveHabits().first);
      expect(habits!.map((habit) => habit.habit.title), isNot(contains('Drink water')));
      await environment.dispose(tester);
    });

    testWidgets('a habit with logs keeps its kind and explains why', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      await pumpKomitApp(
        tester,
        environment,
        theme: lightAppTheme,
        location: AppRoutes.habitEditor(environment.runningHabitId),
      );
      final lockedExplanation = find.textContaining('already has logged days');
      await tester.scrollUntilVisible(lockedExplanation, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('An amount'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Unit'), findsNothing);
      expect(find.text('Objectives'), findsWidgets);
      await environment.dispose(tester);
    });

    for (final locale in [const Locale('en'), const Locale('fr')]) {
      testWidgets('saving a habit of 10,000 steps keeps its target (${locale.languageCode})', (tester) async {
        final environment = await KomitTestEnvironment.create(tester);
        final habitId = (await tester.runAsync(
          () => HabitRepository(environment.database).saveHabit(
            const HabitDraft(
              id: null,
              title: 'Walk',
              description: '',
              colorArgb: 0xFF2196F3,
              iconName: 'footprints',
              reminderMinuteOfDay: null,
              objectives: [],
              quantityGoal: QuantityGoal(unit: 'steps', target: 10000, step: 1000),
            ),
          ),
        ))!;
        await pumpKomitApp(
          tester,
          environment,
          theme: lightAppTheme,
          locale: locale,
          location: AppRoutes.habitEditor(habitId),
        );
        await settleWithDatabaseWork(tester);

        await tester.enterText(find.byType(TextField).first, 'Walk more');
        await tester.tap(find.byType(FilledButton).last);
        await settleWithDatabaseWork(tester);

        final saved = await _savedHabitTitled(tester, environment, 'Walk more');
        expect((saved.quantityGoal?.target, saved.quantityGoal?.step), (10000, 1000));
        await environment.dispose(tester);
      });
    }
  });
}
