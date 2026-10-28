import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'komo_mood.dart';
import 'komo_pose.dart';

/// Colors Komo is drawn with; resolved from the theme by the widget.
class KomoPalette {
  const KomoPalette({
    required this.body,
    required this.bodyShade,
    required this.outline,
    required this.face,
    required this.eyeHighlight,
    required this.gloss,
    required this.cheek,
    required this.sprout,
    required this.groundShadow,
    required this.dozeLetter,
    required this.sparkles,
  });

  final Color body;
  final Color bodyShade;

  /// The thick ink line around every part of Komo, like a sticker.
  final Color outline;
  final Color face;
  final Color eyeHighlight;
  final Color gloss;
  final Color cheek;
  final Color sprout;
  final Color groundShadow;
  final Color dozeLetter;
  final List<Color> sparkles;

  @override
  bool operator ==(Object other) =>
      other is KomoPalette &&
      other.body == body &&
      other.bodyShade == bodyShade &&
      other.outline == outline &&
      other.face == face &&
      other.eyeHighlight == eyeHighlight &&
      other.gloss == gloss &&
      other.cheek == cheek &&
      other.sprout == sprout &&
      other.groundShadow == groundShadow &&
      other.dozeLetter == dozeLetter &&
      listEquals(other.sparkles, sparkles);

  @override
  int get hashCode => Object.hash(
    body,
    bodyShade,
    outline,
    face,
    eyeHighlight,
    gloss,
    cheek,
    sprout,
    groundShadow,
    dozeLetter,
    Object.hashAll(sparkles),
  );
}

/// Komo's geometry, in a 100 × 100 design box. The launcher icon
/// (docs/design/komit-launcher-icon.svg and the Android drawables) reuses the eye shapes.
abstract final class KomoGeometry {
  static const double designBoxSize = 100;
  static const Rect body = Rect.fromLTRB(20, 34, 80, 88);
  static const double bodyCornerRadius = 22;
  static const double outlineWidth = 3.6;

  /// The lower band of the body is darker, like the side of a game button.
  static const double bodyShadeTop = 78;

  /// Glossy highlight across the top of the body.
  static const Rect gloss = Rect.fromLTRB(28, 39, 72, 47);
  static const double glossCornerRadius = 4;
  static const Offset groundShadowCenter = Offset(50, 93);
  static const double groundShadowRadiusX = 26;
  static const double groundShadowRadiusY = 3.6;

  /// Big, tall eyes carry Komo's expression; the launcher icon uses the same proportions.
  static const Offset leftEye = Offset(38.5, 60);
  static const Offset rightEye = Offset(61.5, 60);
  static const double eyeRadiusX = 6;
  static const double eyeRadiusY = 8;
  static const Offset eyeHighlightOffset = Offset(1.9, -3.2);
  static const double eyeHighlightRadius = 2.3;
  static const Offset eyeSparkOffset = Offset(-2.1, 3.4);
  static const double eyeSparkRadius = 1.1;
  static const double eyeArcHalfWidth = 6;
  static const double eyeArcHeight = 6;
  static const Offset leftCheek = Offset(27.5, 71);
  static const Offset rightCheek = Offset(72.5, 71);
  static const Size cheekSize = Size(9, 5.5);
  static const double faceStrokeWidth = 3.2;
  static const Offset mouthCenter = Offset(50, 71);
  static const double smileHalfWidth = 4.5;
  static const double smileDepth = 4;
  static const double softSmileHalfWidth = 3;
  static const double softSmileDepth = 2.2;
  static const double grinHalfWidth = 6.5;
  static const double grinDepth = 9;

  /// The grin starts slightly above the smile line so the open mouth stays centered.
  static const double grinTopOffset = 1.5;
  static const Offset sproutBase = Offset(50, 35);
  static const Offset sproutTip = Offset(51, 22);
  static const double sproutStemWidth = 3.4;

  /// The ink line drawn under the stem; wider than the stem so an edge shows on each side.
  static const double sproutStemOutlinedWidth = 7.8;
  static const Offset leftShoulder = Offset(23, 68);
  static const Offset rightShoulder = Offset(77, 68);
  static const double armLength = 16;
  static const double armThickness = 10;
  static const Offset sparkleOrigin = Offset(50, 58);
  static const double sparkleStartDistance = 34;
  static const double sparkleTravel = 14;
  static const double sparkleRadius = 5;

  /// Sparkles pop in at full size and shrink to this share as they fade away.
  static const double sparkleSmallestScale = 0.6;

  /// A four-point star: its waist is this share of its radius.
  static const double sparkleWaistRatio = 0.32;
  static const double sparkleStrokeWidth = 1.6;
  static const List<double> sparkleAnglesRadians = [-2.62, -1.92, -1.22, -0.52];
  static const Offset dozeOrigin = Offset(76, 30);
  static const Offset dozeTravel = Offset(8, -18);
  static const double dozeLetterSize = 8;
  static const double dozeStrokeWidth = 2.6;
}

/// Draws Komo for one frame of its [mood] animation; repaints on [animation] ticks only.
class KomoPainter extends CustomPainter {
  KomoPainter({required this.mood, required this.animation, required this.palette}) : super(repaint: animation);

  final KomoMood mood;
  final Animation<double> animation;
  final KomoPalette palette;

  final Paint _fillPaint = Paint()..isAntiAlias = true;
  final Paint _strokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final RRect _bodyShape = RRect.fromRectAndRadius(
    KomoGeometry.body,
    const Radius.circular(KomoGeometry.bodyCornerRadius),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final pose = KomoPose.of(mood, animation.value);
    canvas.save();
    canvas.scale(size.width / KomoGeometry.designBoxSize, size.height / KomoGeometry.designBoxSize);
    _paintGroundShadow(canvas, pose);
    canvas.save();
    // Squash and stretch are anchored at Komo's feet, so it stays grounded while bouncing.
    final feet = Offset(KomoGeometry.body.center.dx, KomoGeometry.body.bottom);
    canvas.translate(feet.dx, feet.dy + pose.bodyLift);
    canvas.scale(pose.stretchX, pose.stretchY);
    canvas.translate(-feet.dx, -feet.dy);
    _paintSprout(canvas, pose);
    _paintBody(canvas);
    _paintCheeks(canvas);
    _paintEyes(canvas, pose);
    _paintMouth(canvas, pose);
    // In front of the body, so a raised arm reads as a little mitten rather than a handle.
    _paintArms(canvas, pose);
    canvas.restore();
    if (pose.sparkleProgress case final sparkleProgress?) _paintSparkles(canvas, sparkleProgress);
    if (pose.dozeProgress case final dozeProgress?) _paintDoze(canvas, dozeProgress);
    canvas.restore();
  }

  void _outline(Canvas canvas, Path path, {double width = KomoGeometry.outlineWidth}) {
    _strokePaint
      ..color = palette.outline
      ..strokeWidth = width;
    canvas.drawPath(path, _strokePaint);
  }

  void _paintGroundShadow(Canvas canvas, KomoPose pose) {
    // The shadow shrinks while Komo is in the air.
    final liftRatio = (-pose.bodyLift / KomoGeometry.groundShadowRadiusX).clamp(0.0, 1.0);
    _fillPaint.color = palette.groundShadow;
    canvas.drawOval(
      Rect.fromCenter(
        center: KomoGeometry.groundShadowCenter,
        width: 2 * KomoGeometry.groundShadowRadiusX * (1 - liftRatio),
        height: 2 * KomoGeometry.groundShadowRadiusY,
      ),
      _fillPaint,
    );
  }

  void _paintArms(Canvas canvas, KomoPose pose) {
    for (final (shoulder, angle) in [
      (KomoGeometry.leftShoulder, pose.leftArmAngleRadians),
      (KomoGeometry.rightShoulder, pose.rightArmAngleRadians),
    ]) {
      if (angle == null) continue;
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(angle);
      final arm = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, -KomoGeometry.armThickness / 2, KomoGeometry.armLength, KomoGeometry.armThickness),
            const Radius.circular(KomoGeometry.armThickness / 2),
          ),
        );
      _fillPaint.color = palette.body;
      canvas.drawPath(arm, _fillPaint);
      _outline(canvas, arm);
      canvas.restore();
    }
  }

  void _paintSprout(Canvas canvas, KomoPose pose) {
    canvas.save();
    canvas.translate(KomoGeometry.sproutBase.dx, KomoGeometry.sproutBase.dy);
    canvas.rotate(pose.sproutTiltRadians);
    canvas.translate(-KomoGeometry.sproutBase.dx, -KomoGeometry.sproutBase.dy);
    final stem = Path()
      ..moveTo(KomoGeometry.sproutBase.dx, KomoGeometry.sproutBase.dy)
      ..quadraticBezierTo(50, 28, KomoGeometry.sproutTip.dx, KomoGeometry.sproutTip.dy);
    // Outline first, wider, then the green stem on top: a stroked line with an ink edge.
    _outline(canvas, stem, width: KomoGeometry.sproutStemOutlinedWidth);
    _strokePaint
      ..color = palette.sprout
      ..strokeWidth = KomoGeometry.sproutStemWidth;
    canvas.drawPath(stem, _strokePaint);
    // Two leaves, right one larger.
    final leaves = Path()
      ..moveTo(51, 23)
      ..cubicTo(54, 13, 63, 10, 70, 11)
      ..cubicTo(69, 19, 61, 25, 51, 23)
      ..close()
      ..moveTo(49, 25)
      ..cubicTo(46, 18, 40, 16, 34, 17)
      ..cubicTo(35, 23, 41, 27, 49, 25)
      ..close();
    _fillPaint.color = palette.sprout;
    canvas.drawPath(leaves, _fillPaint);
    _outline(canvas, leaves);
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    _fillPaint.color = palette.body;
    canvas.drawRRect(_bodyShape, _fillPaint);
    canvas.save();
    canvas.clipRRect(_bodyShape);
    _fillPaint.color = palette.bodyShade;
    canvas.drawRect(
      Rect.fromLTRB(
        KomoGeometry.body.left,
        KomoGeometry.bodyShadeTop,
        KomoGeometry.body.right,
        KomoGeometry.body.bottom,
      ),
      _fillPaint,
    );
    canvas.restore();
    _fillPaint.color = palette.gloss;
    canvas.drawRRect(
      RRect.fromRectAndRadius(KomoGeometry.gloss, const Radius.circular(KomoGeometry.glossCornerRadius)),
      _fillPaint,
    );
    _outline(canvas, Path()..addRRect(_bodyShape));
  }

  void _paintCheeks(Canvas canvas) {
    _fillPaint.color = palette.cheek;
    for (final cheek in const [KomoGeometry.leftCheek, KomoGeometry.rightCheek]) {
      canvas.drawOval(
        Rect.fromCenter(center: cheek, width: KomoGeometry.cheekSize.width, height: KomoGeometry.cheekSize.height),
        _fillPaint,
      );
    }
  }

  void _paintEyes(Canvas canvas, KomoPose pose) {
    _strokePaint
      ..color = palette.face
      ..strokeWidth = KomoGeometry.faceStrokeWidth;
    for (final eye in const [KomoGeometry.leftEye, KomoGeometry.rightEye]) {
      switch (pose.eyes) {
        case KomoEyes.open:
          _paintOpenEye(canvas, eye, pose.eyeOpenness);
        case KomoEyes.smiling:
          canvas.drawPath(_arcPath(eye, bulgeDirection: -1), _strokePaint);
        case KomoEyes.closed:
          canvas.drawPath(_arcPath(eye, bulgeDirection: 1), _strokePaint);
      }
    }
  }

  void _paintOpenEye(Canvas canvas, Offset center, double openness) {
    const minimumBlinkHeight = KomoGeometry.faceStrokeWidth;
    final height = math.max(minimumBlinkHeight, 2 * KomoGeometry.eyeRadiusY * openness);
    _fillPaint.color = palette.face;
    canvas.drawOval(Rect.fromCenter(center: center, width: 2 * KomoGeometry.eyeRadiusX, height: height), _fillPaint);
    if (height > KomoGeometry.eyeRadiusY) {
      _fillPaint.color = palette.eyeHighlight;
      canvas.drawCircle(center + KomoGeometry.eyeHighlightOffset, KomoGeometry.eyeHighlightRadius, _fillPaint);
      canvas.drawCircle(center + KomoGeometry.eyeSparkOffset, KomoGeometry.eyeSparkRadius, _fillPaint);
    }
  }

  /// A curved eye: bulging up (-1) reads as smiling, bulging down (1) as asleep.
  Path _arcPath(Offset center, {required double bulgeDirection}) {
    final baselineY = center.dy - bulgeDirection * KomoGeometry.eyeArcHeight / 4;
    return Path()
      ..moveTo(center.dx - KomoGeometry.eyeArcHalfWidth, baselineY)
      ..quadraticBezierTo(
        center.dx,
        baselineY + bulgeDirection * KomoGeometry.eyeArcHeight,
        center.dx + KomoGeometry.eyeArcHalfWidth,
        baselineY,
      );
  }

  void _paintMouth(Canvas canvas, KomoPose pose) {
    const center = KomoGeometry.mouthCenter;
    _strokePaint
      ..color = palette.face
      ..strokeWidth = KomoGeometry.faceStrokeWidth;
    switch (pose.mouth) {
      case KomoMouth.smile:
        canvas.drawPath(_smilePath(KomoGeometry.smileHalfWidth, KomoGeometry.smileDepth), _strokePaint);
      case KomoMouth.soft:
        canvas.drawPath(_smilePath(KomoGeometry.softSmileHalfWidth, KomoGeometry.softSmileDepth), _strokePaint);
      case KomoMouth.grin:
        _fillPaint.color = palette.face;
        canvas.drawPath(
          Path()
            ..moveTo(center.dx - KomoGeometry.grinHalfWidth, center.dy - KomoGeometry.grinTopOffset)
            ..quadraticBezierTo(
              center.dx,
              center.dy - KomoGeometry.grinTopOffset + KomoGeometry.grinDepth,
              center.dx + KomoGeometry.grinHalfWidth,
              center.dy - KomoGeometry.grinTopOffset,
            )
            ..close(),
          _fillPaint,
        );
    }
  }

  Path _smilePath(double halfWidth, double depth) {
    const center = KomoGeometry.mouthCenter;
    return Path()
      ..moveTo(center.dx - halfWidth, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + depth, center.dx + halfWidth, center.dy);
  }

  void _paintSparkles(Canvas canvas, double progress) {
    final opacity = math.sin(math.pi * progress);
    if (opacity <= 0 || palette.sparkles.isEmpty) return;
    final distance = KomoGeometry.sparkleStartDistance + KomoGeometry.sparkleTravel * progress;
    final radius =
        KomoGeometry.sparkleRadius *
        (KomoGeometry.sparkleSmallestScale + (1 - KomoGeometry.sparkleSmallestScale) * opacity);
    for (final (index, angle) in KomoGeometry.sparkleAnglesRadians.indexed) {
      final color = palette.sparkles[index % palette.sparkles.length];
      final center = KomoGeometry.sparkleOrigin + Offset.fromDirection(angle, distance);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(progress * math.pi / 2);
      final star = _starPath(radius);
      _fillPaint.color = color.withValues(alpha: color.a * opacity);
      canvas.drawPath(star, _fillPaint);
      _strokePaint
        ..color = palette.outline.withValues(alpha: palette.outline.a * opacity)
        ..strokeWidth = KomoGeometry.sparkleStrokeWidth;
      canvas.drawPath(star, _strokePaint);
      canvas.restore();
    }
  }

  /// A four-point sparkle centered on the origin.
  Path _starPath(double radius) {
    final waist = radius * KomoGeometry.sparkleWaistRatio;
    return Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(waist, -waist, radius, 0)
      ..quadraticBezierTo(waist, waist, 0, radius)
      ..quadraticBezierTo(-waist, waist, -radius, 0)
      ..quadraticBezierTo(-waist, -waist, 0, -radius)
      ..close();
  }

  void _paintDoze(Canvas canvas, double progress) {
    final opacity = math.sin(math.pi * progress);
    if (opacity <= 0) return;
    _strokePaint
      ..color = palette.dozeLetter.withValues(alpha: palette.dozeLetter.a * opacity)
      ..strokeWidth = KomoGeometry.dozeStrokeWidth;
    final topLeft = KomoGeometry.dozeOrigin + KomoGeometry.dozeTravel * progress;
    const letterSize = KomoGeometry.dozeLetterSize;
    canvas.drawPath(
      Path()
        ..moveTo(topLeft.dx, topLeft.dy)
        ..lineTo(topLeft.dx + letterSize, topLeft.dy)
        ..lineTo(topLeft.dx, topLeft.dy + letterSize)
        ..lineTo(topLeft.dx + letterSize, topLeft.dy + letterSize),
      _strokePaint,
    );
  }

  @override
  bool shouldRepaint(KomoPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.animation != animation || oldDelegate.palette != palette;
}
