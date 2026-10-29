import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/haptics.dart';
import '../../l10n/app_localizations.dart';
import '../shared/shared_widgets.dart';
import '../updates/update_prompt.dart';

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return StartupUpdateCheck(
      child: Scaffold(
        // Content scrolls under the frosted bar; screens pad their lists with the bottom inset.
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: FrostedGlass(
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              if (index != navigationShell.currentIndex) unawaited(KomitHaptics.selection());
              navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
            },
            destinations: [
              NavigationDestination(icon: const Icon(KomitIcons.house), label: localizations.habitsTab),
              NavigationDestination(icon: const Icon(KomitIcons.notebookPen), label: localizations.notesTab),
            ],
          ),
        ),
      ),
    );
  }
}
