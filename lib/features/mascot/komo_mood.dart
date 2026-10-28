import '../../core/theme/app_motion.dart';

/// How Komo feels; each mood has its own pose and animation loop.
enum KomoMood {
  /// A little squash-and-stretch bounce, then a blink: the default companion.
  idle(AppDurations.mascotBounceCycle),

  /// Big springy hops with raised arms and sparkles: every habit logged, a milestone reached.
  happy(AppDurations.mascotHopCycle),

  /// Eyes closed, drooping sprout, slow breathing: nothing yet, or a streak to restart.
  sleepy(AppDurations.mascotDozeCycle),

  /// Waves hello: onboarding and first-run screens.
  waving(AppDurations.mascotWaveCycle);

  const KomoMood(this.cycleDuration);

  final Duration cycleDuration;
}
