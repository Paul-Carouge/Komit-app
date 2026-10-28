import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import 'game_pressable.dart';
import 'game_surface_painter.dart';

/// Komit's card: a thick ink outline, a glossy top band and a soft drop shadow.
///
/// With [onTap] it becomes pressable: it shrinks under the finger and bounces back.
class GameCard extends StatelessWidget {
  const GameCard({
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.large),
    this.isHero = false,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to the neutral face (white by day, raised indigo at night).
  final Color? color;
  final EdgeInsetsGeometry padding;

  /// Hero cards carry a heavier outline and a larger radius.
  final bool isHero;

  /// Replaces the label read from the children when the card is tappable.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final komitColors = KomitColors.of(context);
    final cornerRadius = isHero ? AppRadii.large : AppRadii.tile;
    Widget surface({required bool isFocused}) => CustomPaint(
      painter: GameSurfacePainter(
        faceColor: color ?? komitColors.neutralFace,
        outlineColor: komitColors.outline,
        glossColor: komitColors.gloss,
        cornerRadius: cornerRadius,
        outlineWidth: isHero ? AppOutline.heavy : AppOutline.regular,
        shadowColor: komitColors.dropShadow,
        glossLineHeight: AppSizes.cardGlossLineHeight,
        focusRingColor: isFocused ? komitColors.focusRing : null,
      ),
      // Lets list tiles and switches inside the card draw their ink above its face, within its corners.
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius)),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return surface(isFocused: false);
    return GamePressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressProgress, isFocused) => Transform.scale(
        scale: 1 - (1 - pressedScale) * pressProgress,
        child: surface(isFocused: isFocused),
      ),
    );
  }
}
