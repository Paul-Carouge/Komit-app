import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/repositories/habit_repository.dart';
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
  });
}
