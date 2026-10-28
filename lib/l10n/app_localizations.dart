import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Komit'**
  String get appTitle;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String greeting(String name);

  /// No description provided for @greetingWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get greetingWithoutName;

  /// No description provided for @habitsTab.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsTab;

  /// No description provided for @notesTab.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTab;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last activity: {date}'**
  String lastActivity(String date);

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabit;

  /// No description provided for @emptyHabitsMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first habit to start tracking.'**
  String get emptyHabitsMessage;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @habitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Habit not found'**
  String get habitNotFound;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get bestStreak;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// No description provided for @yearlyProgress.
  ///
  /// In en, this message translates to:
  /// **'Yearly progress'**
  String get yearlyProgress;

  /// No description provided for @logToday.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get logToday;

  /// No description provided for @objectivesLegend.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get objectivesLegend;

  /// No description provided for @logForDate.
  ///
  /// In en, this message translates to:
  /// **'Log for {date}'**
  String logForDate(String date);

  /// No description provided for @clearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear this day'**
  String get clearLog;

  /// No description provided for @chooseYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get chooseYear;

  /// No description provided for @statisticsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTooltip;

  /// No description provided for @moreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActionsTooltip;

  /// No description provided for @editHabit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get editHabit;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete habit'**
  String get deleteHabit;

  /// No description provided for @deleteHabitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" and all its history? This cannot be undone.'**
  String deleteHabitConfirmation(String title);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'{year} statistics'**
  String statisticsTitle(int year);

  /// No description provided for @daysLogged.
  ///
  /// In en, this message translates to:
  /// **'Days logged'**
  String get daysLogged;

  /// No description provided for @objectiveDistribution.
  ///
  /// In en, this message translates to:
  /// **'Objective distribution'**
  String get objectiveDistribution;

  /// No description provided for @monthlyActivity.
  ///
  /// In en, this message translates to:
  /// **'Monthly activity'**
  String get monthlyActivity;

  /// No description provided for @noLogsThisYear.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged this year.'**
  String get noLogsThisYear;

  /// No description provided for @createHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get createHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @reminderEnabledAt.
  ///
  /// In en, this message translates to:
  /// **'Enabled at {time}'**
  String reminderEnabledAt(String time);

  /// No description provided for @reminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get reminderDisabled;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @objectives.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get objectives;

  /// No description provided for @addObjective.
  ///
  /// In en, this message translates to:
  /// **'Add objective'**
  String get addObjective;

  /// No description provided for @objectiveName.
  ///
  /// In en, this message translates to:
  /// **'Objective name'**
  String get objectiveName;

  /// No description provided for @removeObjective.
  ///
  /// In en, this message translates to:
  /// **'Remove objective'**
  String get removeObjective;

  /// No description provided for @reorderObjective.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get reorderObjective;

  /// No description provided for @removeObjectiveWithLogsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 logged day uses this objective. It will be deleted when you save.} other{{count} logged days use this objective. They will be deleted when you save.}}'**
  String removeObjectiveWithLogsConfirmation(int count);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @habitNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give your habit a name.'**
  String get habitNameRequired;

  /// No description provided for @objectiveRequired.
  ///
  /// In en, this message translates to:
  /// **'Add at least one objective.'**
  String get objectiveRequired;

  /// No description provided for @objectiveNamesMustBeFilledAndUnique.
  ///
  /// In en, this message translates to:
  /// **'Each objective needs a unique name.'**
  String get objectiveNamesMustBeFilledAndUnique;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a color'**
  String get chooseColor;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIcon;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{habit}'**
  String reminderNotificationTitle(String habit);

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'How did it go today? Log it in Komit.'**
  String get reminderNotificationBody;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders'**
  String get reminderChannelName;

  /// No description provided for @notificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled for Komit. Enable them in system settings to get reminders.'**
  String get notificationsDenied;

  /// No description provided for @secondBrain.
  ///
  /// In en, this message translates to:
  /// **'Second brain'**
  String get secondBrain;

  /// No description provided for @newNote.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get newNote;

  /// No description provided for @myNotes.
  ///
  /// In en, this message translates to:
  /// **'My notes'**
  String get myNotes;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get noNotesYet;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get noteHint;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this note? This cannot be undone.'**
  String get deleteNoteConfirmation;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @dataAndStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & storage'**
  String get dataAndStorage;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @importConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get importConfirmationTitle;

  /// No description provided for @importConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'This file contains {habits} habits, {logs} logged days and {notes} notes. Everything currently in the app will be replaced.'**
  String importConfirmationMessage(int habits, int logs, int notes);

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @importSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Import complete: {logs} logged days restored.'**
  String importSucceeded(int logs);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'This file could not be imported: {reason}'**
  String importFailed(String reason);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'Komit is up to date.'**
  String get upToDate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Check your connection.'**
  String get updateCheckFailed;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Komit {version} is available'**
  String updateAvailableTitle(String version);

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get installUpdate;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update… {percent}%'**
  String downloadingUpdate(int percent);

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'The update could not be installed: {reason}'**
  String updateFailed(String reason);

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Komit v{version}'**
  String versionLabel(String version);

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Build habits that stick.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track every day with your own objectives, and see your year at a glance.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onboardingNameLabel;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get restoreFromBackup;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @updateErrorInstallPermission.
  ///
  /// In en, this message translates to:
  /// **'allow Komit to install apps in the settings that just opened, then try again.'**
  String get updateErrorInstallPermission;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'the download was interrupted. Check your connection and try again.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorInvalidRelease.
  ///
  /// In en, this message translates to:
  /// **'this version is not available for installation.'**
  String get updateErrorInvalidRelease;

  /// No description provided for @updateErrorCorruptedDownload.
  ///
  /// In en, this message translates to:
  /// **'the downloaded file is damaged. Try again.'**
  String get updateErrorCorruptedDownload;

  /// No description provided for @updateErrorInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Android refused the installation.'**
  String get updateErrorInstallFailed;

  /// No description provided for @logAnotherDay.
  ///
  /// In en, this message translates to:
  /// **'Log another day'**
  String get logAnotherDay;

  /// No description provided for @habitNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The habit name is too long.'**
  String get habitNameTooLong;

  /// No description provided for @exportPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'The exported file is not encrypted: keep it somewhere private.'**
  String get exportPrivacyNote;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
