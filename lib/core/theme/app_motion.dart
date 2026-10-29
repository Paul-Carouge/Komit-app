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

  /// How long an "Undo" message stays: long enough to read it and reach the button.
  static const Duration undoSnackBar = Duration(seconds: 5);

  static const Duration mascotBreathCycle = Duration(milliseconds: 3600);
  static const Duration mascotHopCycle = Duration(milliseconds: 820);
  static const Duration mascotWaveCycle = Duration(milliseconds: 1400);
  static const Duration mascotDozeCycle = Duration(milliseconds: 4800);

  /// Komo stops moving after this long, so an idle screen stops drawing frames and saves battery.
  static const Duration mascotAnimationBudget = Duration(seconds: 12);

  /// Komo in a header or bar answers a change or a tap with a short gesture, then rests: it sits
  /// next to content the user reads and must not pull the eye.
  static const Duration mascotHeaderAnimationBudget = Duration(milliseconds: 2500);

  /// A list row fading and rising into place.
  static const Duration entrance = Duration(milliseconds: 360);

  /// Gap between two rows of a staggered entrance; short, so the eighth row lands in about half a second.
  static const Duration entranceStaggerStep = Duration(milliseconds: 40);

  /// A number counting up to its value.
  static const Duration counter = Duration(milliseconds: 720);

  /// The burst of color behind Komo when a milestone is reached.
  static const Duration celebrationBurst = Duration(milliseconds: 900);

  /// How long a celebration card stays; long enough to read two short lines twice.
  static const Duration celebrationVisible = Duration(seconds: 4);
}

/// Only the first rows of a list are staggered: past these the wait would feel like lag.
const int maximumStaggeredEntranceCount = 8;

/// How far a row rises while it fades in, in logical pixels.
const double entranceRiseDistance = 8;

abstract final class AppCurves {
  static const Curve standard = Curves.easeOutCubic;

  /// Slight overshoot: things the user just created land with a little bounce.
  static const Curve emphasized = Curves.easeOutBack;

  /// Underdamped spring, like Material 3 Expressive motion: settles with a soft wobble.
  static const Curve spring = ElasticOutCurve(0.8);
}

/// Pressed cards and buttons shrink to this scale.
const double pressedScale = 0.96;

/// A card picked up for reordering grows to this scale, like an object lifted toward the eye.
const double liftedScale = 1.03;

/// A freshly logged button starts at this scale, then springs back past full size.
const double loggedButtonInitialScale = 0.8;

/// [Duration.zero] when the user asked the system to remove animations.
Duration motionAwareDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
