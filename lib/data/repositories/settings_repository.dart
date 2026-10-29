import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/calendar_day.dart';

class AppSettings {
  const AppSettings({
    required this.userName,
    required this.isOnboardingComplete,
    required this.themeMode,
    required this.languageCode,
    required this.isAutomaticUpdateCheckEnabled,
    required this.lastExportAt,
    required this.isAppLockEnabled,
    required this.isScreenContentHidden,
  });

  final String? userName;
  final bool isOnboardingComplete;
  final ThemeMode themeMode;

  /// Null follows the device language.
  final String? languageCode;

  /// Whether Komit asks GitHub for a new version on its own, at most once a day.
  final bool isAutomaticUpdateCheckEnabled;

  /// When the user last saved an export file; null if never.
  final DateTime? lastExportAt;

  /// Komit asks for a fingerprint, face or the screen lock at launch and after a while away.
  final bool isAppLockEnabled;

  /// FLAG_SECURE: no screenshots or screen recordings of Komit.
  final bool isScreenContentHidden;
}

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  static const String _userNameKey = 'user_name';
  static const String _isOnboardingCompleteKey = 'onboarding_complete';
  static const String _themeModeKey = 'theme_mode';
  static const String _languageCodeKey = 'language_code';
  static const String _shownCelebrationIdsKey = 'shown_celebration_ids';
  static const String _dismissedWeeklyRecapWeekKey = 'dismissed_weekly_recap_week';
  static const String _isAutomaticUpdateCheckEnabledKey = 'automatic_update_check_enabled';
  static const String _lastAutomaticUpdateCheckAtKey = 'last_automatic_update_check_at';
  static const String _lastExportAtKey = 'last_export_at';
  static const String _isAppLockEnabledKey = 'app_lock_enabled';
  static const String _isScreenContentHiddenKey = 'screen_content_hidden';

  AppSettings readSettings() => AppSettings(
    userName: _preferences.getString(_userNameKey),
    isOnboardingComplete: _preferences.getBool(_isOnboardingCompleteKey) ?? false,
    themeMode: ThemeMode.values.asNameMap()[_preferences.getString(_themeModeKey)] ?? ThemeMode.system,
    languageCode: _preferences.getString(_languageCodeKey),
    isAutomaticUpdateCheckEnabled: _preferences.getBool(_isAutomaticUpdateCheckEnabledKey) ?? true,
    lastExportAt: _readDateTime(_lastExportAtKey),
    isAppLockEnabled: _preferences.getBool(_isAppLockEnabledKey) ?? false,
    isScreenContentHidden: _preferences.getBool(_isScreenContentHiddenKey) ?? false,
  );

  Future<void> saveUserName(String? userName) async {
    final trimmedUserName = userName?.trim() ?? '';
    if (trimmedUserName.isEmpty) {
      await _preferences.remove(_userNameKey);
    } else {
      await _preferences.setString(_userNameKey, trimmedUserName);
    }
  }

  Future<void> markOnboardingComplete() => _preferences.setBool(_isOnboardingCompleteKey, true);

  Future<void> saveThemeMode(ThemeMode themeMode) => _preferences.setString(_themeModeKey, themeMode.name);

  Future<void> saveLanguageCode(String? languageCode) => languageCode == null
      ? _preferences.remove(_languageCodeKey)
      : _preferences.setString(_languageCodeKey, languageCode);

  /// Ids of the celebrations already shown, so none plays twice (see `Celebration.id`).
  Set<String> readShownCelebrationIds() => {...?_preferences.getStringList(_shownCelebrationIdsKey)};

  Future<void> markCelebrationsShown(Iterable<String> celebrationIds) =>
      _preferences.setStringList(_shownCelebrationIdsKey, {...readShownCelebrationIds(), ...celebrationIds}.toList());

  /// The Monday starting the last week whose recap the user dismissed.
  CalendarDay? readDismissedWeeklyRecapWeek() => switch (_preferences.getInt(_dismissedWeeklyRecapWeekKey)) {
    final daysSinceEpoch? => CalendarDay(daysSinceEpoch),
    null => null,
  };

  Future<void> saveDismissedWeeklyRecapWeek(CalendarDay weekMonday) =>
      _preferences.setInt(_dismissedWeeklyRecapWeekKey, weekMonday.daysSinceEpoch);

  Future<void> saveAutomaticUpdateCheckEnabled({required bool isEnabled}) =>
      _preferences.setBool(_isAutomaticUpdateCheckEnabledKey, isEnabled);

  DateTime? readLastAutomaticUpdateCheckAt() => _readDateTime(_lastAutomaticUpdateCheckAtKey);

  Future<void> saveLastAutomaticUpdateCheckAt(DateTime checkedAt) =>
      _preferences.setInt(_lastAutomaticUpdateCheckAtKey, checkedAt.millisecondsSinceEpoch);

  Future<void> saveLastExportAt(DateTime exportedAt) =>
      _preferences.setInt(_lastExportAtKey, exportedAt.millisecondsSinceEpoch);

  Future<void> saveAppLockEnabled({required bool isEnabled}) => _preferences.setBool(_isAppLockEnabledKey, isEnabled);

  Future<void> saveScreenContentHidden({required bool isHidden}) =>
      _preferences.setBool(_isScreenContentHiddenKey, isHidden);

  DateTime? _readDateTime(String key) => switch (_preferences.getInt(key)) {
    final millisecondsSinceEpoch? => DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch),
    null => null,
  };
}
