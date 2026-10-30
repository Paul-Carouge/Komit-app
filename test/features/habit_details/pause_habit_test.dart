import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/core/theme/komit_icons.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/domain/habit_pause.dart';
import 'package:komit/providers.dart';
import 'package:komit/router.dart';

import '../../support/komit_test_app.dart';

final CalendarDay _today = CalendarDay.fromDateTime(komitTestNow);

/// WCAG 1.4.4: text must stay usable at 200 %.
const double _largestSupportedTextScaleFactor = 2;

/// Pauses can only start today or later, so a pause already running is written as if yesterday.
Future<void> _pauseRunningHabitSince(
  WidgetTester tester,
  KomitTestEnvironment environment, {
  required CalendarDay startDay,
  CalendarDay? endDay,
}) async {
  await tester.runAsync(
    () => HabitRepository(
      environment.database,
      now: () => startDay.asLocalDate,
    ).pauseHabit(environment.runningHabitId, startDay: startDay, endDay: endDay),
  );
}

Future<List<HabitPause>> _pausesOfRunningHabit(WidgetTester tester, KomitTestEnvironment environment) async {
  final habit = await tester.runAsync(
    () => HabitRepository(environment.database).watchHabitWithObjectives(environment.runningHabitId).first,
  );
  return habit!.pauses;
}

Future<void> _openActionsOfRunningHabit(WidgetTester tester) async {
  await tester.longPress(find.text('Morning run'));
  await tester.pumpAndSettle();
}

/// Rejects every pause, like a pause added meanwhile on the same days would.
class _OverlappingPauseHabitRepository extends HabitRepository {
  _OverlappingPauseHabitRepository(super.database) : super(now: () => komitTestNow);

  @override
  Future<void> pauseHabit(int habitId, {required CalendarDay startDay, CalendarDay? endDay}) =>
      Future.error(const InvalidPauseException('the habit is already paused then'));
}

void main() {
  testWidgets('pausing from a held row saves the pause and the row says until when', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await _openActionsOfRunningHabit(tester);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Pause Morning run'), findsOneWidget);
    expect(find.text('From Oct 28, until you resume'), findsOneWidget);
    await tester.tap(find.text('1 week'));
    await tester.pumpAndSettle();
    expect(find.text('Oct 28 to Nov 3 · 7 days'), findsOneWidget);
    await tester.tap(find.text('Pause habit'));
    await settleWithDatabaseWork(tester);

    expect(await _pausesOfRunningHabit(tester, environment), [HabitPause(startDay: _today, endDay: _today.addDays(6))]);
    expect(find.text('Morning run is paused'), findsOneWidget);
    expect(find.textContaining('Paused until Nov 3'), findsOneWidget);
    // Only the reading habit is still expected today.
    expect(find.text('0/1 done today'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleWithDatabaseWork(tester);
    expect(await _pausesOfRunningHabit(tester, environment), isEmpty);
    await environment.dispose(tester);
  });

  testWidgets('a pause starting tomorrow is planned, and the actions offer to cancel it', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await _openActionsOfRunningHabit(tester);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause habit'));
    await settleWithDatabaseWork(tester);
    expect(await _pausesOfRunningHabit(tester, environment), [HabitPause(startDay: _today.addDays(1))]);
    expect(find.text('Morning run pauses from Oct 29'), findsOneWidget);
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await _openActionsOfRunningHabit(tester);
    expect(find.text('Pause starts Oct 29'), findsOneWidget);
    await tester.tap(find.text('Cancel the planned pause'));
    await settleWithDatabaseWork(tester);

    expect(await _pausesOfRunningHabit(tester, environment), isEmpty);
    expect(find.text('Planned pause of Morning run cancelled'), findsOneWidget);
    await environment.dispose(tester);
  });

  testWidgets('resuming from the habit page ends the pause on yesterday', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final yesterday = _today.addDays(-1);
    await _pauseRunningHabitSince(tester, environment, startDay: yesterday);
    await pumpKomitApp(
      tester,
      environment,
      theme: lightAppTheme,
      location: AppRoutes.habitDetails(environment.runningHabitId),
    );

    expect(find.text('Paused until you resume'), findsOneWidget);
    expect(find.text('Your streak waits for you.'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await settleWithDatabaseWork(tester);

    expect(await _pausesOfRunningHabit(tester, environment), [HabitPause(startDay: yesterday, endDay: yesterday)]);
    expect(find.text('Morning run counts again from today'), findsOneWidget);
    expect(find.text('Paused until you resume'), findsNothing);
    await environment.dispose(tester);
  });

  testWidgets('a double tap on Resume ends the current pause and keeps the planned one', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final yesterday = _today.addDays(-1);
    await _pauseRunningHabitSince(tester, environment, startDay: yesterday, endDay: _today.addDays(1));
    await _pauseRunningHabitSince(tester, environment, startDay: _today.addDays(5), endDay: _today.addDays(8));
    await pumpKomitApp(
      tester,
      environment,
      theme: lightAppTheme,
      location: AppRoutes.habitDetails(environment.runningHabitId),
    );

    // Both taps land before the card rebuilds, as a quick double tap does.
    await tester.tap(find.text('Resume'));
    await tester.tap(find.text('Resume'));
    await settleWithDatabaseWork(tester);

    expect(await _pausesOfRunningHabit(tester, environment), [
      HabitPause(startDay: yesterday, endDay: yesterday),
      HabitPause(startDay: _today.addDays(5), endDay: _today.addDays(8)),
    ]);
    await environment.dispose(tester);
  });

  testWidgets('a rejected pause says why in a message and saves nothing', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(
      tester,
      environment,
      theme: lightAppTheme,
      overrides: [habitRepositoryProvider.overrideWithValue(_OverlappingPauseHabitRepository(environment.database))],
    );

    await _openActionsOfRunningHabit(tester);
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pause habit'));
    await settleWithDatabaseWork(tester);

    expect(find.text('This habit is already paused on some of these days. Pick other dates.'), findsOneWidget);
    expect(await _pausesOfRunningHabit(tester, environment), isEmpty);
    await environment.dispose(tester);
  });

  testWidgets('paused days read as paused on the dashboard strip and the yearly grid', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _pauseRunningHabitSince(tester, environment, startDay: _today.addDays(-1));
    final semantics = tester.ensureSemantics();
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    expect(find.bySemanticsLabel(RegExp(r'^Morning run, paused, .*Paused')), findsOneWidget);
    // Yesterday was logged before the pause was written: the log stays, but does not count.
    expect(find.semantics.byLabel('Tuesday, October 27: 5 km, paused, does not count'), findsOne);
    expect(find.semantics.byLabel('Wednesday, October 28: paused'), findsOne);
    expect(find.semantics.byLabel('Thursday, October 29: paused'), findsOne);

    await tester.tap(find.text('Morning run'));
    await settleWithDatabaseWork(tester);
    expect(find.semantics.byLabel('October 28, 2026: paused'), findsOne);
    expect(find.semantics.byLabel('November 15, 2026: paused'), findsOne);
    expect(find.semantics.byLabel('October 26, 2026: Walk'), findsOne);
    semantics.dispose();
    await environment.dispose(tester);
  });

  for (final (themeName, theme) in [('light', lightAppTheme), ('dark', darkAppTheme)]) {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      testWidgets('the pause sheet ($themeName, ${locale.languageCode}) fits a compact phone at 200 % text', (
        tester,
      ) async {
        final environment = await KomitTestEnvironment.create(tester);
        await pumpKomitApp(
          tester,
          environment,
          theme: theme,
          locale: locale,
          textScaleFactor: _largestSupportedTextScaleFactor,
          location: AppRoutes.habitDetails(environment.runningHabitId),
        );

        await tester.tap(find.byIcon(KomitIcons.ellipsis));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(KomitIcons.pause));
        await tester.pumpAndSettle();
        final sheetScrollable = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable));
        await tester.drag(sheetScrollable, const Offset(0, -2000));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
        await environment.dispose(tester);
      });
    }
  }
}
