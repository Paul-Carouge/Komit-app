import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_motion.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/splash/splash_handoff.dart';

const String _firstScreenText = 'first screen';

Widget _app({required bool areAnimationsDisabled, bool isFirstScreenReady = true}) => MaterialApp(
  theme: lightAppTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: areAnimationsDisabled),
    child: SplashHandoff(isFirstScreenReady: isFirstScreenReady, child: const Text(_firstScreenText)),
  ),
);

/// How opaque the splash face is: 1 while it fully hides the first screen.
double _splashOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(find.ancestor(of: _splashLayer, matching: find.byType(FadeTransition)).first)
    .opacity
    .value;

/// The orange layer repeating the Android splash.
Finder get _splashLayer => find.byWidgetPredicate(
  (widget) => widget is ColoredBox && widget.color == lightAppTheme.extension<KomitColors>()!.mascotBody,
);

void main() {
  testWidgets("the first frame repeats Komo's splash face, then fades it away", (tester) async {
    await tester.pumpWidget(_app(areAnimationsDisabled: false));

    expect(_splashLayer, findsOneWidget);
    expect(find.text(_firstScreenText), findsOneWidget);

    await tester.pump(AppDurations.splashHandoff ~/ 2);
    expect(_splashLayer, findsOneWidget);

    await tester.pumpAndSettle();
    expect(_splashLayer, findsNothing);
  });

  testWidgets('the handoff is skipped when the system removes animations', (tester) async {
    await tester.pumpWidget(_app(areAnimationsDisabled: true));

    expect(_splashLayer, findsNothing);
    expect(find.text(_firstScreenText), findsOneWidget);
  });

  testWidgets('the splash face waits for the first screen\'s data, then fades', (tester) async {
    const dataLoadDuration = Duration(milliseconds: 300);
    await tester.pumpWidget(_app(areAnimationsDisabled: false, isFirstScreenReady: false));
    await tester.pump(dataLoadDuration);
    // Before, the fade started on the first frame: at 300 ms the splash was 3 % opaque and the
    // loading screen showed through.
    expect(_splashOpacity(tester), 1);

    await tester.pumpWidget(_app(areAnimationsDisabled: false));
    await tester.pumpAndSettle();
    expect(_splashLayer, findsNothing);
  });

  testWidgets('a first screen that never loads still shows after the longest hold', (tester) async {
    await tester.pumpWidget(_app(areAnimationsDisabled: false, isFirstScreenReady: false));

    await tester.pump(maximumSplashHoldDuration);
    await tester.pumpAndSettle();

    expect(_splashLayer, findsNothing);
  });
}
