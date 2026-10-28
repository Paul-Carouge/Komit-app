import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/habit_repository.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class KomitApp extends ConsumerStatefulWidget {
  const KomitApp({super.key});

  @override
  ConsumerState<KomitApp> createState() => _KomitAppState();
}

class _KomitAppState extends ConsumerState<KomitApp> {
  late final GoRouter _router = buildAppRouter(ref);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: lightAppTheme,
      darkTheme: darkAppTheme,
      themeMode: settings.themeMode,
      locale: settings.languageCode == null ? null : Locale(settings.languageCode!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
      builder: (context, child) => _ReminderSynchronizer(child: child!),
    );
  }
}

/// Keeps scheduled reminders equal to the habits in the database, in the current language.
class _ReminderSynchronizer extends ConsumerStatefulWidget {
  const _ReminderSynchronizer({required this.child});

  final Widget child;

  @override
  ConsumerState<_ReminderSynchronizer> createState() => _ReminderSynchronizerState();
}

class _ReminderSynchronizerState extends ConsumerState<_ReminderSynchronizer> {
  Locale? _scheduledLocale;
  List<HabitWithObjectives>? _scheduledHabits;

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(allHabitsProvider).value;
    final locale = Localizations.localeOf(context);
    if (habits != null && (!identical(habits, _scheduledHabits) || locale != _scheduledLocale)) {
      _scheduledHabits = habits;
      _scheduledLocale = locale;
      unawaited(
        ref
            .read(reminderSchedulerProvider)
            .replaceAllReminders(habits, AppLocalizations.of(context))
            .catchError((Object error) => developer.log('Reminder scheduling failed', name: 'komit', error: error)),
      );
    }
    return widget.child;
  }
}
