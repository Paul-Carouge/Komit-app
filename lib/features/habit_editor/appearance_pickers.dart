import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/habit_appearance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/game_text.dart';
import '../../l10n/app_localizations.dart';

const double _swatchSize = AppSizes.minimumTouchTarget;

/// Pickers stop short of full height so the screen behind stays visible as context.
const double _pickerSheetMaximumHeightFraction = 0.7;

Future<int?> showColorPickerSheet(BuildContext context, {required int selectedColorArgb}) {
  // An imported color outside the palette stays selectable instead of silently disappearing.
  final colors = habitColorPaletteArgb.contains(selectedColorArgb)
      ? habitColorPaletteArgb
      : [selectedColorArgb, ...habitColorPaletteArgb];
  return showModalBottomSheet<int>(
    context: context,
    builder: (context) => _PickerSheet(
      title: AppLocalizations.of(context).chooseColor,
      children: [
        for (final colorArgb in colors)
          Semantics(
            selected: colorArgb == selectedColorArgb,
            label: '#${colorArgb.toRadixString(16).substring(2).toUpperCase()}',
            button: true,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(colorArgb),
              child: Container(
                width: _swatchSize,
                height: _swatchSize,
                decoration: BoxDecoration(
                  color: Color(colorArgb),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: KomitColors.of(context).outline,
                    width: colorArgb == selectedColorArgb ? AppSizes.selectedSwatchBorderWidth : AppOutline.regular,
                  ),
                ),
                child: colorArgb == selectedColorArgb
                    ? Icon(LucideIcons.check, color: foregroundColorReadableOn(Color(colorArgb)))
                    : null,
              ),
            ),
          ),
      ],
    ),
  );
}

Future<String?> showIconPickerSheet(BuildContext context, {required String selectedIconName, required int colorArgb}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final komitColors = KomitColors.of(context);
      final habitColor = Color(colorArgb);
      return _PickerSheet(
        title: AppLocalizations.of(context).chooseIcon,
        children: [
          for (final MapEntry(key: iconName, value: icon) in habitIconsByName.entries)
            IconButton(
              tooltip: iconName,
              isSelected: iconName == selectedIconName,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(_swatchSize),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.badge)),
                backgroundColor: iconName == selectedIconName ? habitColor : null,
                side: iconName == selectedIconName
                    ? BorderSide(color: komitColors.outline, width: AppOutline.regular)
                    : null,
              ),
              onPressed: () => Navigator.of(context).pop(iconName),
              icon: Icon(
                icon,
                color: iconName == selectedIconName
                    ? foregroundColorReadableOn(habitColor)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      );
    },
  );
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * _pickerSheetMaximumHeightFraction),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            0,
            AppSpacing.screenGutter,
            AppSpacing.extraLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameTitle(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.large),
              Wrap(spacing: AppSpacing.medium, runSpacing: AppSpacing.medium, children: children),
            ],
          ),
        ),
      ),
    );
  }
}
