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
  String get habitsTab => 'Habits';

  @override
  String get notesTab => 'Notes';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get newHabit => 'New habit';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get loadErrorTitle => 'This screen couldn\'t load';

  @override
  String get loadErrorMessage =>
      'Your data is still safe on your phone. Try again, and restart Komit if it keeps happening.';

  @override
  String get retryLoading => 'Try again';

  @override
  String get logThisDayAction => 'Log this day';

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
  String weekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count weeks', one: '1 week');
    return '$_temp0';
  }

  @override
  String get yearlyProgress => 'Yearly progress';

  @override
  String get logToday => 'Log today';

  @override
  String get objectivesLegend => 'Objectives';

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
  String get reminderLockedNotificationTitle => 'Time for a habit';

  @override
  String get reminderLockedNotificationBody => 'Open Komit to log it.';

  @override
  String get reminderChannelName => 'Habit reminders';

  @override
  String get notificationsDenied =>
      'Reminders need notifications, which are off for Komit. You can turn them on in the system settings.';

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
  String get onboardingTitle => 'Hi, I\'m Komo.';

  @override
  String get onboardingSubtitle =>
      'I keep your habits company. One tap a day, and your year fills up, square by square.';

  @override
  String get onboardingNameLabel => 'Your first name';

  @override
  String get getStarted => 'Get started';

  @override
  String get restoreFromBackup => 'Restore from a backup';

  @override
  String get loading => 'Loading…';

  @override
  String get updateErrorInstallPermission =>
      'Komit is not allowed to install apps yet. Allow it in the settings, then try again.';

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

  @override
  String get onboardingNameTitle => 'What should I call you?';

  @override
  String get onboardingNameMessage => 'Your first name only appears on your home screen. You can skip this step.';

  @override
  String get onboardingRemindersTitle => 'Reminders, only if you want them';

  @override
  String get onboardingRemindersMessage =>
      'Reminders are optional and set habit by habit, at the time you choose. Komit asks for permission only when you turn one on.';

  @override
  String get continueAction => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String onboardingStepProgress(int currentStep, int stepCount) {
    return 'Step $currentStep of $stepCount';
  }

  @override
  String get dashboardEmptyTitle => 'Your first habit is waiting';

  @override
  String get dashboardEmptyMessage =>
      'Pick something to do each day, with your own objectives. I\'ll take care of the calendar.';

  @override
  String get createFirstHabit => 'Create a habit';

  @override
  String get noNotesYetMessage => 'Write down an idea, a feeling or a small win. It stays right here.';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get greetingMorningWithoutName => 'Good morning';

  @override
  String get greetingAfternoonWithoutName => 'Good afternoon';

  @override
  String get greetingEveningWithoutName => 'Good evening';

  @override
  String todayProgress(int done, int total) {
    return '$done/$total done today';
  }

  @override
  String todayProgressSemantics(int done, int total) {
    return '$done of $total habits done today';
  }

  @override
  String get allDoneToday => 'All done today';

  @override
  String get nothingPlannedToday => 'Nothing planned today';

  @override
  String get lastLoggedToday => 'Logged today';

  @override
  String get lastLoggedYesterday => 'Last logged yesterday';

  @override
  String lastLoggedDaysAgo(int count) {
    return 'Last logged $count days ago';
  }

  @override
  String lastLoggedOn(String date) {
    return 'Last logged $date';
  }

  @override
  String get notToday => 'Not today';

  @override
  String weeklyProgress(int done, int target) {
    return '$done/$target this week';
  }

  @override
  String currentStreakSemantics(String streak) {
    return 'Current streak: $streak';
  }

  @override
  String habitRowLoggedToday(String habit, String objective) {
    return '$habit, logged today: $objective';
  }

  @override
  String habitRowNotLoggedToday(String habit) {
    return '$habit, not logged today';
  }

  @override
  String habitRowNotPlannedToday(String habit) {
    return '$habit, not planned today';
  }

  @override
  String logHabitToday(String habit) {
    return 'Log $habit for today';
  }

  @override
  String changeTodayLog(String habit) {
    return 'Change today\'s log for $habit';
  }

  @override
  String get chooseAnObjectiveHint => 'choose an objective';

  @override
  String dayLoggedMessage(String objective, String habit) {
    return '$objective logged for $habit';
  }

  @override
  String dayClearedMessage(String habit) {
    return 'Day cleared for $habit';
  }

  @override
  String get undo => 'Undo';

  @override
  String stripDayLogged(String date, String objective) {
    return '$date: $objective';
  }

  @override
  String stripDayNotLogged(String date) {
    return '$date: not logged';
  }

  @override
  String stripDayNotAvailableYet(String date) {
    return '$date: not available yet';
  }

  @override
  String get relativeToday => 'Today';

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String get futureLogExplanation => 'This future day was logged in the original Komit app. You can only clear it.';

  @override
  String get countsTowardStreak => 'Extends the streak';

  @override
  String get schedule => 'Schedule';

  @override
  String get scheduleEveryDay => 'Every day';

  @override
  String get scheduleSomeDays => 'Some days';

  @override
  String get schedulePerWeek => 'Per week';

  @override
  String targetDaysPerWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days per week',
      one: '1 day per week',
    );
    return '$_temp0';
  }

  @override
  String get fewerDaysPerWeek => 'Fewer days per week';

  @override
  String get moreDaysPerWeek => 'More days per week';

  @override
  String get pickAtLeastOneDay => 'Pick at least one day.';

  @override
  String get preview => 'Preview';

  @override
  String get habitNamePlaceholder => 'Your habit';

  @override
  String get saveHabit => 'Save changes';

  @override
  String get createHabitAction => 'Create habit';

  @override
  String get archiveHabit => 'Archive habit';

  @override
  String get unarchiveHabit => 'Bring back to my list';

  @override
  String habitArchivedMessage(String habit) {
    return '$habit archived';
  }

  @override
  String habitUnarchivedMessage(String habit) {
    return '$habit is back on your list';
  }

  @override
  String archivedHabitsRow(int count) {
    return 'Archived ($count)';
  }

  @override
  String get archivedHabitsTitle => 'Archived';

  @override
  String archivedOn(String date) {
    return 'Archived on $date';
  }

  @override
  String get noArchivedHabitsTitle => 'Nothing archived';

  @override
  String get noArchivedHabitsMessage => 'Archive a habit from its page to pause it without losing its history.';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get noteSaveFailed => 'Your note couldn\'t be saved. Copy its text, then try again.';

  @override
  String reminderNotificationBodyWithDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak. Keep it going today.',
      one: 'Day 1 of your streak is done. Keep it going today.',
    );
    return '$_temp0';
  }

  @override
  String reminderNotificationBodyWithWeekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-week streak. Keep it going today.',
      one: '1-week streak. Keep it going today.',
    );
    return '$_temp0';
  }

  @override
  String get reminderChannelDescription =>
      'One notification on the days a habit is planned, at the time you chose for it.';

  @override
  String get reminderActionDone => 'Done';

  @override
  String get reminderActionLater => 'Later';

  @override
  String reminderPermissionTitle(String habit) {
    return 'Remind you about $habit?';
  }

  @override
  String reminderPermissionMessage(String time) {
    return 'Komit will send one notification at $time on the days this habit is planned, with buttons to log it straight away. Android asks for your permission next.';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get openSettings => 'Open settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsStatusEnabled => 'On: your reminders can appear.';

  @override
  String get notificationsStatusDisabled => 'Off: your reminders will not appear.';

  @override
  String get notificationsStatusUnavailable => 'Not available on this device.';

  @override
  String get notificationsStatusTitle => 'Notification status';

  @override
  String get openSystemSettings => 'Open system settings';

  @override
  String get languageSystem => 'System';

  @override
  String get about => 'About';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get allVersionsOnGitHub => 'All versions on GitHub';

  @override
  String get installPermissionTitle => 'Allow Komit to install its updates';

  @override
  String get installPermissionMessage =>
      'Android opens a settings page next. Turn on “Allow from this source”, then come back: the update continues on its own.';

  @override
  String get confirmInstallInSystemWindow => 'Confirm the installation in the Android window.';

  @override
  String get updateErrorInstallCancelled => 'the installation was cancelled.';

  @override
  String get updateErrorInstallConflict =>
      'another version of Komit on this phone prevents it. Uninstall that version after exporting your data, then try again.';

  @override
  String get updateErrorInstallIncompatible => 'this version is not compatible with your phone.';

  @override
  String get updateErrorInstallStorage => 'there is not enough free storage on your phone.';

  @override
  String get updateErrorInstallBlocked => 'Android blocked the installation.';

  @override
  String get settingsUnavailable => 'The settings could not be opened.';

  @override
  String get thisHabit => 'this habit';

  @override
  String get celebrationFirstLogTitle => 'First day logged';

  @override
  String get celebrationFirstLogMessage => 'Every streak starts with one day.';

  @override
  String celebrationStreakDaysTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in a row',
      one: '1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String celebrationStreakWeeksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks in a row',
      one: '1 week on target',
    );
    return '$_temp0';
  }

  @override
  String get celebrationKeepGoingTomorrow => 'Keep it going tomorrow.';

  @override
  String get celebrationKeepGoingNextWeek => 'Keep it going next week.';

  @override
  String get dismissCelebration => 'dismiss';

  @override
  String get achievementUnlocked => 'Achievement unlocked';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsTooltip => 'Achievements';

  @override
  String achievementsSummary(int unlockedCount, int totalCount) {
    return '$unlockedCount of $totalCount unlocked';
  }

  @override
  String get achievementsIntro => 'Achievements follow your logs: clearing days can lock one again.';

  @override
  String get achievementUnlockedStatus => 'Unlocked';

  @override
  String get achievementLockedStatus => 'Locked';

  @override
  String get achievementFirstWeekTitle => 'First week';

  @override
  String get achievementFirstWeekDescription => 'Seven days in a row on one habit, or one week on target.';

  @override
  String get achievementPerfectWeekTitle => 'Perfect week';

  @override
  String get achievementPerfectWeekDescription => 'Every habit met its schedule for a whole week.';

  @override
  String get achievementHundredSuccessDaysTitle => '100 days';

  @override
  String get achievementHundredSuccessDaysDescription => 'A hundred successful days on one habit.';

  @override
  String get achievementComebackTitle => 'Comeback';

  @override
  String get achievementComebackDescription => 'Back on a habit after a week of missed days.';

  @override
  String get achievementOneYearVeteranTitle => 'One year';

  @override
  String get achievementOneYearVeteranDescription => 'Your first log is a year old.';

  @override
  String get weeklyRecapTitle => 'Last week';

  @override
  String weeklyRecapSuccessDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count success days',
      one: '1 success day',
      zero: 'No success days',
    );
    return '$_temp0';
  }

  @override
  String weeklyRecapMoreThanWeekBefore(int count) {
    return '$count more than the week before';
  }

  @override
  String weeklyRecapFewerThanWeekBefore(int count) {
    return '$count fewer than the week before';
  }

  @override
  String get weeklyRecapSameAsWeekBefore => 'Same as the week before';

  @override
  String weeklyRecapHabitProgress(int doneCount, int expectedCount) {
    return '$doneCount of $expectedCount';
  }

  @override
  String weeklyRecapHabitProgressSemantics(String habitTitle, int doneCount, int expectedCount) {
    return '$habitTitle: $doneCount of $expectedCount';
  }

  @override
  String weeklyRecapBestStreak(String habitTitle, String streak) {
    return 'Longest streak: $habitTitle, $streak';
  }

  @override
  String get dismissWeeklyRecap => 'Dismiss the recap';

  @override
  String get checkForUpdatesAutomatically => 'Check for updates automatically';

  @override
  String get checkForUpdatesAutomaticallyDescription => 'At most once a day, by asking GitHub for the latest version.';

  @override
  String get restoreAutomaticBackup => 'Restore an automatic backup';

  @override
  String get automaticBackups => 'Automatic backups';

  @override
  String automaticBackupsExplanation(int count) {
    return 'Komit keeps a copy of your data on this phone before each import or update, and once a day when something changed. The $count most recent are kept.';
  }

  @override
  String get noAutomaticBackupsTitle => 'No automatic backup yet';

  @override
  String get noAutomaticBackupsMessage => 'The first one is made today, once you have logged something.';

  @override
  String get automaticBackupBeforeImport => 'Before an import';

  @override
  String get automaticBackupBeforeUpdate => 'Before an update';

  @override
  String get automaticBackupDaily => 'Daily copy';

  @override
  String get restoreAutomaticBackupConfirmationTitle => 'Restore this backup?';

  @override
  String restoreAutomaticBackupConfirmationMessage(String date) {
    return 'Everything in the app will be replaced by the copy from $date. Your current data is saved as an automatic backup first.';
  }

  @override
  String get preImportBackupFailed =>
      'Nothing was replaced: Komit could not save a copy of your current data first. Free up some space and try again.';

  @override
  String lastExportDaysAgo(int days) {
    return 'Last export: $days days ago';
  }

  @override
  String get exportEncryptedData => 'Export with a passphrase';

  @override
  String get exportEncryptedDataDescription => 'Only someone who knows it can open the file.';

  @override
  String get encryptBackupTitle => 'Protect the export';

  @override
  String get encryptBackupMessage =>
      'Choose a passphrase. Komit cannot recover it: without it, this file can never be imported.';

  @override
  String get decryptBackupTitle => 'Encrypted backup';

  @override
  String get decryptBackupMessage => 'Enter the passphrase chosen when this file was exported.';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get confirmPassphrase => 'Passphrase again';

  @override
  String get showPassphrase => 'Show passphrase';

  @override
  String get hidePassphrase => 'Hide passphrase';

  @override
  String passphraseTooShort(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String get passphraseRequired => 'Enter the passphrase.';

  @override
  String get passphrasesDoNotMatch => 'The two passphrases differ.';

  @override
  String get wrongBackupPassphrase => 'Wrong passphrase, or the file was damaged.';

  @override
  String get encryptAndExport => 'Encrypt and export';

  @override
  String get unlock => 'Unlock';

  @override
  String get privacyAndSecurity => 'Privacy & security';

  @override
  String get appLockSetting => 'Lock Komit';

  @override
  String get appLockSettingDescription =>
      'Ask for your fingerprint, face or screen lock when Komit opens and after a minute away. Reminders and the widget then hide your habits.';

  @override
  String get appLockUnavailable => 'Set up a screen lock in your phone\'s settings to use this.';

  @override
  String get hideScreenContentSetting => 'Hide from screenshots';

  @override
  String get hideScreenContentSettingDescription =>
      'Blocks screenshots and screen recordings, and blanks Komit in recent apps.';

  @override
  String get appLockTitle => 'Komit is locked';

  @override
  String get appLockMessage => 'Komo is keeping your habits safe while you were away.';

  @override
  String get appLockCancelled => 'Unlocking was cancelled. Your habits stay hidden until you unlock.';

  @override
  String get appLockFailed => 'Komit could not be unlocked. Wait a moment, then try again.';

  @override
  String get appLockPromptTitle => 'Unlock Komit';

  @override
  String get appLockPromptSubtitle => 'Use your fingerprint, face or screen lock';

  @override
  String get tryAgain => 'Try again';

  @override
  String get privacyTitle => 'Your privacy';

  @override
  String get privacyLink => 'What stays on your phone';

  @override
  String get privacyIntroduction =>
      'Komit has no account, no ads and no analytics. Your habits, notes and first name are stored only in Komit\'s private space on this phone.';

  @override
  String get privacyWhatLeavesTitle => 'What leaves your phone';

  @override
  String get privacyUpdateCheckTitle => 'The update check, and nothing else';

  @override
  String get privacyUpdateCheckBody =>
      'At most once a day, Komit asks GitHub for its latest version, which shows GitHub your IP address. An update you accept is downloaded from GitHub too. Turn the automatic check off in Settings, under Updates.';

  @override
  String get privacyNoTrackingTitle => 'No tracking';

  @override
  String get privacyNoTrackingBody => 'Nothing about your habits, notes or use of the app is ever sent anywhere.';

  @override
  String get privacyBackupsTitle => 'Backups and exports';

  @override
  String get privacyCloudBackupTitle => 'Not in your cloud backup';

  @override
  String get privacyCloudBackupBody =>
      'Android\'s backup to Google\'s cloud skips Komit. Moving to a new phone with a cable or Wi-Fi transfer still copies everything (Android 9 and later); otherwise, use an export.';

  @override
  String privacyAutomaticBackupsBody(int count) {
    return 'Copies made before an import or an update, and once a day, stay in Komit\'s private space on this phone. The $count most recent are kept.';
  }

  @override
  String get privacyPlainExportTitle => 'Plain exports';

  @override
  String get privacyPlainExportBody =>
      'A plain export is a readable file: anyone who opens it can read your habits and notes. Keep it somewhere private.';

  @override
  String get privacyEncryptedExportTitle => 'Exports with a passphrase';

  @override
  String get privacyEncryptedExportBody =>
      'Encrypted with AES-256 on this phone. Only your passphrase opens the file, and nobody can recover a forgotten one.';

  @override
  String get privacyErrorLogTitle => 'Error log';

  @override
  String get privacyErrorLogBody =>
      'Komit notes its own errors on this phone, without your habit names, notes or first name. It is never sent.';

  @override
  String get privacyPermissionsTitle => 'Permissions';

  @override
  String get permissionNotificationsTitle => 'Notifications';

  @override
  String get permissionNotificationsBody =>
      'For the reminders you set. Komit asks only when you add your first reminder.';

  @override
  String get permissionStartupTitle => 'Run at startup';

  @override
  String get permissionStartupBody => 'Puts your reminders back after the phone restarts or the time zone changes.';

  @override
  String get permissionInstallTitle => 'Install apps';

  @override
  String get permissionInstallBody => 'Only to install a Komit update you accepted. Android asks you once.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetBody => 'Only for the update check and download, over HTTPS.';

  @override
  String get permissionVibrationTitle => 'Vibration';

  @override
  String get permissionVibrationBody => 'Light taps when you log a day, following your phone\'s settings.';

  @override
  String get permissionBiometricTitle => 'Fingerprint and face';

  @override
  String get permissionBiometricBody => 'Only for the optional app lock. Android checks them; Komit never sees them.';
}
