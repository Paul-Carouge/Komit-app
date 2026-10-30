import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _appLockChannel = MethodChannel('com.paulcarouge.komit/app_lock');

/// Sent by AppLock.kt; anything unknown counts as [failed].
enum AppLockAuthenticationResult {
  succeeded,

  /// The user closed the system prompt.
  cancelled,

  /// Too many attempts, or a hardware error: the prompt can be tried again later.
  failed,

  /// The phone no longer has a screen lock, so there is nothing to check against.
  unavailable,
}

/// The optional app lock and the window protections that go with it (see AppLock.kt).
class AppLockService {
  AppLockService({this._channel = _appLockChannel, bool? isSupported})
    : isSupported = isSupported ?? Platform.isAndroid;

  final MethodChannel _channel;
  final bool isSupported;

  /// True when the phone has a screen lock (PIN, pattern, password) or a strong biometric.
  Future<bool> canAuthenticate() async =>
      isSupported && (await _channel.invokeMethod<bool>('canAuthenticate') ?? false);

  Future<AppLockAuthenticationResult> authenticate({required String title, required String subtitle}) async {
    final resultName = await _channel.invokeMethod<String>('authenticate', {'title': title, 'subtitle': subtitle});
    return AppLockAuthenticationResult.values.asNameMap()[resultName] ?? AppLockAuthenticationResult.failed;
  }

  /// Applies FLAG_SECURE and the recent apps card from both settings at once, so that one
  /// never undoes the other: below Android 13 the lock alone needs FLAG_SECURE too.
  Future<void> applyWindowProtections({required bool isAppLockEnabled, required bool isScreenContentHidden}) async {
    if (isSupported) {
      await _channel.invokeMethod<void>('applyWindowProtections', {
        'isAppLockEnabled': isAppLockEnabled,
        'isScreenContentHidden': isScreenContentHidden,
      });
    }
  }
}
