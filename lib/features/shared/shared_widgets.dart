import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';

/// Renders the loading and error states of [value] the same way on every screen, and
/// cross-fades between them so a screen never jumps from one state to the next.
///
/// An error is written to the private error log and offers to load [retryProvider] again.
class AsyncValueView<T> extends ConsumerStatefulWidget {
  const AsyncValueView({required this.value, required this.builder, required this.retryProvider, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) builder;
  final ProviderOrFamily retryProvider;

  @override
  ConsumerState<AsyncValueView<T>> createState() => _AsyncValueViewState<T>();
}

class _AsyncValueViewState<T> extends ConsumerState<AsyncValueView<T>> {
  static const Key _dataKey = ValueKey('data');
  static const Key _errorKey = ValueKey('error');
  static const Key _loadingKey = ValueKey('loading');

  @override
  void initState() {
    super.initState();
    _logErrorIfNew(previousValue: null);
  }

  @override
  void didUpdateWidget(AsyncValueView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logErrorIfNew(previousValue: oldWidget.value);
  }

  void _logErrorIfNew({required AsyncValue<T>? previousValue}) {
    final value = widget.value;
    if (value is! AsyncError<T> || identical(value.error, previousValue?.error)) return;
    unawaited(
      ref
          .read(appLoggerProvider)
          .logError(event: 'screen_load_failed', error: value.error, stackTrace: value.stackTrace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final value = widget.value;
    final (Key stateKey, Widget stateView) = switch (value) {
      AsyncData(:final value) => (_dataKey, widget.builder(value)),
      // While a retry runs the value is still an error, but loading: show the skeleton again.
      AsyncError() when !value.isLoading => (
        _errorKey,
        KomoEmptyState(
          mood: KomoMood.sleepy,
          title: localizations.loadErrorTitle,
          message: localizations.loadErrorMessage,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(widget.retryProvider),
            icon: const Icon(KomitIcons.rotateCw),
            label: Text(localizations.retryLoading),
          ),
        ),
      ),
      _ => (_loadingKey, const DelayedLoadingSkeleton()),
    };
    return AnimatedSwitcher(
      duration: motionAwareDuration(context, AppDurations.standard),
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      child: KeyedSubtree(key: stateKey, child: stateView),
    );
  }
}

/// Placeholder rows shaped like the content, shown only when loading lasts long enough to be
/// noticed: local reads usually finish first, and a skeleton flashing for a frame looks broken.
class DelayedLoadingSkeleton extends StatefulWidget {
  const DelayedLoadingSkeleton({super.key});

  @override
  State<DelayedLoadingSkeleton> createState() => _DelayedLoadingSkeletonState();
}

class _DelayedLoadingSkeletonState extends State<DelayedLoadingSkeleton> {
  late final Timer _revealTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _revealTimer = Timer(AppDurations.loadingSkeletonDelay, () => setState(() => _isVisible = true));
  }

  @override
  void dispose() {
    _revealTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: motionAwareDuration(context, AppDurations.standard),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.small, AppSpacing.screenGutter, 0),
            child: Column(
              children: [
                for (var index = 0; index < AppSizes.skeletonRowCount; index++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.medium),
                    child: _SkeletonRow(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholderDecoration = BoxDecoration(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadii.small),
    );
    return Container(
      height: AppSizes.skeletonRowHeight,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.iconBadge,
                height: AppSizes.iconBadge,
                decoration: placeholderDecoration.copyWith(borderRadius: BorderRadius.circular(AppRadii.badge)),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 0.5,
                  child: Container(height: AppSizes.skeletonLineHeight, decoration: placeholderDecoration),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(height: AppSizes.skeletonLineHeight, decoration: placeholderDecoration),
        ],
      ),
    );
  }
}

class HabitIconBadge extends StatelessWidget {
  const HabitIconBadge({required this.icon, required this.color, this.size = AppSizes.iconBadge, super.key});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? AppOpacity.badgeTintOnDark : AppOpacity.badgeTintOnLight),
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Icon(icon, color: color, size: size * AppSizes.iconToBadgeRatio),
    );
  }
}

/// A tappable card lifted by a soft shadow, that sinks while pressed and springs back on release,
/// so every card answers the finger the same way.
class PressableCard extends StatefulWidget {
  const PressableCard({
    required this.onTap,
    required this.child,
    this.color,
    this.shape,
    this.customSemanticsActions,
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final ShapeBorder? shape;

  /// Extra screen reader actions (e.g. "Move up"), offered on the card itself.
  final Map<CustomSemanticsAction, VoidCallback>? customSemanticsActions;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final shape = widget.shape ?? Theme.of(context).cardTheme.shape!;
    final isTransparent = widget.color == Colors.transparent;
    final inkWell = InkWell(
      onTap: () {
        unawaited(KomitHaptics.selection());
        widget.onTap();
      },
      onHighlightChanged: (isPressed) => setState(() => _isPressed = isPressed),
      child: widget.child,
    );
    return AnimatedScale(
      scale: _isPressed ? pressedScale : 1,
      // Quick to sink, springy to come back: the press feels physical.
      duration: motionAwareDuration(context, _isPressed ? AppDurations.quick : AppDurations.emphasized),
      curve: _isPressed ? AppCurves.standard : AppCurves.spring,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: isTransparent ? null : AppShadows.card(KomitColors.of(context).cardShadow),
        ),
        child: Card(
          color: widget.color,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          // Inside the card, whose semantics container merges them into the card's own node.
          child: Semantics(customSemanticsActions: widget.customSemanticsActions, child: inkWell),
        ),
      ),
    );
  }
}

/// A surface floating above the page: soft shadow and generous radius, not tappable.
class SoftCard extends StatelessWidget {
  const SoftCard({required this.child, this.padding = const EdgeInsets.all(AppSpacing.large), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = Theme.of(context).cardTheme.shape!;
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: AppShadows.card(KomitColors.of(context).cardShadow)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Blurs whatever scrolls behind [child], like iOS bars, with a translucent page-colored veil.
///
/// In an app bar's flexible space, the blur only runs once content scrolls under the bar: a
/// full-screen-wide blur over the plain page background costs GPU time every frame and shows
/// nothing.
class FrostedGlass extends StatelessWidget {
  const FrostedGlass({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final isContentScrolledUnder =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()?.isScrolledUnder ?? true;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.frostedSigma, sigmaY: AppBlur.frostedSigma),
        // Disabled rather than removed, so the bar's content keeps its state when the blur toggles.
        enabled: isContentScrolledUnder,
        child: ColoredBox(
          color: surface.withValues(alpha: AppOpacity.frostedSurface),
          child: child,
        ),
      ),
    );
  }
}

/// Lines the expanded large title may wrap to before it is ellipsized.
const int _largeTitleMaximumLines = 2;

/// Share of the collapse after which the large title has fully faded into the bar.
const double _largeTitleFadeOutShare = 0.6;

/// iOS-style large title: a bold title under the bar that scrolls away with the content, then
/// the same title fades into the frosted bar once it is collapsed.
///
/// The collapsed title is the toolbar title, so the toolbar lays it out between the back button
/// and the [actions]: it can never slide under them, whatever the length or the font scale.
class LargeTitleSliverAppBar extends StatelessWidget {
  const LargeTitleSliverAppBar({required this.title, this.actions = const [], super.key});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTextScaling.appBarMaximumScaleFactor,
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final expandedTitleStyle = Theme.of(context).textTheme.headlineLarge!.copyWith(color: colorScheme.onSurface);
          final expandedTitleHeight = _measureExpandedTitleHeight(context, expandedTitleStyle);
          return SliverAppBar.large(
            pinned: true,
            toolbarHeight: AppSizes.topAppBarHeight,
            expandedHeight: AppSizes.topAppBarHeight + AppSpacing.small + expandedTitleHeight + AppSpacing.large,
            titleSpacing: AppSpacing.screenGutter,
            actionsPadding: const EdgeInsetsDirectional.only(end: AppSpacing.appBarActionsEndInset),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: actions,
            flexibleSpace: FrostedGlass(
              child: _ExpandedLargeTitle(title: title, style: expandedTitleStyle),
            ),
          );
        },
      ),
    );
  }

  /// The bar grows with the title, so a two-line title or a large font is never cut.
  double _measureExpandedTitleHeight(BuildContext context, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: _largeTitleMaximumLines,
      ellipsis: '…',
    );
    // shortcut: assumes the bar spans the screen width, true for every Komit screen; measure with
    // a LayoutBuilder if a screen ever shows it in a side pane.
    painter.layout(maxWidth: MediaQuery.sizeOf(context).width - 2 * AppSpacing.screenGutter);
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

class _ExpandedLargeTitle extends StatelessWidget {
  const _ExpandedLargeTitle({required this.title, required this.style});

  final String title;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>()!;
    final collapsibleExtent = settings.maxExtent - settings.minExtent;
    final collapseProgress = collapsibleExtent <= 0
        ? 1.0
        : ((settings.maxExtent - settings.currentExtent) / collapsibleExtent).clamp(0.0, 1.0);
    final isCollapsed = collapseProgress >= 1;
    return Padding(
      // The title slides under the toolbar edge like content, instead of crossing the actions.
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + AppSizes.topAppBarHeight),
      child: ClipRect(
        child: Opacity(
          opacity: (1 - collapseProgress / _largeTitleFadeOutShare).clamp(0.0, 1.0),
          // Faded but not yet collapsed: still the screen's heading for screen readers.
          alwaysIncludeSemantics: !isCollapsed,
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
              child: Semantics(
                header: true,
                child: Text(title, style: style, maxLines: _largeTitleMaximumLines, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A field that reads as plain text inside a row or a page, without a box around it.
InputDecoration borderlessInlineInputDecoration({required String hintText}) => InputDecoration(
  hintText: hintText,
  counterText: '',
  filled: false,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
);

/// A number that counts up to [value] when it first appears and to each new value after, in
/// tabular figures so the digits do not jiggle. Screen readers only hear the final value.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({required this.value, required this.style, this.format, super.key});

  final int value;
  final TextStyle? style;

  /// Turns the number into text, e.g. "12 days"; the bare number by default.
  final String Function(int count)? format;

  @override
  Widget build(BuildContext context) {
    final format = this.format ?? (count) => '$count';
    return Semantics(
      label: format(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: value),
        duration: motionAwareDuration(context, AppDurations.counter),
        curve: AppCurves.standard,
        builder: (context, count, _) =>
            Text(format(count), style: style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot({required this.color, this.size = AppSizes.colorDot, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

/// A section heading with an optional trailing action, which moves under the heading when
/// both do not fit on one line (long translations, large fonts).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.extraLarge, bottom: AppSpacing.medium),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.small,
        children: [
          Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Returns true only when the user explicitly confirmed.
Future<bool> showDestructiveConfirmationDialog(
  BuildContext context, {
  required String message,
  required String confirmLabel,
  String? title,

  /// Names what staying means when "Cancel" would be ambiguous, e.g. "Keep editing".
  String? cancelLabel,
}) async {
  final localizations = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final isConfirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel ?? localizations.cancel)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return isConfirmed ?? false;
}

void showMessageSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    // With an action, Flutter keeps the message until the user acts on it or dismisses it.
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// Explains why Komit is about to ask Android for a permission, before Android asks.
/// Returns true only when the user chose [confirmLabel].
Future<bool> showPermissionRationaleSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final isConfirmed = await showModalBottomSheet<bool>(
    context: context,
    // Root navigator, like every Komit sheet: it covers the frosted navigation bar instead of sliding under it.
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final localizations = AppLocalizations.of(context);
      final textTheme = Theme.of(context).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, 0, AppSpacing.screenGutter, AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: HabitIconBadge(
                  icon: icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: AppSizes.heroBadge,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Semantics(header: true, child: Text(title, style: textTheme.headlineSmall)),
              const SizedBox(height: AppSpacing.small),
              Text(message, style: textTheme.bodyLarge?.copyWith(color: KomitColors.of(context).mutedText)),
              const SizedBox(height: AppSpacing.extraLarge),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.primaryButtonHeight)),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
              const SizedBox(height: AppSpacing.small),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.minimumTouchTarget)),
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.notNow),
              ),
            ],
          ),
        ),
      );
    },
  );
  return isConfirmed ?? false;
}
