import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/core/ui/game_badges.dart';
import 'package:komit/core/ui/game_button.dart';
import 'package:komit/core/ui/game_card.dart';
import 'package:komit/core/ui/game_text.dart';

Widget _app(Widget child, {ThemeData? theme, double textScale = 1}) => MaterialApp(
  theme: theme ?? lightAppTheme,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _labelTop(WidgetTester tester, String label) => tester.getTopLeft(find.text(label)).dy;

void main() {
  final recordedFeedbackTypes = <String?>[];

  setUp(() {
    recordedFeedbackTypes.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') recordedFeedbackTypes.add(call.arguments as String?);
        return null;
      },
    );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  group('GameButton', () {
    testWidgets('sinks under the finger with a haptic tick, then springs back and fires once', (tester) async {
      var pressCount = 0;
      await tester.pumpWidget(_app(GameButton(label: 'Save changes', onPressed: () => pressCount++)));
      final restingTop = _labelTop(tester, 'Save changes');

      final gesture = await tester.startGesture(tester.getCenter(find.text('Save changes')));
      await tester.pumpAndSettle();
      expect(_labelTop(tester, 'Save changes'), moreOrLessEquals(restingTop + AppDepth.button));
      expect(recordedFeedbackTypes, ['HapticFeedbackType.selectionClick']);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_labelTop(tester, 'Save changes'), moreOrLessEquals(restingTop));
      expect(pressCount, 1);
    });

    testWidgets('disabled: does not sink, vibrate or fire, and says so to screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const GameButton(label: 'Save changes', onPressed: null)));
      final restingTop = _labelTop(tester, 'Save changes');

      final gesture = await tester.startGesture(tester.getCenter(find.text('Save changes')));
      await tester.pumpAndSettle();
      expect(_labelTop(tester, 'Save changes'), restingTop);
      expect(recordedFeedbackTypes, isEmpty);
      await gesture.up();

      expect(
        tester.getSemantics(find.text('Save changes')),
        matchesSemantics(label: 'Save changes', isButton: true, hasEnabledState: true),
      );
      semantics.dispose();
    });

    testWidgets('is one button for screen readers, labeled by its text, with its selected state', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(GameButton(label: 'English', isSelected: true, onPressed: () {})));

      expect(
        tester.getSemantics(find.text('English')),
        matchesSemantics(
          label: 'English',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('activates from the keyboard', (tester) async {
      var pressCount = 0;
      await tester.pumpWidget(_app(GameButton(label: 'Continue', onPressed: () => pressCount++)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(pressCount, 1);
    });

    testWidgets('keeps at least a 48 dp touch target and grows with 200 % text', (tester) async {
      await tester.pumpWidget(_app(GameButton(label: 'Go', isCompact: true, onPressed: () {})));
      final regularSize = tester.getSize(find.byType(GameButton));
      expect(regularSize.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
      expect(regularSize.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));

      await tester.pumpWidget(_app(GameButton(label: 'Go', isCompact: true, onPressed: () {}), textScale: 2));

      expect(tester.getSize(find.byType(GameButton)).height, greaterThan(regularSize.height));
      expect(tester.takeException(), isNull);
    });

    for (final (themeName, theme) in [('light', lightAppTheme), ('dark', darkAppTheme)]) {
      testWidgets('every tone paints in the $themeName theme', (tester) async {
        await tester.pumpWidget(
          _app(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tone in GameButtonTone.values) GameButton(label: tone.name, tone: tone, onPressed: () {}),
                GameIconButton(icon: Icons.add, tooltip: 'Add', onPressed: () {}),
                GameCard(onTap: () {}, child: const Text('Card')),
                const GameBadge(icon: Icons.star, color: Colors.teal),
                const GameProgressBar(value: 0.5, color: Colors.teal),
              ],
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('GameIconButton reads its tooltip as its label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(GameIconButton(icon: Icons.settings, tooltip: 'Settings', onPressed: () {})));

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('GameTitle stays a single header text, even with its outline', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(const GameTitle('Read 10 pages', onColor: Colors.deepPurple)));

    expect(find.text('Read 10 pages'), findsOneWidget);
    expect(tester.getSemantics(find.text('Read 10 pages')), matchesSemantics(label: 'Read 10 pages', isHeader: true));
    semantics.dispose();
  });

  testWidgets('GameProgressBar announces its label and percentage', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 200,
          child: GameProgressBar(value: 0.5, color: Colors.amber, semanticLabel: 'Step'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.byType(GameProgressBar)), matchesSemantics(label: 'Step', value: '50 %'));
    semantics.dispose();
  });
}
