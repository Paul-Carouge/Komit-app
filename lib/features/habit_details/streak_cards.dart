import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/game_badges.dart';
import '../../core/ui/game_card.dart';
import '../../core/ui/game_text.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';

class StreakCards extends StatelessWidget {
  const StreakCards({required this.streaks, super.key});

  final StreakSummary streaks;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StreakCard(
              icon: LucideIcons.flame,
              label: localizations.currentStreak,
              value: localizations.dayCount(streaks.currentStreakDays),
              faceColor: komitColors.streakFace,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: _StreakCard(
              icon: LucideIcons.trophy,
              label: localizations.bestStreak,
              value: localizations.dayCount(streaks.bestStreakDays),
              faceColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.icon, required this.label, required this.value, required this.faceColor});

  final IconData icon;
  final String label;
  final String value;
  final Color faceColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foregroundColor = foregroundColorReadableOn(faceColor);
    return MergeSemantics(
      child: GameCard(
        color: faceColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GameBadge(icon: icon, color: depthShadeOf(faceColor), size: AppSizes.smallBadge),
            const SizedBox(height: AppSpacing.small),
            Text(label, style: textTheme.labelLarge?.copyWith(color: foregroundColor)),
            const SizedBox(height: AppSpacing.small),
            GameTitle(
              value,
              isHeader: false,
              onColor: faceColor,
              style: textTheme.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
      ),
    );
  }
}
