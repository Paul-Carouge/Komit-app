import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'sequential_task_runner.dart';

/// Above this size the log file is rotated, so the logs never take more than twice of it.
const int maximumLogFileSizeBytes = 256 * 1024;

/// Enough frames to locate a crash without keeping whole traces.
const int maximumLoggedStackFrameCount = 20;

const String _logFileName = 'komit.log';
const String _previousLogFileName = 'komit.log.1';

/// Structured, size-capped error log kept on the device only, in app support storage.
///
/// Privacy: only an event name, the error *type* and the stack frames are written. Error
/// messages are never written because they can quote habit titles, notes or the user's name.
class AppLogger {
  AppLogger(this._logDirectory, {this._now = DateTime.now});

  static Future<AppLogger> openInApplicationSupportDirectory() async =>
      AppLogger(await getApplicationSupportDirectory());

  final Directory _logDirectory;
  final DateTime Function() _now;
  final SequentialTaskRunner _writes = SequentialTaskRunner();

  File get currentLogFile => File('${_logDirectory.path}/$_logFileName');
  File get previousLogFile => File('${_logDirectory.path}/$_previousLogFileName');

  /// Appends one JSON line; never throws, since a failing logger must not crash the app.
  Future<void> logError({required String event, required Object error, StackTrace? stackTrace}) {
    final line = jsonEncode({
      'time': _now().toUtc().toIso8601String(),
      'level': 'error',
      'event': event,
      'errorType': error.runtimeType.toString(),
      if (stackTrace != null)
        'stack': stackTrace
            .toString()
            .split('\n')
            .where((frame) => frame.isNotEmpty)
            .take(maximumLoggedStackFrameCount)
            .toList(),
    });
    return _writes.run(() => _appendLine(line)).catchError((Object writeError) {
      developer.log('Log file write failed', name: 'komit.logger', error: writeError.runtimeType);
    });
  }

  Future<void> _appendLine(String line) async {
    final file = currentLogFile;
    if (await file.exists() && await file.length() >= maximumLogFileSizeBytes) {
      await file.rename(previousLogFile.path);
    }
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }
}
