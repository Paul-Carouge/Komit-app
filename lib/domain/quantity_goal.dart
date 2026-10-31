/// A logged amount keeps three decimals, so repeated 0.1 steps add up to exactly 0.3.
const double _quantityRoundingFactor = 1000;

/// What a quantity habit asks for each day: [target] of [unit], [step] at a time (docs/adr/0008).
class QuantityGoal {
  const QuantityGoal({required this.unit, required this.target, required this.step});

  final String unit;
  final double target;

  /// The amount one tap adds.
  final double step;

  /// The success rule every surface shares: the day counts once the target is reached.
  bool isReachedBy(double? value) => value != null && value >= target;

  /// How much of the target [value] covers, from 0 to 1.
  double shareReachedBy(double? value) => value == null ? 0 : (value / target).clamp(0, 1).toDouble();
}

/// [value] rounded as it is stored.
double roundQuantity(double value) => (value * _quantityRoundingFactor).roundToDouble() / _quantityRoundingFactor;
