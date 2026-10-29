import 'dart:io';

import 'package:flutter/services.dart';

import 'reminder_scheduler.dart';

const MethodChannel _notificationSettingsChannel = MethodChannel('com.paulcarouge.komit/notification_settings');

enum NotificationStatus {
  enabled,
  disabled,

  /// Reminders cannot be shown here: not Android, or the notifications setup failed.
  unavailable,
}

/// Whether Komit may show notifications, and the ways to change it.
class NotificationPermissionService {
  NotificationPermissionService(this._reminderScheduler);

  final ReminderScheduler _reminderScheduler;

  Future<NotificationStatus> readNotificationStatus() async {
    if (!Platform.isAndroid || !await _reminderScheduler.isAvailable) return NotificationStatus.unavailable;
    final isEnabled = await _notificationSettingsChannel.invokeMethod<bool>('areNotificationsEnabled');
    return isEnabled == true ? NotificationStatus.enabled : NotificationStatus.disabled;
  }

  /// Shows Android's permission dialog; returns false at once when Android no longer asks
  /// (after two refusals), which only the system settings can then change.
  Future<bool> requestPermission() => _reminderScheduler.requestPermission();

  /// Opens Komit's page in the system notification settings.
  Future<void> openNotificationSettings() =>
      _notificationSettingsChannel.invokeMethod<void>('openNotificationSettings');
}
