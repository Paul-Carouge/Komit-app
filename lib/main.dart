import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/app_logger.dart';
import 'data/database/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'providers.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (preferences, reminderScheduler, logger) = await (
    SharedPreferences.getInstance(),
    ReminderScheduler.initialize(),
    AppLogger.openInApplicationSupportDirectory(),
  ).wait;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(logger.logError(event: 'flutter_error', error: details.exception, stackTrace: details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(logger.logError(event: 'uncaught_error', error: error, stackTrace: stackTrace));
    // Handled: the error is recorded, and letting it propagate would only kill the isolate.
    return true;
  };
  // Edge-to-edge on every Android version, not only on 15 and later where the system forces it.
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(AppDatabase()),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(preferences)),
        reminderSchedulerProvider.overrideWithValue(reminderScheduler),
        appLoggerProvider.overrideWithValue(logger),
      ],
      child: const KomitApp(),
    ),
  );
}
