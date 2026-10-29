import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/achievements.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../mascot/komo_mood.dart';
import '../mascot/komo_painter.dart';
import '../shared/shared_widgets.dart';
import 'achievement_texts.dart';

/// Below this width per tile, a tile's text wraps too much to read; grows with the font size.
const double _minimumTileWidth = 156;

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final habits = ref.watch(allHabitsProvider);
    final logs = ref.watch(allObjectiveIdByDayByHabitIdProvider);
    final unlockedAchievements = ref.watch(unlockedAchievementsProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeTitleSliverAppBar(title: localizations.achievementsTitle),
          switch ((habits, logs, unlockedAchievements)) {
            (_, _, final unlocked?) => SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                0,
                AppSpacing.screenGutter,
                AppSpacing.huge + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(child: _AchievementGrid(unlockedAchievements: unlocked)),
            ),
            (AsyncError(), _, _) || (AsyncLoading(), _, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: AsyncValueView(value: habits, retryProvider: allHabitsProvider, builder: (_) => const SizedBox()),
            ),
            _ => SliverFillRemaining(
              hasScrollBody: false,
              child: AsyncValueView(
                value: logs,
                retryProvider: allObjectiveIdByDayByHabitIdProvider,
                builder: (_) => const SizedBox(),
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  const _AchievementGrid({required this.unlockedAchievements});

  final Set<Achievement> unlockedAchievements;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final komitColors = KomitColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.achievementsSummary(unlockedAchievements.length, Achievement.values.length),
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.extraSmall),
        Text(localizations.achievementsIntro, style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText)),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = _minimumTileWidth * bodyTextScaleOf(context);
            final columnCount = (constraints.maxWidth / tileWidth).floor().clamp(1, Achievement.values.length);
            // Rows of equal-height tiles; a fixed-height grid would cut text at large font sizes.
            return Column(
              children: [
                for (var first = 0; first < Achievement.values.length; first += columnCount)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var column = 0; column < columnCount; column++) ...[
                            if (column > 0) const SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: first + column < Achievement.values.length
                                  ? _AchievementTile(
                                      achievement: Achievement.values[first + column],
                                      isUnlocked: unlockedAchievements.contains(Achievement.values[first + column]),
                                    )
                                  : const SizedBox(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Unlocked: Komo's open eyes on its orange square. Locked: a gray square with closed eyes,
/// waiting. The status is also written, so it never relies on color alone.
class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isUnlocked});

  final Achievement achievement;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final statusColor = isUnlocked ? komitColors.accentText : komitColors.mutedText;
    final tileContent = Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: const Size.square(AppSizes.mascotSmall),
              painter: KomoPainter(
                mood: isUnlocked ? KomoMood.idle : KomoMood.sleepy,
                animation: const AlwaysStoppedAnimation(0),
                palette: KomoPalette(
                  body: isUnlocked ? komitColors.mascotBody : colorScheme.surfaceContainerHighest,
                  eyes: isUnlocked ? komitColors.mascotFace : komitColors.mutedText,
                  groundShadow: Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            achievementTitle(localizations, achievement),
            style: textTheme.titleMedium?.copyWith(color: isUnlocked ? null : komitColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.extraSmall),
          Text(
            achievementDescription(localizations, achievement),
            style: textTheme.bodySmall?.copyWith(color: komitColors.mutedText),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Icon(isUnlocked ? LucideIcons.check : LucideIcons.lock, size: AppSizes.iconSmall, color: statusColor),
              const SizedBox(width: AppSpacing.extraSmall),
              Flexible(
                child: Text(
                  isUnlocked ? localizations.achievementUnlockedStatus : localizations.achievementLockedStatus,
                  style: textTheme.labelMedium?.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return MergeSemantics(
      child: isUnlocked
          ? SoftCard(padding: EdgeInsets.zero, child: tileContent)
          // Locked tiles are only outlined in the page, without the fill and lift of a card.
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant, width: AppSizes.emphasisBorderWidth),
                borderRadius: BorderRadius.circular(AppRadii.large),
              ),
              child: tileContent,
            ),
    );
  }
}
