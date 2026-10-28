import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/domain/habit_statistics.dart';

void main() {
  final today = CalendarDay.fromDate(2026, 3, 10);
  List<CalendarDay> daysBeforeToday(Iterable<int> offsets) => [for (final offset in offsets) today.addDays(-offset)];

  group('computeStreakSummary', () {
    test('is zero without logs', () {
      final summary = computeStreakSummary(const [], today: today);
      expect(summary.currentStreakDays, 0);
      expect(summary.bestStreakDays, 0);
    });

    test('counts today and the consecutive days before it', () {
      final summary = computeStreakSummary(daysBeforeToday([0, 1, 2, 4]), today: today);
      expect(summary.currentStreakDays, 3);
      expect(summary.bestStreakDays, 3);
    });

    test('keeps the streak alive when today is not logged yet', () {
      expect(computeStreakSummary(daysBeforeToday([1, 2]), today: today).currentStreakDays, 2);
    });

    test('breaks the current streak after a missed day', () {
      expect(computeStreakSummary(daysBeforeToday([2, 3]), today: today).currentStreakDays, 0);
    });

    test('finds the best streak across a month boundary, ignoring order', () {
      final days = [
        CalendarDay.fromDate(2026, 3, 1),
        CalendarDay.fromDate(2026, 2, 27),
        CalendarDay.fromDate(2026, 2, 28),
        CalendarDay.fromDate(2026, 1, 1),
      ];
      expect(computeStreakSummary(days, today: today).bestStreakDays, 3);
    });
  });

  test('computeYearStatistics counts logs per objective and month for that year only', () {
    final statistics = computeYearStatistics({
      CalendarDay.fromDate(2025, 12, 31): 1,
      CalendarDay.fromDate(2026, 1, 1): 1,
      CalendarDay.fromDate(2026, 1, 2): 2,
      CalendarDay.fromDate(2026, 12, 31): 2,
    }, year: 2026);

    expect(statistics.logCountByObjectiveId, {1: 1, 2: 2});
    expect(statistics.logCountByMonth.first, 2);
    expect(statistics.logCountByMonth.last, 1);
    expect(statistics.totalLogCount, 3);
  });

  test('CalendarDay keeps the calendar date whatever the time of day', () {
    expect(CalendarDay.fromDateTime(DateTime(2026, 3, 29, 23, 59)), CalendarDay.fromDate(2026, 3, 29));
    expect(CalendarDay.fromDate(2026, 3, 29).asLocalDate, DateTime(2026, 3, 29));
  });
}
