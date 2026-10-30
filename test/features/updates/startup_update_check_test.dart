import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/current_calendar_day.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/features/updates/update_prompt.dart';
import 'package:komit/l10n/app_localizations.dart';
import 'package:komit/providers.dart';
import 'package:komit/services/app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/komit_test_app.dart';

const String _notes = '## Komit 2.4.0\n\n- **Nouveautés après une mise à jour**';

/// Plays the installed app and GitHub: a fixed installed version and nothing newer online.
class _FakeAppUpdateService extends AppUpdateService {
  _FakeAppUpdateService({required this.installedVersion});

  final String installedVersion;
  int checkCount = 0;

  @override
  bool get isSupported => true;

  @override
  Future<String> readInstalledVersion() async => installedVersion;

  @override
  Future<AvailableUpdate?> findAvailableUpdate() async {
    checkCount++;
    return null;
  }
}

Future<SettingsRepository> _pumpStartup(
  WidgetTester tester,
  _FakeAppUpdateService updateService, {
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final settingsRepository = SettingsRepository(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        appUpdateServiceProvider.overrideWithValue(updateService),
        clockProvider.overrideWithValue(() => komitTestNow),
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
        home: const StartupUpdateCheck(child: Scaffold(body: Text('home'))),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return settingsRepository;
}

Map<String, Object> _pendingUpdate(String version) => {
  'pending_update_version': version,
  'pending_update_release_notes': _notes,
};

void main() {
  testWidgets('the first launch of the pending version shows its notes once, then checks', (tester) async {
    final updateService = _FakeAppUpdateService(installedVersion: '2.4.0');
    final settingsRepository = await _pumpStartup(tester, updateService, preferences: _pendingUpdate('2.4.0'));

    expect(find.text('Welcome to 2.4.0'), findsOneWidget);
    expect(settingsRepository.readPendingUpdate(), isNull, reason: 'never shown twice');
    expect(updateService.checkCount, 0, reason: 'the check waits for the sheet');

    await tester.tap(find.text("Let's go"));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(updateService.checkCount, 1);
    expect(settingsRepository.readSettings().lastUpToDateCheckAt, komitTestNow);
  });

  testWidgets('a cancelled install keeps its notes for later, without a sheet', (tester) async {
    final updateService = _FakeAppUpdateService(installedVersion: '2.3.1');
    final settingsRepository = await _pumpStartup(tester, updateService, preferences: _pendingUpdate('2.4.0'));

    expect(find.text('Welcome to 2.4.0'), findsNothing);
    expect(settingsRepository.readPendingUpdate()?.version, '2.4.0');
    expect(updateService.checkCount, 1);
  });

  testWidgets('notes replaced by a newer install are dropped without a sheet', (tester) async {
    final updateService = _FakeAppUpdateService(installedVersion: '2.5.0');
    final settingsRepository = await _pumpStartup(tester, updateService, preferences: _pendingUpdate('2.4.0'));

    expect(find.text('Welcome to 2.4.0'), findsNothing);
    expect(settingsRepository.readPendingUpdate(), isNull);
  });
}
