import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// January 1, 2024 was a Monday: day N of that month is weekday N.
const int _yearStartingOnMonday = 2024;

String _localeTagOf(BuildContext context) => Localizations.localeOf(context).toLanguageTag();

/// "Tuesday", "Mardi": capitalized, since it stands alone as a title (French weekdays are lowercase).
String weekdayName(BuildContext context, int weekday) => toBeginningOfSentenceCase(
  DateFormat.EEEE(_localeTagOf(context)).format(DateTime(_yearStartingOnMonday, DateTime.january, weekday)),
);

/// "March", "Mars": capitalized for the same reason.
String monthName(BuildContext context, int month) =>
    toBeginningOfSentenceCase(DateFormat.MMMM(_localeTagOf(context)).format(DateTime(_yearStartingOnMonday, month)));

/// "M", "T"…: one letter per weekday, Monday first, for the weekday strip.
List<String> narrowWeekdayNames(BuildContext context) {
  final format = DateFormat('EEEEE', _localeTagOf(context));
  return [
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
      format.format(DateTime(_yearStartingOnMonday, DateTime.january, weekday)),
  ];
}

/// "J", "F"…: one letter per month, for the month strip.
List<String> narrowMonthNames(BuildContext context) {
  final format = DateFormat('MMMMM', _localeTagOf(context));
  return [
    for (var month = 1; month <= DateTime.monthsPerYear; month++) format.format(DateTime(_yearStartingOnMonday, month)),
  ];
}
