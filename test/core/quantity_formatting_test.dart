import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/quantity_formatting.dart';

void main() {
  for (final localeTag in ['en', 'fr']) {
    test('an amount formatted for editing reads back unchanged in $localeTag', () {
      for (final amount in [10000.5, 1000000.0, 0.25, 8.0]) {
        expect(parseQuantity(formatQuantityForEditingIn(localeTag, amount)), amount);
      }
    });
  }

  test('grouping spaces are ignored, and anything not a finite number is refused', () {
    expect(parseQuantity('10 000,5'), 10000.5);
    expect(parseQuantity('10 000'), 10000);
    expect(parseQuantity(' 2 000 '), 2000);
    for (final text in ['NaN', 'Infinity', '', 'abc', '1.000.5']) {
      expect(parseQuantity(text), isNull, reason: text);
    }
  });
}
