import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/seasons.dart';

void main() {
  test('Easter Sunday matches known dates', () {
    expect(easterSundayOf(2024), CalendarDay.fromDate(2024, 3, 31));
    expect(easterSundayOf(2025), CalendarDay.fromDate(2025, 4, 20));
    expect(easterSundayOf(2026), CalendarDay.fromDate(2026, 4, 5));
    expect(easterSundayOf(2027), CalendarDay.fromDate(2027, 3, 28));
    expect(easterSundayOf(2038), CalendarDay.fromDate(2038, 4, 25));
  });

  test('Halloween runs from October 24 to November 6', () {
    expect(seasonOn(CalendarDay.fromDate(2026, 10, 23)), isNull);
    expect(seasonOn(CalendarDay.fromDate(2026, 10, 24)), Season.halloween);
    expect(seasonOn(CalendarDay.fromDate(2026, 10, 31)), Season.halloween);
    expect(seasonOn(CalendarDay.fromDate(2026, 11, 6)), Season.halloween);
    expect(seasonOn(CalendarDay.fromDate(2026, 11, 7)), isNull);
  });

  test('Christmas runs from December 1 to Epiphany', () {
    expect(seasonOn(CalendarDay.fromDate(2026, 11, 30)), isNull);
    expect(seasonOn(CalendarDay.fromDate(2026, 12, 1)), Season.christmas);
    expect(seasonOn(CalendarDay.fromDate(2027, 1, 6)), Season.christmas);
    expect(seasonOn(CalendarDay.fromDate(2027, 1, 7)), isNull);
  });

  test('Easter runs from Palm Sunday to the Sunday after, Easter Monday included', () {
    // Easter 2026 is April 5.
    expect(seasonOn(CalendarDay.fromDate(2026, 3, 28)), isNull);
    expect(seasonOn(CalendarDay.fromDate(2026, 3, 29)), Season.easter);
    expect(seasonOn(CalendarDay.fromDate(2026, 4, 6)), Season.easter);
    expect(seasonOn(CalendarDay.fromDate(2026, 4, 12)), Season.easter);
    expect(seasonOn(CalendarDay.fromDate(2026, 4, 13)), isNull);
  });

  test('an ordinary day has no season', () {
    expect(seasonOn(CalendarDay.fromDate(2026, 7, 14)), isNull);
  });
}
