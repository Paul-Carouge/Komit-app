/// Bit `weekday - 1` is set for each scheduled [DateTime.monday]..[DateTime.sunday].
const int everyWeekdayMask = 0x7F;
const int minimumTargetDaysPerWeek = 1;
const int maximumTargetDaysPerWeek = DateTime.daysPerWeek;

bool isWeekdayScheduled(int scheduledWeekdayMask, int weekday) => scheduledWeekdayMask & (1 << (weekday - 1)) != 0;

/// Daily and weekday habits may skip up to this many scheduled days per ISO week (docs/adr/0007).
const int maximumRestDaysPerWeek = 2;
