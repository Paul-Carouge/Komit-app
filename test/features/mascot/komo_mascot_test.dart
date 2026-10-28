import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_motion.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/mascot/komo_mascot.dart';
import 'package:komit/features/mascot/komo_pose.dart';

Widget _komoApp({required KomoMood mood, ThemeData? theme, bool areAnimationsDisabled = false}) => MaterialApp(
  theme: theme ?? lightAppTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: areAnimationsDisabled),
    child: Center(child: KomoMascot(mood: mood)),
  ),
);

void _expectSamePose(KomoPose actual, KomoPose expected) {
  expect(actual.bodyLift, moreOrLessEquals(expected.bodyLift));
  expect(actual.stretchX, moreOrLessEquals(expected.stretchX));
  expect(actual.stretchY, moreOrLessEquals(expected.stretchY));
  expect(actual.eyes, expected.eyes);
  expect(actual.eyeOpenness, moreOrLessEquals(expected.eyeOpenness));
  expect(actual.sproutTiltRadians, moreOrLessEquals(expected.sproutTiltRadians));
  expect(
    actual.leftArmAngleRadians,
    expected.leftArmAngleRadians == null ? isNull : moreOrLessEquals(expected.leftArmAngleRadians!),
  );
  expect(
    actual.rightArmAngleRadians,
    expected.rightArmAngleRadians == null ? isNull : moreOrLessEquals(expected.rightArmAngleRadians!),
  );
}

void main() {
  for (final mood in KomoMood.values) {
    test('$mood ends its cycle on the pose it started from, so stopping never jumps', () {
      _expectSamePose(KomoPose.of(mood, 1), KomoPose.of(mood, 0));
    });

    for (final (themeName, theme) in [('light', lightAppTheme), ('dark', darkAppTheme)]) {
      testWidgets('$mood paints in the $themeName theme', (tester) async {
        await tester.pumpWidget(_komoApp(mood: mood, theme: theme));
        await tester.pump(mood.cycleDuration ~/ 3);

        expect(tester.takeException(), isNull);
        expect(find.byType(KomoMascot), findsOneWidget);
      });
    }
  }

  testWidgets('stops animating after its budget, so an idle screen draws no frames', (tester) async {
    await tester.pumpWidget(_komoApp(mood: KomoMood.idle));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(AppDurations.mascotAnimationBudget + AppDurations.mascotBreathCycle);

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('never animates when the system asks to remove animations', (tester) async {
    await tester.pumpWidget(_komoApp(mood: KomoMood.happy, areAnimationsDisabled: true));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a mood change plays the new mood', (tester) async {
    await tester.pumpWidget(_komoApp(mood: KomoMood.idle));
    await tester.pump(AppDurations.mascotAnimationBudget + AppDurations.mascotBreathCycle);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_komoApp(mood: KomoMood.happy));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('is hidden from screen readers unless it has a label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightAppTheme,
        home: const Column(
          children: [
            KomoMascot(mood: KomoMood.idle),
            KomoMascot(mood: KomoMood.waving, semanticLabel: 'Komo waving'),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Komo waving'), findsOneWidget);
    semantics.dispose();
  });
}
