import '../../core/theme/app_motion.dart';

/// How Komo feels; each mood has its own pose and animation loop.
enum KomoMood {
  /// Calm breathing and an occasional blink: the default companion.
  idle(AppDurations.mascotBreathCycle),

  /// Hops with a squash and a squint: a day logged, a milestone reached.
  happy(AppDurations.mascotHopCycle),

  /// Eyes closed, slow breathing: nothing yet, or a streak to restart.
  sleepy(AppDurations.mascotDozeCycle),

  /// Sways and glances around to say hello: onboarding and first-run screens.
  waving(AppDurations.mascotWaveCycle);

  const KomoMood(this.cycleDuration);

  final Duration cycleDuration;
}
