import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Number of copies drawn around each glyph to fake a stroke; enough for a smooth outline up to 4 px.
const int _outlineShadowCount = 16;

/// The hard drop shadow under a title sits this many outline widths below it.
const double _dropShadowOutlineMultiple = 1.4;

/// Page titles drop an amber shadow of this share of their font size.
const double _pageTitleDropRatio = 0.08;

/// A stroke around every glyph, plus a hard drop shadow, made of [Shadow]s so the text stays one
/// [Text] widget: one semantics node, found once by tests, scaled by the user's font size.
List<Shadow> outlinedTextShadows({required Color outlineColor, required double outlineWidth}) => [
  for (var index = 0; index < _outlineShadowCount; index++)
    Shadow(color: outlineColor, offset: Offset.fromDirection(2 * math.pi * index / _outlineShadowCount, outlineWidth)),
  Shadow(color: outlineColor, offset: Offset(0, outlineWidth * _dropShadowOutlineMultiple)),
];

/// Outline width proportional to the font size, so small and large titles look equally chunky.
double titleOutlineWidthFor(TextStyle style) =>
    (style.fontSize ?? AppSpacing.extraLarge) / AppSpacing.extraLarge * AppOutline.titleStrokePer24Pixels;

/// A title in Komit's game voice.
///
/// On a plain page it is ink (white at night) with a hard amber drop shadow. On a saturated
/// [onColor] background it switches to the readable foreground; white text gets a dark outline,
/// like a game banner, which also keeps it legible on light habit colors.
class GameTitle extends StatelessWidget {
  const GameTitle(
    this.text, {
    this.style,
    this.onColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.isHeader = true,
    super.key,
  });

  final String text;

  /// Defaults to [TextTheme.headlineSmall].
  final TextStyle? style;

  /// The saturated color the title sits on; null on a plain page.
  final Color? onColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final komitColors = KomitColors.of(context);
    final baseStyle = style ?? theme.textTheme.headlineSmall!;
    final onColor = this.onColor;
    final TextStyle resolvedStyle;
    if (onColor == null) {
      resolvedStyle = baseStyle.copyWith(
        color: baseStyle.color ?? theme.colorScheme.onSurface,
        shadows: [
          Shadow(
            color: theme.colorScheme.primary,
            offset: Offset(0, (baseStyle.fontSize ?? AppSpacing.extraLarge) * _pageTitleDropRatio),
          ),
        ],
      );
    } else {
      final foregroundColor = foregroundColorReadableOn(onColor);
      final isLightText = foregroundColor.computeLuminance() > onColor.computeLuminance();
      resolvedStyle = baseStyle.copyWith(
        color: foregroundColor,
        shadows: isLightText
            ? outlinedTextShadows(outlineColor: komitColors.outline, outlineWidth: titleOutlineWidthFor(baseStyle))
            : [Shadow(color: komitColors.gloss, offset: Offset(0, titleOutlineWidthFor(baseStyle)))],
      );
    }
    return Semantics(
      header: isHeader,
      child: Text(text, style: resolvedStyle, textAlign: textAlign, maxLines: maxLines, overflow: overflow),
    );
  }
}
