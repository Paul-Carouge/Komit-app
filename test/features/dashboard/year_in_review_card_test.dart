import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/router.dart';

import '../../support/komit_test_app.dart';

const String _cardTitle = 'Your 2026 in review';

void main() {
  testWidgets('the card shows from December 1 to January 15 only', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    for (final (now, isShown) in [
      (DateTime(2026, 11, 30, 10), false),
      (DateTime(2026, 12, 1, 10), true),
      (DateTime(2027, 1, 15, 10), true),
      (DateTime(2027, 1, 16, 10), false),
    ]) {
      await pumpKomitApp(tester, environment, theme: lightAppTheme, now: now);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text(_cardTitle), isShown ? findsOneWidget : findsNothing, reason: '$now');
      await tester.pumpWidget(const SizedBox());
    }
    await environment.dispose(tester);
  });

  testWidgets('a year without any log gets no card', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    // The seeded history ends in October 2026: December 2027 has nothing to tell yet.
    await pumpKomitApp(tester, environment, theme: lightAppTheme, now: DateTime(2027, 12, 15, 10));
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text('Your 2027 in review'), findsNothing);
    await environment.dispose(tester);
  });

  testWidgets('the card opens the review, and stays dismissed for that year', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final december = DateTime(2026, 12, 15, 10);
    await pumpKomitApp(tester, environment, theme: lightAppTheme, now: december);

    await tester.tap(find.text(_cardTitle));
    await tester.pumpAndSettle();
    expect(find.text('Your year with Komit'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dismiss the year in review'));
    await tester.pumpAndSettle();
    expect(find.text(_cardTitle), findsNothing);

    // A fresh start of the app reads the dismissal back from the preferences, even in January.
    await tester.pumpWidget(const SizedBox());
    await pumpKomitApp(tester, environment, theme: lightAppTheme, now: DateTime(2027, 1, 5, 10));
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text(_cardTitle), findsNothing);
    await environment.dispose(tester);
  });

  testWidgets('the statistics screen opens the review during the period only', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final statistics = AppRoutes.habitStatistics(environment.runningHabitId, 2026);
    await pumpKomitApp(tester, environment, theme: lightAppTheme, location: statistics);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('See your 2026 in review'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    await pumpKomitApp(
      tester,
      environment,
      theme: lightAppTheme,
      location: statistics,
      now: DateTime(2026, 12, 15, 10),
    );
    await tester.scrollUntilVisible(find.text('See your 2026 in review'), 300);
    await tester.tap(find.text('See your 2026 in review'));
    await tester.pumpAndSettle();
    expect(find.text('Your year with Komit'), findsOneWidget);
    await environment.dispose(tester);
  });
}
