import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/router.dart';

import '../support/komit_test_app.dart';

/// Renders the main screens to PNG files for visual review. Skipped unless
/// KOMIT_SCREENSHOT_DIR names the output folder; the files are never committed.
///
///     KOMIT_SCREENSHOT_DIR=/tmp/komit-shots flutter test test/screenshots
final String? _outputDirectory = Platform.environment['KOMIT_SCREENSHOT_DIR'];

/// A common modern phone, so the screenshots look like the real device.
const Size _phoneLogicalSize = Size(390, 844);

const List<int> _robotoWeights = [400, 500, 700, 800, 900];

Future<void> _loadRealFonts() async {
  final flutterRoot = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final materialFontsDirectory = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final weight in _robotoWeights) {
    final fileName = switch (weight) {
      400 => 'Roboto-Regular.ttf',
      500 => 'Roboto-Medium.ttf',
      700 => 'Roboto-Bold.ttf',
      _ => 'Roboto-Black.ttf',
    };
    final bytes = File('$materialFontsDirectory/$fileName').readAsBytesSync();
    roboto.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'));
  await lucide.load();
}

Future<void> _saveScreenshot(WidgetTester tester, String name) async {
  final renderView = tester.binding.renderViews.first;
  final layer = renderView.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(renderView.paintBounds);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File('$_outputDirectory/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (_outputDirectory != null) Directory(_outputDirectory!).createSync(recursive: true);
  });

  for (final (themeName, theme) in [('light', lightAppTheme), ('dark', darkAppTheme)]) {
    testWidgets('renders the main screens in $themeName', skip: _outputDirectory == null, (tester) async {
      await tester.runAsync(_loadRealFonts);
      final environment = await KomitTestEnvironment.create(
        tester,
        additionalHabitTitles: ['Drink water', 'Meditate ten minutes', 'Stretch after work'],
      );
      final router = await pumpKomitApp(tester, environment, theme: theme, logicalSize: _phoneLogicalSize);
      await _saveScreenshot(tester, 'dashboard_expanded_$themeName');
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await _saveScreenshot(tester, 'dashboard_collapsed_$themeName');

      for (final (name, location) in [
        ('details', AppRoutes.habitDetails(environment.runningHabitId)),
        ('statistics', AppRoutes.habitStatistics(environment.runningHabitId, komitTestNow.year)),
        ('settings', AppRoutes.settings),
        ('editor', AppRoutes.habitEditor(environment.runningHabitId)),
      ]) {
        // Pushed like in the app, so the bars show their back button.
        router.go(AppRoutes.habits);
        unawaited(router.push(location));
        await settleWithDatabaseWork(tester);
        await _saveScreenshot(tester, '${name}_$themeName');
      }
      router.go(AppRoutes.notes);
      await settleWithDatabaseWork(tester);
      await _saveScreenshot(tester, 'notes_$themeName');
      router.go(AppRoutes.habits);
      unawaited(router.push(AppRoutes.habitDetails(environment.runningHabitId)));
      await settleWithDatabaseWork(tester);
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      await _saveScreenshot(tester, 'details_scrolled_$themeName');
      await environment.dispose(tester);
    });
  }
}
