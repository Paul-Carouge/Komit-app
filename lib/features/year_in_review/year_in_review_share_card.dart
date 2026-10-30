import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Uint8List;

import '../../core/theme/app_theme.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/habit_statistics.dart';
import '../../domain/year_in_review.dart';
import '../../l10n/app_localizations.dart';
import '../mascot/komo_mascot.dart';
import 'year_in_review_texts.dart';

/// The shared image is laid out at a phone's logical size, then rendered at [_shareImagePixelRatio]:
/// a 1080 x 1920 PNG, the size story formats expect, far below the 10 MB the share sheet accepts.
const Size yearInReviewShareCardSize = Size(360, 640);
const double _shareImagePixelRatio = 3;

/// The year on one image, for the share sheet. Habit names appear only when
/// [isShowingHabitNames] is true; by default the image says how the year went, not what is tracked.
///
/// Always drawn in the light theme at a fixed size and text scale: the image is seen in other apps,
/// on unknown backgrounds, and must look the same whoever shares it.
class YearInReviewShareCard extends StatelessWidget {
  const YearInReviewShareCard({
    required this.review,
    required this.habitsById,
    required this.isShowingHabitNames,
    super.key,
  });

  final YearInReview review;
  final Map<int, HabitWithObjectives> habitsById;
  final bool isShowingHabitNames;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
      child: Theme(
        data: lightAppTheme,
        child: Builder(builder: _buildCard),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    String? habitTitleOf(int habitId) => isShowingHabitNames ? habitsById[habitId]?.habit.title : null;
    String withHabit(String label, String? habitTitle) => habitTitle == null ? label : '$label · $habitTitle';
    final streak = review.longestStreak;
    final weekday = review.mostRegularWeekday;
    final month = review.bestMonth;
    final mostKeptHabit = review.mostKeptHabit;
    final achievementCount = review.achievementsUnlocked.length;
    return SizedBox.fromSize(
      size: yearInReviewShareCardSize,
      child: ColoredBox(
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.huge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.yearInReviewShareHeading(review.year), style: textTheme.headlineLarge),
                        Text(
                          localizations.yearInReviewShareSubheading,
                          style: textTheme.bodyLarge?.copyWith(color: komitColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  // Resting pose: the image is a still, and a mid-hop Komo would look cut off.
                  const KomoMascot(mood: KomoMood.happy, isAnimatedOnMount: false),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              _ShareRow(
                value: '${review.successDayCount}',
                label: localizations.yearInReviewSuccessDaysLabel(review.successDayCount),
              ),
              if (streak != null)
                _ShareRow(
                  value: switch (streak.unit) {
                    StreakUnit.days => localizations.dayCount(streak.length),
                    StreakUnit.weeks => localizations.weekCount(streak.length),
                  },
                  label: withHabit(localizations.yearInReviewShareStreakLabel, habitTitleOf(streak.habitId)),
                ),
              if (weekday != null)
                _ShareRow(value: weekdayName(context, weekday), label: localizations.yearInReviewShareWeekdayLabel),
              if (month != null)
                _ShareRow(value: monthName(context, month), label: localizations.yearInReviewShareMonthLabel),
              if (mostKeptHabit != null)
                _ShareRow(
                  value: localizations.dayCount(mostKeptHabit.successDayCount),
                  label: withHabit(localizations.yearInReviewShareHabitLabel, habitTitleOf(mostKeptHabit.habitId)),
                ),
              if (achievementCount > 0)
                _ShareRow(
                  value: '$achievementCount',
                  label: localizations.yearInReviewShareAchievementsLabel(achievementCount),
                ),
              const Spacer(),
              Text(localizations.appTitle, style: textTheme.titleMedium?.copyWith(color: komitColors.accentText)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: KomitColors.of(context).accentText,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: KomitColors.of(context).mutedText),
          ),
        ],
      ),
    );
  }
}

/// Renders the [RepaintBoundary] holding a [YearInReviewShareCard] to PNG bytes, at its own size
/// whatever the scale of the on-screen preview around it.
Future<Uint8List> renderYearInReviewShareCardToPng(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) throw StateError('The share card is not on screen');
  final image = await boundary.toImage(pixelRatio: _shareImagePixelRatio);
  try {
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes == null) throw StateError('The share card could not be encoded as PNG');
    return pngBytes.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
