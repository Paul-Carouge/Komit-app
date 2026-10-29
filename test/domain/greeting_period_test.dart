import 'package:flutter_test/flutter_test.dart';
import 'package:komit/domain/greeting_period.dart';

void main() {
  test('each hour maps to the period that starts at or before it', () {
    expect(greetingPeriodForHour(morningStartHour - 1), GreetingPeriod.evening);
    expect(greetingPeriodForHour(morningStartHour), GreetingPeriod.morning);
    expect(greetingPeriodForHour(afternoonStartHour - 1), GreetingPeriod.morning);
    expect(greetingPeriodForHour(afternoonStartHour), GreetingPeriod.afternoon);
    expect(greetingPeriodForHour(eveningStartHour), GreetingPeriod.evening);
    expect(greetingPeriodForHour(0), GreetingPeriod.evening);
    expect(greetingPeriodForHour(23), GreetingPeriod.evening);
  });
}
