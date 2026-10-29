import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'calendar_day.dart';

/// Overridable in tests to control "now".
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's calendar day, updated at local midnight and when the app comes back to the foreground,
/// so a screen left open overnight never logs on yesterday.
class CurrentCalendarDayController extends Notifier<CalendarDay> {
  Timer? _midnightTimer;

  @override
  CalendarDay build() {
    final now = ref.watch(clockProvider)();
    _armMidnightTimer(now);
    final lifecycleListener = AppLifecycleListener(onResume: refreshIfDayChanged);
    ref.onDispose(() {
      _midnightTimer?.cancel();
      lifecycleListener.dispose();
    });
    return CalendarDay.fromDateTime(now);
  }

  void _armMidnightTimer(DateTime now) {
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer?.cancel();
    _midnightTimer = Timer(nextMidnight.difference(now), _onMidnightTimerFired);
  }

  void _onMidnightTimerFired() {
    final now = ref.read(clockProvider)();
    // Timers can fire slightly early; still the same day means waiting for the rest of it.
    if (CalendarDay.fromDateTime(now) == state) {
      _armMidnightTimer(now);
    } else {
      ref.invalidateSelf();
    }
  }

  void refreshIfDayChanged() {
    final today = CalendarDay.fromDateTime(ref.read(clockProvider)());
    // Rebuilding also re-arms the midnight timer for the new day.
    if (today != state) ref.invalidateSelf();
  }
}

final currentCalendarDayProvider = NotifierProvider<CurrentCalendarDayController, CalendarDay>(
  CurrentCalendarDayController.new,
);
