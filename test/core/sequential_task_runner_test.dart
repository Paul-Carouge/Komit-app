import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/sequential_task_runner.dart';

void main() {
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
