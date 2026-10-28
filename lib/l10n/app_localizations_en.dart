// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Komit';

  @override
  String greeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get greetingWithoutName => 'Hello!';

  @override
  String get habitsTab => 'Habits';

  @override
  String get notesTab => 'Notes';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String lastActivity(String date) {
    return 'Last activity: $date';
  }

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get newHabit => 'New habit';

  @override
  String get emptyHabitsMessage => 'Create your first habit to start tracking.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get habitNotFound => 'Habit not found';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get bestStreak => 'Best streak';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get yearlyProgress => 'Yearly progress';

  @override
  String get logToday => 'Log today';

  @override
  String get objectivesLegend => 'Objectives';

  @override
  String logForDate(String date) {
    return 'Log for $date';
  }

  @override
  String get clearLog => 'Clear this day';

  @override
  String get chooseYear => 'Year';

  @override
  String get statisticsTooltip => 'Statistics';

  @override
  String get moreActionsTooltip => 'More actions';

  @override
  String get editHabit => 'Edit habit';

  @override
  String get deleteHabit => 'Delete habit';

  @override
  String deleteHabitConfirmation(String title) {
    return 'Delete \"$title\" and all its history? This cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String statisticsTitle(int year) {
    return '$year statistics';
  }

  @override
  String get daysLogged => 'Days logged';

  @override
  String get objectiveDistribution => 'Objective distribution';

  @override
  String get monthlyActivity => 'Monthly activity';

  @override
  String get noLogsThisYear => 'Nothing logged this year.';

  @override
  String get createHabit => 'New habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get appearance => 'Appearance';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String reminderEnabledAt(String time) {
    return 'Enabled at $time';
  }

  @override
  String get reminderDisabled => 'Disabled';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get objectives => 'Objectives';

  @override
  String get addObjective => 'Add objective';

  @override
  String get objectiveName => 'Objective name';

  @override
  String get removeObjective => 'Remove objective';

  @override
  String get reorderObjective => 'Drag to reorder';

  @override
  String removeObjectiveWithLogsConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logged days use this objective. They will be deleted when you save.',
      one: '1 logged day uses this objective. It will be deleted when you save.',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Remove';

  @override
  String get habitNameRequired => 'Give your habit a name.';

  @override
  String get objectiveRequired => 'Add at least one objective.';

  @override
  String get objectiveNamesMustBeFilledAndUnique => 'Each objective needs a unique name.';

  @override
  String get chooseColor => 'Choose a color';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String reminderNotificationTitle(String habit) {
    return '$habit';
  }

  @override
  String get reminderNotificationBody => 'How did it go today? Log it in Komit.';

  @override
  String get reminderChannelName => 'Habit reminders';

  @override
  String get notificationsDenied =>
      'Notifications are disabled for Komit. Enable them in system settings to get reminders.';

  @override
  String get secondBrain => 'Second brain';

  @override
  String get newNote => 'New note';

  @override
  String get myNotes => 'My notes';

  @override
  String get noNotesYet => 'No notes yet.';

  @override
  String get noteHint => 'What\'s on your mind?';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get deleteNoteConfirmation => 'Delete this note? This cannot be undone.';

  @override
  String get settings => 'Settings';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get yourName => 'Your name';

  @override
  String get dataAndStorage => 'Data & storage';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get importConfirmationTitle => 'Replace all data?';

  @override
  String importConfirmationMessage(int habits, int logs, int notes) {
    return 'This file contains $habits habits, $logs logged days and $notes notes. Everything currently in the app will be replaced.';
  }

  @override
  String get replace => 'Replace';

  @override
  String importSucceeded(int logs) {
    return 'Import complete: $logs logged days restored.';
  }

  @override
  String importFailed(String reason) {
    return 'This file could not be imported: $reason';
  }

  @override
  String get exportFailed => 'Export failed. Please try again.';

  @override
  String get updates => 'Updates';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get upToDate => 'Komit is up to date.';

  @override
  String get updateCheckFailed => 'Could not check for updates. Check your connection.';

  @override
  String updateAvailableTitle(String version) {
    return 'Komit $version is available';
  }

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get later => 'Later';

  @override
  String get installUpdate => 'Install';

  @override
  String downloadingUpdate(int percent) {
    return 'Downloading update… $percent%';
  }

  @override
  String updateFailed(String reason) {
    return 'The update could not be installed: $reason';
  }

  @override
  String versionLabel(String version) {
    return 'Komit v$version';
  }

  @override
  String get onboardingTitle => 'Build habits that stick.';

  @override
  String get onboardingSubtitle => 'Track every day with your own objectives, and see your year at a glance.';

  @override
  String get onboardingNameLabel => 'What should we call you?';

  @override
  String get getStarted => 'Get started';

  @override
  String get restoreFromBackup => 'Restore from a backup';

  @override
  String get loading => 'Loading…';

  @override
  String get updateErrorInstallPermission =>
      'allow Komit to install apps in the settings that just opened, then try again.';

  @override
  String get updateErrorNetwork => 'the download was interrupted. Check your connection and try again.';

  @override
  String get updateErrorInvalidRelease => 'this version is not available for installation.';

  @override
  String get updateErrorCorruptedDownload => 'the downloaded file is damaged. Try again.';

  @override
  String get updateErrorInstallFailed => 'Android refused the installation.';

  @override
  String get logAnotherDay => 'Log another day';

  @override
  String get habitNameTooLong => 'The habit name is too long.';

  @override
  String get exportPrivacyNote => 'The exported file is not encrypted: keep it somewhere private.';
}
