import 'dart:math' as math;

import 'komo_mood.dart';

enum KomoEyes { open, smiling, closed }

enum KomoMouth { smile, grin, soft }

/// Everything that moves on Komo at one instant of a mood's animation cycle.
///
/// Every value is a periodic function of the cycle progress, so progress 0 and 1 give the
/// same resting pose: the animation can stop on any cycle boundary without a visible jump.
class KomoPose {
  const KomoPose({
    required this.bodyLift,
    required this.stretchX,
    required this.stretchY,
    required this.eyes,
    required this.eyeOpenness,
    required this.mouth,
    required this.sproutTiltRadians,
    this.leftArmAngleRadians,
    this.rightArmAngleRadians,
    this.sparkleProgress,
    this.dozeProgress,
  });

  /// Vertical offset of the body in design units; negative is up.
  final double bodyLift;
  final double stretchX;
  final double stretchY;
  final KomoEyes eyes;

  /// 1 is fully open, 0 is a closed blink.
  final double eyeOpenness;
  final KomoMouth mouth;
  final double sproutTiltRadians;

  /// Null hides the arm; 0 points right, negative angles point up.
  final double? leftArmAngleRadians;
  final double? rightArmAngleRadians;

  /// Null shows no celebration sparkles.
  final double? sparkleProgress;

  /// Null shows no sleeping "z".
  final double? dozeProgress;

  factory KomoPose.of(KomoMood mood, double cycleProgress) {
    final turn = 2 * math.pi * cycleProgress;
    final breath = math.sin(turn);
    switch (mood) {
      case KomoMood.idle:
        return KomoPose(
          bodyLift: 0,
          stretchX: 1 - _breathStretchX * breath,
          stretchY: 1 + _breathStretchY * breath,
          eyes: KomoEyes.open,
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _idleBlinkCenter),
          mouth: KomoMouth.smile,
          sproutTiltRadians: _sproutSwayRadians * math.cos(turn),
        );
      case KomoMood.happy:
        final hop = math.sin(math.pi * cycleProgress);
        final wiggle = _armWiggleRadians * math.sin(turn * 2);
        return KomoPose(
          bodyLift: -_hopHeight * hop,
          stretchX: 1 - _hopStretchX * hop,
          stretchY: 1 + _hopStretchY * hop,
          eyes: KomoEyes.smiling,
          eyeOpenness: 1,
          mouth: KomoMouth.grin,
          sproutTiltRadians: _sproutSwayRadians * math.sin(turn),
          leftArmAngleRadians: -_raisedArmRadians - math.pi / 3 + wiggle,
          rightArmAngleRadians: -_raisedArmRadians + wiggle,
          sparkleProgress: cycleProgress,
        );
      case KomoMood.sleepy:
        return KomoPose(
          bodyLift: _sleepySinkHeight,
          stretchX: 1 - _breathStretchX * breath,
          stretchY: 1 + _sleepyBreathStretchY * breath,
          eyes: KomoEyes.closed,
          eyeOpenness: 1,
          mouth: KomoMouth.soft,
          sproutTiltRadians: _droopedSproutRadians + _sproutSwayRadians * breath,
          dozeProgress: cycleProgress,
        );
      case KomoMood.waving:
        return KomoPose(
          bodyLift: 0,
          stretchX: 1 - _breathStretchX * breath,
          stretchY: 1 + _breathStretchY * breath,
          eyes: KomoEyes.open,
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _wavingBlinkCenter),
          mouth: KomoMouth.smile,
          sproutTiltRadians: _sproutSwayRadians * math.sin(turn),
          rightArmAngleRadians: -_raisedArmRadians + _waveAmplitudeRadians * math.sin(turn * 2),
        );
    }
  }

  static const double _breathStretchX = 0.012;
  static const double _breathStretchY = 0.025;
  static const double _sleepyBreathStretchY = 0.035;
  static const double _hopHeight = 10;
  static const double _hopStretchX = 0.03;
  static const double _hopStretchY = 0.05;
  static const double _sleepySinkHeight = 2;
  static const double _sproutSwayRadians = 0.06;
  static const double _droopedSproutRadians = 0.4;
  static const double _raisedArmRadians = math.pi / 3;
  static const double _armWiggleRadians = 0.18;
  static const double _waveAmplitudeRadians = 0.45;
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
