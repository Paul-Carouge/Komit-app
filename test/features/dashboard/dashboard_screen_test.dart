import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/mascot/komo_mascot.dart';

import '../../support/komit_test_app.dart';

/// Long enough to be ellipsized in the collapsed bar of a compact phone.
const String _longUserName = 'Maximilien-Alexandre';

void main() {
  for (final textScaleFactor in [1.0, 2.0]) {
    testWidgets('the collapsed greeting stays left of Komo at ${textScaleFactor}x text', (tester) async {
      final environment = await KomitTestEnvironment.create(tester, userName: _longUserName);
      await pumpKomitApp(tester, environment, theme: lightAppTheme, textScaleFactor: textScaleFactor);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      final collapsedTitle = find.descendant(
        of: find.byType(NavigationToolbar),
        matching: find.text('Hello, $_longUserName!'),
      );
      final firstAction = find.descendant(of: find.byType(AppBar), matching: find.byType(KomoMascot));
      expect(collapsedTitle, findsOneWidget);
      expect(tester.getRect(collapsedTitle).right, lessThanOrEqualTo(tester.getRect(firstAction).left));
      await environment.dispose(tester);
    });
  }

  testWidgets('the log sheet opened from a habit row paints above the navigation bar', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme);

    await tester.tap(find.byTooltip('Log today').first);
    await tester.pumpAndSettle();

    final sheet = tester.renderObject(find.byType(BottomSheet));
    final navigationBar = tester.renderObject(find.byType(NavigationBar));
    final hitAtNavigationBar = tester.hitTestOnBinding(tester.getCenter(find.byType(NavigationBar)));
    final hitTargets = hitAtNavigationBar.path.map((entry) => entry.target).toList();
    expect(hitTargets, contains(sheet));
    expect(hitTargets.whereType<RenderObject>().where((target) => identical(target, navigationBar)), isEmpty);
    await environment.dispose(tester);
  });
}
