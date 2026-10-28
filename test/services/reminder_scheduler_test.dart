import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/sequential_task_runner.dart';
import 'package:komit/services/reminder_scheduler.dart';
import 'package:timezone/data/latest_all.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  time_zone_data.initializeTimeZones();

  group('nextDailyReminderAfter', () {
    final paris = tz.getLocation('Europe/Paris');

    test('is later today when the time has not passed yet', () {
      final next = nextDailyReminderAfter(tz.TZDateTime(paris, 2026, 3, 10, 8), reminderMinuteOfDay: 9 * 60);
      expect(next, tz.TZDateTime(paris, 2026, 3, 10, 9));
    });

    test('is tomorrow when the time has passed', () {
      final next = nextDailyReminderAfter(tz.TZDateTime(paris, 2026, 3, 10, 9), reminderMinuteOfDay: 9 * 60);
      expect(next, tz.TZDateTime(paris, 2026, 3, 11, 9));
    });

    test('keeps the wall-clock time across the spring DST change', () {
      // Clocks jump from 02:00 to 03:00 on 2026-03-29 in Paris.
      final next = nextDailyReminderAfter(tz.TZDateTime(paris, 2026, 3, 28, 10), reminderMinuteOfDay: 9 * 60);
      expect(next.hour, 9);
      expect(next.day, 29);
    });

    test('rolls over to the next month', () {
      final next = nextDailyReminderAfter(tz.TZDateTime(paris, 2026, 1, 31, 23), reminderMinuteOfDay: 20 * 60);
      expect(next, tz.TZDateTime(paris, 2026, 2, 1, 20));
    });
  });

  test('SequentialTaskRunner never overlaps tasks, even when one fails', () async {
    final runner = SequentialTaskRunner();
    final events = <String>[];
    final firstTaskGate = Completer<void>();

    final firstRun = runner.run(() async {
      events.add('first started');
      await firstTaskGate.future;
      events.add('first finished');
      throw StateError('first failed');
    });
    final secondRun = runner.run(() async => events.add('second ran'));

    await Future<void>.delayed(Duration.zero);
    expect(events, ['first started']);

    firstTaskGate.complete();
    await expectLater(firstRun, throwsStateError);
    await secondRun;
    expect(events, ['first started', 'first finished', 'second ran']);
  });
}
