import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';

const String _androidResourcesPath = 'android/app/src/main/res';

/// Reads `<color name="...">#AARRGGBB</color>` entries; the Android files hold nothing fancier.
Map<String, Color> _colorsInResourceFile(String relativePath) {
  final content = File('$_androidResourcesPath/$relativePath').readAsStringSync();
  return {
    for (final match in RegExp(r'<color name="(\w+)">#([0-9A-Fa-f]{8})</color>').allMatches(content))
      match.group(1)!: Color(int.parse(match.group(2)!, radix: 16)),
  };
}

void main() {
  test('the window behind Flutter has the page color of each theme, so the start never flashes', () {
    expect(_colorsInResourceFile('values/colors.xml')['komit_surface'], lightAppTheme.colorScheme.surface);
    expect(_colorsInResourceFile('values-night/colors.xml')['komit_surface'], darkAppTheme.colorScheme.surface);
  });

  test("the splash shows Komo's colors, which Flutter's first frame repeats", () {
    final colors = _colorsInResourceFile('values/colors.xml');
    final komitColors = lightAppTheme.extension<KomitColors>()!;
    expect(colors['komit_launch_background'], komitColors.mascotBody);
    expect(colors['komo_eye'], komitColors.mascotFace);
  });

  test('no normal window background is orange, in any Android version or night mode', () {
    for (final directory in ['values', 'values-night', 'values-v31', 'values-night-v31']) {
      final styles = File('$_androidResourcesPath/$directory/styles.xml').readAsStringSync();
      final normalTheme = RegExp(r'<style name="NormalTheme"[\s\S]*?</style>').firstMatch(styles)!.group(0)!;
      expect(normalTheme, contains('@color/komit_surface'), reason: directory);
    }
  });
}
