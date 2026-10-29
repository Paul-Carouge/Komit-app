import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mascot/komo_mascot.dart';

/// What one celebration card says, and the color its burst takes.
class CelebrationCardContent {
  const CelebrationCardContent({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.burstColor,
  });

  /// What the celebration is about: the habit, or "Achievement unlocked".
  final String eyebrow;
  final String title;
  final String message;
  final Color burstColor;
}

/// Shows [cards] one after the other at the top of the screen. The cards never block the
/// screen: the "Undo" message and the list stay usable. Each one leaves after
/// [AppDurations.celebrationVisible], or at once when tapped.
void showCelebrationCards(OverlayState overlay, List<CelebrationCardContent> cards) {
  if (cards.isEmpty) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _CelebrationQueue(cards: cards, onFinished: entry.remove),
  );
  overlay.insert(entry);
}

class _CelebrationQueue extends StatefulWidget {
  const _CelebrationQueue({required this.cards, required this.onFinished});

  final List<CelebrationCardContent> cards;
  final VoidCallback onFinished;

  @override
  State<_CelebrationQueue> createState() => _CelebrationQueueState();
}

class _CelebrationQueueState extends State<_CelebrationQueue> {
  int _shownIndex = 0;

  void _showNext() {
    if (_shownIndex + 1 >= widget.cards.length) {
      widget.onFinished();
      return;
    }
    setState(() => _shownIndex++);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.small,
      left: AppSpacing.screenGutter,
      right: AppSpacing.screenGutter,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readableContentMaximumWidth),
          child: CelebrationCard(
            key: ValueKey(_shownIndex),
            content: widget.cards[_shownIndex],
            onDismissed: _showNext,
          ),
        ),
      ),
    );
  }
}

/// Komo hopping in front of a burst of color, next to what was achieved. Without animations,
/// the same card appears and leaves at once, with neither burst nor hop.
class CelebrationCard extends StatefulWidget {
  const CelebrationCard({required this.content, required this.onDismissed, super.key});

  final CelebrationCardContent content;
  final VoidCallback onDismissed;

  @override
  State<CelebrationCard> createState() => _CelebrationCardState();
}

/// The card drops in from this far above its place, as a share of its height.
const double _cardDropShare = 0.6;

class _CelebrationCardState extends State<CelebrationCard> with TickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(vsync: this, duration: AppDurations.emphasized);
  late final AnimationController _burst = AnimationController(vsync: this, duration: AppDurations.celebrationBurst);
  late final Timer _visibilityTimer;
  bool _isMotionReduced = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _visibilityTimer = Timer(AppDurations.celebrationVisible, () => unawaited(_dismiss()));
    unawaited(KomitHaptics.celebration());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMotionReduced = MediaQuery.disableAnimationsOf(context);
    if (_presence.value > 0 || _presence.isAnimating) return;
    if (_isMotionReduced) {
      _presence.value = 1;
    } else {
      unawaited(_presence.forward());
      unawaited(_burst.forward());
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    _visibilityTimer.cancel();
    if (!_isMotionReduced) await _presence.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _visibilityTimer.cancel();
    _presence.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final content = widget.content;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Material(
      color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(_dismiss()),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              SizedBox.square(
                dimension: AppSizes.mascotSmall,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (!_isMotionReduced)
                      Positioned.fill(
                        child: CelebrationBurst(progress: _burst, color: content.burstColor),
                      ),
                    const KomoMascot(
                      mood: KomoMood.happy,
                      size: AppSizes.mascotSmall,
                      animationBudget: AppDurations.mascotHeaderAnimationBudget,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content.eyebrow, style: textTheme.labelMedium?.copyWith(color: komitColors.accentText)),
                    Text(content.title, style: textTheme.titleLarge),
                    Text(content.message, style: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      onTapHint: localizations.dismissCelebration,
      child: AnimatedBuilder(
        animation: _presence,
        builder: (context, child) {
          final presence = AppCurves.standard.transform(_presence.value);
          return FractionalTranslation(
            translation: Offset(0, -_cardDropShare * (1 - presence)),
            child: Opacity(opacity: presence, child: child),
          );
        },
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large)),
            // A floating card casts its shadow in dark mode too, or it would merge with the page.
            shadows: AppShadows.lifted(colorScheme.shadow.withValues(alpha: AppOpacity.liftedShadow)),
          ),
          child: card,
        ),
      ),
    );
  }
}

/// Rays of [color] flying out from the center and fading, drawn once as [progress] goes to 1.
/// Painted by hand: a particle package would be a dependency for twelve strokes.
class CelebrationBurst extends StatelessWidget {
  const CelebrationBurst({required this.progress, required this.color, super.key});

  final Animation<double> progress;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _BurstPainter(progress: progress, color: color),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const int _rayCount = 12;

  /// Rays start at Komo's edge and end this far out, as shares of Komo's size.
  static const double _rayStartShare = 0.55;
  static const double _rayEndShare = 1.15;

  /// Every other ray is shorter, so the burst does not look like a clock face.
  static const double _shortRayShare = 0.6;
  static const double _rayLengthShare = 0.22;
  static const double _strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress.value;
    if (value <= 0 || value >= 1) return;
    final travel = Curves.easeOutCubic.transform(value);
    // Fully visible for the first half, then gone by the end.
    final opacity = (1 - Curves.easeIn.transform(value)).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity)
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final extent = size.shortestSide;
    for (var ray = 0; ray < _rayCount; ray++) {
      final angle = 2 * math.pi * ray / _rayCount;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final lengthShare = _rayLengthShare * (ray.isEven ? 1 : _shortRayShare);
      final outer = lerpDouble(_rayStartShare, _rayEndShare, travel)! * extent;
      final inner = outer - lengthShare * extent * (1 - travel);
      canvas.drawLine(center + direction * inner, center + direction * outer, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.color != color;
}
