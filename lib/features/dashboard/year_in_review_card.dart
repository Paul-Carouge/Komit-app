import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../router.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';

/// From December 1 to January 15, an invitation to the year in review, until the user dismisses
/// it for that year.
class YearInReviewSection extends ConsumerWidget {
  const YearInReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(yearInReviewYearProvider);
    final dismissedYear = ref.watch(dismissedYearInReviewYearProvider);
    final isShown = year != null && dismissedYear != year && ref.watch(hasLogsInYearInReviewYearProvider);
    return AnimatedSwitcher(
      duration: motionAwareDuration(context, AppDurations.standard),
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: isShown
          ? Padding(
              key: ValueKey(year),
              padding: const EdgeInsets.only(bottom: AppSpacing.large),
              child: YearInReviewCard(
                year: year,
                onOpened: () => context.push(AppRoutes.yearInReview),
                onDismissed: () {
                  unawaited(KomitHaptics.selection());
                  unawaited(ref.read(dismissedYearInReviewYearProvider.notifier).dismiss(year));
                },
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class YearInReviewCard extends StatelessWidget {
  const YearInReviewCard({required this.year, required this.onOpened, required this.onDismissed, super.key});

  final int year;
  final VoidCallback onOpened;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    // The dismiss button sits beside the card, not inside it: the card merges its content into one
    // tappable node, which would swallow a second action.
    return Stack(
      children: [
        PressableCard(
          color: komitColors.highlightContainer,
          onTap: onOpened,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.large,
              AppSpacing.large,
              AppSizes.minimumTouchTarget,
              AppSpacing.large,
            ),
            child: Row(
              children: [
                const KomoMascot(mood: KomoMood.waving, size: AppSizes.mascotSmall, isAnimatedOnMount: false),
                const SizedBox(width: AppSpacing.large),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.yearInReviewDashboardTitle(year),
                        style: textTheme.titleMedium?.copyWith(color: komitColors.onHighlightContainer),
                      ),
                      const SizedBox(height: AppSpacing.extraSmall),
                      Text(
                        localizations.yearInReviewDashboardMessage,
                        style: textTheme.bodyMedium?.copyWith(color: komitColors.onHighlightContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: IconButton(
            tooltip: localizations.dismissYearInReview,
            onPressed: onDismissed,
            icon: Icon(KomitIcons.x, color: komitColors.onHighlightContainer),
          ),
        ),
      ],
    );
  }
}
