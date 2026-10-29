import 'package:flutter/services.dart';

/// Semantic haptic feedback, so every screen vibrates the same way for the same meaning.
///
/// Android plays these through the view's haptic feedback, which the system silences when the
/// user turned touch vibration off: no extra setting is needed to respect that choice.
abstract final class KomitHaptics {
  /// Gap between the two taps of [celebration]; short enough to read as a single "ta-da".
  static const Duration celebrationTapGap = Duration(milliseconds: 90);

  /// A choice moved: a chip, a step, a year, a toggle.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// A day was logged or something was saved.
  static Future<void> success() => HapticFeedback.lightImpact();

  /// A milestone worth celebrating, such as finishing the onboarding.
  static Future<void> celebration() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(celebrationTapGap);
    await HapticFeedback.lightImpact();
  }

  /// A card was picked up to be moved.
  static Future<void> lift() => HapticFeedback.mediumImpact();

  /// Something was removed or cleared on purpose.
  static Future<void> warning() => HapticFeedback.mediumImpact();

  /// An action failed.
  static Future<void> error() => HapticFeedback.heavyImpact();
}
