import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_motion.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/features/dashboard/dashboard_screen.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A narrow phone, where two cards side by side leave the least room for text.
const Size _phoneSize = Size(360, 760);

Future<void> _pumpDashboard(WidgetTester tester, {required double textScale}) async {
  tester.view.physicalSize = _phoneSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await tester.runAsync(() async {
    final repository = HabitRepository(database);
    for (final title in ['Meditation', 'Read 10 pages', 'Running', 'Water']) {
      await repository.saveHabit(
        HabitDraft(
          id: null,
          title: title,
          description: '',
          colorArgb: 0xFF42A5F5,
          iconName: 'target',
          reminderMinuteOfDay: null,
          objectives: const [ObjectiveDraft(id: null, title: 'Done', colorArgb: 0xFF66BB6A)],
        ),
      );
    }
  });
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(preferences)),
      ],
      child: MaterialApp(
        theme: lightAppTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    ),
  );
  // Lets the database streams deliver the habits.
  for (var frame = 0; frame < 5; frame++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

/// Unmounts the screen so its database stream subscriptions and Komo's animation end before the database closes.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(AppDurations.mascotAnimationBudget);
}

void main() {
  for (final textScale in [1.0, 2.0]) {
    testWidgets('habit cards fit their content at ${(textScale * 100).round()} % text', (tester) async {
      await _pumpDashboard(tester, textScale: textScale);

      expect(find.text('Meditation'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    });
  }

  testWidgets('large text stacks the habit cards in a single column', (tester) async {
    await _pumpDashboard(tester, textScale: 2);

    expect(
      tester.getTopLeft(find.text('Read 10 pages')).dy,
      greaterThan(tester.getTopLeft(find.text('Meditation')).dy),
    );
    expect(tester.getTopLeft(find.text('Read 10 pages')).dx, tester.getTopLeft(find.text('Meditation')).dx);
    await _unmount(tester);
  });
}
