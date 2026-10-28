import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'data/repositories/settings_repository.dart';
import 'providers.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The SIL Open Font License asks for its text to travel with the bundled Fraunces font.
  LicenseRegistry.addLicense(() async* {
    final frauncesLicense = await rootBundle.loadString('assets/fonts/Fraunces-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Fraunces'], frauncesLicense);
  });
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
