import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/app.dart';
import 'package:komit/core/app_logger.dart';
import 'package:komit/core/current_calendar_day.dart';
import 'package:komit/data/repositories/settings_repository.dart';
import 'package:komit/providers.dart';
import 'package:komit/services/reminder_scheduler.dart';

import 'support/komit_test_app.dart';

void main() {
  testWidgets('the dashboard still opens when the notifications setup fails', (tester) async {
    final environment = await KomitTestEnvironment.create(tester);
    Object? reportedError;
    final reminderScheduler = ReminderScheduler.startInitializing(
      initializePlugin: (_) async => throw const ReminderSchedulerUnavailableException('no notification service'),
      onInitializationFailed: (error, _) => reportedError = error,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(environment.database),
          settingsRepositoryProvider.overrideWithValue(SettingsRepository(environment.preferences)),
          reminderSchedulerProvider.overrideWithValue(reminderScheduler),
          appLoggerProvider.overrideWithValue(AppLogger(Directory.systemTemp.createTempSync('komit_test_logs'))),
          clockProvider.overrideWithValue(() => komitTestNow),
        ],
        child: const KomitApp(),
      ),
    );
    await settleWithDatabaseWork(tester);

    expect(find.text('Morning run'), findsOneWidget);
    expect(reportedError, isA<ReminderSchedulerUnavailableException>());
    expect(await tester.runAsync(() => reminderScheduler.isAvailable), isFalse);
    await environment.dispose(tester);
  });
}
