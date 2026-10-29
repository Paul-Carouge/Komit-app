import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Komit's look: Material 3 Expressive shapes and type, with premium touches borrowed from iOS
/// (frosted bars, large titles, soft diffuse shadows, springy presses), kept native to Android.

abstract final class AppSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
  static const double huge = 32;
  static const double giant = 48;
  static const double screenGutter = 20;

  /// Space after the last app bar action, so it does not touch the screen edge.
  static const double appBarActionsEndInset = 8;
}

/// Corner radii, from the sharpest (a day cell) to the roundest (cards and sheets).
/// Expressive shapes are generous: nothing a finger touches has a sharp corner.
abstract final class AppRadii {
  static const double gridCell = 5;
  static const double small = 10;
  static const double badge = 14;
  static const double medium = 20;
  static const double tile = 24;
  static const double large = 32;
}

abstract final class AppSizes {
  static const double minimumTouchTarget = 48;

  /// Material 3 top app bar height, also the collapsed height of large-title bars.
  static const double topAppBarHeight = 64;

  /// Primary actions are taller than the minimum target, like Material 3 Expressive buttons.
  static const double primaryButtonHeight = 56;
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

  /// The round log-today button on each dashboard row: a full touch target, drawn at full size.
  static const double logButton = 48;
  static const double checkMarkStrokeWidth = 2.5;

  /// The today header's progress ring, and the thickness of its track.
  static const double todayProgressRing = 56;
  static const double todayProgressRingStrokeWidth = 6;

  /// One weekday toggle in the schedule picker; seven fit side by side on a 390 dp phone.
  static const double weekdayToggle = 44;

  /// Thickness of each habit's bar in the weekly recap: visible at a glance, thinner than text.
  static const double recapProgressBarHeight = 6;

  /// A spinner in place of a list tile's trailing icon while its action runs.
  static const double inlineProgressIndicator = 20;
  static const double inlineProgressIndicatorStroke = 2.5;

  static const double mascotSmall = 48;
  static const double mascotMedium = 112;
  static const double mascotLarge = 168;

  /// Onboarding and empty states read as a column of text; wider lines hurt reading on tablets.
  static const double readableContentMaximumWidth = 480;

  /// Height of one placeholder row while a list loads: about a dashboard habit row.
  static const double skeletonRowHeight = 112;
  static const double skeletonLineHeight = 12;
  static const int skeletonRowCount = 3;
}

/// Body text size at which the system text scale is measured; non-linear scalers grow small text more.
const double _textScaleReferenceFontSize = 16;

/// How much the user's font size setting enlarges body text: 1 by default, 2 at 200 %.
double bodyTextScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_textScaleReferenceFontSize) / _textScaleReferenceFontSize;

/// Limits on the user's font scale for text that is already large or must fit a fixed bar.
abstract final class AppTextScaling {
  /// Large titles start at headline size and app bars have a fixed height: past this factor
  /// they would push the content off a phone screen. Body text keeps the full scale.
  static const double appBarMaximumScaleFactor = 1.5;
}

/// Opacities used to tint a surface with a habit or brand color.
abstract final class AppOpacity {
  static const double badgeTintOnLight = 0.14;
  static const double badgeTintOnDark = 0.22;
  static const double selectedTint = 0.16;

  /// A translucent layer of the foreground color over a saturated background (hero cards, banners).
  static const double overlayOnColor = 0.18;

  /// Shadow of a card lifted for reordering, over the page color.
  static const double liftedShadow = 0.22;

  /// Frosted bars stay readable over any content while letting it show through.
  static const double frostedSurface = 0.78;
}

/// Material elevation stays at zero: depth comes from [AppShadows], which are softer than
/// Material's shadows, and from frosted glass.
abstract final class AppElevation {
  static const double flat = 0;
  static const double floating = 3;
}

/// Blur strength of frosted bars and sheets.
abstract final class AppBlur {
  static const double frostedSigma = 24;
}

/// One large, faint, offset shadow: cards look lifted without a visible edge. A tight contact
/// shadow would draw a gray ledge under each card, so there is none; the negative spread keeps
/// the shadow from peeking out at the sides.
abstract final class AppShadows {
  static const double _liftedBlurRadius = 40;
  static const Offset _liftedOffset = Offset(0, 18);

  static const double _cardBlurRadius = 32;
  static const double _cardSpreadRadius = -8;
  static const Offset _cardOffset = Offset(0, 12);

  /// Empty for a transparent [shadowColor]: dark mode lifts cards with lighter surfaces instead,
  /// and an invisible blur would still cost a draw on every frame.
  static List<BoxShadow> card(Color shadowColor) => shadowColor.a == 0
      ? const []
      : [
          BoxShadow(
            color: shadowColor,
            blurRadius: _cardBlurRadius,
            spreadRadius: _cardSpreadRadius,
            offset: _cardOffset,
          ),
        ];

  /// A card picked up to be moved: a deeper shadow, drawn in dark mode too, so it clearly floats.
  static List<BoxShadow> lifted(Color shadowColor) => [
    BoxShadow(
      color: shadowColor,
      blurRadius: _liftedBlurRadius,
      spreadRadius: _cardSpreadRadius,
      offset: _liftedOffset,
    ),
  ];
}

/// Product colors that Material's [ColorScheme] has no slot for.
@immutable
class KomitColors extends ThemeExtension<KomitColors> {
  const KomitColors({
    required this.emptyCell,
    required this.futureCell,
    required this.mutedText,
    required this.accentText,
    required this.highlightContainer,
    required this.onHighlightContainer,
    required this.cardShadow,
    required this.mascotBody,
    required this.mascotFace,
    required this.mascotGroundShadow,
  });

  final Color emptyCell;
  final Color futureCell;
  final Color mutedText;

  /// Orange that keeps a 4.5:1 contrast on cards, unlike the brand orange.
  final Color accentText;
  final Color highlightContainer;
  final Color onHighlightContainer;
  final Color cardShadow;

  /// Komo is the app icon come alive: an orange rounded square with two pill eyes.
  final Color mascotBody;
  final Color mascotFace;
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
      highlightContainer: lerpColor(highlightContainer, other.highlightContainer),
      onHighlightContainer: lerpColor(onHighlightContainer, other.onHighlightContainer),
      cardShadow: lerpColor(cardShadow, other.cardShadow),
      mascotBody: lerpColor(mascotBody, other.mascotBody),
      mascotFace: lerpColor(mascotFace, other.mascotFace),
      mascotGroundShadow: lerpColor(mascotGroundShadow, other.mascotGroundShadow),
    );
  }
}

/// Komo's orange, shared with code outside the theme such as the notification accent.
/// Mirrored in android/app/src/main/res/values/colors.xml for the launcher icon and splash.
const Color komitBrandOrange = Color(0xFFFF8C1A);

abstract final class _BrandColors {
  static const Color orange = komitBrandOrange;
  static const Color orangeOnDark = Color(0xFFFF9D42);

  /// Near-black of Komo's eyes, also used for text on orange.
  static const Color ink = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color danger = Color(0xFFD93025);
  static const Color dangerOnDark = Color(0xFFFF8A80);
  static const Color violet = Color(0xFF6B4CE5);
}

/// Transparent system bars for edge-to-edge, with icons readable on the app's background.
SystemUiOverlayStyle systemUiOverlayStyleFor(Brightness brightness) =>
    (brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      // The frosted navigation bar already separates content from the gesture bar.
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    );

/// Picks ink or white so text and icons stay readable on any user-chosen habit color.
Color foregroundColorReadableOn(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? _BrandColors.white : _BrandColors.ink;

final ThemeData lightAppTheme = _buildTheme(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: _BrandColors.orange,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFFFFE7D1),
    onPrimaryContainer: Color(0xFF5A2D00),
    secondary: _BrandColors.violet,
    onSecondary: _BrandColors.white,
    secondaryContainer: Color(0xFFEAE4FF),
    onSecondaryContainer: Color(0xFF2B1A73),
    surface: Color(0xFFF6F4F1),
    onSurface: _BrandColors.ink,
    surfaceContainerLowest: _BrandColors.white,
    surfaceContainerLow: _BrandColors.white,
    surfaceContainer: Color(0xFFF0EDE9),
    surfaceContainerHigh: Color(0xFFEAE6E1),
    surfaceContainerHighest: Color(0xFFE3DFD9),
    onSurfaceVariant: Color(0xFF5E5A54),
    outline: Color(0xFF8A857E),
    outlineVariant: Color(0xFFE5E1DB),
    inverseSurface: Color(0xFF2A2826),
    onInverseSurface: Color(0xFFF6F4F1),
    inversePrimary: _BrandColors.orangeOnDark,
    error: _BrandColors.danger,
    onError: _BrandColors.white,
    errorContainer: Color(0xFFFDE7E5),
    onErrorContainer: Color(0xFF8C1D18),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFFECE9E4),
    futureCell: Color(0xFFF4F2EF),
    mutedText: Color(0xFF6B665F),
    accentText: Color(0xFFAD4E00),
    highlightContainer: Color(0xFFFFE7D1),
    onHighlightContainer: Color(0xFF5A2D00),
    cardShadow: Color(0x0F2A1A08),
    mascotBody: _BrandColors.orange,
    mascotFace: _BrandColors.ink,
    mascotGroundShadow: Color(0x142A1A08),
  ),
);

final ThemeData darkAppTheme = _buildTheme(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _BrandColors.orangeOnDark,
    onPrimary: _BrandColors.ink,
    primaryContainer: Color(0xFF4D2A08),
    onPrimaryContainer: Color(0xFFFFDCC0),
    secondary: Color(0xFFB8A6FF),
    onSecondary: _BrandColors.ink,
    secondaryContainer: Color(0xFF3A2D7A),
    onSecondaryContainer: Color(0xFFEAE4FF),
    surface: Color(0xFF0F0E0D),
    onSurface: Color(0xFFF2EFEA),
    // Dark mode shows depth with lighter steps instead of shadows: page, then cards, then sheets.
    surfaceContainerLowest: Color(0xFF1B1A18),
    surfaceContainerLow: Color(0xFF1F1D1B),
    surfaceContainer: Color(0xFF232120),
    surfaceContainerHigh: Color(0xFF2C2A28),
    surfaceContainerHighest: Color(0xFF363330),
    onSurfaceVariant: Color(0xFFCAC5BD),
    outline: Color(0xFF948F87),
    outlineVariant: Color(0xFF34312E),
    inverseSurface: Color(0xFFF2EFEA),
    onInverseSurface: Color(0xFF1B1A18),
    inversePrimary: Color(0xFFAD4E00),
    error: _BrandColors.dangerOnDark,
    onError: _BrandColors.ink,
    errorContainer: Color(0xFF5C1A15),
    onErrorContainer: Color(0xFFFFDAD5),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFF2B2927),
    futureCell: Color(0xFF211F1E),
    mutedText: Color(0xFFA19C94),
    accentText: _BrandColors.orangeOnDark,
    highlightContainer: Color(0xFF4D2A08),
    onHighlightContainer: Color(0xFFFFDCC0),
    cardShadow: Color(0x00000000),
    mascotBody: _BrandColors.orange,
    mascotFace: _BrandColors.ink,
    mascotGroundShadow: Color(0x33000000),
  ),
);

/// Roboto with Material 3 Expressive emphasis: heavy, slightly tightened titles.
TextTheme _buildTextTheme(TextTheme base) => base.copyWith(
  headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
  headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
  headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
  titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
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
  // Sheets and dialogs float above cards: white in light mode, one step lighter than cards in dark.
  final floatingSurfaceColor = brightness == Brightness.dark
      ? colorScheme.surfaceContainerHigh
      : colorScheme.surfaceContainerLowest;
  final fieldShape = BorderRadius.circular(AppRadii.medium);
  const pillShape = StadiumBorder();
  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [komitColors],
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    actionIconTheme: ActionIconThemeData(backButtonIconBuilder: (context) => const Icon(LucideIcons.chevronLeft)),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        // Matches Android 14+ predictive back; the fallback fade uses the page color, not black.
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(fallbackColor: colorScheme.surface),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      scrolledUnderElevation: AppElevation.flat,
      centerTitle: false,
      systemOverlayStyle: systemUiOverlayStyleFor(brightness),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: AppElevation.flat,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      // Transparent: the bar sits on a frosted layer drawn by the scaffold.
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.flat,
      indicatorShape: pillShape,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: floatingSurfaceColor,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.large))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: floatingSurfaceColor,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium)),
    ),
    // Brand orange is too light on white for a focus ring or a label (WCAG 1.4.11 asks 3:1),
    // so focused fields use the accent text color.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: fieldShape, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: fieldShape,
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: fieldShape,
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
        minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight),
        shape: pillShape,
        textStyle: textTheme.titleMedium,
        elevation: AppElevation.flat,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
        shape: pillShape,
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSizes.minimumTouchTarget, AppSizes.minimumTouchTarget),
        shape: pillShape,
        foregroundColor: komitColors.accentText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.minimumTouchTarget)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: pillShape,
      side: BorderSide(color: colorScheme.outlineVariant),
      backgroundColor: colorScheme.surfaceContainerLowest,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
        // The default unselected label color is too faint on the page for WCAG AA.
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colorScheme.onPrimary : null,
      ),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: AppSizes.hairline, space: 0),
  );
}
