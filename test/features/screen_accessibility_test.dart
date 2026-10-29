import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/router.dart';

import '../support/komit_test_app.dart';

/// WCAG 1.4.4: text must stay usable at 200 %.
const double _largestSupportedTextScaleFactor = 2;

/// Every main screen, by route, built from the seeded environment's running habit.
Map<String, String> _screenLocations(KomitTestEnvironment environment) => {
  'dashboard': AppRoutes.habits,
  'details': AppRoutes.habitDetails(environment.runningHabitId),
  'editor': AppRoutes.habitEditor(environment.runningHabitId),
  'statistics': AppRoutes.habitStatistics(environment.runningHabitId, komitTestNow.year),
  'settings': AppRoutes.settings,
  'notes': AppRoutes.notes,
  'achievements': AppRoutes.achievements,
};

/// Content each screen shows once loaded, so a test never passes on a loading or error state.
Finder _loadedContentOf(String screenName) => switch (screenName) {
  'editor' => find.byType(EditableText),
  'statistics' => find.text('Days logged'),
  'settings' => find.text('Your name'),
  'notes' => find.text('Run slower on Mondays.'),
  'achievements' => find.text('Perfect week'),
  _ => find.text('Morning run'),
};

const List<String> _screenNames = ['dashboard', 'details', 'editor', 'statistics', 'settings', 'notes', 'achievements'];

void main() {
  for (final (themeName, theme) in [('light', lightAppTheme), ('dark', darkAppTheme)]) {
    for (final screenName in _screenNames) {
      testWidgets('$screenName ($themeName) lays out at 200 % text without overflow', (tester) async {
        final environment = await KomitTestEnvironment.create(tester);
        await pumpKomitApp(
          tester,
          environment,
          theme: theme,
          location: _screenLocations(environment)[screenName]!,
          textScaleFactor: _largestSupportedTextScaleFactor,
        );
        expect(_loadedContentOf(screenName), findsWidgets);
        // Scrolling to the end lays out every section, not only the first screenful.
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -3000));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await environment.dispose(tester);
      });

      testWidgets('$screenName ($themeName) meets the tap target, label and contrast guidelines', (tester) async {
        final environment = await KomitTestEnvironment.create(tester);
        final semantics = tester.ensureSemantics();
        await pumpKomitApp(tester, environment, theme: theme, location: _screenLocations(environment)[screenName]!);
        expect(_loadedContentOf(screenName), findsWidgets);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        semantics.dispose();
        await environment.dispose(tester);
      });
    }
  }
}
