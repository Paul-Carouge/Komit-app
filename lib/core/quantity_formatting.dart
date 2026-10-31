import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../domain/quantity_goal.dart';
import '../l10n/app_localizations.dart';

/// "1,5" in French, "1.5" in English, grouped ("10,000"): at most the three decimals an amount
/// keeps. For display only; a field gets [formatQuantityForEditing].
String formatQuantity(BuildContext context, double value) =>
    _quantityFormat(Localizations.localeOf(context).toLanguageTag()).format(value);

/// Like [formatQuantity] without grouping, so [parseQuantity] reads the text back unchanged:
/// a grouping comma would read as a decimal separator ("10,000" as 10).
String formatQuantityForEditing(BuildContext context, double value) =>
    formatQuantityForEditingIn(Localizations.localeOf(context).toLanguageTag(), value);

/// [formatQuantityForEditing] for a locale tag, outside the widget tree.
String formatQuantityForEditingIn(String localeTag, double value) =>
    (_quantityFormat(localeTag)..turnOffGrouping()).format(value);

NumberFormat _quantityFormat(String localeTag) => NumberFormat.decimalPattern(localeTag)..maximumFractionDigits = 3;

/// Spaces some locales group digits with (French uses a narrow no-break space).
final RegExp _groupingSpaces = RegExp(r'[\s\u00A0\u202F]');

/// Reads a typed amount with either decimal separator, ignoring grouping spaces; null when it is
/// not a finite number.
double? parseQuantity(String text) {
  final value = double.tryParse(text.replaceAll(_groupingSpaces, '').replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

/// "3/8 glasses": compact, for rows and messages.
String describeQuantityProgress(BuildContext context, QuantityGoal goal, double? value) =>
    AppLocalizations.of(context)
        .quantityProgress(formatQuantity(context, value ?? 0), formatQuantity(context, goal.target), goal.unit);

/// "3 of 8 glasses": what screen readers say for [describeQuantityProgress].
String describeQuantityProgressForScreenReaders(BuildContext context, QuantityGoal goal, double? value) =>
    AppLocalizations.of(
      context,
    ).quantityProgressSemantics(formatQuantity(context, value ?? 0), formatQuantity(context, goal.target), goal.unit);
