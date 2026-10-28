import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Renders the loading and error states of [value] the same way on every screen.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({required this.value, required this.builder, super.key});

  final AsyncValue<T> value;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Text(AppLocalizations.of(context).genericError, textAlign: TextAlign.center),
        ),
      ),
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
        color: color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(AppRadii.small + AppSpacing.extraSmall),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
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
