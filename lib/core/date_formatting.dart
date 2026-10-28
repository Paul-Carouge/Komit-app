import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'calendar_day.dart';

String formatFullDate(BuildContext context, CalendarDay day) =>
    DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).format(day.asLocalDate);
