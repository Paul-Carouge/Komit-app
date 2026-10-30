import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/habit_appearance.dart';
import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/repositories/habit_repository.dart';
import '../../domain/achievements.dart';
import '../../domain/habit_statistics.dart';
import '../../domain/year_in_review.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../achievements/achievement_appearance.dart';
import '../achievements/achievement_texts.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';
import '../shared/shared_widgets.dart';
import 'year_in_review_share_card.dart';
import 'year_in_review_texts.dart';

/// Below this height Komo shrinks when the text is large, so a card's words stay on screen.
const double _compactScreenHeight = 700;

/// Text scale from which Komo gives its room to the words on a short screen.
const double _largeTextScale = 1.5;

/// The share preview's height on screen; the image itself keeps [yearInReviewShareCardSize].
const double _sharePreviewHeight = 280;

/// Side of the little rotated square that turns the narration into a speech bubble from Komo.
const double _speechBubbleTailSize = 12;

/// One card of the review. Komo's mood follows the card: happy on a number to be proud of, calm on
/// a fact, waving to open and close.
enum _CardKind {
  intro(KomoMood.waving),
  successDays(KomoMood.happy),
  longestStreak(KomoMood.happy),
  mostRegularWeekday(KomoMood.idle),
  bestMonth(KomoMood.idle),
  mostKeptHabit(KomoMood.happy),
  achievements(KomoMood.happy),
  quietYear(KomoMood.idle),
  outro(KomoMood.waving);

  const _CardKind(this.komoMood);

  final KomoMood komoMood;
}

/// A quiet year gets three kind cards instead of near-empty numbers; a full year skips any card
/// it has nothing to say on.
List<_CardKind> _cardKindsFor(YearInReview review) => review.isQuietYear
    ? const [_CardKind.intro, _CardKind.quietYear, _CardKind.outro]
    : [
        _CardKind.intro,
        _CardKind.successDays,
        if (review.longestStreak != null) _CardKind.longestStreak,
        if (review.mostRegularWeekday != null) _CardKind.mostRegularWeekday,
        if (review.bestMonth != null) _CardKind.bestMonth,
        if (review.mostKeptHabit != null) _CardKind.mostKeptHabit,
        if (review.achievementsUnlocked.isNotEmpty) _CardKind.achievements,
        _CardKind.outro,
      ];

/// The year told by Komo, one full-screen card at a time, from December 1 to January 15.
class YearInReviewScreen extends ConsumerWidget {
  const YearInReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(yearInReviewProvider);
    if (review == null) {
      final localizations = AppLocalizations.of(context);
      final isInPeriod = ref.watch(yearInReviewYearProvider) != null;
      final hasLoadFailed =
          ref.watch(allHabitsProvider).hasError || ref.watch(allObjectiveIdByDayByHabitIdProvider).hasError;
      return Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: switch ((isInPeriod, hasLoadFailed)) {
          (false, _) => KomoEmptyState(mood: KomoMood.sleepy, title: localizations.yearInReviewNotYet),
          (true, true) => KomoEmptyState(
            mood: KomoMood.sleepy,
            title: localizations.loadErrorTitle,
            message: localizations.loadErrorMessage,
          ),
          // No review yet only means the logs are loading: a blink, no placeholder.
          (true, false) => const SizedBox.shrink(),
        },
      );
    }
    final habitsById = {
      for (final habit in ref.watch(allHabitsProvider).value ?? const <HabitWithObjectives>[]) habit.habit.id: habit,
    };
    return _YearInReviewStory(review: review, habitsById: habitsById);
  }
}

class _YearInReviewStory extends ConsumerStatefulWidget {
  const _YearInReviewStory({required this.review, required this.habitsById});

  final YearInReview review;
  final Map<int, HabitWithObjectives> habitsById;

  @override
  ConsumerState<_YearInReviewStory> createState() => _YearInReviewStoryState();
}

class _YearInReviewStoryState extends ConsumerState<_YearInReviewStory> {
  final _pageController = PageController();
  final _shareCardBoundaryKey = GlobalKey();
  int _cardIndex = 0;
  bool _isShowingHabitNames = false;
  bool _isSharing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showCard(int index) {
    final duration = motionAwareDuration(context, AppDurations.storyCard);
    if (duration == Duration.zero) {
      _pageController.jumpToPage(index);
    } else {
      unawaited(_pageController.animateToPage(index, duration: duration, curve: AppCurves.standard));
    }
  }

  Future<void> _shareImage() async {
    final localizations = AppLocalizations.of(context);
    // Read before awaiting: the user may close the review while the image encodes.
    final imageShareService = ref.read(imageShareServiceProvider);
    final appLogger = ref.read(appLoggerProvider);
    setState(() => _isSharing = true);
    try {
      final pngBytes = await renderYearInReviewShareCardToPng(_shareCardBoundaryKey);
      if (!mounted) return;
      await imageShareService.sharePng(pngBytes, chooserTitle: localizations.yearInReviewShareTitle);
    } on Object catch (error, stackTrace) {
      unawaited(appLogger.logError(event: 'year_in_review_share_failed', error: error, stackTrace: stackTrace));
      unawaited(KomitHaptics.error());
      if (mounted) showMessageSnackBar(context, localizations.yearInReviewShareFailed);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  double _komoSize(BuildContext context) {
    final isShortScreen = MediaQuery.sizeOf(context).height < _compactScreenHeight;
    if (!isShortScreen) return AppSizes.mascotLarge;
    return bodyTextScaleOf(context) >= _largeTextScale ? AppSizes.mascotSmall : AppSizes.mascotMedium;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final cardKinds = _cardKindsFor(widget.review);
    final cardIndex = math.min(_cardIndex, cardKinds.length - 1);
    final isLastCard = cardIndex == cardKinds.length - 1;
    final isShareSupported = ref.watch(imageShareServiceProvider).isSupported;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readableContentMaximumWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.small, AppSpacing.small, AppSpacing.extraLarge, 0),
                  child: SizedBox(
                    height: AppSizes.minimumTouchTarget,
                    child: Row(
                      children: [
                        const CloseButton(),
                        const Spacer(),
                        StepProgressCells(
                          currentStepIndex: cardIndex,
                          stepCount: cardKinds.length,
                          semanticLabel: localizations.yearInReviewProgress(cardIndex + 1, cardKinds.length),
                        ),
                      ],
                    ),
                  ),
                ),
                // Komo stays while the cards slide under it: it is the one telling the story.
                KomoMascot(
                  mood: cardKinds[cardIndex].komoMood,
                  size: _komoSize(context),
                  animationBudget: AppDurations.mascotHeaderAnimationBudget,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cardKinds.length,
                    onPageChanged: (index) {
                      unawaited(KomitHaptics.selection());
                      setState(() => _cardIndex = index);
                    },
                    itemBuilder: (context, index) => _buildCard(
                      context,
                      cardKinds[index],
                      index,
                      cardKinds.length,
                      isShareSupported: isShareSupported,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.small,
                    AppSpacing.screenGutter,
                    AppSpacing.large,
                  ),
                  child: Row(
                    children: [
                      // The first card has nothing behind it, like the onboarding's first step.
                      if (cardIndex > 0) ...[
                        IconButton(
                          tooltip: localizations.yearInReviewPreviousCard,
                          onPressed: () => _showCard(cardIndex - 1),
                          icon: const Icon(KomitIcons.chevronLeft),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                      ],
                      Expanded(
                        child: isLastCard
                            ? FilledButton(
                                onPressed: () => Navigator.of(context).maybePop(),
                                child: Text(localizations.yearInReviewDone),
                              )
                            : FilledButton.icon(
                                onPressed: () => _showCard(cardIndex + 1),
                                icon: const Icon(KomitIcons.arrowRight),
                                iconAlignment: IconAlignment.end,
                                label: Text(
                                  cardIndex == 0 ? localizations.yearInReviewStart : localizations.yearInReviewNextCard,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _CardKind kind, int index, int cardCount, {required bool isShareSupported}) {
    final localizations = AppLocalizations.of(context);
    final review = widget.review;
    // The non-null assertions below hold: _cardKindsFor lists a kind only when its value is set.
    final nextYear = review.year + 1;
    final isLastCard = index == cardCount - 1;
    // A tap anywhere moves on, like a story; the buttons below do the same for screen readers.
    final onTap = isLastCard ? null : () => _showCard(index + 1);
    return switch (kind) {
      _CardKind.intro => _StoryCard(
        narration: localizations.yearInReviewIntroNarration,
        onTap: onTap,
        content: _Hero(
          value: Text('${review.year}', style: _heroNumberStyle(context)),
          label: localizations.yearInReviewIntroLabel,
          caption: localizations.yearInReviewPeriod(
            DateFormat.MMMMd(Localizations.localeOf(context).toLanguageTag()).format(review.lastDay.asLocalDate),
          ),
        ),
      ),
      _CardKind.successDays => _StoryCard(
        narration: localizations.yearInReviewSuccessDaysNarration,
        onTap: onTap,
        content: _Hero(
          value: AnimatedCount(value: review.successDayCount, style: _heroNumberStyle(context)),
          label: localizations.yearInReviewSuccessDaysLabel(review.successDayCount),
          caption: localizations.yearInReviewSuccessDaysCaption,
        ),
      ),
      _CardKind.longestStreak => _buildStreakCard(context, review.longestStreak!, onTap),
      _CardKind.mostRegularWeekday => _StoryCard(
        narration: localizations.yearInReviewWeekdayNarration,
        onTap: onTap,
        content: _Hero(
          value: Text(weekdayName(context, review.mostRegularWeekday!), style: _heroWordStyle(context)),
          caption: localizations.yearInReviewWeekdayCaption,
          visual: _HighlightedCellStrip(
            labels: narrowWeekdayNames(context),
            highlightedIndex: review.mostRegularWeekday! - DateTime.monday,
          ),
        ),
      ),
      _CardKind.bestMonth => _StoryCard(
        narration: localizations.yearInReviewMonthNarration,
        onTap: onTap,
        content: _Hero(
          value: Text(monthName(context, review.bestMonth!), style: _heroWordStyle(context)),
          caption: localizations.yearInReviewMonthCaption,
          visual: _HighlightedCellStrip(labels: narrowMonthNames(context), highlightedIndex: review.bestMonth! - 1),
        ),
      ),
      _CardKind.mostKeptHabit => _buildMostKeptHabitCard(context, review.mostKeptHabit!, onTap),
      _CardKind.achievements => _StoryCard(
        narration: localizations.yearInReviewAchievementsNarration,
        onTap: onTap,
        content: _Hero(
          value: AnimatedCount(value: review.achievementsUnlocked.length, style: _heroNumberStyle(context)),
          label: localizations.yearInReviewAchievementsLabel(review.achievementsUnlocked.length),
          visual: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final achievement in review.achievementsUnlocked) _AchievementChip(achievement: achievement),
            ],
          ),
        ),
      ),
      _CardKind.quietYear => _StoryCard(
        narration: review.successDayCount == 0
            ? localizations.yearInReviewEmptyNarration
            : localizations.yearInReviewQuietNarration,
        onTap: onTap,
        content: Text(
          review.successDayCount == 0
              ? localizations.yearInReviewEmptyMessage
              : localizations.yearInReviewQuietMessage(review.successDayCount),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      _CardKind.outro when review.isQuietYear => _StoryCard(
        narration: localizations.yearInReviewQuietOutroNarration(nextYear),
        content: _Hero(value: Text('$nextYear', style: _heroNumberStyle(context))),
      ),
      _CardKind.outro => _StoryCard(
        narration: localizations.yearInReviewOutroNarration(nextYear),
        isMergedForScreenReaders: false,
        content: isShareSupported
            ? _buildShareSection(context)
            : _Hero(value: Text('$nextYear', style: _heroNumberStyle(context))),
      ),
    };
  }

  Widget _buildStreakCard(BuildContext context, YearStreak streak, VoidCallback? onTap) {
    final localizations = AppLocalizations.of(context);
    final habit = widget.habitsById[streak.habitId];
    return _StoryCard(
      narration: localizations.yearInReviewStreakNarration,
      onTap: onTap,
      content: _Hero(
        value: AnimatedCount(value: streak.length, style: _heroNumberStyle(context)),
        label: switch (streak.unit) {
          StreakUnit.days => localizations.yearInReviewStreakDaysLabel(streak.length),
          StreakUnit.weeks => localizations.yearInReviewStreakWeeksLabel(streak.length),
        },
        visual: habit == null ? null : _HabitLine(habit: habit),
      ),
    );
  }

  Widget _buildMostKeptHabitCard(BuildContext context, HabitYearSuccess mostKeptHabit, VoidCallback? onTap) {
    final localizations = AppLocalizations.of(context);
    final habit = widget.habitsById[mostKeptHabit.habitId];
    final textTheme = Theme.of(context).textTheme;
    return _StoryCard(
      narration: localizations.yearInReviewHabitNarration,
      onTap: onTap,
      content: Column(
        children: [
          if (habit != null) ...[
            HabitIconBadge(
              icon: habitIconForName(habit.habit.iconName),
              color: Color(habit.habit.colorArgb),
              size: AppSizes.habitIdentityIcon,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(habit.habit.title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.small),
          ],
          Text(
            localizations.yearInReviewHabitCaption(mostKeptHabit.successDayCount),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: KomitColors.of(context).accentText),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          // What is on screen is exactly what gets shared: the image is rendered from this preview.
          child: Semantics(
            image: true,
            label: _isShowingHabitNames
                ? localizations.yearInReviewSharePreviewWithNames
                : localizations.yearInReviewSharePreviewWithoutNames,
            excludeSemantics: true,
            child: IgnorePointer(
              child: Container(
                height: _sharePreviewHeight,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant, width: AppSizes.hairline),
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  child: FittedBox(
                    child: RepaintBoundary(
                      key: _shareCardBoundaryKey,
                      child: YearInReviewShareCard(
                        review: widget.review,
                        habitsById: widget.habitsById,
                        isShowingHabitNames: _isShowingHabitNames,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        SoftCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            title: Text(localizations.yearInReviewShowHabitNames),
            subtitle: Text(
              _isShowingHabitNames
                  ? localizations.yearInReviewHabitNamesShown
                  : localizations.yearInReviewHabitNamesHidden,
            ),
            value: _isShowingHabitNames,
            onChanged: (isShowing) {
              unawaited(KomitHaptics.selection());
              setState(() => _isShowingHabitNames = isShowing);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        // Outlined: sharing is optional, "Done" below stays the one filled action.
        OutlinedButton.icon(
          onPressed: _isSharing ? null : _shareImage,
          icon: const Icon(KomitIcons.share2),
          label: Text(localizations.yearInReviewShareImage),
        ),
      ],
    );
  }
}

TextStyle? _heroNumberStyle(BuildContext context) =>
    Theme.of(context).textTheme.displayLarge
        ?.copyWith(fontWeight: FontWeight.w800, color: KomitColors.of(context).accentText);

TextStyle? _heroWordStyle(BuildContext context) =>
    Theme.of(context).textTheme.displaySmall
        ?.copyWith(fontWeight: FontWeight.w800, color: KomitColors.of(context).accentText);

/// One card: Komo's line in a speech bubble at the top, then the card's content centered in the
/// space left. Scrolls when large text or a short screen needs it.
class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.narration, required this.content, this.onTap, this.isMergedForScreenReaders = true});

  final String narration;
  final Widget content;

  /// Null on the last card, whose content has its own controls.
  final VoidCallback? onTap;

  /// True when the card is only words and numbers: a screen reader then reads it in one go.
  final bool isMergedForScreenReaders;

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.extraLarge, vertical: AppSpacing.small),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 2 * AppSpacing.small)),
          child: Column(
            // Three equal gaps around two empty boxes: a third of the free room above the content,
            // two thirds below, so the answer stays close to Komo's question. (Spacers would need
            // IntrinsicHeight, and ListTile underestimates its intrinsic height.)
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SpeechBubble(text: narration),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.extraLarge),
                child: content,
              ),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
    final readableCard = isMergedForScreenReaders
        ? Semantics(container: true, liveRegion: true, child: MergeSemantics(child: card))
        : card;
    final onTap = this.onTap;
    if (onTap == null) return readableCard;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
      child: readableCard,
    );
  }
}

/// Komo's line, in a warm bubble whose tail points up at Komo.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    return Column(
      children: [
        // Drawn first, so the bubble covers its lower half and only a tip shows.
        Transform.translate(
          offset: const Offset(0, _speechBubbleTailSize / 2),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: _speechBubbleTailSize,
              height: _speechBubbleTailSize,
              decoration: BoxDecoration(
                color: komitColors.highlightContainer,
                borderRadius: BorderRadius.circular(AppSizes.hairline),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
          decoration: BoxDecoration(
            color: komitColors.highlightContainer,
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: komitColors.onHighlightContainer),
          ),
        ),
      ],
    );
  }
}

/// The card's big value, what it counts, a short explanation and an optional picture.
class _Hero extends StatelessWidget {
  const _Hero({required this.value, this.label, this.caption, this.visual});

  final Widget value;
  final String? label;
  final String? caption;
  final Widget? visual;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = this.label;
    final caption = this.caption;
    final visual = this.visual;
    return Column(
      children: [
        // A long weekday or month in a large font shrinks rather than breaking mid-word.
        FittedBox(fit: BoxFit.scaleDown, child: value),
        if (label != null) Text(label, textAlign: TextAlign.center, style: textTheme.titleLarge),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: KomitColors.of(context).mutedText),
          ),
        ],
        if (visual != null) ...[const SizedBox(height: AppSpacing.extraLarge), visual],
      ],
    );
  }
}

class _HabitLine extends StatelessWidget {
  const _HabitLine({required this.habit});

  final HabitWithObjectives habit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HabitIconBadge(icon: habitIconForName(habit.habit.iconName), color: Color(habit.habit.colorArgb)),
        const SizedBox(width: AppSpacing.medium),
        Flexible(child: Text(habit.habit.title, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}

/// Seven weekdays or twelve months drawn as day cells, the winning one filled with orange. The
/// winner is also written above in words, so the strip never carries the answer by color alone.
class _HighlightedCellStrip extends StatelessWidget {
  const _HighlightedCellStrip({required this.labels, required this.highlightedIndex});

  final List<String> labels;
  final int highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.extraSmall / 2),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: index == highlightedIndex ? colorScheme.primary : komitColors.emptyCell,
                          borderRadius: BorderRadius.circular(AppRadii.gridCell),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraSmall),
                    Text(
                      label,
                      style: index == highlightedIndex
                          ? labelStyle?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800)
                          : labelStyle?.copyWith(color: komitColors.mutedText),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.small,
        AppSpacing.small,
        AppSpacing.large,
        AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.tile),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HabitIconBadge(icon: achievementIcon(achievement), color: achievementFamily(achievement).color),
          const SizedBox(width: AppSpacing.small),
          Flexible(
            child: Text(
              achievementTitle(AppLocalizations.of(context), achievement),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
