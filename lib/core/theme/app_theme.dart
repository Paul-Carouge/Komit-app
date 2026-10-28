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
/// Everything chunky is generously rounded: there is no sharp corner in Komit.
abstract final class AppRadii {
  static const double gridCell = 5;
  static const double small = 8;
  static const double badge = 14;
  static const double control = 16;
  static const double medium = 18;
  static const double tile = 22;
  static const double large = 28;
}

/// Thickness of the dark outline that draws every chunky component, like a sticker.
abstract final class AppOutline {
  /// Small things: badges, tags, day cells in the dashboard, progress bar tracks.
  static const double thin = 2;

  /// Buttons, cards, fields, chips: the default.
  static const double regular = 2.5;

  /// Hero cards and dialogs, which carry the most weight on a screen.
  static const double heavy = 3;

  /// Outline drawn around text set on a saturated color, in logical pixels per 24 px of type.
  static const double titleStrokePer24Pixels = 2.2;
}

/// Height of the darker band under a "3D" button face; the face sinks by this much when pressed.
abstract final class AppDepth {
  static const double button = 5;
  static const double compactButton = 4;
  static const double iconButton = 4;

  /// Cards do not sink: their depth is a soft drop shadow offset downwards.
  static const double cardShadowOffset = 4;
  static const double cardShadowBlur = 10;

  /// Habit and objective colors get their depth band by darkening the face color this much (HSL lightness).
  static const double shadeLightnessDrop = 0.16;
}

abstract final class AppSizes {
  static const double minimumTouchTarget = 48;
  static const double smallBadge = 32;
  static const double iconBadge = 40;
  static const double heroBadge = 56;
  static const double colorDot = 16;
  static const double colorDotLarge = 26;
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double iconHero = 30;
  static const double hairline = 1;
  static const double emphasisBorderWidth = 2;
  static const double selectedSwatchBorderWidth = 3.5;
  static const double progressBarHeight = 18;
  static const double compactProgressBarHeight = 12;

  /// Share of a badge filled by its icon; leaves the colored square visible around it.
  static const double iconToBadgeRatio = 0.55;

  /// Share of a glossy face covered by its top highlight band.
  static const double glossHeightRatio = 0.42;

  /// Height of the thin highlight line inside the top edge of a card.
  static const double cardGlossLineHeight = 4;

  static const double mascotSmall = 64;
  static const double mascotMedium = 120;
  static const double mascotLarge = 196;

  /// Onboarding and empty states read as a column of text; wider lines hurt reading on tablets.
  static const double readableContentMaximumWidth = 480;
}

/// From this text scale on, side-by-side layouts stack vertically so words are not cut mid-word.
const double largeTextScaleThreshold = 1.5;

/// Body text size at which the system text scale is measured; non-linear scalers grow small text more.
const double _textScaleReferenceFontSize = 16;

/// How much the user's font size setting enlarges body text: 1 by default, 2 at 200 %.
double bodyTextScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleReferenceFontSize) / _textScaleReferenceFontSize;

/// True when the user's font size calls for stacked layouts.
bool isLargeTextScale(BuildContext context) => bodyTextScaleOf(context) >= largeTextScaleThreshold;

/// Opacities used to tint a surface with a habit or brand color.
abstract final class AppOpacity {
  static const double badgeTintOnLight = 0.14;
  static const double badgeTintOnDark = 0.22;
  static const double selectedTint = 0.16;

  /// A translucent layer of the foreground color over a saturated background (hero cards, banners).
  static const double overlayOnColor = 0.2;

  /// A disabled chunky button keeps its shape but fades, so the layout does not jump.
  static const double disabledContent = 0.45;
}

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
    required this.outline,
    required this.gloss,
    required this.dropShadow,
    required this.neutralFace,
    required this.onNeutralFace,
    required this.focusRing,
    required this.notesFace,
    required this.onNotesFace,
    required this.streakFace,
    required this.onStreakFace,
    required this.mascotBody,
    required this.mascotBodyShade,
    required this.mascotOutline,
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

  /// The dark ink that outlines buttons, cards, badges and Komo.
  final Color outline;

  /// The translucent white band at the top of every glossy face.
  final Color gloss;
  final Color dropShadow;

  /// Secondary buttons and chips: a plain face that lets the primary amber lead.
  final Color neutralFace;
  final Color onNeutralFace;
  final Color focusRing;

  /// Grape violet of the notes tab and the statistics hero.
  final Color notesFace;
  final Color onNotesFace;

  /// Flame orange of the current streak.
  final Color streakFace;
  final Color onStreakFace;

  /// Komo, the mascot, is a living day cell: an amber tile with a sprout on top.
  final Color mascotBody;
  final Color mascotBodyShade;
  final Color mascotOutline;
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
      outline: lerpColor(outline, other.outline),
      gloss: lerpColor(gloss, other.gloss),
      dropShadow: lerpColor(dropShadow, other.dropShadow),
      neutralFace: lerpColor(neutralFace, other.neutralFace),
      onNeutralFace: lerpColor(onNeutralFace, other.onNeutralFace),
      focusRing: lerpColor(focusRing, other.focusRing),
      notesFace: lerpColor(notesFace, other.notesFace),
      onNotesFace: lerpColor(onNotesFace, other.onNotesFace),
      streakFace: lerpColor(streakFace, other.streakFace),
      onStreakFace: lerpColor(onStreakFace, other.onStreakFace),
      mascotBody: lerpColor(mascotBody, other.mascotBody),
      mascotBodyShade: lerpColor(mascotBodyShade, other.mascotBodyShade),
      mascotOutline: lerpColor(mascotOutline, other.mascotOutline),
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
  /// "Sunburst": Komo's body, the primary action, the logged-day joy.
  static const Color sunburst = Color(0xFFFFBC1F);
  static const Color sunburstShade = Color(0xFFE58E00);

  /// Plum ink: text and outlines. Close to black but in the violet family, so it ties amber and grape together.
  static const Color ink = Color(0xFF2A1F3D);
  static const Color cream = Color(0xFFFFF4DC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grape = Color(0xFF6B3FE0);
  static const Color grapeOnDark = Color(0xFF7C55F0);
  static const Color flame = Color(0xFFFF7A1A);
  static const Color mint = Color(0xFF2EC27E);
  static const Color tomato = Color(0xFFD92D20);
  static const Color tomatoOnDark = Color(0xFFFF8A80);
  static const Color coral = Color(0xCCFF7F6B);

  /// "Night arcade": a deep indigo instead of grey, so the dark theme stays colorful.
  static const Color night = Color(0xFF1A1736);
  static const Color nightCard = Color(0xFF28234F);
  static const Color nightRaised = Color(0xFF332D63);
  static const Color nightInk = Color(0xFF0B0918);
  static const Color nightText = Color(0xFFF4F1FF);
}

/// Picks ink or white so text and icons stay readable on any user-chosen habit color.
Color foregroundColorReadableOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? _BrandColors.white : _BrandColors.ink;

/// The darker band under a glossy face of [face] color.
Color depthShadeOf(Color face) {
  final hsl = HSLColor.fromColor(face);
  return hsl.withLightness((hsl.lightness - AppDepth.shadeLightnessDrop).clamp(0.0, 1.0)).toColor();
}

final ThemeData lightAppTheme = _buildTheme(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: _BrandColors.sunburst,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFFFFE6A8),
    onPrimaryContainer: Color(0xFF5C3B00),
    secondary: _BrandColors.grape,
    onSecondary: _BrandColors.white,
    tertiary: _BrandColors.mint,
    onTertiary: _BrandColors.ink,
    surface: _BrandColors.cream,
    onSurface: _BrandColors.ink,
    surfaceContainerLowest: _BrandColors.white,
    surfaceContainerLow: _BrandColors.white,
    surfaceContainer: Color(0xFFFFFAEE),
    surfaceContainerHigh: Color(0xFFFFEFCB),
    surfaceContainerHighest: Color(0xFFFBE7BC),
    onSurfaceVariant: Color(0xFF5E5670),
    outline: _BrandColors.ink,
    outlineVariant: Color(0xFFE9DFC8),
    inverseSurface: _BrandColors.ink,
    onInverseSurface: _BrandColors.cream,
    inversePrimary: _BrandColors.sunburst,
    error: _BrandColors.tomato,
    onError: _BrandColors.white,
    errorContainer: Color(0xFFFDE4E1),
    onErrorContainer: Color(0xFF8C1D18),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFFEDE5D3),
    futureCell: Color(0xFFF7F1E3),
    mutedText: Color(0xFF5E5670),
    accentText: Color(0xFF8A4B00),
    outline: _BrandColors.ink,
    gloss: Color(0x66FFFFFF),
    dropShadow: Color(0x332A1F3D),
    neutralFace: _BrandColors.white,
    onNeutralFace: _BrandColors.ink,
    focusRing: _BrandColors.grape,
    notesFace: _BrandColors.grape,
    onNotesFace: _BrandColors.white,
    streakFace: _BrandColors.flame,
    onStreakFace: _BrandColors.ink,
    mascotBody: _BrandColors.sunburst,
    mascotBodyShade: _BrandColors.sunburstShade,
    mascotOutline: _BrandColors.ink,
    mascotFace: _BrandColors.ink,
    mascotEyeHighlight: _BrandColors.white,
    mascotCheek: _BrandColors.coral,
    mascotSprout: _BrandColors.mint,
    mascotGroundShadow: Color(0x262A1F3D),
  ),
);

final ThemeData darkAppTheme = _buildTheme(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _BrandColors.sunburst,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFF4A3A1C),
    onPrimaryContainer: Color(0xFFFFDDA6),
    secondary: Color(0xFFB39DFF),
    onSecondary: _BrandColors.ink,
    tertiary: _BrandColors.mint,
    onTertiary: _BrandColors.ink,
    surface: _BrandColors.night,
    onSurface: _BrandColors.nightText,
    surfaceContainerLowest: Color(0xFF121027),
    surfaceContainerLow: _BrandColors.nightCard,
    surfaceContainer: _BrandColors.nightCard,
    surfaceContainerHigh: _BrandColors.nightRaised,
    surfaceContainerHighest: Color(0xFF3D3672),
    onSurfaceVariant: Color(0xFFB7B0DD),
    outline: _BrandColors.nightInk,
    outlineVariant: Color(0xFF3D3672),
    inverseSurface: _BrandColors.nightText,
    onInverseSurface: _BrandColors.ink,
    inversePrimary: Color(0xFF8A4B00),
    error: _BrandColors.tomatoOnDark,
    onError: _BrandColors.ink,
    errorContainer: Color(0xFF5C1A15),
    onErrorContainer: Color(0xFFFFDAD5),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFF3A3470),
    futureCell: Color(0xFF2F2A5C),
    mutedText: Color(0xFFB7B0DD),
    accentText: _BrandColors.sunburst,
    outline: _BrandColors.nightInk,
    gloss: Color(0x40FFFFFF),
    dropShadow: Color(0x80000000),
    neutralFace: _BrandColors.nightRaised,
    onNeutralFace: _BrandColors.nightText,
    focusRing: _BrandColors.sunburst,
    notesFace: _BrandColors.grapeOnDark,
    onNotesFace: _BrandColors.white,
    streakFace: _BrandColors.flame,
    onStreakFace: _BrandColors.ink,
    mascotBody: _BrandColors.sunburst,
    mascotBodyShade: _BrandColors.sunburstShade,
    mascotOutline: _BrandColors.nightInk,
    mascotFace: _BrandColors.ink,
    mascotEyeHighlight: _BrandColors.white,
    mascotCheek: _BrandColors.coral,
    mascotSprout: _BrandColors.mint,
    mascotGroundShadow: Color(0x66000000),
  ),
);

/// Lilita One (heavy, rounded, slightly condensed) speaks the playful voice: titles, big numbers,
/// button labels. Nunito's rounded terminals keep body text friendly and highly legible.
abstract final class AppTypefaces {
  static const String display = 'LilitaOne';
  static const String body = 'Nunito';

  /// Nunito is a variable font: its weight axis follows [TextStyle.fontWeight].
  static const FontWeight bodyWeight = FontWeight.w600;
  static const FontWeight strongWeight = FontWeight.w800;

  /// Lilita One has a single weight; asking for more would make the engine fake a bold.
  static const FontWeight displayWeight = FontWeight.w400;
  static const double displayLetterSpacing = 0.3;
}

TextStyle? _displayStyle(TextStyle? base) => base?.copyWith(
  fontFamily: AppTypefaces.display,
  fontWeight: AppTypefaces.displayWeight,
  letterSpacing: AppTypefaces.displayLetterSpacing,
);

TextTheme _buildTextTheme(TextTheme base) {
  final bodyTheme = base.apply(fontFamily: AppTypefaces.body);
  TextStyle? body(TextStyle? style) => style?.copyWith(fontWeight: AppTypefaces.bodyWeight);
  TextStyle? strong(TextStyle? style) => style?.copyWith(fontWeight: AppTypefaces.strongWeight);
  return bodyTheme.copyWith(
    displayLarge: _displayStyle(bodyTheme.displayLarge),
    displayMedium: _displayStyle(bodyTheme.displayMedium),
    displaySmall: _displayStyle(bodyTheme.displaySmall),
    headlineLarge: _displayStyle(bodyTheme.headlineLarge),
    headlineMedium: _displayStyle(bodyTheme.headlineMedium),
    headlineSmall: _displayStyle(bodyTheme.headlineSmall),
    titleLarge: _displayStyle(bodyTheme.titleLarge),
    titleMedium: strong(bodyTheme.titleMedium),
    titleSmall: strong(bodyTheme.titleSmall),
    bodyLarge: body(bodyTheme.bodyLarge),
    bodyMedium: body(bodyTheme.bodyMedium),
    bodySmall: body(bodyTheme.bodySmall),
    labelLarge: strong(bodyTheme.labelLarge),
    labelMedium: strong(bodyTheme.labelMedium),
    labelSmall: strong(bodyTheme.labelSmall),
  );
}

ThemeData _buildTheme({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required KomitColors komitColors,
}) {
  final base = ThemeData(brightness: brightness, colorScheme: colorScheme, useMaterial3: true);
  // ThemeData only merges font sizes into its text theme when Theme.of() reads it; merging them here
  // keeps the styles copied into component themes (app bar, dialogs, snack bars) at their real size.
  final textTheme = _buildTextTheme(Typography.englishLike2021.merge(base.textTheme));
  final regularOutline = BorderSide(color: komitColors.outline, width: AppOutline.regular);
  final heavyOutline = BorderSide(color: komitColors.outline, width: AppOutline.heavy);
  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.tile), side: regularOutline);
  final dialogShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large), side: heavyOutline);
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.control));
  OutlineInputBorder fieldBorder(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.control),
    borderSide: BorderSide(color: color, width: width),
  );
  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [komitColors],
    textTheme: textTheme,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        // Matches Android 14+ predictive back; the fallback fade uses the page color, not black.
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(fallbackColor: colorScheme.surface),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      scrolledUnderElevation: AppElevation.flat,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: komitColors.neutralFace,
      elevation: AppElevation.flat,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: komitColors.mutedText),
      iconColor: colorScheme.onSurface,
      minVerticalPadding: AppSpacing.medium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: komitColors.neutralFace,
      indicatorColor: colorScheme.primary,
      indicatorShape: StadiumBorder(side: regularOutline),
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge?.copyWith(color: colorScheme.onSurface)),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? colorScheme.onPrimary : colorScheme.onSurface,
          size: AppSizes.iconLarge,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      dragHandleColor: komitColors.outline,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.large)),
        side: heavyOutline,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: dialogShape,
      titleTextStyle: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
      contentTextStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: dialogShape,
      headerHeadlineStyle: textTheme.headlineMedium,
    ),
    timePickerTheme: TimePickerThemeData(backgroundColor: colorScheme.surface, shape: dialogShape),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onInverseSurface,
        fontWeight: AppTypefaces.strongWeight,
      ),
      actionTextColor: colorScheme.inversePrimary,
      elevation: AppElevation.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: colorScheme.primary, width: AppOutline.regular),
      ),
    ),
    // Brand amber is too light on cream for a focus ring or a label (WCAG 1.4.11 asks 3:1),
    // so focused fields use the accent text color: deep amber by day, brand amber at night.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: komitColors.neutralFace,
      border: fieldBorder(komitColors.outline, AppOutline.regular),
      enabledBorder: fieldBorder(komitColors.outline, AppOutline.regular),
      focusedBorder: fieldBorder(komitColors.accentText, AppOutline.heavy),
      errorBorder: fieldBorder(colorScheme.error, AppOutline.regular),
      focusedErrorBorder: fieldBorder(colorScheme.error, AppOutline.heavy),
      labelStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontWeight: AppTypefaces.strongWeight,
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
    // Only the system pickers (date, time) still use Material buttons; Komit's own use GameButton.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
        shape: controlShape,
        foregroundColor: komitColors.accentText,
        textStyle: textTheme.labelLarge,
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colorScheme.primary : komitColors.emptyCell,
      ),
      trackOutlineColor: WidgetStatePropertyAll(komitColors.outline),
      trackOutlineWidth: const WidgetStatePropertyAll(AppOutline.thin),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? komitColors.outline : komitColors.mutedText,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? komitColors.accentText : komitColors.mutedText,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      circularTrackColor: komitColors.emptyCell,
      strokeWidth: AppOutline.heavy * 2,
      strokeCap: StrokeCap.round,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: colorScheme.inverseSurface, borderRadius: BorderRadius.circular(AppRadii.small)),
      textStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onInverseSurface),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: AppOutline.thin),
  );
}
