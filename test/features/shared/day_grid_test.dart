import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/theme/app_theme.dart';
import 'package:komit/features/shared/day_grid.dart';

const Color _emptyColor = Color(0xFFEEEEEE);
const Color _loggedColor = Color(0xFF66BB6A);
const int _cellCount = 14;

Widget _grid(List<Color> colors, {bool areAnimationsDisabled = false}) => MaterialApp(
  theme: lightAppTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: areAnimationsDisabled),
    child: SizedBox(
      width: 280,
      child: DayGrid(
        columnCount: 7,
        cells: [for (final color in colors) DayGridCell(color: color, semanticLabel: '')],
      ),
    ),
  ),
);

List<Color> _colorsWithLoggedCells(Set<int> loggedIndexes) => [
  for (var index = 0; index < _cellCount; index++) loggedIndexes.contains(index) ? _loggedColor : _emptyColor,
];

void main() {
  testWidgets('a newly logged day pops into its cell', (tester) async {
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({})));
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({3})));

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('many cells changing at once (another year, a new day) change without popping', (tester) async {
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({})));
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({1, 2, 3, 4})));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a logged day does not pop when the system removes animations', (tester) async {
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({}), areAnimationsDisabled: true));
    await tester.pumpWidget(_grid(_colorsWithLoggedCells({3}), areAnimationsDisabled: true));

    expect(tester.hasRunningAnimations, isFalse);
  });
}
