import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/game_text.dart';
import 'komo_mascot.dart';

/// Komo above a short message and an optional next action: empty lists, errors, missing items.
class KomoEmptyState extends StatelessWidget {
  const KomoEmptyState({
    required this.mood,
    required this.title,
    this.message,
    this.action,
    this.mascotSize = AppSizes.mascotMedium,
    super.key,
  });

  final KomoMood mood;
  final String title;
  final String? message;

  /// Usually a single button naming the next step.
  final Widget? action;
  final double mascotSize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = this.message;
    final action = this.action;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.readableContentMaximumWidth),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KomoMascot(mood: mood, size: mascotSize),
              const SizedBox(height: AppSpacing.large),
              GameTitle(title, textAlign: TextAlign.center, style: textTheme.headlineSmall),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: KomitColors.of(context).mutedText),
                ),
              ],
              if (action != null) ...[const SizedBox(height: AppSpacing.extraLarge), action],
            ],
          ),
        ),
      ),
    );
  }
}
