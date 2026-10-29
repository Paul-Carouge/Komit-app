import 'package:flutter/widgets.dart';

/// Every duration in Komit. Motion answers a user action; it never decorates for its own sake.
abstract final class AppDurations {
  /// Press feedback: must feel instant.
  static const Duration quick = Duration(milliseconds: 120);

  /// State changes inside a screen (selection, switching onboarding steps).
  static const Duration standard = Duration(milliseconds: 240);

  /// Loading shorter than this shows nothing: a skeleton flashing for a frame looks broken.
  static const Duration loadingSkeletonDelay = Duration(milliseconds: 150);

  /// Komo's face from the Android splash fading away to reveal the first screen.
  static const Duration splashHandoff = Duration(milliseconds: 420);

  /// A freshly logged day popping into its cell.
  static const Duration emphasized = Duration(milliseconds: 460);

  static const Duration mascotBreathCycle = Duration(milliseconds: 3600);
  static const Duration mascotHopCycle = Duration(milliseconds: 820);
  static const Duration mascotWaveCycle = Duration(milliseconds: 1400);
  static const Duration mascotDozeCycle = Duration(milliseconds: 4800);

  /// Komo stops moving after this long, so an idle screen stops drawing frames and saves battery.
  static const Duration mascotAnimationBudget = Duration(seconds: 12);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;

  /// Slight overshoot: things the user just created land with a little bounce.
  static const Curve emphasized = Curves.easeOutBack;

  /// Underdamped spring, like Material 3 Expressive motion: settles with a soft wobble.
  static const Curve spring = ElasticOutCurve(0.8);
}

/// Pressed cards and buttons shrink to this scale.
const double pressedScale = 0.96;

/// [Duration.zero] when the user asked the system to remove animations.
Duration motionAwareDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
