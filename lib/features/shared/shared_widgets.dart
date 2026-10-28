import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../mascot/komo_empty_state.dart';
import '../mascot/komo_mascot.dart';

/// Renders the loading and error states of [value] the same way on every screen.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({required this.value, required this.builder, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError() => KomoEmptyState(mood: KomoMood.sleepy, title: AppLocalizations.of(context).genericError),
      _ => Center(child: CircularProgressIndicator(semanticsLabel: AppLocalizations.of(context).loading)),
    };
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

/// A tappable card that sinks slightly while pressed, so every card answers the finger the same way.
class PressableCard extends StatefulWidget {
  const PressableCard({required this.onTap, required this.child, this.color, this.shape, this.gradient, super.key});

  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final ShapeBorder? shape;

  /// Painted under the ink ripple, which a plain [Card.color] could not do with a gradient.
  final Gradient? gradient;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient;
    final inkWell = InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (isPressed) => setState(() => _isPressed = isPressed),
      child: widget.child,
    );
    return AnimatedScale(
      scale: _isPressed ? pressedScale : 1,
      duration: motionAwareDuration(context, AppDurations.quick),
      curve: AppCurves.standard,
      child: Card(
        color: widget.color,
        shape: widget.shape,
        clipBehavior: Clip.antiAlias,
        child: gradient == null
            ? inkWell
            : Ink(
                decoration: BoxDecoration(gradient: gradient),
                child: inkWell,
              ),
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

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.extraLarge, bottom: AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
          ),
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
}) async {
  final localizations = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final isConfirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(localizations.cancel)),
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

void showMessageSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
