/// The part of the day the dashboard greets the user with.
enum GreetingPeriod { morning, afternoon, evening }

/// Hours (0..23) at which each period starts; the evening runs past midnight until morning,
/// so someone logging at 1 a.m. is still greeted for the evening they have not ended yet.
const int morningStartHour = 5;
const int afternoonStartHour = 12;
const int eveningStartHour = 18;

GreetingPeriod greetingPeriodForHour(int hour) {
  if (hour >= morningStartHour && hour < afternoonStartHour) return GreetingPeriod.morning;
  if (hour >= afternoonStartHour && hour < eveningStartHour) return GreetingPeriod.afternoon;
  return GreetingPeriod.evening;
}
