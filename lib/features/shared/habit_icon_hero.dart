import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// How a habit icon square looks in one place of the app.
@immutable
class HabitIconLook {
  const HabitIconLook({
    required this.size,
    required this.iconSize,
    required this.borderRadius,
    required this.backgroundColor,
    required this.opaqueBackgroundColor,
    required this.iconColor,
  });

  /// On a card: the habit color as a light tint, like [HabitIconBadge].
  factory HabitIconLook.onCard(BuildContext context, Color habitColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = habitColor.withValues(alpha: isDark ? AppOpacity.badgeTintOnDark : AppOpacity.badgeTintOnLight);
    return HabitIconLook(
      size: AppSizes.iconBadge,
      iconSize: AppSizes.iconBadge * AppSizes.iconToBadgeRatio,
      borderRadius: AppRadii.badge,
      backgroundColor: tint,
      opaqueBackgroundColor: Color.alphaBlend(tint, Theme.of(context).cardTheme.color!),
      iconColor: habitColor,
    );
  }

  /// On a surface filled with the habit color, such as the habit page's hero card.
  factory HabitIconLook.onHabitColor(Color habitColor) {
    final foregroundColor = foregroundColorReadableOn(habitColor);
    final overlay = foregroundColor.withValues(alpha: AppOpacity.overlayOnColor);
    return HabitIconLook(
      size: AppSizes.heroBadge,
      iconSize: AppSizes.iconHero,
      borderRadius: AppRadii.medium,
      backgroundColor: overlay,
      opaqueBackgroundColor: Color.alphaBlend(overlay, habitColor),
      iconColor: foregroundColor,
    );
  }

  final double size;
  final double iconSize;
  final double borderRadius;

  /// Translucent over the surface it sits on.
  final Color backgroundColor;

  /// [backgroundColor] already blended onto its surface: in flight, that surface is not behind.
  final Color opaqueBackgroundColor;
  final Color iconColor;
}

/// The habit icon flying from its home screen row to the habit page and back, morphing its
/// corners and colors on the way. It stays in place when the system asks for reduced motion.
class HabitIconHero extends StatelessWidget {
  const HabitIconHero({required this.habitId, required this.icon, required this.look, super.key});

  final int habitId;
  final IconData icon;
  final HabitIconLook look;

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: ('habit_icon', habitId),
        flightShuttleBuilder: _buildFlightShuttle,
        child: _HabitIconSquare(icon: icon, look: look),
      ),
    );
  }

  static Widget _buildFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    HabitIconLook lookOf(BuildContext heroContext) => ((heroContext.widget as Hero).child as _HabitIconSquare).look;
    // Both ways the animation runs from the row (0) to the page (1); a pop swaps from and to.
    final (rowLook, pageLook) = direction == HeroFlightDirection.push
        ? (lookOf(fromHeroContext), lookOf(toHeroContext))
        : (lookOf(toHeroContext), lookOf(fromHeroContext));
    final icon = ((toHeroContext.widget as Hero).child as _HabitIconSquare).icon;
    return HabitIconHeroShuttle(animation: animation, icon: icon, rowLook: rowLook, pageLook: pageLook);
  }
}

/// What flies between the two screens; public so tests can tell whether a flight happened.
class HabitIconHeroShuttle extends StatelessWidget {
  const HabitIconHeroShuttle({
    required this.animation,
    required this.icon,
    required this.rowLook,
    required this.pageLook,
    super.key,
  });

  final Animation<double> animation;
  final IconData icon;
  final HabitIconLook rowLook;
  final HabitIconLook pageLook;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        // The flight's box gives tight constraints, which win over the lerped size.
        return _HabitIconSquare(
          icon: icon,
          look: HabitIconLook(
            size: lerpDouble(rowLook.size, pageLook.size, progress)!,
            iconSize: lerpDouble(rowLook.iconSize, pageLook.iconSize, progress)!,
            borderRadius: lerpDouble(rowLook.borderRadius, pageLook.borderRadius, progress)!,
            backgroundColor: Color.lerp(rowLook.opaqueBackgroundColor, pageLook.opaqueBackgroundColor, progress)!,
            opaqueBackgroundColor: Color.lerp(rowLook.opaqueBackgroundColor, pageLook.opaqueBackgroundColor, progress)!,
            iconColor: Color.lerp(rowLook.iconColor, pageLook.iconColor, progress)!,
          ),
        );
      },
    );
  }
}

class _HabitIconSquare extends StatelessWidget {
  const _HabitIconSquare({required this.icon, required this.look});

  final IconData icon;
  final HabitIconLook look;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: look.size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: look.backgroundColor, borderRadius: BorderRadius.circular(look.borderRadius)),
        child: Center(
          child: Icon(icon, color: look.iconColor, size: look.iconSize),
        ),
      ),
    );
  }
}
