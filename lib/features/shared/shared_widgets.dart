import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/ui/game_button.dart';
import '../../core/ui/game_text.dart';
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
      _ => const GameLoadingIndicator(),
    };
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: KomitColors.of(context).outline, width: AppOutline.thin),
      ),
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
          Expanded(child: GameTitle(text, style: Theme.of(context).textTheme.titleLarge)),
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
  final isConfirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actionsOverflowButtonSpacing: AppSpacing.small,
      actions: [
        GameButton(
          label: localizations.cancel,
          tone: GameButtonTone.neutral,
          isCompact: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        GameButton(
          label: confirmLabel,
          tone: GameButtonTone.danger,
          isCompact: true,
          onPressed: () => Navigator.of(context).pop(true),
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

/// Loading state: a chunky amber spinner, labeled for screen readers.
class GameLoadingIndicator extends StatelessWidget {
  const GameLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(semanticsLabel: AppLocalizations.of(context).loading));
}
