import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/seasons.dart';
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
  KomoPainter({required this.mood, required this.animation, required this.palette, this.season})
    : super(repaint: animation);

  final KomoMood mood;
  final Animation<double> animation;
  final KomoPalette palette;

  /// Komo wears a witch hat, a Santa hat or bunny ears during that holiday.
  final Season? season;

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

  /// With an accessory, Komo shrinks toward the ground so the hat or ears stay inside the canvas.
  static const double _accessoryScale = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final pose = KomoPose.of(mood, animation.value);
    final unit = size.shortestSide / _gridSize;
    canvas.save();
    canvas.scale(unit);
    if (season != null) {
      const anchor = Offset(_gridSize / 2, _bodyTop + _bodySize + _shadowHeight);
      canvas.translate(anchor.dx, anchor.dy);
      canvas.scale(_accessoryScale);
      canvas.translate(-anchor.dx, -anchor.dy);
    }
    _paintGroundShadow(canvas, pose);

    final bodyCenterX = _gridSize / 2;
    final bodyBottom = _bodyTop + _bodySize + pose.bodyLift * _gridSize;
    canvas.translate(bodyCenterX, bodyBottom);
    canvas.rotate(pose.tiltRadians);
    // Stretching from the bottom keeps Komo standing on the ground.
    canvas.scale(pose.stretchX, pose.stretchY);
    canvas.translate(-bodyCenterX, -bodyBottom);

    final bodyRect = Rect.fromLTWH((_gridSize - _bodySize) / 2, bodyBottom - _bodySize, _bodySize, _bodySize);
    if (season == Season.easter) _paintBunnyEars(canvas, bodyRect);
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
    switch (season) {
      case Season.halloween:
        _paintWitchHat(canvas, bodyRect);
      case Season.christmas:
        _paintSantaHat(canvas, bodyRect);
      case Season.easter || null:
        break;
    }
    canvas.restore();
  }

  void _paintWitchHat(Canvas canvas, Rect bodyRect) {
    final brimCenter = Offset(bodyRect.center.dx + 3, bodyRect.top + 2);
    canvas.save();
    canvas.translate(brimCenter.dx, brimCenter.dy);
    canvas.rotate(-0.12);
    final hatPaint = Paint()..color = SeasonalAccessoryColors.witchHat;
    final cone = Path()
      ..moveTo(-21, 0)
      ..quadraticBezierTo(-10, -14, 4, -30)
      ..quadraticBezierTo(8, -16, 21, 0)
      ..close();
    canvas.drawPath(cone, hatPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-17, -7, 34, 5), const Radius.circular(2)),
      Paint()..color = SeasonalAccessoryColors.witchHatBand,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 62, height: 7), const Radius.circular(3.5)),
      hatPaint,
    );
    canvas.restore();
  }

  /// The fur sits on Komo's orange and the pompom has a soft outline, so the white never
  /// melts into a light page.
  void _paintSantaHat(Canvas canvas, Rect bodyRect) {
    final base = bodyRect.top + 6;
    final pompomCenter = Offset(bodyRect.right + 5, bodyRect.top + 2);
    final hat = Path()
      ..moveTo(bodyRect.left + 6, base)
      ..cubicTo(
        bodyRect.left + 8,
        bodyRect.top - 20,
        bodyRect.center.dx + 14,
        bodyRect.top - 24,
        pompomCenter.dx,
        pompomCenter.dy,
      )
      ..quadraticBezierTo(bodyRect.right - 4, bodyRect.top - 4, bodyRect.right - 6, base)
      ..close();
    canvas.drawPath(hat, Paint()..color = SeasonalAccessoryColors.santaHat);
    final furPaint = Paint()..color = SeasonalAccessoryColors.santaHatFur;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(bodyRect.left + 4, base - 4, bodyRect.right - 4, base + 7),
        const Radius.circular(5.5),
      ),
      furPaint,
    );
    canvas.drawCircle(pompomCenter, 6.5, furPaint);
    canvas.drawCircle(
      pompomCenter,
      6.5,
      Paint()
        ..color = SeasonalAccessoryColors.santaHatFurOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintBunnyEars(Canvas canvas, Rect bodyRect) {
    final earPaint = Paint()..color = palette.body;
    final insidePaint = Paint()..color = SeasonalAccessoryColors.bunnyEarInside;
    for (final direction in const [-1, 1]) {
      canvas.save();
      canvas.translate(bodyRect.center.dx + direction * 15, bodyRect.top + 8);
      canvas.rotate(direction * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -36, 14, 40), const Radius.circular(7)),
        earPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -30, 6, 24), const Radius.circular(3)),
        insidePaint,
      );
      canvas.restore();
    }
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
      oldDelegate.mood != mood ||
      oldDelegate.season != season ||
      oldDelegate.palette.body != palette.body ||
      oldDelegate.palette.eyes != palette.eyes;
}
