import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double extraSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;
  static const double huge = 32;
  static const double screenGutter = 20;
}

abstract final class AppRadii {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 28;
  static const double gridCell = 4;
}

abstract final class AppSizes {
  static const double minimumTouchTarget = 48;
  static const double iconBadge = 40;
  static const double colorDot = 14;
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
    required this.highlightContainer,
    required this.onHighlightContainer,
  });

  final Color emptyCell;
  final Color futureCell;
  final Color mutedText;

  /// Amber that keeps a 4.5:1 contrast on light containers, unlike the brand amber.
  final Color accentText;
  final Color notesGradientStart;
  final Color notesGradientEnd;
  final Color highlightContainer;
  final Color onHighlightContainer;

  static KomitColors of(BuildContext context) => Theme.of(context).extension<KomitColors>()!;

  @override
  KomitColors copyWith() => this;

  @override
  KomitColors lerp(KomitColors? other, double t) {
    if (other == null) return this;
    return KomitColors(
      emptyCell: Color.lerp(emptyCell, other.emptyCell, t)!,
      futureCell: Color.lerp(futureCell, other.futureCell, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      notesGradientStart: Color.lerp(notesGradientStart, other.notesGradientStart, t)!,
      notesGradientEnd: Color.lerp(notesGradientEnd, other.notesGradientEnd, t)!,
      highlightContainer: Color.lerp(highlightContainer, other.highlightContainer, t)!,
      onHighlightContainer: Color.lerp(onHighlightContainer, other.onHighlightContainer, t)!,
    );
  }
}

abstract final class _BrandColors {
  static const Color amber = Color(0xFFF9A825);
  static const Color nearBlack = Color(0xFF1A1A1A);
  static const Color danger = Color(0xFFD32F2F);
  static const Color dangerOnDark = Color(0xFFFF8A80);
  static const Color violet = Color(0xFF6B4CE5);
  static const Color purple = Color(0xFF9446FD);
}

final ThemeData lightAppTheme = _buildTheme(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: _BrandColors.amber,
    onPrimary: _BrandColors.nearBlack,
    primaryContainer: Color(0xFFFEEED3),
    onPrimaryContainer: Color(0xFF5C3B00),
    secondary: _BrandColors.violet,
    onSecondary: Colors.white,
    surface: Color(0xFFFBF6E5),
    onSurface: _BrandColors.nearBlack,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFFFEF7),
    surfaceContainer: Color(0xFFFFFEF7),
    surfaceContainerHigh: Color(0xFFF7F2E2),
    onSurfaceVariant: Color(0xFF5F5B52),
    outline: Color(0xFF8A857A),
    outlineVariant: Color(0xFFEAE5D6),
    error: _BrandColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFDE4E1),
    onErrorContainer: Color(0xFF8C1D18),
  ),
  komitColors: const KomitColors(
    emptyCell: Color(0xFFECEBE5),
    futureCell: Color(0xFFF5F4EE),
    mutedText: Color(0xFF6E6A60),
    accentText: Color(0xFF8A5300),
    notesGradientStart: _BrandColors.violet,
    notesGradientEnd: _BrandColors.purple,
    highlightContainer: Color(0xFFE3F2FD),
    onHighlightContainer: Color(0xFF0D47A1),
  ),
);

final ThemeData darkAppTheme = _buildTheme(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _BrandColors.amber,
    onPrimary: _BrandColors.nearBlack,
    primaryContainer: Color(0xFF4A3712),
    onPrimaryContainer: Color(0xFFFFDDA6),
    secondary: Color(0xFFB39DFF),
    onSecondary: _BrandColors.nearBlack,
    surface: Color(0xFF16140F),
    onSurface: Color(0xFFF4EFE2),
    surfaceContainerLowest: Color(0xFF0F0E0A),
    surfaceContainerLow: Color(0xFF1F1C16),
    surfaceContainer: Color(0xFF221F18),
    surfaceContainerHigh: Color(0xFF2C2820),
    onSurfaceVariant: Color(0xFFCBC5B6),
    outline: Color(0xFF9A9486),
    outlineVariant: Color(0xFF3A352B),
    error: _BrandColors.dangerOnDark,
    onError: _BrandColors.nearBlack,
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
    highlightContainer: Color(0xFF0E2A44),
    onHighlightContainer: Color(0xFF9FD0FF),
  ),
);

ThemeData _buildTheme({
  required Brightness brightness,
  required ColorScheme colorScheme,
  required KomitColors komitColors,
}) {
  final base = ThemeData(brightness: brightness, colorScheme: colorScheme, useMaterial3: true);
  final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.large));
  return base.copyWith(
    scaffoldBackgroundColor: colorScheme.surface,
    extensions: [komitColors],
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainerLowest,
      indicatorColor: colorScheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.large))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.medium), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.medium)),
        textStyle: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? colorScheme.primary : null,
      ),
    ),
  );
}
