import 'package:flutter/widgets.dart';

/// Every duration in Komit. Motion answers a user action; it never decorates for its own sake.
abstract final class AppDurations {
  /// A chunky button sinking under the finger: must feel instant.
  static const Duration pressDown = Duration(milliseconds: 70);

  /// The same button springing back, long enough for its overshoot to read as a bounce.
  static const Duration pressRelease = Duration(milliseconds: 320);

  /// Small feedback such as a card scaling while pressed.
  static const Duration quick = Duration(milliseconds: 120);

  /// State changes inside a screen (selection, switching onboarding steps).
  static const Duration standard = Duration(milliseconds: 240);

  /// A freshly logged day popping into its cell, a progress bar filling up.
  static const Duration emphasized = Duration(milliseconds: 520);

  static const Duration mascotBounceCycle = Duration(milliseconds: 2400);
  static const Duration mascotHopCycle = Duration(milliseconds: 900);
  static const Duration mascotWaveCycle = Duration(milliseconds: 1400);
  static const Duration mascotDozeCycle = Duration(milliseconds: 4800);

  /// Komo stops moving after this long, so an idle screen stops drawing frames and saves battery.
  static const Duration mascotAnimationBudget = Duration(seconds: 12);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;

  /// Slight overshoot: things the user just created land with a little bounce.
  static const Curve emphasized = Curves.easeOutBack;

  /// A released button springs back past its resting place, like a rubber key.
  static const Curve pressRelease = ElasticOutCurve(_pressReleaseElasticPeriod);

  /// Big celebratory entrances: a value counting into place, a step badge landing.
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1);

  /// Lower is springier; this keeps one visible rebound, two at most.
  static const double _pressReleaseElasticPeriod = 0.55;
}

/// Pressed cards shrink to this scale.
const double pressedScale = 0.96;

/// [Duration.zero] when the user asked the system to remove animations.
Duration motionAwareDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
