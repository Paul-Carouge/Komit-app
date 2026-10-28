import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/calendar_day.dart';
import 'package:komit/core/current_calendar_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('moves to the new day when the app resumes after midnight', () {
    var now = DateTime(2026, 3, 10, 23, 59);
    final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    addTearDown(container.dispose);

    expect(container.read(currentCalendarDayProvider), CalendarDay.fromDate(2026, 3, 10));

    now = DateTime(2026, 3, 11, 0, 1);
    container.read(currentCalendarDayProvider.notifier).refreshIfDayChanged();

    expect(container.read(currentCalendarDayProvider), CalendarDay.fromDate(2026, 3, 11));
  });

  test('keeps the same state within the same day', () {
    var now = DateTime(2026, 3, 10, 8);
    final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    addTearDown(container.dispose);
    final firstDay = container.read(currentCalendarDayProvider);

    now = DateTime(2026, 3, 10, 22);
    container.read(currentCalendarDayProvider.notifier).refreshIfDayChanged();

    expect(container.read(currentCalendarDayProvider), firstDay);
  });

  test('CalendarDay keeps the local date across the DST change', () {
    expect(CalendarDay.fromDateTime(DateTime(2026, 3, 29, 0, 30)), CalendarDay.fromDate(2026, 3, 29));
    expect(CalendarDay.fromDateTime(DateTime(2026, 3, 29, 23, 30)), CalendarDay.fromDate(2026, 3, 29));
    expect(CalendarDay.fromDate(2026, 3, 29).addDays(1).asLocalDate, DateTime(2026, 3, 30));
  });
}
