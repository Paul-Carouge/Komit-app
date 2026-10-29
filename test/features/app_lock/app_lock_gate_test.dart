import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/app_logger.dart';
import 'package:komit/core/current_calendar_day.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/features/app_lock/app_lock_gate.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:komit/router.dart';
import 'package:komit/services/app_lock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/komit_test_app.dart';

const MethodChannel _fakeAppLockChannel = MethodChannel('test/app_lock');
const String _secretContent = 'Morning run, 12 days in a row';

/// Plays AppLock.kt: answers each prompt with the next queued result, recording the calls.
class _FakeAppLockPlatform {
  _FakeAppLockPlatform({this.canAuthenticate = true}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _fakeAppLockChannel,
      _handle,
    );
  }

  bool canAuthenticate;
  final List<Completer<String>> pendingPrompts = [];
  bool? isRecentsScreenshotEnabled;

  AppLockService get service => AppLockService(channel: _fakeAppLockChannel, isSupported: true);

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'canAuthenticate':
        return canAuthenticate;
      case 'authenticate':
        final prompt = Completer<String>();
        pendingPrompts.add(prompt);
        return prompt.future;
      case 'setRecentsScreenshotEnabled':
        isRecentsScreenshotEnabled = (call.arguments as Map<Object?, Object?>)['isEnabled'] as bool?;
        return null;
      case 'setSecureWindow':
        return null;
    }
    throw MissingPluginException(call.method);
  }

  void answerLastPrompt(String result) => pendingPrompts.last.complete(result);
}

Future<void> _pumpLockedApp(
  WidgetTester tester,
  _FakeAppLockPlatform platform, {
  required DateTime Function() now,
}) async {
  SharedPreferences.setMockInitialValues({'app_lock_enabled': true});
  final preferences = await SharedPreferences.getInstance();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(preferences)),
        appLockServiceProvider.overrideWithValue(platform.service),
        appLoggerProvider.overrideWithValue(AppLogger(Directory.systemTemp.createTempSync('komit_test_logs'))),
        clockProvider.overrideWithValue(now),
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
        builder: (context, child) => AppLockGate(child: child!),
        home: const Scaffold(body: Center(child: Text(_secretContent))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _leaveAndComeBack(WidgetTester tester, {required void Function() whileAway}) async {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  whileAway();
  for (final state in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the lock screen hides the content until the prompt succeeds', (tester) async {
    final platform = _FakeAppLockPlatform();
    await _pumpLockedApp(tester, platform, now: () => komitTestNow);

    expect(find.text('Komit is locked'), findsOneWidget);
    expect(find.text(_secretContent), findsNothing);
    expect(platform.pendingPrompts, hasLength(1), reason: 'the prompt opens on its own at launch');
    expect(platform.isRecentsScreenshotEnabled, isFalse);

    platform.answerLastPrompt('succeeded');
    await tester.pumpAndSettle();

    expect(find.text(_secretContent), findsOneWidget);
    expect(find.text('Komit is locked'), findsNothing);
  });

  testWidgets('a cancelled prompt keeps the lock and offers to try again', (tester) async {
    final platform = _FakeAppLockPlatform();
    await _pumpLockedApp(tester, platform, now: () => komitTestNow);

    platform.answerLastPrompt('cancelled');
    await tester.pumpAndSettle();

    expect(find.text(_secretContent), findsNothing);
    expect(find.textContaining('Unlocking was cancelled'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    platform.answerLastPrompt('succeeded');
    await tester.pumpAndSettle();

    expect(platform.pendingPrompts, hasLength(2));
    expect(find.text(_secretContent), findsOneWidget);
  });

  testWidgets('locks again after the grace period away, not after a quick switch', (tester) async {
    final platform = _FakeAppLockPlatform();
    var now = komitTestNow;
    await _pumpLockedApp(tester, platform, now: () => now);
    platform.answerLastPrompt('succeeded');
    await tester.pumpAndSettle();

    await _leaveAndComeBack(tester, whileAway: () => now = now.add(const Duration(seconds: 20)));
    expect(find.text(_secretContent), findsOneWidget);

    await _leaveAndComeBack(tester, whileAway: () => now = now.add(appLockBackgroundGracePeriod));
    expect(find.text(_secretContent), findsNothing);
    expect(find.text('Komit is locked'), findsOneWidget);
  });

  group('the app lock setting', () {
    for (final (canAuthenticate, description) in [(false, 'is disabled and explains why'), (true, 'is enabled')]) {
      testWidgets('${canAuthenticate ? 'with' : 'without'} a screen lock on the phone $description', (tester) async {
        final platform = _FakeAppLockPlatform(canAuthenticate: canAuthenticate);
        final environment = await KomitTestEnvironment.create(tester);
        await pumpKomitApp(
          tester,
          environment,
          theme: lightAppTheme,
          location: AppRoutes.settings,
          appLockService: platform.service,
        );

        await tester.scrollUntilVisible(find.text('Lock Komit'), 200, scrollable: find.byType(Scrollable).first);
        final toggle = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Lock Komit'));
        expect(toggle.onChanged == null, !canAuthenticate);
        expect(
          find.text("Set up a screen lock in your phone's settings to use this."),
          canAuthenticate ? findsNothing : findsOneWidget,
        );
        await environment.dispose(tester);
      });
    }
  });
}
