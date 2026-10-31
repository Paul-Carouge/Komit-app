import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/komit_icons.dart';
import '../../data/database/app_database.dart' show maximumQuantityUnitLength;
import '../../l10n/app_localizations.dart';
import '../shared/shared_widgets.dart';
import 'schedule_picker.dart';

/// Objectives or an amount: two rows in one card, like the schedule. The amount row opens its
/// unit, daily target and step (docs/adr/0008).
class HabitKindPicker extends StatelessWidget {
  const HabitKindPicker({
    required this.habitColor,
    required this.isQuantity,
    required this.isLocked,
    required this.quantitySummary,
    required this.unitController,
    required this.targetController,
    required this.stepController,
    required this.onKindChanged,
    super.key,
  });

  final Color habitColor;
  final bool isQuantity;

  /// True once the habit has a log: its logs would lose their meaning in the other kind.
  final bool isLocked;

  /// "8 glasses a day · 1 per tap" once the fields are filled; null while they are not.
  final String? quantitySummary;
  final TextEditingController unitController;
  final TextEditingController targetController;
  final TextEditingController stepController;
  final ValueChanged<bool> onKindChanged;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final mutedText = KomitColors.of(context).mutedText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          child: Column(
            children: [
              EditorOptionRow(
                icon: KomitIcons.listChecks,
                title: localizations.habitKindObjectives,
                subtitle: localizations.habitKindObjectivesHint,
                isSubtitleAnError: false,
                isSelected: !isQuantity,
                habitColor: habitColor,
                onSelected: isLocked ? null : () => onKindChanged(false),
                setting: null,
              ),
              EditorOptionRow(
                icon: KomitIcons.gauge,
                title: localizations.habitKindQuantity,
                subtitle: isQuantity
                    ? quantitySummary ?? localizations.habitKindQuantityHint
                    : localizations.habitKindQuantityHint,
                isSubtitleAnError: false,
                isSelected: isQuantity,
                habitColor: habitColor,
                onSelected: isLocked ? null : () => onKindChanged(true),
                setting: isQuantity
                    ? _QuantityFields(
                        unitController: unitController,
                        targetController: targetController,
                        stepController: stepController,
                      )
                    : null,
              ),
            ],
          ),
        ),
        if (isLocked)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.medium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(KomitIcons.lock, size: AppSizes.iconSmall, color: mutedText),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Text(
                    localizations.habitKindLocked,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mutedText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Unit on its own line (it reads as a word), then the two numbers side by side.
class _QuantityFields extends StatelessWidget {
  const _QuantityFields({required this.unitController, required this.targetController, required this.stepController});

  final TextEditingController unitController;
  final TextEditingController targetController;
  final TextEditingController stepController;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    InputDecoration decoration(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: '',
      fillColor: Theme.of(context).colorScheme.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        borderSide: BorderSide.none,
      ),
    );
    Widget numberField(TextEditingController controller, String label) => TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      textInputAction: TextInputAction.next,
      decoration: decoration(label),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Column(
        children: [
          TextField(
            controller: unitController,
            maxLength: maximumQuantityUnitLength,
            textInputAction: TextInputAction.next,
            decoration: decoration(localizations.quantityUnitLabel, hint: localizations.quantityUnitHint),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(child: numberField(targetController, localizations.quantityTargetLabel)),
              const SizedBox(width: AppSpacing.medium),
              Expanded(child: numberField(stepController, localizations.quantityStepLabel)),
            ],
          ),
        ],
      ),
    );
  }
}
