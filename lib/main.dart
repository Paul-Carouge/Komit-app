import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'providers.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (preferences, reminderScheduler) = await (SharedPreferences.getInstance(), ReminderScheduler.initialize()).wait;
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(AppDatabase()),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(preferences)),
        reminderSchedulerProvider.overrideWithValue(reminderScheduler),
      ],
      child: const KomitApp(),
    ),
  );
}
