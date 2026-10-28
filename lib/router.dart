import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static String habitDetails(int habitId) => '/habit/$habitId';
  static String habitEditor(int habitId) => '/habit/$habitId/edit';
  static String habitStatistics(int habitId, int year) => '/habit/$habitId/statistics/$year';
  static String noteEditor(int noteId) => '/note/$noteId';
}

GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.habits,
    redirect: (context, state) {
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
      GoRoute(path: AppRoutes.newHabit, builder: (context, state) => const HabitEditorScreen(habitId: null)),
      GoRoute(
        path: '/habit/:habitId',
        builder: (context, state) =>
            _withValidIntParameters(state, ['habitId'], (ids) => HabitDetailsScreen(habitId: ids[0])),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                _withValidIntParameters(state, ['habitId'], (ids) => HabitEditorScreen(habitId: ids[0])),
          ),
          GoRoute(
            path: 'statistics/:year',
            builder: (context, state) => _withValidIntParameters(state, [
              'habitId',
              'year',
            ], (ids) => HabitStatisticsScreen(habitId: ids[0], year: ids[1])),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.newNote, builder: (context, state) => const NoteEditorScreen(noteId: null)),
      GoRoute(
        path: '/note/:noteId',
        builder: (context, state) =>
            _withValidIntParameters(state, ['noteId'], (ids) => NoteEditorScreen(noteId: ids[0])),
      ),
    ],
  );
}

/// Path parameters come from outside the app (deep links), so a malformed one goes back home.
Widget _withValidIntParameters(GoRouterState state, List<String> names, Widget Function(List<int> ids) build) {
  final ids = [for (final name in names) int.tryParse(state.pathParameters[name] ?? '')];
  if (ids.contains(null)) return const _RedirectHome();
  return build(ids.cast<int>());
}

class _RedirectHome extends StatelessWidget {
  const _RedirectHome();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) context.go(AppRoutes.habits);
    });
    return const SizedBox.shrink();
  }
}
