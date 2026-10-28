import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/core/ui/game_button.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/features/onboarding/onboarding_screen.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:komit/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _homeText = 'home screen';

Future<SharedPreferences> _pumpOnboarding(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.habits, builder: (context, state) => const Text(_homeText)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(SettingsRepository(preferences))],
      child: MaterialApp.router(
        theme: lightAppTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

/// The test window is short: the step actions may sit below the fold of the scrolling layout.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets('walks through the three steps and saves the first name', (tester) async {
    final preferences = await _pumpOnboarding(tester);
    expect(find.text("Hi, I'm Komo."), findsOneWidget);
    expect(find.text('Restore from a backup'), findsOneWidget);

    await _scrollToAndTap(tester, find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Paul');
    await _scrollToAndTap(tester, find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('A gentle nudge in the evening?'), findsOneWidget);
    expect(find.text('Allow notifications'), findsOneWidget);

    await _scrollToAndTap(tester, find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text(_homeText), findsOneWidget);
    final settings = SettingsRepository(preferences).readSettings();
    expect(settings.isOnboardingComplete, isTrue);
    expect(settings.userName, 'Paul');
  });

  testWidgets('skipping the name step leaves no name', (tester) async {
    final preferences = await _pumpOnboarding(tester);

    await _scrollToAndTap(tester, find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Typo');
    await _scrollToAndTap(tester, find.text('Skip'));
    await tester.pumpAndSettle();
    await _scrollToAndTap(tester, find.text('Later'));
    await tester.pumpAndSettle();

    expect(SettingsRepository(preferences).readSettings().userName, isNull);
  });

  testWidgets('the back button returns to the previous step', (tester) async {
    await _pumpOnboarding(tester);

    await _scrollToAndTap(tester, find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('What should I call you?'), findsOneWidget);

    await tester.tap(find.byType(GameBackButton));
    await tester.pumpAndSettle();

    expect(find.text("Hi, I'm Komo."), findsOneWidget);
  });

  testWidgets('announces the current step to screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboarding(tester);

    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    semantics.dispose();
  });
}
