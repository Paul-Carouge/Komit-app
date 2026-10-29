import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/calendar_day.dart';

class AppSettings {
  const AppSettings({
    required this.userName,
    required this.isOnboardingComplete,
    required this.themeMode,
    required this.languageCode,
  });

  final String? userName;
  final bool isOnboardingComplete;
  final ThemeMode themeMode;

  /// Null follows the device language.
  final String? languageCode;
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

  AppSettings readSettings() => AppSettings(
    userName: _preferences.getString(_userNameKey),
    isOnboardingComplete: _preferences.getBool(_isOnboardingCompleteKey) ?? false,
    themeMode: ThemeMode.values.asNameMap()[_preferences.getString(_themeModeKey)] ?? ThemeMode.system,
    languageCode: _preferences.getString(_languageCodeKey),
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
}
