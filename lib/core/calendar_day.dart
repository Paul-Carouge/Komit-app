/// A calendar date without time or time zone, stored as days since 1970-01-01.
///
/// Logs are keyed by calendar day, not by instant: a habit logged "on the 5th"
/// must stay on the 5th whatever the device time zone or DST changes.
extension type const CalendarDay(int daysSinceEpoch) implements Object {
  factory CalendarDay.fromDate(int year, int month, int day) =>
      CalendarDay(DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay);

  /// Takes the local calendar date of [dateTime], ignoring its time of day.
  factory CalendarDay.fromDateTime(DateTime dateTime) =>
      CalendarDay.fromDate(dateTime.year, dateTime.month, dateTime.day);

  DateTime get asUtcDate =>
      DateTime.fromMillisecondsSinceEpoch(daysSinceEpoch * Duration.millisecondsPerDay, isUtc: true);

  /// Local midnight of this day, for display and formatting.
  DateTime get asLocalDate {
    final utcDate = asUtcDate;
    return DateTime(utcDate.year, utcDate.month, utcDate.day);
  }

  int get year => asUtcDate.year;

  /// [DateTime.monday]..[DateTime.sunday].
  int get weekday => asUtcDate.weekday;

  /// The Monday that starts this day's ISO week, as weekly targets count weeks.
  CalendarDay get mondayOfWeek => addDays(-(weekday - DateTime.monday));

  CalendarDay addDays(int days) => CalendarDay(daysSinceEpoch + days);

  bool isAfter(CalendarDay other) => daysSinceEpoch > other.daysSinceEpoch;
}
