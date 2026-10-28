import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import 'game_pressable.dart';
import 'game_surface_painter.dart';
import 'game_text.dart';

/// What a [GameButton] means, which decides its colors.
enum GameButtonTone {
  /// The one main action of a screen or sheet: amber.
  primary,

  /// Every other action: a plain face that lets the primary lead.
  neutral,

  /// Deletes or replaces data: red.
  danger,
}

/// Komit's button: a glossy face on a darker depth band, both outlined in ink.
/// The face sinks into the band while pressed and springs back with a little bounce.
class GameButton extends StatelessWidget {
  const GameButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.trailing,
    this.tone = GameButtonTone.primary,
    this.faceColor,
    this.isSelected,
    this.isCompact = false,
    this.semanticLabel,
    super.key,
  });

  final String label;

  /// Replaces [label] for screen readers when the visible text alone is ambiguous, e.g. a bare year.
  final String? semanticLabel;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Replaces [icon] when the leading element is not an icon, e.g. a color dot.
  final Widget? leading;
  final Widget? trailing;
  final GameButtonTone tone;

  /// Overrides the tone's face color, e.g. with an objective color.
  final Color? faceColor;

  /// Non-null makes the button a toggle that screen readers announce as selected or not.
  final bool? isSelected;

  /// A shorter, tighter button for chips, toolbars and dialog actions.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onPressed != null;
    final face =
        faceColor ??
        switch (tone) {
          GameButtonTone.primary => colorScheme.primary,
          GameButtonTone.neutral => komitColors.neutralFace,
          GameButtonTone.danger =>
            colorScheme.brightness == Brightness.light ? colorScheme.error : depthShadeOf(colorScheme.error),
        };
    final resolvedFace = isEnabled ? face : komitColors.emptyCell;
    final foregroundColor = tone == GameButtonTone.neutral && faceColor == null
        ? komitColors.onNeutralFace
        : foregroundColorReadableOn(resolvedFace);
    final depth = isCompact ? AppDepth.compactButton : AppDepth.button;
    final labelBaseStyle = (isCompact ? textTheme.titleMedium : textTheme.titleLarge)!.copyWith(
      fontFamily: AppTypefaces.display,
      fontWeight: AppTypefaces.displayWeight,
    );
    final isLightLabel = foregroundColor.computeLuminance() > resolvedFace.computeLuminance();
    final labelStyle = labelBaseStyle.copyWith(
      color: foregroundColor,
      // White labels get the ink outline of game banners; dark labels stay crisp without it.
      shadows: isLightLabel && isEnabled
          ? outlinedTextShadows(
              outlineColor: komitColors.outline,
              outlineWidth: titleOutlineWidthFor(labelBaseStyle) / 2,
            )
          : null,
    );
    final icon = this.icon;
    final leading = this.leading ?? (icon == null ? null : Icon(icon));
    final trailing = this.trailing;
    final horizontalPadding = isCompact ? AppSpacing.large : AppSpacing.extraLarge;
    return GamePressable(
      onPressed: onPressed,
      isSelected: isSelected,
      semanticLabel: semanticLabel,
      builder: (context, pressProgress, isFocused) {
        final faceOffset = isEnabled ? depth * pressProgress : 0.0;
        return CustomPaint(
          painter: GameSurfacePainter(
            faceColor: resolvedFace,
            outlineColor: komitColors.outline,
            glossColor: komitColors.gloss,
            cornerRadius: isCompact ? AppRadii.control : AppRadii.medium,
            outlineWidth: AppOutline.regular,
            depth: depth,
            faceOffset: faceOffset,
            focusRingColor: isFocused ? komitColors.focusRing : null,
          ),
          child: Transform.translate(
            offset: Offset(0, faceOffset),
            child: Padding(
              padding: EdgeInsets.only(bottom: depth),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: AppSizes.minimumTouchTarget - (isCompact ? depth : 0),
                  minWidth: AppSizes.minimumTouchTarget,
                ),
                child: Opacity(
                  opacity: isEnabled ? 1 : AppOpacity.disabledContent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.small),
                    child: IconTheme.merge(
                      data: IconThemeData(
                        color: foregroundColor,
                        size: isCompact ? AppSizes.iconMedium : AppSizes.iconLarge,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (leading != null) ...[leading, const SizedBox(width: AppSpacing.small)],
                          Flexible(
                            child: Text(label, style: labelStyle, textAlign: TextAlign.center),
                          ),
                          if (trailing != null) ...[const SizedBox(width: AppSpacing.small), trailing],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A square chunky button with a single icon; [tooltip] is also its screen-reader label.
class GameIconButton extends StatelessWidget {
  const GameIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = GameButtonTone.neutral,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final GameButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final komitColors = KomitColors.of(context);
    final isEnabled = onPressed != null;
    final face = !isEnabled
        ? komitColors.emptyCell
        : switch (tone) {
            GameButtonTone.primary => colorScheme.primary,
            GameButtonTone.neutral => komitColors.neutralFace,
            GameButtonTone.danger => colorScheme.error,
          };
    final foregroundColor = tone == GameButtonTone.neutral
        ? komitColors.onNeutralFace
        : foregroundColorReadableOn(face);
    return GamePressable(
      onPressed: onPressed,
      tooltip: tooltip,
      semanticLabel: tooltip,
      builder: (context, pressProgress, isFocused) {
        final faceOffset = isEnabled ? AppDepth.iconButton * pressProgress : 0.0;
        return SizedBox.square(
          dimension: AppSizes.minimumTouchTarget,
          child: CustomPaint(
            painter: GameSurfacePainter(
              faceColor: face,
              outlineColor: komitColors.outline,
              glossColor: komitColors.gloss,
              cornerRadius: AppRadii.badge,
              outlineWidth: AppOutline.regular,
              depth: AppDepth.iconButton,
              faceOffset: faceOffset,
              focusRingColor: isFocused ? komitColors.focusRing : null,
            ),
            child: Transform.translate(
              offset: Offset(0, faceOffset),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDepth.iconButton),
                child: Center(
                  child: Opacity(
                    opacity: isEnabled ? 1 : AppOpacity.disabledContent,
                    child: Icon(icon, color: foregroundColor, size: AppSizes.iconMedium),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// [GameIconButton] that goes back, for app bars.
class GameBackButton extends StatelessWidget {
  const GameBackButton({this.onPressed, super.key});

  /// Defaults to popping the current route.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GameIconButton(
        icon: LucideIcons.arrowLeft,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
