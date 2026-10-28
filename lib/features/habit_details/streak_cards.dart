import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
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
              backgroundColor: colorScheme.primaryContainer,
              accentColor: komitColors.accentText,
              valueColor: komitColors.accentText,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: _StreakCard(
              icon: LucideIcons.trophy,
              label: localizations.bestStreak,
              value: localizations.dayCount(streaks.bestStreakDays),
              backgroundColor: colorScheme.surfaceContainerLow,
              accentColor: komitColors.mutedText,
              valueColor: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.accentColor,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color accentColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadii.medium + AppSpacing.extraSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSpacing.large + AppSpacing.extraSmall, color: accentColor),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(label, style: textTheme.labelLarge?.copyWith(color: accentColor)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
