import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

/// Geometry of Komo's eyes in the launcher icon foreground and the Android splash
/// (android/app/src/main/res/drawable/ic_launcher_foreground.xml), on its 108-unit grid.
abstract final class _SplashEyeGeometry {
  static const double gridSize = 108;
  static const double eyeWidth = 11;
  static const double eyeHeight = 20;
  static const double eyeCenterOffsetX = 12.5;
  static const double eyeCenterY = 47.5;

  /// Android draws the 108-unit splash icon over 288 dp (launch_background.xml uses the same).
  static const double nativeSplashIconSize = 288;
}

/// Komo's eyes grow by this share while the splash fades, as if the app opened toward the user.
const double _eyeGrowthDuringHandoff = 0.12;

/// The Android splash shows Komo's face: the orange screen and its two pill eyes. The first
/// Flutter frame repeats it exactly, then fades it away over the first screen, so the app
/// appears out of Komo instead of cutting from orange to the page.
///
/// Skipped when the system removes animations: the first screen then shows at once.
class SplashHandoff extends StatefulWidget {
  const SplashHandoff({required this.child, super.key});

  final Widget child;

  @override
  State<SplashHandoff> createState() => _SplashHandoffState();
}

class _SplashHandoffState extends State<SplashHandoff> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppDurations.splashHandoff);
  bool _isHandoffDone = false;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _isHandoffDone = true;
      return;
    }
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _isHandoffDone = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Once done, the overlay leaves the tree: no layer and no cost for the rest of the session.
    if (_isHandoffDone) return widget.child;
    final komitColors = KomitColors.of(context);
    final progress = CurvedAnimation(parent: _controller, curve: AppCurves.standard);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: FadeTransition(
                opacity: ReverseAnimation(progress),
                child: ColoredBox(
                  color: komitColors.mascotBody,
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1 + _eyeGrowthDuringHandoff).animate(progress),
                      child: CustomPaint(
                        size: const Size.square(_SplashEyeGeometry.nativeSplashIconSize),
                        painter: _SplashEyesPainter(color: komitColors.mascotFace),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashEyesPainter extends CustomPainter {
  const _SplashEyesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / _SplashEyeGeometry.gridSize;
    final paint = Paint()..color = color;
    for (final direction in const [-1, 1]) {
      final eyeRect = Rect.fromCenter(
        center: Offset(
          (_SplashEyeGeometry.gridSize / 2 + direction * _SplashEyeGeometry.eyeCenterOffsetX) * unit,
          _SplashEyeGeometry.eyeCenterY * unit,
        ),
        width: _SplashEyeGeometry.eyeWidth * unit,
        height: _SplashEyeGeometry.eyeHeight * unit,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(eyeRect, Radius.circular(eyeRect.width / 2)), paint);
    }
  }

  @override
  bool shouldRepaint(_SplashEyesPainter oldDelegate) => oldDelegate.color != color;
}
