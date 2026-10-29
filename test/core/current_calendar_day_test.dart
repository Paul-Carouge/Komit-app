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

  testWidgets('flips at real midnight when the midnight timer fires one second early', (tester) async {
    var now = DateTime(2026, 3, 10, 23, 59);
    final container = ProviderContainer(overrides: [clockProvider.overrideWithValue(() => now)]);
    container.listen(currentCalendarDayProvider, (_, _) {});
    expect(container.read(currentCalendarDayProvider), CalendarDay.fromDate(2026, 3, 10));

    // The timer is due in 60 s; the wall clock lags and reads 23:59:59 when it fires.
    now = DateTime(2026, 3, 10, 23, 59, 59);
    await tester.pump(const Duration(minutes: 1));
    expect(container.read(currentCalendarDayProvider), CalendarDay.fromDate(2026, 3, 10));

    now = DateTime(2026, 3, 11);
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(currentCalendarDayProvider), CalendarDay.fromDate(2026, 3, 11));
    // Cancels the timer armed for the next midnight before the fake clock checks pending timers.
    container.dispose();
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
