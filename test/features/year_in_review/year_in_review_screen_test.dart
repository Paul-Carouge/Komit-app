import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/domain/achievements.dart';
import 'package:komit/domain/habit_statistics.dart';
import 'package:komit/domain/year_in_review.dart';
import 'package:komit/features/shared/shared_widgets.dart';
import 'package:komit/features/year_in_review/year_in_review_share_card.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:komit/router.dart';

import '../../support/komit_test_app.dart';

/// Mid-December: the review covers the seeded history, January 1 to today.
final DateTime _december15 = DateTime(2026, 12, 15, 10);
final CalendarDay _december15Day = CalendarDay.fromDateTime(_december15);

/// WCAG 1.4.4: text must stay usable at 200 %.
const double _largestSupportedTextScaleFactor = 2;

YearInReview _review({
  required int habitId,
  int successDayCount = 120,
  bool hasLongestStreak = true,
  List<Achievement> achievementsUnlocked = const [Achievement.perfectWeek],
}) => YearInReview(
  year: 2026,
  lastDay: _december15Day,
  successDayCount: successDayCount,
  longestStreak: hasLongestStreak ? YearStreak(habitId: habitId, length: 21, unit: StreakUnit.days) : null,
  mostRegularWeekday: DateTime.tuesday,
  bestMonth: DateTime.march,
  mostKeptHabit: HabitYearSuccess(habitId: habitId, successDayCount: 90),
  achievementsUnlocked: achievementsUnlocked,
);

/// A year with fewer success days than a full review needs: every other value is empty, as the domain
/// computes it for such a year.
YearInReview _quietReview({required int successDayCount}) => YearInReview(
  year: 2026,
  lastDay: _december15Day,
  successDayCount: successDayCount,
  longestStreak: null,
  mostRegularWeekday: null,
  bestMonth: null,
  mostKeptHabit: null,
  achievementsUnlocked: const [],
);

Future<void> _openReview(
  WidgetTester tester,
  KomitTestEnvironment environment, {
  YearInReview? review,
  FakeImageShareService? shareService,
  double textScaleFactor = 1,
  Locale locale = const Locale('en'),
}) async {
  final router = await pumpKomitApp(
    tester,
    environment,
    theme: lightAppTheme,
    now: _december15,
    textScaleFactor: textScaleFactor,
    locale: locale,
    overrides: [
      if (review != null) yearInReviewProvider.overrideWithValue(review),
      if (shareService != null) imageShareServiceProvider.overrideWithValue(shareService),
    ],
  );
  // Pushed like from the dashboard card, so "Done" has a screen to go back to.
  unawaited(router.push(AppRoutes.yearInReview));
  await tester.pumpAndSettle();
}

int _cardCount(WidgetTester tester) => tester.widget<StepProgressCells>(find.byType(StepProgressCells)).stepCount;

/// Komo's line on each card, in order, moving on with the bottom button.
Future<List<String>> _readNarrations(WidgetTester tester) async {
  final narrations = <String>[];
  for (var card = 0; card < _cardCount(tester); card++) {
    final bubbleText = find.descendant(
      of: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_SpeechBubble'),
      matching: find.byType(Text),
    );
    narrations.add(tester.widget<Text>(bubbleText).data!);
    if (_nextButton.evaluate().isEmpty) break;
    await tester.tap(_nextButton);
    await tester.pumpAndSettle();
  }
  return narrations;
}

Future<void> _goToLastCard(WidgetTester tester) async {
  final lastIndex = _cardCount(tester) - 1;
  for (var card = 0; card < lastIndex; card++) {
    await tester.tap(_nextButton);
    await tester.pumpAndSettle();
  }
}

final Finder _nextButton = find.byWidgetPredicate(
  (widget) => widget is Text && (widget.data == 'Next' || widget.data == 'Start'),
);

Finder _habitNameInShareCard(String habitTitle) =>
    find.descendant(of: find.byType(YearInReviewShareCard), matching: find.textContaining(habitTitle));

void main() {
  final localizations = lookupAppLocalizations(const Locale('en'));

  testWidgets('a full year tells every card in order, then closes with "Done"', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(tester, environment);

    expect(_cardCount(tester), 8);
    expect(find.text('Your year with Komit'), findsOneWidget);
    expect(find.text('January 1 to December 15'), findsOneWidget);
    expect(find.byTooltip('Previous card'), findsNothing, reason: 'the first card has nothing behind it');
    expect(await _readNarrations(tester), [
      localizations.yearInReviewIntroNarration,
      localizations.yearInReviewSuccessDaysNarration,
      localizations.yearInReviewStreakNarration,
      localizations.yearInReviewWeekdayNarration,
      localizations.yearInReviewMonthNarration,
      localizations.yearInReviewHabitNarration,
      localizations.yearInReviewAchievementsNarration,
      localizations.yearInReviewOutroNarration(2027),
    ]);

    await tester.tap(find.byTooltip('Previous card'));
    await tester.pumpAndSettle();
    expect(find.text(localizations.yearInReviewAchievementsNarration), findsOneWidget);
    await tester.tap(_nextButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Morning run'), findsOneWidget, reason: 'back on the dashboard');
    await environment.dispose(tester);
  });

  testWidgets('a tap anywhere on a card or a swipe moves to the next card', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(tester, environment, review: _review(habitId: environment.runningHabitId));

    await tester.tap(find.text('Your year with Komit'));
    await tester.pumpAndSettle();
    expect(find.text('success days'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('days in a row'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Morning run'), findsOneWidget, reason: 'the streak names its habit on screen');
    await environment.dispose(tester);
  });

  testWidgets('a card without data is skipped', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(
      tester,
      environment,
      review: _review(habitId: environment.runningHabitId, hasLongestStreak: false, achievementsUnlocked: const []),
    );

    expect(_cardCount(tester), 6);
    final narrations = await _readNarrations(tester);
    expect(narrations, isNot(contains(localizations.yearInReviewStreakNarration)));
    expect(narrations, isNot(contains(localizations.yearInReviewAchievementsNarration)));
    expect(narrations, contains(localizations.yearInReviewWeekdayNarration));
    await environment.dispose(tester);
  });

  testWidgets('a quiet year gets three kind cards and no empty numbers', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(tester, environment, review: _quietReview(successDayCount: 3));

    expect(_cardCount(tester), 3);
    expect(await _readNarrations(tester), [
      localizations.yearInReviewIntroNarration,
      localizations.yearInReviewQuietNarration,
      localizations.yearInReviewQuietOutroNarration(2027),
    ]);
    await tester.tap(find.byTooltip('Previous card'));
    await tester.pumpAndSettle();
    expect(find.text('You succeeded on 3 days this year. Each one counts.'), findsOneWidget);
    expect(find.text('success days'), findsNothing);
    await environment.dispose(tester);
  });

  testWidgets('a year without any success gets a kind start, and nothing to share', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(
      tester,
      environment,
      review: _quietReview(successDayCount: 0),
      shareService: FakeImageShareService(),
    );

    await tester.tap(_nextButton);
    await tester.pumpAndSettle();
    expect(find.text(localizations.yearInReviewEmptyNarration), findsOneWidget);
    expect(find.text(localizations.yearInReviewEmptyMessage), findsOneWidget);
    await tester.tap(_nextButton);
    await tester.pumpAndSettle();
    expect(find.byType(YearInReviewShareCard), findsNothing);
    await environment.dispose(tester);
  });

  testWidgets('the shared image hides habit names until the user shows them', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final shareService = FakeImageShareService();
    await _openReview(
      tester,
      environment,
      review: _review(habitId: environment.runningHabitId),
      shareService: shareService,
    );
    await _goToLastCard(tester);

    expect(find.byType(YearInReviewShareCard), findsOneWidget);
    expect(_habitNameInShareCard('Morning run'), findsNothing);
    expect(find.text(localizations.yearInReviewHabitNamesHidden), findsOneWidget);

    await tester.ensureVisible(find.text('Show habit names'));
    await tester.tap(find.text('Show habit names'));
    await tester.pumpAndSettle();
    expect(_habitNameInShareCard('Morning run'), findsWidgets);
    expect(find.text(localizations.yearInReviewHabitNamesShown), findsOneWidget);

    await tester.ensureVisible(find.text('Share the image'));
    await tester.tap(find.text('Share the image'));
    await _waitForRealWork(tester, until: () => shareService.sharedPngs.isNotEmpty);
    expect(shareService.sharedPngs, hasLength(1));
    final png = shareService.sharedPngs.single;
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    // IHDR width and height, big-endian, right after the 8-byte signature and the chunk header.
    final header = ByteData.sublistView(png, 16, 24);
    expect((header.getUint32(0), header.getUint32(4)), (1080, 1920));
    await environment.dispose(tester);
  });

  testWidgets('a failed share explains itself in a message', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await _openReview(
      tester,
      environment,
      review: _review(habitId: environment.runningHabitId),
      shareService: FakeImageShareService(error: Exception('No app can receive images')),
    );
    await _goToLastCard(tester);

    await tester.ensureVisible(find.text('Share the image'));
    await tester.tap(find.text('Share the image'));
    await _waitForRealWork(tester, until: () => find.text(localizations.yearInReviewShareFailed).evaluate().isNotEmpty);
    expect(find.text(localizations.yearInReviewShareFailed), findsOneWidget);
    await environment.dispose(tester);
  });

  for (final locale in const [Locale('en'), Locale('fr')]) {
    testWidgets('every card lays out at 200 % text on a compact phone ($locale)', (tester) async {
      final environment = await KomitTestEnvironment.create(tester);
      await _openReview(
        tester,
        environment,
        textScaleFactor: _largestSupportedTextScaleFactor,
        locale: locale,
        shareService: FakeImageShareService(),
      );
      final cardLocalizations = lookupAppLocalizations(locale);
      final cardCount = _cardCount(tester);
      for (var card = 0; card < cardCount; card++) {
        // Scrolling to the end lays out the whole card, not only what fits on screen.
        await tester.drag(find.byType(SingleChildScrollView).hitTestable().first, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (card < cardCount - 1) {
          await tester.tap(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  (widget.data == cardLocalizations.yearInReviewNextCard ||
                      widget.data == cardLocalizations.yearInReviewStart),
            ),
          );
          await tester.pumpAndSettle();
        }
      }
      expect(find.text(cardLocalizations.yearInReviewShareImage), findsOneWidget);
      await environment.dispose(tester);
    });
  }

  testWidgets('the first and last cards meet the tap target, label and contrast guidelines', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    final semantics = tester.ensureSemantics();
    await _openReview(tester, environment, shareService: FakeImageShareService());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await _goToLastCard(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
    await environment.dispose(tester);
  });

  testWidgets('outside December 1 to January 15 the screen says when the review opens', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    await pumpKomitApp(tester, environment, theme: lightAppTheme, location: AppRoutes.yearInReview);

    expect(find.text('Your year in review opens on December 1.'), findsOneWidget);
    await environment.dispose(tester);
  });
}

/// Rendering the image to PNG needs real time: lets it run in small steps until [until] holds,
/// so a slow machine waits longer instead of failing.
Future<void> _waitForRealWork(WidgetTester tester, {required bool Function() until}) async {
  const step = Duration(milliseconds: 50);
  const maximumWait = Duration(seconds: 10);
  for (var waited = Duration.zero; waited < maximumWait && !until(); waited += step) {
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
