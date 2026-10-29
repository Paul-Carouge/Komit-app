import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_motion.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/splash/splash_handoff.dart';

const String _firstScreenText = 'first screen';

Widget _app({required bool areAnimationsDisabled}) => MaterialApp(
  theme: lightAppTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: areAnimationsDisabled),
    child: const SplashHandoff(child: Text(_firstScreenText)),
  ),
);

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
}
