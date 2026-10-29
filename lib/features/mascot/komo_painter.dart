import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import 'komo_mood.dart';
import 'komo_pose.dart';

/// Komo's colors, resolved from the theme by the widget.
class KomoPalette {
  const KomoPalette({required this.body, required this.eyes, required this.groundShadow});

  final Color body;
  final Color eyes;
  final Color groundShadow;
}

/// Draws Komo with the same geometry as the launcher icon (docs/design/komit-launcher-icon.svg):
/// an orange rounded square and two pill-shaped eyes, on a 108-unit grid.
class KomoPainter extends CustomPainter {
  KomoPainter({required this.mood, required this.animation, required this.palette}) : super(repaint: animation);

  final KomoMood mood;
  final Animation<double> animation;
  final KomoPalette palette;

  /// Body square inside the 108-unit grid, leaving room for the hop and the ground shadow.
  static const double _gridSize = 108;
  static const double _bodySize = 76;
  static const double _bodyCornerRadius = 26;
  static const double _bodyTop = 14;
  static const double _eyeWidth = 11;
  static const double _eyeHeight = 20;
  static const double _eyeCenterOffsetX = 12.5;

  /// Eyes sit above the body center, which reads as a face rather than a pause symbol.
  static const double _eyeCenterYFromBodyTop = 33;
  static const double _closedEyeHeight = 3;
  static const double _shadowWidth = 54;
  static const double _shadowHeight = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final pose = KomoPose.of(mood, animation.value);
    final unit = size.shortestSide / _gridSize;
    canvas.save();
    canvas.scale(unit);
    _paintGroundShadow(canvas, pose);

    final bodyCenterX = _gridSize / 2;
    final bodyBottom = _bodyTop + _bodySize + pose.bodyLift * _gridSize;
    canvas.translate(bodyCenterX, bodyBottom);
    canvas.rotate(pose.tiltRadians);
    // Stretching from the bottom keeps Komo standing on the ground.
    canvas.scale(pose.stretchX, pose.stretchY);
    canvas.translate(-bodyCenterX, -bodyBottom);

    final bodyRect = Rect.fromLTWH((_gridSize - _bodySize) / 2, bodyBottom - _bodySize, _bodySize, _bodySize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(_bodyCornerRadius)),
      Paint()..color = palette.body,
    );

    final eyePaint = Paint()..color = palette.eyes;
    final eyeHeight = _closedEyeHeight + (_eyeHeight - _closedEyeHeight) * pose.eyeOpenness;
    final eyeCenterY = bodyRect.top + _eyeCenterYFromBodyTop;
    final glance = pose.eyeGlanceX * _gridSize;
    for (final direction in const [-1, 1]) {
      final eyeRect = Rect.fromCenter(
        center: Offset(bodyCenterX + direction * _eyeCenterOffsetX + glance, eyeCenterY),
        width: _eyeWidth,
        height: eyeHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(eyeRect, const Radius.circular(_eyeWidth / 2)), eyePaint);
    }
    canvas.restore();
  }

  void _paintGroundShadow(Canvas canvas, KomoPose pose) {
    // The shadow shrinks while Komo is in the air.
    final shadowScale = 1 + pose.bodyLift * 2;
    final shadowRect = Rect.fromCenter(
      center: const Offset(_gridSize / 2, _bodyTop + _bodySize + _shadowHeight / 2),
      width: _shadowWidth * shadowScale,
      height: _shadowHeight * shadowScale,
    );
    canvas.drawOval(shadowRect, Paint()..color = palette.groundShadow);
  }

  @override
  bool shouldRepaint(KomoPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.palette.body != palette.body || oldDelegate.palette.eyes != palette.eyes;
}
