import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';

/// Paints the chunky "3D sticker" look shared by buttons, chips, badges and cards:
/// an optional soft drop shadow, an optional darker depth band, a face with a glossy top band,
/// and a dark outline around both.
class GameSurfacePainter extends CustomPainter {
  const GameSurfacePainter({
    required this.faceColor,
    required this.outlineColor,
    required this.glossColor,
    required this.cornerRadius,
    required this.outlineWidth,
    this.depth = 0,
    this.faceOffset = 0,
    this.depthColor,
    this.shadowColor,
    this.focusRingColor,
    this.glossLineHeight,
  });

  final Color faceColor;
  final Color outlineColor;
  final Color glossColor;
  final double cornerRadius;
  final double outlineWidth;

  /// Height of the band under the face; 0 for a flat card.
  final double depth;

  /// How far the face has sunk into its band, from 0 (rest) to [depth] (pressed).
  final double faceOffset;

  /// Defaults to [depthShadeOf] the face.
  final Color? depthColor;

  /// Null draws no drop shadow.
  final Color? shadowColor;

  /// Null when the control does not have keyboard focus.
  final Color? focusRingColor;

  /// Large surfaces (cards) get a thin highlight line of this height instead of a glossy band,
  /// which would wash out their content.
  final double? glossLineHeight;

  static const double _focusRingGap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cornerRadius);
    final bounds = Offset.zero & size;
    // Strokes are centered on the edge: inset them so the outline stays inside the layout box.
    final strokeInset = outlineWidth / 2;
    final paint = Paint()..isAntiAlias = true;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..color = outlineColor;

    if (shadowColor case final shadowColor?) {
      paint
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, AppDepth.cardShadowBlur / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.shift(const Offset(0, AppDepth.cardShadowOffset)), radius),
        paint,
      );
      paint.maskFilter = null;
    }

    if (depth > 0) {
      final band = RRect.fromRectAndRadius(bounds.deflate(strokeInset), radius);
      paint.color = depthColor ?? depthShadeOf(faceColor);
      canvas.drawRRect(band, paint);
      canvas.drawRRect(band, strokePaint);
    }

    final faceRect = Rect.fromLTRB(
      bounds.left,
      bounds.top + faceOffset,
      bounds.right,
      bounds.bottom - depth + faceOffset,
    ).deflate(strokeInset);
    final face = RRect.fromRectAndRadius(faceRect, radius);
    paint.color = faceColor;
    canvas.drawRRect(face, paint);

    // The gloss is a lighter band across the top of the face, inside the outline.
    canvas.save();
    canvas.clipRRect(face);
    paint.color = glossColor;
    final glossInset = outlineWidth;
    final glossLineHeight = this.glossLineHeight;
    canvas.drawRRect(
      glossLineHeight == null
          ? RRect.fromRectAndRadius(
              Rect.fromLTWH(
                faceRect.left + glossInset,
                faceRect.top + glossInset,
                faceRect.width - 2 * glossInset,
                faceRect.height * AppSizes.glossHeightRatio,
              ),
              Radius.circular(cornerRadius - glossInset),
            )
          : RRect.fromRectAndRadius(
              Rect.fromLTWH(
                faceRect.left + cornerRadius / 2,
                faceRect.top + glossInset * 2,
                faceRect.width - cornerRadius,
                glossLineHeight,
              ),
              Radius.circular(glossLineHeight / 2),
            ),
      paint,
    );
    canvas.restore();
    canvas.drawRRect(face, strokePaint);

    if (focusRingColor case final focusRingColor?) {
      strokePaint.color = focusRingColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds.inflate(_focusRingGap), Radius.circular(cornerRadius + _focusRingGap)),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(GameSurfacePainter oldDelegate) =>
      oldDelegate.faceColor != faceColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.glossColor != glossColor ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.outlineWidth != outlineWidth ||
      oldDelegate.depth != depth ||
      oldDelegate.faceOffset != faceOffset ||
      oldDelegate.depthColor != depthColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.focusRingColor != focusRingColor ||
      oldDelegate.glossLineHeight != glossLineHeight;
}
