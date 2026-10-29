import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';

import '../../support/komit_test_app.dart';

/// The Monday after the seeded "now": the recap covers the seeded week.
final DateTime _monday = DateTime(2026, 11, 2, 9);

void main() {
  testWidgets('the recap shows on Monday only, and stays dismissed for that week', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);
    expect(find.text('Last week'), findsNothing, reason: 'the seeded day is a Wednesday');
    await tester.pumpWidget(const SizedBox());

    await pumpKomitApp(tester, environment, theme: lightAppTheme, now: _monday);
    expect(find.text('Last week'), findsOneWidget);
    expect(find.text('4 success days · 4 fewer than the week before'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss the recap'));
    await tester.pumpAndSettle();
    expect(find.text('Last week'), findsNothing);

    // A fresh start of the app on the same Monday reads the dismissal back from the preferences.
    await tester.pumpWidget(const SizedBox());
    await pumpKomitApp(tester, environment, theme: lightAppTheme, now: _monday);
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.text('Last week'), findsNothing);
    await environment.dispose(tester);
  });
}
