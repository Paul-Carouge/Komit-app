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
    required this.face,
    required this.eyeHighlight,
    required this.cheek,
    required this.sprout,
    required this.groundShadow,
    required this.dozeLetter,
    required this.sparkles,
  });

  final Color body;
  final Color bodyShade;
  final Color face;
  final Color eyeHighlight;
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
      other.face == face &&
      other.eyeHighlight == eyeHighlight &&
      other.cheek == cheek &&
      other.sprout == sprout &&
      other.groundShadow == groundShadow &&
      other.dozeLetter == dozeLetter &&
      listEquals(other.sparkles, sparkles);

  @override
  int get hashCode => Object.hash(
    body,
    bodyShade,
    face,
    eyeHighlight,
    cheek,
    sprout,
    groundShadow,
    dozeLetter,
    Object.hashAll(sparkles),
  );
}

/// Komo's geometry, in a 100 × 100 design box. The launcher icon
/// (android/app/src/main/res/drawable/ic_launcher_foreground.xml) uses the same numbers.
abstract final class KomoGeometry {
  static const double designBoxSize = 100;
  static const Rect body = Rect.fromLTRB(22, 36, 78, 86);
  static const double bodyCornerRadius = 16;

  /// The lower band of the body is darker, like the side of a key cap.
  static const double bodyShadeTop = 77;
  static const Offset groundShadowCenter = Offset(50, 90);
  static const double groundShadowRadiusX = 22;
  static const double groundShadowRadiusY = 3.4;
  static const Offset leftEye = Offset(39, 59);
  static const Offset rightEye = Offset(61, 59);
  static const double eyeRadius = 4.3;
  static const Offset eyeHighlightOffset = Offset(1.4, -1.5);
  static const double eyeHighlightRadius = 1.4;
  static const double eyeArcHalfWidth = 4;
  static const double eyeArcHeight = 5;
  static const Offset leftCheek = Offset(31.5, 67);
  static const Offset rightCheek = Offset(68.5, 67);
  static const Size cheekSize = Size(10, 6.4);
  static const double faceStrokeWidth = 2.6;
  static const Offset mouthCenter = Offset(50, 66.5);
  static const double smileHalfWidth = 4.5;
  static const double smileDepth = 4.5;
  static const double softSmileHalfWidth = 3;
  static const double softSmileDepth = 2.5;
  static const double grinHalfWidth = 6;
  static const double grinDepth = 9.5;

  /// The grin starts slightly above the smile line so the open mouth stays centered.
  static const double grinTopOffset = 1;
  static const Offset sproutBase = Offset(50, 37);
  static const Offset sproutTip = Offset(51, 25);
  static const double sproutStemWidth = 3;
  static const Offset leftShoulder = Offset(26, 63);
  static const Offset rightShoulder = Offset(74, 63);
  static const double armLength = 19;
  static const double armThickness = 7.5;
  static const Offset sparkleOrigin = Offset(50, 56);
  static const double sparkleStartDistance = 32;
  static const double sparkleTravel = 14;
  static const double sparkleSize = 6;
  static const List<double> sparkleAnglesRadians = [-2.62, -1.92, -1.22, -0.52];
  static const Offset dozeOrigin = Offset(74, 32);
  static const Offset dozeTravel = Offset(8, -18);
  static const double dozeLetterSize = 7;
  static const double dozeStrokeWidth = 2;
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
    // Squash and stretch are anchored at Komo's feet, so it stays grounded while breathing.
    final feet = Offset(KomoGeometry.body.center.dx, KomoGeometry.body.bottom);
    canvas.translate(feet.dx, feet.dy + pose.bodyLift);
    canvas.scale(pose.stretchX, pose.stretchY);
    canvas.translate(-feet.dx, -feet.dy);
    _paintArms(canvas, pose);
    _paintSprout(canvas, pose);
    _paintBody(canvas);
    _paintCheeks(canvas);
    _paintEyes(canvas, pose);
    _paintMouth(canvas, pose);
    canvas.restore();
    if (pose.sparkleProgress case final sparkleProgress?) _paintSparkles(canvas, sparkleProgress);
    if (pose.dozeProgress case final dozeProgress?) _paintDoze(canvas, dozeProgress);
    canvas.restore();
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
    _fillPaint.color = palette.bodyShade;
    for (final (shoulder, angle) in [
      (KomoGeometry.leftShoulder, pose.leftArmAngleRadians),
      (KomoGeometry.rightShoulder, pose.rightArmAngleRadians),
    ]) {
      if (angle == null) continue;
      canvas.save();
      canvas.translate(shoulder.dx, shoulder.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, -KomoGeometry.armThickness / 2, KomoGeometry.armLength, KomoGeometry.armThickness),
          const Radius.circular(KomoGeometry.armThickness / 2),
        ),
        _fillPaint,
      );
      canvas.restore();
    }
  }

  void _paintSprout(Canvas canvas, KomoPose pose) {
    canvas.save();
    canvas.translate(KomoGeometry.sproutBase.dx, KomoGeometry.sproutBase.dy);
    canvas.rotate(pose.sproutTiltRadians);
    canvas.translate(-KomoGeometry.sproutBase.dx, -KomoGeometry.sproutBase.dy);
    _strokePaint
      ..color = palette.sprout
      ..strokeWidth = KomoGeometry.sproutStemWidth;
    canvas.drawPath(
      Path()
        ..moveTo(KomoGeometry.sproutBase.dx, KomoGeometry.sproutBase.dy)
        ..quadraticBezierTo(50, 30, KomoGeometry.sproutTip.dx, KomoGeometry.sproutTip.dy),
      _strokePaint,
    );
    _fillPaint.color = palette.sprout;
    // Two leaves, right one larger; same path data as the launcher icon.
    canvas.drawPath(
      Path()
        ..moveTo(51, 26)
        ..cubicTo(54, 17, 62, 14, 68, 15)
        ..cubicTo(67, 22, 60, 27, 51, 26)
        ..close()
        ..moveTo(49, 28)
        ..cubicTo(46, 22, 41, 20, 36, 21)
        ..cubicTo(37, 26, 42, 29, 49, 28)
        ..close(),
      _fillPaint,
    );
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
    _fillPaint.color = palette.face;
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
    final height = math.max(minimumBlinkHeight, 2 * KomoGeometry.eyeRadius * openness);
    _fillPaint.color = palette.face;
    canvas.drawOval(Rect.fromCenter(center: center, width: 2 * KomoGeometry.eyeRadius, height: height), _fillPaint);
    if (height > KomoGeometry.eyeRadius) {
      _fillPaint.color = palette.eyeHighlight;
      canvas.drawCircle(center + KomoGeometry.eyeHighlightOffset, KomoGeometry.eyeHighlightRadius, _fillPaint);
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
    for (final (index, angle) in KomoGeometry.sparkleAnglesRadians.indexed) {
      final color = palette.sparkles[index % palette.sparkles.length];
      _fillPaint.color = color.withValues(alpha: color.a * opacity);
      final center = KomoGeometry.sparkleOrigin + Offset.fromDirection(angle, distance);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(progress * math.pi / 2);
      // Sparkles are tiny day cells: rounded squares, like the ones in the grids.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: KomoGeometry.sparkleSize, height: KomoGeometry.sparkleSize),
          const Radius.circular(KomoGeometry.sparkleSize / 4),
        ),
        _fillPaint,
      );
      canvas.restore();
    }
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
