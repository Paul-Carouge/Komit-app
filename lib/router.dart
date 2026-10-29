import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/achievements/achievements_screen.dart';
import 'features/archived_habits/archived_habits_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/habit_details/habit_details_screen.dart';
import 'features/habit_editor/habit_editor_screen.dart';
import 'features/navigation/scaffold_with_navigation_bar.dart';
import 'features/notes/note_editor_screen.dart';
import 'features/notes/notes_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/privacy_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/statistics/habit_statistics_screen.dart';
import 'providers.dart';

abstract final class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String habits = '/habits';
  static const String notes = '/notes';
  static const String settings = '/settings';
  static const String newHabit = '/habit/new';
  static const String newNote = '/note/new';
  static const String archivedHabits = '/archived';
  static const String achievements = '/achievements';
  static const String privacy = '/privacy';

  static String habitDetails(int habitId) => '/habit/$habitId';
  static String habitEditor(int habitId) => '/habit/$habitId/edit';
  static String habitStatistics(int habitId, int year) => '/habit/$habitId/statistics/$year';
  static String noteEditor(int noteId) => '/note/$noteId';
}

GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.habits,
    redirect: (context, state) {
      // Every path parameter in Komit is an integer id or year; anything else is a malformed link.
      final hasMalformedParameter = state.pathParameters.values.any((value) => int.tryParse(value) == null);
      if (hasMalformedParameter) return AppRoutes.habits;
      final isOnboardingComplete = ref.read(settingsControllerProvider).isOnboardingComplete;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;
      // The privacy screen is linked from the onboarding, before it completes.
      final isOnPrivacy = state.matchedLocation == AppRoutes.privacy;
      if (!isOnboardingComplete && !isOnOnboarding && !isOnPrivacy) return AppRoutes.onboarding;
      if (isOnboardingComplete && isOnOnboarding) return AppRoutes.habits;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ScaffoldWithNavigationBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.habits, builder: (context, state) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.notes, builder: (context, state) => const NotesScreen())],
          ),
        ],
      ),
      GoRoute(path: AppRoutes.settings, pageBuilder: (context, state) => _materialPage(state, const SettingsScreen())),
      GoRoute(path: AppRoutes.privacy, pageBuilder: (context, state) => _materialPage(state, const PrivacyScreen())),
      GoRoute(
        path: AppRoutes.archivedHabits,
        pageBuilder: (context, state) => _materialPage(state, const ArchivedHabitsScreen()),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        pageBuilder: (context, state) => _materialPage(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: AppRoutes.newHabit,
        pageBuilder: (context, state) => _materialPage(state, const HabitEditorScreen(habitId: null)),
      ),
      GoRoute(
        path: '/habit/:habitId',
        pageBuilder: (context, state) =>
            _materialPage(state, HabitDetailsScreen(habitId: _integerPathParameter(state, 'habitId'))),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) =>
                _materialPage(state, HabitEditorScreen(habitId: _integerPathParameter(state, 'habitId'))),
          ),
          GoRoute(
            path: 'statistics/:year',
            pageBuilder: (context, state) => _materialPage(
              state,
              HabitStatisticsScreen(
                habitId: _integerPathParameter(state, 'habitId'),
                year: _integerPathParameter(state, 'year'),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.newNote,
        pageBuilder: (context, state) => _materialPage(state, const NoteEditorScreen(noteId: null)),
      ),
      GoRoute(
        path: '/note/:noteId',
        pageBuilder: (context, state) =>
            _materialPage(state, NoteEditorScreen(noteId: _integerPathParameter(state, 'noteId'))),
      ),
    ],
  );
}

/// go_router 18 looks for the `material_ui` package's MaterialApp; Komit uses Flutter's, so
/// without an explicit page every pushed screen would appear without a transition, without the
/// predictive back animation and without hero flights.
Page<void> _materialPage(GoRouterState state, Widget screen) => MaterialPage(key: state.pageKey, child: screen);

/// Safe because the top-level redirect sends any non-integer path parameter back home.
int _integerPathParameter(GoRouterState state, String name) => int.parse(state.pathParameters[name]!);
