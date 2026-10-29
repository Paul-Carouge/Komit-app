import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/features/mascot/komo_mascot.dart';
import 'package:komit/features/shared/day_grid.dart';
import 'package:komit/features/shared/shared_widgets.dart';
import 'package:komit/providers.dart';

import '../../support/komit_test_app.dart';

/// Long enough to be ellipsized in the collapsed bar of a compact phone.
const String _longUserName = 'Maximilien-Alexandre';

final CalendarDay _today = CalendarDay.fromDateTime(komitTestNow);

HabitRepository _repositoryOf(KomitTestEnvironment environment) =>
    HabitRepository(environment.database, now: () => komitTestNow);

Future<HabitWithObjectives> _habitTitled(WidgetTester tester, KomitTestEnvironment environment, String title) async {
  final habits = await tester.runAsync(() => _repositoryOf(environment).watchActiveHabits().first);
  return habits!.firstWhere((habit) => habit.habit.title == title);
}

Future<Map<CalendarDay, int>> _logsOf(WidgetTester tester, KomitTestEnvironment environment, int habitId) async =>
    (await tester.runAsync(() => _repositoryOf(environment).watchObjectiveIdByDayForHabit(habitId).first))!;

Future<int> _countLogsOnDay(WidgetTester tester, KomitTestEnvironment environment, CalendarDay day) async {
  final database = environment.database;
  final logs = await tester.runAsync(
    () => (database.select(database.habitLogs)..where((log) => log.day.equals(day.daysSinceEpoch))).get(),
  );
  return logs!.length;
}

Finder _rowOf(String habitTitle) =>
    find.ancestor(of: find.text(habitTitle), matching: find.byType(PressableCard)).first;

/// The center of the strip cell showing [day] in the row of [habitTitle].
Offset _stripCellCenter(WidgetTester tester, String habitTitle, CalendarDay day) {
  final gridRect = tester.getRect(find.descendant(of: _rowOf(habitTitle), matching: find.byType(DayGrid)));
  const gap = AppSpacing.extraSmall;
  final cellSize = (gridRect.width - gap * (recentDayCountShownOnDashboard - 1)) / recentDayCountShownOnDashboard;
  final index = day.daysSinceEpoch - firstDayShownOnDashboard(_today).daysSinceEpoch;
  return Offset(gridRect.left + index * (cellSize + gap) + cellSize / 2, gridRect.center.dy);
}

void main() {
  for (final textScaleFactor in [1.0, 2.0]) {
    testWidgets('the collapsed greeting stays left of the settings button at ${textScaleFactor}x text', (tester) async {
      final environment = await KomitTestEnvironment.create(tester, userName: _longUserName);
      await pumpKomitApp(tester, environment, theme: lightAppTheme, textScaleFactor: textScaleFactor);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final collapsedTitle = find.descendant(
        of: find.byType(NavigationToolbar),
        matching: find.text('Good morning, $_longUserName'),
      );
      final firstAction = find.descendant(of: find.byType(AppBar), matching: find.byTooltip('Settings'));
      expect(collapsedTitle, findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.byType(KomoMascot)), findsNothing);
      expect(tester.getRect(collapsedTitle).right, lessThanOrEqualTo(tester.getRect(firstAction).left));
      await environment.dispose(tester);
    });
  }

  testWidgets('a long press on the log button opens the sheet above the navigation bar', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await tester.longPress(find.byTooltip('Log today').first);
    await tester.pumpAndSettle();

    final sheet = tester.renderObject(find.byType(BottomSheet));
    final navigationBar = tester.renderObject(find.byType(NavigationBar));
    final hitAtNavigationBar = tester.hitTestOnBinding(tester.getCenter(find.byType(NavigationBar)));
    final hitTargets = hitAtNavigationBar.path.map((entry) => entry.target).toList();
    expect(hitTargets, contains(sheet));
    expect(hitTargets.whereType<RenderObject>().where((target) => identical(target, navigationBar)), isEmpty);
    expect(await _countLogsOnDay(tester, environment, _today), 0);
    await environment.dispose(tester);
  });

  testWidgets('one tap on a single-objective habit logs today once, and Undo removes it', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);
    final reading = await _habitTitled(tester, environment, 'Read before bed');

    await tester.tap(find.byTooltip('Log today').at(1));
    await settleWithDatabaseWork(tester);

    expect(await _countLogsOnDay(tester, environment, _today), 1);
    expect((await _logsOf(tester, environment, reading.habit.id))[_today], reading.objectives.single.id);
    expect(find.text('20 pages logged for Read before bed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleWithDatabaseWork(tester);
    expect(await _countLogsOnDay(tester, environment, _today), 0);
    await environment.dispose(tester);
  });

  testWidgets('changing today from A to B, then Undo, restores A', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final running = await _habitTitled(tester, environment, 'Morning run');
    final [walk, fiveKilometers] = running.objectives;
    await tester.runAsync(
      () => _repositoryOf(environment).logObjectiveForDay(habitId: running.habit.id, objectiveId: walk.id, day: _today),
    );
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    // Already logged: a tap opens the sheet instead of logging again.
    await tester.tap(find.byTooltip('Log today').first);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('5 km')));
    await settleWithDatabaseWork(tester);
    expect((await _logsOf(tester, environment, running.habit.id))[_today], fiveKilometers.id);

    await tester.tap(find.text('Undo'));
    await settleWithDatabaseWork(tester);
    expect((await _logsOf(tester, environment, running.habit.id))[_today], walk.id);
    await environment.dispose(tester);
  });

  testWidgets('tapping yesterday in the strip logs yesterday; a future day is not tappable', (tester) async {
    final environment = await KomitTestEnvironment.create(tester, additionalHabitTitles: ['Drink water']);
    final semantics = tester.ensureSemantics();
    await pumpKomitApp(tester, environment, theme: lightAppTheme);
    final water = await _habitTitled(tester, environment, 'Drink water');
    await tester.ensureVisible(_rowOf('Drink water'));
    await tester.pumpAndSettle();
    final yesterday = _today.addDays(-1);

    await tester.tapAt(_stripCellCenter(tester, 'Drink water', yesterday));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text('Done')));
    await settleWithDatabaseWork(tester);
    expect(await _logsOf(tester, environment, water.habit.id), {yesterday: water.objectives.single.id});

    await tester.tapAt(_stripCellCenter(tester, 'Drink water', _today.addDays(1)));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    final futureCells = find.semantics.byPredicate((node) => node.label == 'Thursday, October 29: not available yet');
    expect(futureCells, findsWidgets);
    for (final node in futureCells.evaluate()) {
      expect(node.getSemanticsData().hasAction(SemanticsAction.customAction), isFalse);
    }
    semantics.dispose();
    await environment.dispose(tester);
  });

  testWidgets('the header counts only the habits scheduled today', (tester) async {
    final environment = await KomitTestEnvironment.create(
      tester,
      additionalHabitTitles: ['Drink water', 'Meditate', 'Stretch', 'Journal'],
    );
    final repository = _repositoryOf(environment);
    final journal = await _habitTitled(tester, environment, 'Journal');
    final database = environment.database;
    const everyDayButWednesdayMask = everyWeekdayMask & ~(1 << (DateTime.wednesday - 1));
    await tester.runAsync(() async {
      await (database.update(database.habits)..where((habit) => habit.id.equals(journal.habit.id))).write(
        const HabitsCompanion(scheduledWeekdayMask: Value(everyDayButWednesdayMask)),
      );
      // Logged although off schedule: it counts in neither number.
      for (final title in ['Morning run', 'Read before bed', 'Drink water', 'Journal']) {
        final habit = (await repository.watchActiveHabits().first).firstWhere((habit) => habit.habit.title == title);
        await repository.logObjectiveForDay(
          habitId: habit.habit.id,
          objectiveId: habit.objectives.first.id,
          day: _today,
        );
      }
    });
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    expect(find.text('3/5 done today'), findsOneWidget);
    await environment.dispose(tester);
  });

  testWidgets('an archived habit leaves the dashboard and appears under Archived', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await tester.tap(find.text('Morning run'));
    await settleWithDatabaseWork(tester);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive habit'));
    await settleWithDatabaseWork(tester);

    expect(find.text('Morning run'), findsNothing);
    expect(find.text('Morning run archived'), findsOneWidget);
    // The undo message floats over the end of the list.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archived (1)'));
    await settleWithDatabaseWork(tester);
    expect(find.text('Morning run'), findsOneWidget);
    await environment.dispose(tester);
  });

  testWidgets('the Move down screen reader action reorders the habits for good', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final semantics = tester.ensureSemantics();
    await pumpKomitApp(tester, environment, theme: lightAppTheme);
    final moveDownIdentifier = CustomSemanticsAction.getIdentifier(const CustomSemanticsAction(label: 'Move down'));
    final runningRow = find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label.startsWith('Morning run,') &&
          (data.customSemanticsActionIds?.contains(moveDownIdentifier) ?? false);
    });

    tester.semantics.performAction(runningRow, SemanticsAction.customAction, args: moveDownIdentifier);
    await settleWithDatabaseWork(tester);

    final habits = await tester.runAsync(() => _repositoryOf(environment).watchActiveHabits().first);
    expect(habits!.map((habit) => habit.habit.title), ['Read before bed', 'Morning run']);
    semantics.dispose();
    await environment.dispose(tester);
  });
}
