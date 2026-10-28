import 'dart:async';

import 'package:flutter/material.dart';

import '../haptics.dart';
import '../theme/app_motion.dart';

/// Builds a chunky control for one frame of its press animation.
///
/// [pressProgress] is 0 at rest and 1 fully pressed; on release it springs back and briefly
/// goes below 0, which lets the face pop up past its resting place.
typedef GamePressableBuilder = Widget Function(BuildContext context, double pressProgress, bool isFocused);

/// Press, focus, keyboard and screen-reader behavior shared by every chunky control, so a
/// button, a chip and a card all answer the finger, the keyboard and TalkBack the same way.
class GamePressable extends StatefulWidget {
  const GamePressable({
    required this.onPressed,
    required this.builder,
    this.isSelected,
    this.semanticLabel,
    this.tooltip,
    super.key,
  });

  /// Null disables the control.
  final VoidCallback? onPressed;
  final GamePressableBuilder builder;

  /// Null when the control is not a toggle.
  final bool? isSelected;

  /// Replaces the label read from the children, e.g. for an icon-only button.
  final String? semanticLabel;
  final String? tooltip;

  @override
  State<GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<GamePressable> {
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isEnabled => widget.onPressed != null;

  void _setPressed(bool isPressed) {
    if (!_isEnabled || isPressed == _isPressed) return;
    if (isPressed) unawaited(KomitHaptics.press());
    setState(() => _isPressed = isPressed);
  }

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final duration = motionAwareDuration(context, _isPressed ? AppDurations.pressDown : AppDurations.pressRelease);
    Widget control = FocusableActionDetector(
      enabled: _isEnabled,
      mouseCursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowFocusHighlight: (isFocused) => setState(() => _isFocused = isFocused),
      actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _activate())},
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _isEnabled ? _activate : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _isPressed ? 1 : 0),
          duration: duration,
          curve: _isPressed ? AppCurves.standard : AppCurves.pressRelease,
          builder: (context, pressProgress, _) => widget.builder(context, pressProgress, _isFocused),
        ),
      ),
    );
    control = Semantics(
      container: true,
      button: true,
      enabled: _isEnabled,
      selected: widget.isSelected,
      label: widget.semanticLabel,
      onTap: _isEnabled ? _activate : null,
      excludeSemantics: widget.semanticLabel != null,
      child: control,
    );
    // Reads the label of the children as the button's own, as Material buttons do.
    if (widget.semanticLabel == null) control = MergeSemantics(child: control);
    final tooltip = widget.tooltip;
    return tooltip == null ? control : Tooltip(message: tooltip, excludeFromSemantics: true, child: control);
  }
}
