import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'game_surface_painter.dart';

/// An icon on a glossy, outlined square of [color], like an ability badge.
class GameBadge extends StatelessWidget {
  const GameBadge({required this.icon, required this.color, this.size = AppSizes.iconBadge, super.key});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: GameSurfacePainter(
          faceColor: color,
          outlineColor: komitColors.outline,
          glossColor: komitColors.gloss,
          cornerRadius: size * AppRadii.badge / AppSizes.iconBadge,
          outlineWidth: AppOutline.thin,
        ),
        child: Icon(icon, color: foregroundColorReadableOn(color), size: size * AppSizes.iconToBadgeRatio),
      ),
    );
  }
}

/// A non-interactive outlined pill: a legend entry, a small label.
class GameTag extends StatelessWidget {
  const GameTag({required this.label, this.leading, super.key});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final leading = this.leading;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: komitColors.neutralFace,
        shape: StadiumBorder(
          side: BorderSide(color: komitColors.outline, width: AppOutline.thin),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: AppSpacing.small)],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: komitColors.onNeutralFace),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chunky horizontal bar: an outlined track and a glossy fill that springs to its [value].
class GameProgressBar extends StatelessWidget {
  const GameProgressBar({
    required this.value,
    required this.color,
    this.height = AppSizes.progressBarHeight,
    this.semanticLabel,
    super.key,
  });

  /// Between 0 and 1.
  final double value;
  final Color color;
  final double height;

  /// Null hides the bar from screen readers, when the same value is already written next to it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final clampedValue = value.clamp(0.0, 1.0);
    final bar = SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: clampedValue),
        duration: motionAwareDuration(context, AppDurations.emphasized),
        curve: AppCurves.overshoot,
        builder: (context, animatedValue, _) => CustomPaint(
          size: Size.infinite,
          painter: _ProgressBarPainter(
            value: animatedValue,
            fillColor: color,
            trackColor: komitColors.emptyCell,
            outlineColor: komitColors.outline,
            glossColor: komitColors.gloss,
          ),
        ),
      ),
    );
    final semanticLabel = this.semanticLabel;
    if (semanticLabel == null) return ExcludeSemantics(child: bar);
    return Semantics(
      label: semanticLabel,
      value: '${(clampedValue * 100).round()} %',
      excludeSemantics: true,
      child: bar,
    );
  }
}

/// The darker band at the bottom of the fill and the gloss at its top, as shares of the bar height.
const double _progressDepthShare = 0.3;
const double _progressGlossShare = 0.28;

class _ProgressBarPainter extends CustomPainter {
  const _ProgressBarPainter({
    required this.value,
    required this.fillColor,
    required this.trackColor,
    required this.outlineColor,
    required this.glossColor,
  });

  /// May briefly exceed 1 or drop under 0 while the fill overshoots.
  final double value;
  final Color fillColor;
  final Color trackColor;
  final Color outlineColor;
  final Color glossColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = AppOutline.thin / 2;
    final track = RRect.fromRectAndRadius((Offset.zero & size).deflate(inset), Radius.circular(size.height / 2));
    final paint = Paint()..color = trackColor;
    canvas.drawRRect(track, paint);
    final fillWidth = track.width * value.clamp(0.0, 1.0);
    if (fillWidth > 0) {
      canvas.save();
      canvas.clipRRect(track);
      // Never narrower than its height, so a small value still reads as a rounded pill.
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(track.left, track.top, fillWidth < track.height ? track.height : fillWidth, track.height),
        Radius.circular(track.height / 2),
      );
      paint.color = fillColor;
      canvas.drawRRect(fill, paint);
      paint.color = depthShadeOf(fillColor);
      canvas.drawRect(
        Rect.fromLTRB(fill.left, fill.bottom - track.height * _progressDepthShare, fill.right, fill.bottom),
        paint,
      );
      paint.color = glossColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            fill.left + track.height / 4,
            fill.top + AppOutline.thin,
            fill.width - track.height / 2,
            track.height * _progressGlossShare,
          ),
          Radius.circular(track.height / 4),
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawRRect(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppOutline.thin
        ..color = outlineColor,
    );
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.glossColor != glossColor;
}
