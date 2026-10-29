import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:komit/core/app_logger.dart';

void main() {
  late Directory logDirectory;
  late AppLogger logger;

  setUp(() {
    logDirectory = Directory.systemTemp.createTempSync('komit_logger_test');
    logger = AppLogger(logDirectory, now: () => DateTime.utc(2026, 10, 29, 8));
  });
  tearDown(() => logDirectory.deleteSync(recursive: true));

  test('writes a structured line without the error message', () async {
    await logger.logError(
      event: 'flutter_error',
      error: StateError('Habit "Secret diary" for Alex'),
      stackTrace: StackTrace.current,
    );

    final text = logger.currentLogFile.readAsStringSync();
    expect(text, isNot(contains('Secret diary')));
    expect(text, isNot(contains('Alex')));
    final entry = jsonDecode(text.trim()) as Map<String, Object?>;
    expect(entry['time'], '2026-10-29T08:00:00.000Z');
    expect(entry['event'], 'flutter_error');
    expect(entry['errorType'], 'StateError');
    expect((entry['stack']! as List<Object?>).length, lessThanOrEqualTo(maximumLoggedStackFrameCount));
  });

  test('rotates the file so the logs stay under twice the size cap', () async {
    final longStackTrace = StackTrace.fromString(List.filled(maximumLoggedStackFrameCount, 'frame' * 100).join('\n'));
    for (var i = 0; i < 200; i++) {
      await logger.logError(event: 'uncaught_error', error: Exception(), stackTrace: longStackTrace);
    }

    expect(logger.previousLogFile.existsSync(), isTrue);
    final totalSize = logger.currentLogFile.lengthSync() + logger.previousLogFile.lengthSync();
    expect(totalSize, lessThan(2 * maximumLogFileSizeBytes + 16 * 1024));
  });
}
