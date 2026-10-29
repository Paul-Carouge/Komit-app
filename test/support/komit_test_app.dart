import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:komit/core/app_logger.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/current_calendar_day.dart';
import 'package:komit/core/habit_appearance.dart';
import 'package:komit/data/database/app_database.dart';
import 'package:komit/data/repositories/habit_repository.dart';
import 'package:komit/data/repositories/note_repository.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:komit/router.dart';
import 'package:komit/services/app_lock_service.dart';
import 'package:komit/services/notification_permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fixed "now", so logs, streaks and the two-week strip are the same on every run.
final DateTime komitTestNow = DateTime(2026, 10, 28, 10);

/// A compact phone, the smallest screen Komit is designed for.
const Size compactPhoneLogicalSize = Size(360, 640);
const double _compactPhoneDevicePixelRatio = 3;

/// Days of history given to the seeded habits, enough for streaks and several months of stats.
const int _seededHistoryDayCount = 120;

/// Every third day is left empty, so the grids show both logged and empty days.
const int _seededSkippedDayPeriod = 3;

const int _maximumCloseAttempts = 20;
const Duration _closeAttemptFakeTimeStep = Duration(milliseconds: 100);
const Duration _closeAttemptRealTimeStep = Duration(milliseconds: 10);

/// A database and preferences seeded like a real user's phone: two habits with history and a note.
class KomitTestEnvironment {
  KomitTestEnvironment._(this.database, this.preferences, this.runningHabitId);

  final AppDatabase database;
  final SharedPreferences preferences;
  final int runningHabitId;

  /// [additionalHabitTitles] adds plain habits without history, e.g. to make the dashboard scroll.
  static Future<KomitTestEnvironment> create(
    WidgetTester tester, {
    String userName = 'Paul',
    List<String> additionalHabitTitles = const [],
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    final environment = await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      final settingsRepository = SettingsRepository(preferences);
      await settingsRepository.saveUserName(userName);
      await settingsRepository.markOnboardingComplete();
      final database = AppDatabase(NativeDatabase.memory());
      final habitRepository = HabitRepository(database, now: () => komitTestNow);
      final runningHabitId = await habitRepository.saveHabit(
        HabitDraft(
          id: null,
          title: 'Morning run',
          description: 'Ten minutes count on busy days.',
          colorArgb: habitColorPaletteArgb[9],
          iconName: 'footprints',
          reminderMinuteOfDay: null,
          objectives: [
            ObjectiveDraft(id: null, title: 'Walk', colorArgb: habitColorPaletteArgb[3]),
            ObjectiveDraft(id: null, title: '5 km', colorArgb: habitColorPaletteArgb[9]),
          ],
        ),
      );
      final readingHabitId = await habitRepository.saveHabit(
        HabitDraft(
          id: null,
          title: 'Read before bed',
          description: '',
          colorArgb: habitColorPaletteArgb[5],
          iconName: 'bookOpen',
          reminderMinuteOfDay: null,
          objectives: [ObjectiveDraft(id: null, title: '20 pages', colorArgb: habitColorPaletteArgb[5])],
        ),
      );
      for (final (index, title) in additionalHabitTitles.indexed) {
        await habitRepository.saveHabit(
          HabitDraft(
            id: null,
            title: title,
            description: '',
            colorArgb: habitColorPaletteArgb[index % habitColorPaletteArgb.length],
            iconName: defaultHabitIconName,
            reminderMinuteOfDay: null,
            objectives: [ObjectiveDraft(id: null, title: 'Done', colorArgb: habitColorPaletteArgb[index])],
          ),
        );
      }
      final today = CalendarDay.fromDateTime(komitTestNow);
      for (final habitId in [runningHabitId, readingHabitId]) {
        final habit = (await habitRepository.watchHabitWithObjectives(habitId).first)!;
        for (var daysAgo = 1; daysAgo < _seededHistoryDayCount; daysAgo++) {
          if (daysAgo % _seededSkippedDayPeriod == 0) continue;
          await habitRepository.logObjectiveForDay(
            habitId: habitId,
            objectiveId: habit.objectives[daysAgo % habit.objectives.length].id,
            day: today.addDays(-daysAgo),
          );
        }
      }
      await NoteRepository(database).saveNote(noteId: null, content: 'Run slower on Mondays.');
      return KomitTestEnvironment._(database, preferences, runningHabitId);
    });
    return environment!;
  }

  /// Unmounts the app first: its database streams must be cancelled before the database closes.
  ///
  /// Closing needs both fake time (stream cleanup timers of the widget tree) and real time (the
  /// database's own work), so it alternates between the two until the database reports closed.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    var isClosed = false;
    unawaited(database.close().then((_) => isClosed = true));
    for (var attempt = 0; attempt < _maximumCloseAttempts && !isClosed; attempt++) {
      await tester.pump(_closeAttemptFakeTimeStep);
      await tester.runAsync(() => Future<void>.delayed(_closeAttemptRealTimeStep));
    }
    expect(isClosed, isTrue, reason: 'The test database did not close');
  }
}

/// Notification status and permission answers chosen by the test, recording what was asked.
class FakeNotificationPermissionService implements NotificationPermissionService {
  FakeNotificationPermissionService({this.status = NotificationStatus.enabled, this.isPermissionGranted = true});

  NotificationStatus status;
  bool isPermissionGranted;
  int permissionRequestCount = 0;
  int settingsOpenCount = 0;

  @override
  Future<NotificationStatus> readNotificationStatus() async => status;

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    if (isPermissionGranted) status = NotificationStatus.enabled;
    return isPermissionGranted;
  }

  @override
  Future<void> openNotificationSettings() async => settingsOpenCount++;
}

/// Renders the real router and screens at [location], on a compact phone by default.
Future<GoRouter> pumpKomitApp(
  WidgetTester tester,
  KomitTestEnvironment environment, {
  required ThemeData theme,
  String location = AppRoutes.habits,
  NotificationPermissionService? notificationPermissionService,
  AppLockService? appLockService,
  double textScaleFactor = 1,
  Size logicalSize = compactPhoneLogicalSize,
  DateTime? now,
}) async {
  tester.view.devicePixelRatio = _compactPhoneDevicePixelRatio;
  tester.view.physicalSize = logicalSize * _compactPhoneDevicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(environment.database),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(environment.preferences)),
        appLoggerProvider.overrideWithValue(AppLogger(Directory.systemTemp.createTempSync('komit_test_logs'))),
        clockProvider.overrideWithValue(() => now ?? komitTestNow),
        notificationPermissionServiceProvider.overrideWithValue(
          notificationPermissionService ?? FakeNotificationPermissionService(),
        ),
        if (appLockService != null) appLockServiceProvider.overrideWithValue(appLockService),
      ],
      child: _KomitTestApp(theme: theme, onRouterCreated: (createdRouter) => router = createdRouter),
    ),
  );
  router.go(location);
  await settleWithDatabaseWork(tester);
  return router;
}

/// Some database reads (one-off loads such as the editor's) only complete with real time, so
/// fake frames and short real waits alternate before the usual settle.
Future<void> settleWithDatabaseWork(WidgetTester tester) async {
  for (var step = 0; step < _databaseSettleSteps; step++) {
    await tester.runAsync(() => Future<void>.delayed(_closeAttemptRealTimeStep));
    await tester.pump(_closeAttemptFakeTimeStep);
  }
  await tester.pumpAndSettle();
}

const int _databaseSettleSteps = 5;

class _KomitTestApp extends ConsumerStatefulWidget {
  const _KomitTestApp({required this.theme, required this.onRouterCreated});

  final ThemeData theme;
  final ValueChanged<GoRouter> onRouterCreated;

  @override
  ConsumerState<_KomitTestApp> createState() => _KomitTestAppState();
}

class _KomitTestAppState extends ConsumerState<_KomitTestApp> {
  late final GoRouter _router = buildAppRouter(ref);

  @override
  void initState() {
    super.initState();
    widget.onRouterCreated(_router);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: widget.theme,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
