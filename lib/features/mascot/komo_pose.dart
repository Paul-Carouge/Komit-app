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
        // A small hop at the start of the cycle, then a calm pause: lively without being restless.
        final isHopping = cycleProgress < _idleHopShare;
        final hop = isHopping
            ? _HopFrame.at(cycleProgress / _idleHopShare, height: _idleHopHeight, squash: _idleSquash)
            : const _HopFrame.resting();
        return KomoPose(
          bodyLift: hop.lift,
          stretchX: _volumeKeepingStretchX(hop.stretchY),
          stretchY: hop.stretchY,
          eyes: KomoEyes.open,
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _idleBlinkCenter),
          mouth: KomoMouth.smile,
          sproutTiltRadians: _sproutSwayRadians * math.sin(2 * turn) * (isHopping ? 1 : 0),
        );
      case KomoMood.happy:
        final hop = _HopFrame.at(cycleProgress, height: _happyHopHeight, squash: _happySquash);
        final wiggle = _armWiggleRadians * math.sin(turn * 2);
        return KomoPose(
          bodyLift: hop.lift,
          stretchX: _volumeKeepingStretchX(hop.stretchY),
          stretchY: hop.stretchY,
          eyes: KomoEyes.smiling,
          eyeOpenness: 1,
          mouth: KomoMouth.grin,
          // The sprout lags behind the body, which sells the jump.
          sproutTiltRadians: _sproutSwayRadians * 2 * math.sin(turn),
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
        // Komo bobs twice per cycle, once per swing of the arm.
        final bob = math.sin(turn * 2);
        return KomoPose(
          bodyLift: -_waveBobHeight * bob.abs(),
          stretchX: 1 - _breathStretchX * bob,
          stretchY: 1 + _breathStretchY * bob,
          eyes: KomoEyes.open,
          eyeOpenness: _blinkOpenness(cycleProgress, blinkCenter: _wavingBlinkCenter),
          mouth: KomoMouth.smile,
          sproutTiltRadians: _sproutSwayRadians * math.sin(turn),
          rightArmAngleRadians: -_raisedArmRadians + _waveAmplitudeRadians * bob,
        );
    }
  }

  static const double _idleHopShare = 0.36;
  static const double _idleHopHeight = 5;
  static const double _idleSquash = 0.08;
  static const double _happyHopHeight = 15;
  static const double _happySquash = 0.14;
  static const double _breathStretchX = 0.02;
  static const double _breathStretchY = 0.04;
  static const double _sleepyBreathStretchY = 0.05;
  static const double _sleepySinkHeight = 2;
  static const double _waveBobHeight = 2;
  static const double _sproutSwayRadians = 0.1;
  static const double _droopedSproutRadians = 0.45;
  static const double _raisedArmRadians = math.pi / 3;
  static const double _armWiggleRadians = 0.2;
  static const double _waveAmplitudeRadians = 0.5;
  static const double _idleBlinkCenter = 0.7;
  static const double _wavingBlinkCenter = 0.85;

  /// Share of the squash that turns into widening, so Komo looks like it keeps its volume.
  static const double _volumeKeepingRatio = 0.7;

  /// Share of the cycle during which the eyes are closing and reopening.
  static const double _blinkHalfWidth = 0.035;

  static double _volumeKeepingStretchX(double stretchY) => 1 + (1 - stretchY) * _volumeKeepingRatio;

  static double _blinkOpenness(double cycleProgress, {required double blinkCenter}) {
    final distanceFromBlink = (cycleProgress - blinkCenter).abs();
    if (distanceFromBlink >= _blinkHalfWidth) return 1;
    return distanceFromBlink / _blinkHalfWidth;
  }
}

/// One frame of a cartoon hop: squash down to gather, stretch up in the air, squash on landing.
class _HopFrame {
  const _HopFrame({required this.lift, required this.stretchY});

  const _HopFrame.resting() : lift = 0, stretchY = 1;

  /// [progress] runs from 0 to 1 over one hop; both ends are the resting pose.
  factory _HopFrame.at(double progress, {required double height, required double squash}) {
    if (progress < _anticipationEnd) {
      return _HopFrame(lift: 0, stretchY: 1 - squash * math.sin(math.pi * progress / _anticipationEnd));
    }
    if (progress < _landingStart) {
      final airProgress = (progress - _anticipationEnd) / (_landingStart - _anticipationEnd);
      final arc = math.sin(math.pi * airProgress);
      return _HopFrame(lift: -height * arc, stretchY: 1 + squash * _airStretchShare * arc);
    }
    final landingProgress = (progress - _landingStart) / (1 - _landingStart);
    return _HopFrame(lift: 0, stretchY: 1 - squash * math.sin(math.pi * landingProgress));
  }

  static const double _anticipationEnd = 0.2;
  static const double _landingStart = 0.78;

  /// In the air Komo stretches less than it squashes on the ground.
  static const double _airStretchShare = 0.6;

  final double lift;
  final double stretchY;
}
