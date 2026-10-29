import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/archived_habits/archived_habits_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/habit_details/habit_details_screen.dart';
import 'features/habit_editor/habit_editor_screen.dart';
import 'features/navigation/scaffold_with_navigation_bar.dart';
import 'features/notes/note_editor_screen.dart';
import 'features/notes/notes_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
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
      if (!isOnboardingComplete && !isOnOnboarding) return AppRoutes.onboarding;
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
      GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
      GoRoute(path: AppRoutes.archivedHabits, builder: (context, state) => const ArchivedHabitsScreen()),
      GoRoute(path: AppRoutes.newHabit, builder: (context, state) => const HabitEditorScreen(habitId: null)),
      GoRoute(
        path: '/habit/:habitId',
        builder: (context, state) => HabitDetailsScreen(habitId: _integerPathParameter(state, 'habitId')),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => HabitEditorScreen(habitId: _integerPathParameter(state, 'habitId')),
          ),
          GoRoute(
            path: 'statistics/:year',
            builder: (context, state) => HabitStatisticsScreen(
              habitId: _integerPathParameter(state, 'habitId'),
              year: _integerPathParameter(state, 'year'),
            ),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.newNote, builder: (context, state) => const NoteEditorScreen(noteId: null)),
      GoRoute(
        path: '/note/:noteId',
        builder: (context, state) => NoteEditorScreen(noteId: _integerPathParameter(state, 'noteId')),
      ),
    ],
  );
}

/// Safe because the top-level redirect sends any non-integer path parameter back home.
int _integerPathParameter(GoRouterState state, String name) => int.parse(state.pathParameters[name]!);
