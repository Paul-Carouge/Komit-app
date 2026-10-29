import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import 'komo_mood.dart';
import 'komo_painter.dart';

export 'komo_mood.dart';

/// Komo, Komit's mascot: an orange rounded square with two pill eyes, like the app icon.
///
/// It plays its [mood] animation for [AppDurations.mascotAnimationBudget], then rests, so a
/// screen left open stops drawing frames. Tapping Komo plays it again. With system animations
/// turned off, Komo is drawn in its resting pose and never animates.
///
/// Decorative by default; give a [semanticLabel] only when Komo carries meaning on its own.
class KomoMascot extends StatefulWidget {
  const KomoMascot({required this.mood, this.size = AppSizes.mascotMedium, this.semanticLabel, super.key});

  final KomoMood mood;
  final double size;
  final String? semanticLabel;

  @override
  State<KomoMascot> createState() => _KomoMascotState();
}

class _KomoMascotState extends State<KomoMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.mood.cycleDuration);

  /// Null until the first dependency resolution, so the animation starts exactly once on mount.
  bool? _isMotionReduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);
    if (isMotionReduced == _isMotionReduced) return;
    _isMotionReduced = isMotionReduced;
    _playMoodAnimation();
  }

  @override
  void didUpdateWidget(KomoMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = widget.mood.cycleDuration;
      _playMoodAnimation();
    }
  }

  void _playMoodAnimation() {
    if (_isMotionReduced ?? false) {
      _controller.value = 0;
      return;
    }
    final cycleCount = AppDurations.mascotAnimationBudget.inMilliseconds ~/ widget.mood.cycleDuration.inMilliseconds;
    // Every pose is periodic, so ending on a cycle boundary lands on the resting pose.
    unawaited(_controller.repeat(count: cycleCount < 1 ? 1 : cycleCount));
  }

  void _replay() {
    if (_isMotionReduced ?? false) return;
    unawaited(KomitHaptics.selection());
    _controller.value = 0;
    _playMoodAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final mascot = GestureDetector(
      onTap: _replay,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: KomoPainter(
            mood: widget.mood,
            animation: _controller,
            palette: KomoPalette(
              body: komitColors.mascotBody,
              eyes: komitColors.mascotFace,
              groundShadow: komitColors.mascotGroundShadow,
            ),
          ),
        ),
      ),
    );
    final semanticLabel = widget.semanticLabel;
    if (semanticLabel == null) return ExcludeSemantics(child: mascot);
    return Semantics(image: true, label: semanticLabel, excludeSemantics: true, child: mascot);
  }
}
