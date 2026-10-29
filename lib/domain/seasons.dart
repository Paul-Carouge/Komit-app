import '../core/calendar_day.dart';

/// Holidays during which Komit dresses up, following the French calendar.
enum Season { halloween, christmas, easter }

/// Halloween week and the week after, ending on November 6.
const int halloweenSeasonDaysBefore = 7;
const int halloweenSeasonDaysAfter = 6;

/// From Palm Sunday to the Sunday after Easter, so Easter Monday (a French holiday) is included.
const int easterSeasonDaysAroundSunday = 7;

/// Advent to Epiphany.
const int christmasSeasonFirstDecemberDay = 1;
const int christmasSeasonLastJanuaryDay = 6;

/// The season [day] falls in, or null on an ordinary day.
Season? seasonOn(CalendarDay day) {
  final date = day.asUtcDate;
  final halloween = CalendarDay.fromDate(date.year, DateTime.october, 31);
  if (_isWithin(day, halloween.addDays(-halloweenSeasonDaysBefore), halloween.addDays(halloweenSeasonDaysAfter))) {
    return Season.halloween;
  }
  if ((date.month == DateTime.december && date.day >= christmasSeasonFirstDecemberDay) ||
      (date.month == DateTime.january && date.day <= christmasSeasonLastJanuaryDay)) {
    return Season.christmas;
  }
  final easter = easterSundayOf(date.year);
  if (_isWithin(day, easter.addDays(-easterSeasonDaysAroundSunday), easter.addDays(easterSeasonDaysAroundSunday))) {
    return Season.easter;
  }
  return null;
}

bool _isWithin(CalendarDay day, CalendarDay first, CalendarDay last) => !first.isAfter(day) && !day.isAfter(last);

/// Western (Gregorian) Easter Sunday, with the anonymous Gregorian algorithm (Meeus/Jones/Butcher).
CalendarDay easterSundayOf(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final dayOfMonth = (h + l - 7 * m + 114) % 31 + 1;
  return CalendarDay.fromDate(year, month, dayOfMonth);
}
