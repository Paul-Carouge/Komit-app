import 'package:flutter/material.dart';

import '../../core/theme/komit_icons.dart';

import '../../core/habit_appearance.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

const double _swatchSize = AppSizes.minimumTouchTarget;

/// Pickers stop short of full height so the screen behind stays visible as context.
const double _pickerSheetMaximumHeightFraction = 0.7;

/// An imported color outside the palette stays selectable instead of silently disappearing.
List<int> _selectableColorsArgb(int selectedColorArgb) => habitColorPaletteArgb.contains(selectedColorArgb)
    ? habitColorPaletteArgb
    : [selectedColorArgb, ...habitColorPaletteArgb];

Future<int?> showColorPickerSheet(BuildContext context, {required int selectedColorArgb}) {
  final colors = _selectableColorsArgb(selectedColorArgb);
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    builder: (context) => _PickerSheet(
      title: AppLocalizations.of(context).chooseColor,
      children: [
        for (final (index, colorArgb) in colors.indexed)
          Semantics(
            selected: colorArgb == selectedColorArgb,
            label: AppLocalizations.of(context).habitEditorColorSwatch(index + 1, colors.length),
            button: true,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(colorArgb),
              child: Container(
                width: _swatchSize,
                height: _swatchSize,
                decoration: BoxDecoration(
                  color: Color(colorArgb),
                  shape: BoxShape.circle,
                  border: colorArgb == selectedColorArgb
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: AppSizes.selectedSwatchBorderWidth,
                        )
                      : null,
                ),
                child: colorArgb == selectedColorArgb
                    ? Icon(KomitIcons.check, color: foregroundColorReadableOn(Color(colorArgb)))
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
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return _PickerSheet(
        title: AppLocalizations.of(context).chooseIcon,
        children: [
          for (final MapEntry(key: iconName, value: icon) in habitIconsByName.entries)
            IconButton(
              tooltip: iconName,
              isSelected: iconName == selectedIconName,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(_swatchSize),
                backgroundColor: iconName == selectedIconName
                    ? Color(colorArgb).withValues(alpha: AppOpacity.selectedTint)
                    : null,
              ),
              onPressed: () => Navigator.of(context).pop(iconName),
              icon: Icon(icon, color: iconName == selectedIconName ? Color(colorArgb) : colorScheme.onSurfaceVariant),
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
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.large),
              Wrap(spacing: AppSpacing.medium, runSpacing: AppSpacing.medium, children: children),
            ],
          ),
        ),
      ),
    );
  }
}

/// The habit's icon, large and filled with its color, at the top of the editor. A tap opens the
/// icon picker; the pencil disc says so. A new icon springs in, the one expressive moment here.
class HabitIdentityIconButton extends StatelessWidget {
  const HabitIdentityIconButton({required this.iconName, required this.colorArgb, required this.onPressed, super.key});

  final String iconName;
  final int colorArgb;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final habitColor = Color(colorArgb);
    final squareShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.tile));
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).chooseIcon,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSizes.habitIdentityIcon,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: motionAwareDuration(context, AppDurations.standard),
                curve: AppCurves.standard,
                decoration: ShapeDecoration(shape: squareShape, color: habitColor),
                child: Material(
                  type: MaterialType.transparency,
                  shape: squareShape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPressed,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: motionAwareDuration(context, AppDurations.emphasized),
                        switchInCurve: AppCurves.spring,
                        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          habitIconForName(iconName),
                          key: ValueKey(iconName),
                          size: AppSizes.iconHero,
                          color: foregroundColorReadableOn(habitColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -AppSpacing.extraSmall,
              bottom: -AppSpacing.extraSmall,
              child: IgnorePointer(
                child: Container(
                  width: AppSizes.editBadge,
                  height: AppSizes.editBadge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.inverseSurface,
                    border: Border.all(color: colorScheme.surfaceContainerLow, width: AppSizes.emphasisBorderWidth),
                  ),
                  child: Icon(KomitIcons.pencil, size: AppSizes.editBadgeIcon, color: colorScheme.onInverseSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every habit color on one scrolling line, so trying a color is one tap with the result in view.
class HabitColorStrip extends StatefulWidget {
  const HabitColorStrip({required this.selectedColorArgb, required this.onColorSelected, super.key});

  final int selectedColorArgb;
  final ValueChanged<int> onColorSelected;

  @override
  State<HabitColorStrip> createState() => _HabitColorStripState();
}

class _HabitColorStripState extends State<HabitColorStrip> {
  /// Colors left visible before the selected one when the strip opens, so it is not at the edge.
  static const int _colorsShownBeforeSelected = 2;

  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset:
        (_selectableColorsArgb(widget.selectedColorArgb).indexOf(widget.selectedColorArgb) - _colorsShownBeforeSelected)
            .clamp(0, habitColorPaletteArgb.length) *
        _swatchSize,
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _selectableColorsArgb(widget.selectedColorArgb);
    return SizedBox(
      height: _swatchSize,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        itemExtent: _swatchSize,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final colorArgb = colors[index];
          final isSelected = colorArgb == widget.selectedColorArgb;
          final color = Color(colorArgb);
          return Semantics(
            selected: isSelected,
            button: true,
            label: localizations.habitEditorColorSwatch(index + 1, colors.length),
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => widget.onColorSelected(colorArgb),
              radius: _swatchSize / 2,
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1 : pressedScale,
                  duration: motionAwareDuration(context, AppDurations.emphasized),
                  curve: AppCurves.spring,
                  child: Container(
                    width: AppSizes.colorSwatch,
                    height: AppSizes.colorSwatch,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colorScheme.onSurface, width: AppSizes.emphasisBorderWidth)
                          : null,
                    ),
                    child: isSelected
                        ? Icon(KomitIcons.check, size: AppSizes.iconMedium, color: foregroundColorReadableOn(color))
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
