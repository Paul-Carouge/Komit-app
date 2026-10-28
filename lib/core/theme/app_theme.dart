import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
  static const double huge = 32;
  static const double giant = 48;
  static const double screenGutter = 20;
}

/// Corner radii, from the sharpest (a day cell) to the roundest (cards and sheets).
abstract final class AppRadii {
  static const double gridCell = 4;
  static const double small = 8;
  static const double badge = 12;
  static const double medium = 16;
  static const double tile = 20;
  static const double large = 28;
}

abstract final class AppSizes {
  static const double minimumTouchTarget = 48;
  static const double iconBadge = 40;
  static const double heroBadge = 56;
  static const double colorDot = 14;
  static const double colorDotLarge = 24;
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconHero = 32;
  static const double hairline = 1;
  static const double emphasisBorderWidth = 2;
  static const double selectedSwatchBorderWidth = 3;

  /// Share of a badge filled by its icon; leaves the tinted square visible around it.
  static const double iconToBadgeRatio = 0.55;

  static const double mascotSmall = 56;
  static const double mascotMedium = 112;
  static const double mascotLarge = 184;

  /// Onboarding and empty states read as a column of text; wider lines hurt reading on tablets.
  static const double readableContentMaximumWidth = 480;
}

/// Opacities used to tint a surface with a habit or brand color.
abstract final class AppOpacity {
  static const double badgeTintOnLight = 0.14;
  static const double badgeTintOnDark = 0.22;
  static const double selectedTint = 0.16;

  /// A translucent layer of the foreground color over a saturated background (hero cards, banners).
  static const double overlayOnColor = 0.18;
}

/// Komit is flat by default: depth comes from surface container tones, shadows are reserved
/// for what floats above the page.
abstract final class AppElevation {
  static const double flat = 0;
  static const double floating = 3;
}

/// Product colors that Material's [ColorScheme] has no slot for.
@immutable
class KomitColors extends ThemeExtension<KomitColors> {
  const KomitColors({
    required this.emptyCell,
    required this.futureCell,
    required this.mutedText,
    required this.accentText,
    required this.notesGradientStart,
    required this.notesGradientEnd,
    required this.onNotesGradient,
    required this.highlightContainer,
    required this.onHighlightContainer,
    required this.mascotBody,
    required this.mascotBodyShade,
    required this.mascotFace,
    required this.mascotEyeHighlight,
    required this.mascotCheek,
    required this.mascotSprout,
    required this.mascotGroundShadow,
  });

  final Color emptyCell;
  final Color futureCell;
  final Color mutedText;

  /// Amber that keeps a 4.5:1 contrast on light containers, unlike the brand amber.
  final Color accentText;
  final Color notesGradientStart;
  final Color notesGradientEnd;
  final Color onNotesGradient;
  final Color highlightContainer;
  final Color onHighlightContainer;

  /// Komo, the mascot, is a living day cell: an amber tile with a sprout on top.
  final Color mascotBody;
  final Color mascotBodyShade;
  final Color mascotFace;
  final Color mascotEyeHighlight;
  final Color mascotCheek;
  final Color mascotSprout;
  final Color mascotGroundShadow;

  static KomitColors of(BuildContext context) => Theme.of(context).extension<KomitColors>()!;

  @override
  KomitColors copyWith() => this;

  @override
  KomitColors lerp(KomitColors? other, double t) {
    if (other == null) return this;
    Color lerpColor(Color from, Color to) => Color.lerp(from, to, t)!;
    return KomitColors(
      emptyCell: lerpColor(emptyCell, other.emptyCell),
      futureCell: lerpColor(futureCell, other.futureCell),
      mutedText: lerpColor(mutedText, other.mutedText),
      accentText: lerpColor(accentText, other.accentText),
      notesGradientStart: lerpColor(notesGradientStart, other.notesGradientStart),
      notesGradientEnd: lerpColor(notesGradientEnd, other.notesGradientEnd),
      onNotesGradient: lerpColor(onNotesGradient, other.onNotesGradient),
      highlightContainer: lerpColor(highlightContainer, other.highlightContainer),
      onHighlightContainer: lerpColor(onHighlightContainer, other.onHighlightContainer),
      mascotBody: lerpColor(mascotBody, other.mascotBody),
      mascotBodyShade: lerpColor(mascotBodyShade, other.mascotBodyShade),
      mascotFace: lerpColor(mascotFace, other.mascotFace),
      mascotEyeHighlight: lerpColor(mascotEyeHighlight, other.mascotEyeHighlight),
      mascotCheek: lerpColor(mascotCheek, other.mascotCheek),
      mascotSprout: lerpColor(mascotSprout, other.mascotSprout),
      mascotGroundShadow: lerpColor(mascotGroundShadow, other.mascotGroundShadow),
    );
  }
}

/// Mirrored in android/app/src/main/res/values*/colors.xml for the launcher icon and splash.
abstract final class _BrandColors {
  static const Color amber = Color(0xFFF9A825);
  static const Color amberShade = Color(0xFFE08A00);
  static const Color cream = Color(0xFFFBF6E5);

  /// Warm near-black: keeps text and Komo's face in the same family as the cream paper.
  static const Color ink = Color(0xFF231A10);
  static const Color nightSurface = Color(0xFF16140F);
  static const Color nightText = Color(0xFFF4EFE2);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerOnDark = Color(0xFFFF8A80);
  static const Color violet = Color(0xFF6B4CE5);
  static const Color purple = Color(0xFF9446FD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color coral = Color(0xB3FF7F6B);
}

/// Picks ink or white so text and icons stay readable on any user-chosen habit color.
Color foregroundColorReadableOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? _BrandColors.white : _BrandColors.ink;

final ThemeData lightAppTheme = _buildTheme(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: _BrandColors.amber,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFFFEEED3),
    onPrimaryContainer: Color(0xFF5C3B00),
    secondary: _BrandColors.violet,
    onSecondary: _BrandColors.white,
    surface: _BrandColors.cream,
    onSurface: _BrandColors.ink,
    surfaceContainerLowest: _BrandColors.white,
    surfaceContainerLow: Color(0xFFFFFEF7),
    surfaceContainer: Color(0xFFFFFEF7),
    surfaceContainerHigh: Color(0xFFF7F2E2),
    onSurfaceVariant: Color(0xFF5F5A50),
    outline: Color(0xFF8A847A),
    outlineVariant: Color(0xFFEAE4D4),
    inverseSurface: _BrandColors.ink,
    onInverseSurface: _BrandColors.cream,
    inversePrimary: _BrandColors.amber,
    error: _BrandColors.danger,
    onError: _BrandColors.white,
    errorContainer: Color(0xFFFDE4E1),
    onErrorContainer: Color(0xFF8C1D18),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFFECEAE2),
    futureCell: Color(0xFFF5F3EC),
    mutedText: Color(0xFF6E685D),
    accentText: Color(0xFF8A5300),
    notesGradientStart: _BrandColors.violet,
    notesGradientEnd: _BrandColors.purple,
    onNotesGradient: _BrandColors.white,
    highlightContainer: Color(0xFFE3F2FD),
    onHighlightContainer: Color(0xFF0D47A1),
    mascotBody: _BrandColors.amber,
    mascotBodyShade: _BrandColors.amberShade,
    mascotFace: _BrandColors.ink,
    mascotEyeHighlight: _BrandColors.cream,
    mascotCheek: _BrandColors.coral,
    mascotSprout: Color(0xFF4E8F35),
    mascotGroundShadow: Color(0x1A231A10),
  ),
);

final ThemeData darkAppTheme = _buildTheme(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _BrandColors.amber,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFF4A3712),
    onPrimaryContainer: Color(0xFFFFDDA6),
    secondary: Color(0xFFB39DFF),
    onSecondary: _BrandColors.ink,
    surface: _BrandColors.nightSurface,
    onSurface: _BrandColors.nightText,
    surfaceContainerLowest: Color(0xFF0F0E0A),
    surfaceContainerLow: Color(0xFF1F1C16),
    surfaceContainer: Color(0xFF221F18),
    surfaceContainerHigh: Color(0xFF2C2820),
    onSurfaceVariant: Color(0xFFCBC5B6),
    outline: Color(0xFF9A9486),
    outlineVariant: Color(0xFF3A352B),
    inverseSurface: _BrandColors.nightText,
    onInverseSurface: _BrandColors.ink,
    inversePrimary: Color(0xFF8A5300),
    error: _BrandColors.dangerOnDark,
    onError: _BrandColors.ink,
    errorContainer: Color(0xFF5C1A15),
    onErrorContainer: Color(0xFFFFDAD5),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFF2E2A21),
    futureCell: Color(0xFF221F18),
    mutedText: Color(0xFFA39E90),
    accentText: _BrandColors.amber,
    notesGradientStart: _BrandColors.violet,
    notesGradientEnd: _BrandColors.purple,
    onNotesGradient: _BrandColors.white,
    highlightContainer: Color(0xFF0E2A44),
    onHighlightContainer: Color(0xFF9FD0FF),
    mascotBody: _BrandColors.amber,
    mascotBodyShade: _BrandColors.amberShade,
    mascotFace: _BrandColors.ink,
    mascotEyeHighlight: _BrandColors.cream,
    mascotCheek: _BrandColors.coral,
    mascotSprout: Color(0xFF86C460),
    mascotGroundShadow: Color(0x40000000),
  ),
);

/// Fraunces carries the headings (screen titles, greetings, big numbers); the platform sans
/// keeps body text and labels highly legible.
abstract final class _DisplayTypeface {
  static const String family = 'Fraunces';

  /// Maximum softness rounds the serifs, echoing Komo's soft corners.
  static const double softness = 100;
  static const double displayWeight = 620;
  static const double headingWeight = 580;
}

/// Variable fonts ignore [TextStyle.fontWeight]; the weight and optical size are set as axes.
/// The nominal weight stays normal so the engine never adds a synthetic bold on top.
TextStyle? _displayTypefaceStyle(TextStyle? base, {required double weight}) => base?.copyWith(
  fontFamily: _DisplayTypeface.family,
  fontWeight: FontWeight.normal,
  fontVariations: [
    FontVariation.weight(weight),
    const FontVariation('SOFT', _DisplayTypeface.softness),
    FontVariation.opticalSize(base.fontSize ?? AppSpacing.extraLarge),
  ],
);

TextTheme _buildTextTheme(TextTheme base) => base.copyWith(
  displayLarge: _displayTypefaceStyle(base.displayLarge, weight: _DisplayTypeface.displayWeight),
  displayMedium: _displayTypefaceStyle(base.displayMedium, weight: _DisplayTypeface.displayWeight),
  displaySmall: _displayTypefaceStyle(base.displaySmall, weight: _DisplayTypeface.displayWeight),
  headlineLarge: _displayTypefaceStyle(base.headlineLarge, weight: _DisplayTypeface.headingWeight),
  headlineMedium: _displayTypefaceStyle(base.headlineMedium, weight: _DisplayTypeface.headingWeight),
  headlineSmall: _displayTypefaceStyle(base.headlineSmall, weight: _DisplayTypeface.headingWeight),
  titleLarge: _displayTypefaceStyle(base.titleLarge, weight: _DisplayTypeface.headingWeight),
  titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
);

ThemeData _buildTheme({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required KomitColors komitColors,
}) {
  final base = ThemeData(brightness: brightness, colorScheme: colorScheme, useMaterial3: true);
  final textTheme = _buildTextTheme(base.textTheme);
  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large));
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium));
  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [komitColors],
    textTheme: textTheme,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        // Matches Android 14+ predictive back; the fallback fade uses the cream page, not black.
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(fallbackColor: colorScheme.surface),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      scrolledUnderElevation: AppElevation.flat,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: AppElevation.flat,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLowest,
      indicatorColor: colorScheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.large))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: cardShape,
      titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onInverseSurface),
      actionTextColor: colorScheme.inversePrimary,
      elevation: AppElevation.floating,
      shape: controlShape,
    ),
    // Brand amber is too light on cream for a focus ring or a label (WCAG 1.4.11 asks 3:1),
    // so focused fields use the accent text color: deep amber by day, brand amber at night.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.medium), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: BorderSide(color: komitColors.accentText, width: AppSizes.emphasisBorderWidth),
      ),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.error)
              ? colorScheme.error
              : states.contains(WidgetState.focused)
              ? komitColors.accentText
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: komitColors.accentText,
      selectionHandleColor: komitColors.accentText,
      selectionColor: colorScheme.primary.withValues(alpha: AppOpacity.badgeTintOnDark),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
        shape: controlShape,
        textStyle: textTheme.titleMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
        shape: controlShape,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
        shape: controlShape,
        foregroundColor: komitColors.accentText,
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
      ),
    ),
  );
}
