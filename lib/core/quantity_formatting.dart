import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../domain/quantity_goal.dart';
import '../l10n/app_localizations.dart';

/// "1,5" in French, "1.5" in English: at most the three decimals an amount keeps.
String formatQuantity(BuildContext context, double value) => (NumberFormat.decimalPattern(
  Localizations.localeOf(context).toLanguageTag(),
)..maximumFractionDigits = 3).format(value);

/// Reads a typed amount with either decimal separator; null when it is not a number.
double? parseQuantity(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// "3/8 glasses": compact, for rows and messages.
String describeQuantityProgress(BuildContext context, QuantityGoal goal, double? value) =>
    AppLocalizations.of(context)
        .quantityProgress(formatQuantity(context, value ?? 0), formatQuantity(context, goal.target), goal.unit);

/// "3 of 8 glasses": what screen readers say for [describeQuantityProgress].
String describeQuantityProgressForScreenReaders(BuildContext context, QuantityGoal goal, double? value) =>
    AppLocalizations.of(
      context,
    ).quantityProgressSemantics(formatQuantity(context, value ?? 0), formatQuantity(context, goal.target), goal.unit);
