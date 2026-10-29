import 'package:flutter/material.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/habit_statistics.dart';
import '../../l10n/app_localizations.dart';
import '../shared/shared_widgets.dart';

class StreakCards extends StatelessWidget {
  const StreakCards({required this.streaks, super.key});

  final StreakSummary streaks;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final formatStreakLength = switch (streaks.unit) {
      StreakUnit.days => localizations.dayCount,
      StreakUnit.weeks => localizations.weekCount,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StreakCard(
              icon: KomitIcons.flame,
              label: localizations.currentStreak,
              value: streaks.currentStreakLength,
              formatValue: formatStreakLength,
              backgroundColor: colorScheme.primaryContainer,
              accentColor: komitColors.accentText,
              valueColor: komitColors.accentText,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: _StreakCard(
              icon: KomitIcons.trophy,
              label: localizations.bestStreak,
              value: streaks.bestStreakLength,
              formatValue: formatStreakLength,
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
    required this.formatValue,
    required this.backgroundColor,
    required this.accentColor,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final int value;
  final String Function(int count) formatValue;
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
          borderRadius: BorderRadius.circular(AppRadii.tile),
          boxShadow: AppShadows.card(KomitColors.of(context).cardShadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconMedium, color: accentColor),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(label, style: textTheme.labelLarge?.copyWith(color: accentColor)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            AnimatedCount(
              value: value,
              format: formatValue,
              style: textTheme.headlineSmall?.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
