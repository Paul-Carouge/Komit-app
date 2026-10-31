import 'package:flutter_test/flutter_test.dart';
import 'package:komit/domain/quantity_goal.dart';

void main() {
  const goal = QuantityGoal(unit: 'glasses', target: 8, step: 1);

  test('a day succeeds once its amount reaches the target, and not before', () {
    expect(goal.isReachedBy(null), isFalse);
    expect(goal.isReachedBy(7.999), isFalse);
    expect(goal.isReachedBy(8), isTrue);
    expect(goal.isReachedBy(12), isTrue);
  });

  test('the share of the target stays between 0 and 1', () {
    expect(goal.shareReachedBy(null), 0);
    expect(goal.shareReachedBy(2), 0.25);
    expect(goal.shareReachedBy(20), 1);
  });

  test('amounts keep three decimals', () {
    expect(roundQuantity(0.1 + 0.2), 0.3);
    expect(roundQuantity(1.23456), 1.235);
  });
}
