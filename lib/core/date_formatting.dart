import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'calendar_day.dart';

String formatFullDate(BuildContext context, CalendarDay day) =>
    DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(day.asLocalDate);

/// "Oct 12": compact, for dense rows where the year is obvious.
String formatShortDate(BuildContext context, CalendarDay day) =>
    DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).format(day.asLocalDate);

/// "Wednesday, October 28": the day the user is looking at, spelled out.
String formatWeekdayAndDate(BuildContext context, CalendarDay day) =>
    DateFormat.MMMMEEEEd(Localizations.localeOf(context).toLanguageTag()).format(day.asLocalDate);

/// "Today", "Yesterday", or the spelled-out date: how people name the day they are logging.
String formatRelativeDay(BuildContext context, CalendarDay day, {required CalendarDay today}) {
  final localizations = AppLocalizations.of(context);
  if (day == today) return localizations.relativeToday;
  if (day == today.addDays(-1)) return localizations.relativeYesterday;
  return formatWeekdayAndDate(context, day);
}
