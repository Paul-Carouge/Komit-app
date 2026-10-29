import 'dart:math' as math;

import 'komo_mood.dart';

/// Everything that moves on Komo at one instant of a mood's animation cycle.
///
/// Komo is only an orange rounded square with two pill eyes, so moods live in motion and in
/// the eyes. Every value is a periodic function of the cycle progress, so progress 0 and 1
/// give the same resting pose: the animation can stop on any cycle boundary without a jump.
class KomoPose {
  const KomoPose({
    required this.bodyLift,
    required this.stretchX,
    required this.stretchY,
    required this.tiltRadians,
    required this.eyeOpenness,
    required this.eyeGlanceX,
  });

  /// Vertical offset of the body, as a share of Komo's size; negative is up.
  final double bodyLift;
  final double stretchX;
  final double stretchY;
  final double tiltRadians;

  /// 1 is a full pill, 0 a closed eye drawn as a thin line.
  final double eyeOpenness;

  /// Horizontal shift of both eyes, as a share of Komo's size; looking sideways.
  final double eyeGlanceX;

  factory KomoPose.of(KomoMood mood, double cycleProgress) {
    final turn = 2 * math.pi * cycleProgress;
    final breath = math.sin(turn);
    switch (mood) {
      case KomoMood.idle:
        return KomoPose(
          bodyLift: 0,
          stretchX: 1 - _breathStretch * breath,
          stretchY: 1 + _breathStretch * breath,
          tiltRadians: 0,
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _idleBlinkCenter),
          eyeGlanceX: 0,
        );
      case KomoMood.happy:
        final hop = math.sin(math.pi * cycleProgress);
        // Squash on landing and take-off, stretch at the top of the hop.
        final landingSquash = math.pow(math.cos(math.pi * cycleProgress), 8).toDouble();
        return KomoPose(
          bodyLift: -_hopHeight * hop,
          stretchX: 1 + _hopSquash * landingSquash - _hopStretch * hop,
          stretchY: 1 - _hopSquash * landingSquash + _hopStretch * hop,
          tiltRadians: 0,
          eyeOpenness: 1 - _happySquint * hop,
          eyeGlanceX: 0,
        );
      case KomoMood.sleepy:
        return KomoPose(
          bodyLift: _sleepySink,
          stretchX: 1 + _breathStretch * breath,
          stretchY: 1 - _breathStretch * breath,
          tiltRadians: 0,
          eyeOpenness: 0,
          eyeGlanceX: 0,
        );
      case KomoMood.waving:
        return KomoPose(
          bodyLift: 0,
          stretchX: 1,
          stretchY: 1,
          tiltRadians: _greetingTiltRadians * math.sin(turn),
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _wavingBlinkCenter),
          eyeGlanceX: _greetingGlance * math.sin(turn),
        );
    }
  }

  static const double _breathStretch = 0.02;
  static const double _hopHeight = 0.12;
  static const double _hopStretch = 0.05;
  static const double _hopSquash = 0.08;
  static const double _happySquint = 0.35;
  static const double _sleepySink = 0.02;
  static const double _greetingTiltRadians = 0.12;
  static const double _greetingGlance = 0.04;
  static const double _idleBlinkCenter = 0.65;
  static const double _wavingBlinkCenter = 0.85;

  /// Share of the cycle during which the eyes are closing and reopening.
  static const double _blinkHalfWidth = 0.035;

  static double _blinkOpenness(double cycleProgress, {required double blinkCenter}) {
    final distanceFromBlink = (cycleProgress - blinkCenter).abs();
    if (distanceFromBlink >= _blinkHalfWidth) return 1;
    return distanceFromBlink / _blinkHalfWidth;
  }
}
