import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/current_calendar_day.dart';
import 'features/splash/splash_handoff.dart';
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
  late final StreamSubscription<int> _reminderTapSubscription;

  @override
  void initState() {
    super.initState();
    // Payloads are mapped to a route in Dart: Flutter deep links stay disabled.
    _reminderTapSubscription = ref
        .read(reminderSchedulerProvider)
        .habitIdsOpenedFromReminders
        .listen((habitId) => _router.push(AppRoutes.habitDetails(habitId)));
  }

  @override
  void dispose() {
    unawaited(_reminderTapSubscription.cancel());
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
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        // Screens without an app bar still get transparent bars with readable icons.
        value: systemUiOverlayStyleFor(Theme.of(context).brightness),
        child: SplashHandoff(child: _ReminderSynchronizer(child: child!)),
      ),
    );
  }
}

/// Keeps scheduled reminders equal to the database, in the current language: after every
/// habit or log change, at midnight, and when the app resumes (the time zone, the language or
/// the notification permission may have changed meanwhile).
class _ReminderSynchronizer extends ConsumerStatefulWidget {
  const _ReminderSynchronizer({required this.child});

  final Widget child;

  @override
  ConsumerState<_ReminderSynchronizer> createState() => _ReminderSynchronizerState();
}

class _ReminderSynchronizerState extends ConsumerState<_ReminderSynchronizer> {
  late final AppLifecycleListener _lifecycleListener;
  Object? _lastSynchronizedInputs;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    ref.invalidate(notificationStatusProvider);
    await ref.read(reminderSchedulerProvider).refreshLocalTimeZone();
    if (mounted) _rebuildReminders();
  }

  void _rebuildReminders() {
    unawaited(
      ref
          .read(reminderSchedulerProvider)
          .rebuildReminders(ref.read(habitRepositoryProvider), AppLocalizations.of(context))
          .catchError(
            (Object error, StackTrace stackTrace) => ref
                .read(appLoggerProvider)
                .logError(event: 'reminder_rebuild_failed', error: error, stackTrace: stackTrace),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(activeHabitsProvider).value;
    final recentLogs = ref.watch(recentObjectiveIdByDayByHabitIdProvider).value;
    // Records compare their fields with ==, which is identity for the list and the map: any
    // new database emission, a new day or another language triggers one rebuild.
    final inputs = (habits, recentLogs, ref.watch(currentCalendarDayProvider), Localizations.localeOf(context));
    if (habits != null && recentLogs != null && inputs != _lastSynchronizedInputs) {
      _lastSynchronizedInputs = inputs;
      _rebuildReminders();
    }
    return widget.child;
  }
}
