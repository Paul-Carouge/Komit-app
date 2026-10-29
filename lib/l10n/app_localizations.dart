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

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This screen couldn\'t load'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Your data is still safe on your phone. Try again, and restart Komit if it keeps happening.'**
  String get loadErrorMessage;

  /// No description provided for @retryLoading.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryLoading;

  /// No description provided for @logThisDayAction.
  ///
  /// In en, this message translates to:
  /// **'Log this day'**
  String get logThisDayAction;

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

  /// No description provided for @weekCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String weekCount(int count);

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
  /// **'Reminders need notifications, which are off for Komit. You can turn them on in the system settings.'**
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
  /// **'Hi, I\'m Komo.'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I keep your habits company. One tap a day, and your year fills up, square by square.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
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
  /// **'Komit is not allowed to install apps yet. Allow it in the settings, then try again.'**
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

  /// No description provided for @onboardingNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should I call you?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Your first name only appears on your home screen. You can skip this step.'**
  String get onboardingNameMessage;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders, only if you want them'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminders are optional and set habit by habit, at the time you choose. Komit asks for permission only when you turn one on.'**
  String get onboardingRemindersMessage;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @onboardingStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {currentStep} of {stepCount}'**
  String onboardingStepProgress(int currentStep, int stepCount);

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first habit is waiting'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick something to do each day, with your own objectives. I\'ll take care of the calendar.'**
  String get dashboardEmptyMessage;

  /// No description provided for @createFirstHabit.
  ///
  /// In en, this message translates to:
  /// **'Create a habit'**
  String get createFirstHabit;

  /// No description provided for @noNotesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Write down an idea, a feeling or a small win. It stays right here.'**
  String get noNotesYetMessage;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @greetingMorningWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorningWithoutName;

  /// No description provided for @greetingAfternoonWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoonWithoutName;

  /// No description provided for @greetingEveningWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEveningWithoutName;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done today'**
  String todayProgress(int done, int total);

  /// No description provided for @todayProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} habits done today'**
  String todayProgressSemantics(int done, int total);

  /// No description provided for @allDoneToday.
  ///
  /// In en, this message translates to:
  /// **'All done today'**
  String get allDoneToday;

  /// No description provided for @nothingPlannedToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned today'**
  String get nothingPlannedToday;

  /// No description provided for @lastLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Logged today'**
  String get lastLoggedToday;

  /// No description provided for @lastLoggedYesterday.
  ///
  /// In en, this message translates to:
  /// **'Last logged yesterday'**
  String get lastLoggedYesterday;

  /// No description provided for @lastLoggedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last logged {count} days ago'**
  String lastLoggedDaysAgo(int count);

  /// No description provided for @lastLoggedOn.
  ///
  /// In en, this message translates to:
  /// **'Last logged {date}'**
  String lastLoggedOn(String date);

  /// No description provided for @notToday.
  ///
  /// In en, this message translates to:
  /// **'Not today'**
  String get notToday;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{target} this week'**
  String weeklyProgress(int done, int target);

  /// No description provided for @currentStreakSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current streak: {streak}'**
  String currentStreakSemantics(String streak);

  /// No description provided for @habitRowLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'{habit}, logged today: {objective}'**
  String habitRowLoggedToday(String habit, String objective);

  /// No description provided for @habitRowNotLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'{habit}, not logged today'**
  String habitRowNotLoggedToday(String habit);

  /// No description provided for @habitRowNotPlannedToday.
  ///
  /// In en, this message translates to:
  /// **'{habit}, not planned today'**
  String habitRowNotPlannedToday(String habit);

  /// No description provided for @logHabitToday.
  ///
  /// In en, this message translates to:
  /// **'Log {habit} for today'**
  String logHabitToday(String habit);

  /// No description provided for @changeTodayLog.
  ///
  /// In en, this message translates to:
  /// **'Change today\'s log for {habit}'**
  String changeTodayLog(String habit);

  /// No description provided for @chooseAnObjectiveHint.
  ///
  /// In en, this message translates to:
  /// **'choose an objective'**
  String get chooseAnObjectiveHint;

  /// No description provided for @dayLoggedMessage.
  ///
  /// In en, this message translates to:
  /// **'{objective} logged for {habit}'**
  String dayLoggedMessage(String objective, String habit);

  /// No description provided for @dayClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Day cleared for {habit}'**
  String dayClearedMessage(String habit);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @stripDayLogged.
  ///
  /// In en, this message translates to:
  /// **'{date}: {objective}'**
  String stripDayLogged(String date, String objective);

  /// No description provided for @stripDayNotLogged.
  ///
  /// In en, this message translates to:
  /// **'{date}: not logged'**
  String stripDayNotLogged(String date);

  /// No description provided for @stripDayNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'{date}: not available yet'**
  String stripDayNotAvailableYet(String date);

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get relativeToday;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @futureLogExplanation.
  ///
  /// In en, this message translates to:
  /// **'This future day was logged in the original Komit app. You can only clear it.'**
  String get futureLogExplanation;

  /// No description provided for @countsTowardStreak.
  ///
  /// In en, this message translates to:
  /// **'Extends the streak'**
  String get countsTowardStreak;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @scheduleEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get scheduleEveryDay;

  /// No description provided for @scheduleSomeDays.
  ///
  /// In en, this message translates to:
  /// **'Some days'**
  String get scheduleSomeDays;

  /// No description provided for @schedulePerWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get schedulePerWeek;

  /// No description provided for @targetDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day per week} other{{count} days per week}}'**
  String targetDaysPerWeek(int count);

  /// No description provided for @fewerDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Fewer days per week'**
  String get fewerDaysPerWeek;

  /// No description provided for @moreDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'More days per week'**
  String get moreDaysPerWeek;

  /// No description provided for @pickAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get pickAtLeastOneDay;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @habitNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your habit'**
  String get habitNamePlaceholder;

  /// No description provided for @saveHabit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveHabit;

  /// No description provided for @createHabitAction.
  ///
  /// In en, this message translates to:
  /// **'Create habit'**
  String get createHabitAction;

  /// No description provided for @archiveHabit.
  ///
  /// In en, this message translates to:
  /// **'Archive habit'**
  String get archiveHabit;

  /// No description provided for @unarchiveHabit.
  ///
  /// In en, this message translates to:
  /// **'Bring back to my list'**
  String get unarchiveHabit;

  /// No description provided for @habitArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'{habit} archived'**
  String habitArchivedMessage(String habit);

  /// No description provided for @habitUnarchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'{habit} is back on your list'**
  String habitUnarchivedMessage(String habit);

  /// No description provided for @archivedHabitsRow.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String archivedHabitsRow(int count);

  /// No description provided for @archivedHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedHabitsTitle;

  /// No description provided for @archivedOn.
  ///
  /// In en, this message translates to:
  /// **'Archived on {date}'**
  String archivedOn(String date);

  /// No description provided for @noArchivedHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing archived'**
  String get noArchivedHabitsTitle;

  /// No description provided for @noArchivedHabitsMessage.
  ///
  /// In en, this message translates to:
  /// **'Archive a habit from its page to pause it without losing its history.'**
  String get noArchivedHabitsMessage;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @noteSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Your note couldn\'t be saved. Copy its text, then try again.'**
  String get noteSaveFailed;

  /// No description provided for @reminderNotificationBodyWithDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Day 1 of your streak is done. Keep it going today.} other{{count}-day streak. Keep it going today.}}'**
  String reminderNotificationBodyWithDayStreak(int count);

  /// No description provided for @reminderNotificationBodyWithWeekStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-week streak. Keep it going today.} other{{count}-week streak. Keep it going today.}}'**
  String reminderNotificationBodyWithWeekStreak(int count);

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'One notification on the days a habit is planned, at the time you chose for it.'**
  String get reminderChannelDescription;

  /// No description provided for @reminderActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reminderActionDone;

  /// No description provided for @reminderActionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get reminderActionLater;

  /// No description provided for @reminderPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind you about {habit}?'**
  String reminderPermissionTitle(String habit);

  /// No description provided for @reminderPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Komit will send one notification at {time} on the days this habit is planned, with buttons to log it straight away. Android asks for your permission next.'**
  String reminderPermissionMessage(String time);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsStatusEnabled.
  ///
  /// In en, this message translates to:
  /// **'On: your reminders can appear.'**
  String get notificationsStatusEnabled;

  /// No description provided for @notificationsStatusDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off: your reminders will not appear.'**
  String get notificationsStatusDisabled;

  /// No description provided for @notificationsStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get notificationsStatusUnavailable;

  /// No description provided for @notificationsStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification status'**
  String get notificationsStatusTitle;

  /// No description provided for @openSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Open system settings'**
  String get openSystemSettings;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @allVersionsOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'All versions on GitHub'**
  String get allVersionsOnGitHub;

  /// No description provided for @installPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Komit to install its updates'**
  String get installPermissionTitle;

  /// No description provided for @installPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Android opens a settings page next. Turn on “Allow from this source”, then come back: the update continues on its own.'**
  String get installPermissionMessage;

  /// No description provided for @confirmInstallInSystemWindow.
  ///
  /// In en, this message translates to:
  /// **'Confirm the installation in the Android window.'**
  String get confirmInstallInSystemWindow;

  /// No description provided for @updateErrorInstallCancelled.
  ///
  /// In en, this message translates to:
  /// **'the installation was cancelled.'**
  String get updateErrorInstallCancelled;

  /// No description provided for @updateErrorInstallConflict.
  ///
  /// In en, this message translates to:
  /// **'another version of Komit on this phone prevents it. Uninstall that version after exporting your data, then try again.'**
  String get updateErrorInstallConflict;

  /// No description provided for @updateErrorInstallIncompatible.
  ///
  /// In en, this message translates to:
  /// **'this version is not compatible with your phone.'**
  String get updateErrorInstallIncompatible;

  /// No description provided for @updateErrorInstallStorage.
  ///
  /// In en, this message translates to:
  /// **'there is not enough free storage on your phone.'**
  String get updateErrorInstallStorage;

  /// No description provided for @updateErrorInstallBlocked.
  ///
  /// In en, this message translates to:
  /// **'Android blocked the installation.'**
  String get updateErrorInstallBlocked;

  /// No description provided for @settingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The settings could not be opened.'**
  String get settingsUnavailable;

  /// No description provided for @thisHabit.
  ///
  /// In en, this message translates to:
  /// **'this habit'**
  String get thisHabit;

  /// No description provided for @celebrationFirstLogTitle.
  ///
  /// In en, this message translates to:
  /// **'First day logged'**
  String get celebrationFirstLogTitle;

  /// No description provided for @celebrationFirstLogMessage.
  ///
  /// In en, this message translates to:
  /// **'Every streak starts with one day.'**
  String get celebrationFirstLogMessage;

  /// No description provided for @celebrationStreakDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day in a row} other{{count} days in a row}}'**
  String celebrationStreakDaysTitle(int count);

  /// No description provided for @celebrationStreakWeeksTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week on target} other{{count} weeks in a row}}'**
  String celebrationStreakWeeksTitle(int count);

  /// No description provided for @celebrationKeepGoingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Keep it going tomorrow.'**
  String get celebrationKeepGoingTomorrow;

  /// No description provided for @celebrationKeepGoingNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Keep it going next week.'**
  String get celebrationKeepGoingNextWeek;

  /// No description provided for @dismissCelebration.
  ///
  /// In en, this message translates to:
  /// **'dismiss'**
  String get dismissCelebration;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked'**
  String get achievementUnlocked;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @achievementsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTooltip;

  /// No description provided for @achievementsSummary.
  ///
  /// In en, this message translates to:
  /// **'{unlockedCount} of {totalCount} unlocked'**
  String achievementsSummary(int unlockedCount, int totalCount);

  /// No description provided for @achievementsIntro.
  ///
  /// In en, this message translates to:
  /// **'Achievements follow your logs: clearing days can lock one again.'**
  String get achievementsIntro;

  /// No description provided for @achievementUnlockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementUnlockedStatus;

  /// No description provided for @achievementLockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get achievementLockedStatus;

  /// No description provided for @achievementFirstWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'First week'**
  String get achievementFirstWeekTitle;

  /// No description provided for @achievementFirstWeekDescription.
  ///
  /// In en, this message translates to:
  /// **'Seven days in a row on one habit, or one week on target.'**
  String get achievementFirstWeekDescription;

  /// No description provided for @achievementPerfectWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfect week'**
  String get achievementPerfectWeekTitle;

  /// No description provided for @achievementPerfectWeekDescription.
  ///
  /// In en, this message translates to:
  /// **'Every habit met its schedule for a whole week.'**
  String get achievementPerfectWeekDescription;

  /// No description provided for @achievementHundredSuccessDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'100 days'**
  String get achievementHundredSuccessDaysTitle;

  /// No description provided for @achievementHundredSuccessDaysDescription.
  ///
  /// In en, this message translates to:
  /// **'A hundred successful days on one habit.'**
  String get achievementHundredSuccessDaysDescription;

  /// No description provided for @achievementComebackTitle.
  ///
  /// In en, this message translates to:
  /// **'Comeback'**
  String get achievementComebackTitle;

  /// No description provided for @achievementComebackDescription.
  ///
  /// In en, this message translates to:
  /// **'Back on a habit after a week of missed days.'**
  String get achievementComebackDescription;

  /// No description provided for @achievementOneYearVeteranTitle.
  ///
  /// In en, this message translates to:
  /// **'One year'**
  String get achievementOneYearVeteranTitle;

  /// No description provided for @achievementOneYearVeteranDescription.
  ///
  /// In en, this message translates to:
  /// **'Your first log is a year old.'**
  String get achievementOneYearVeteranDescription;

  /// No description provided for @weeklyRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Last week'**
  String get weeklyRecapTitle;

  /// No description provided for @weeklyRecapSuccessDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No success days} =1{1 success day} other{{count} success days}}'**
  String weeklyRecapSuccessDays(int count);

  /// No description provided for @weeklyRecapMoreThanWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} more than the week before'**
  String weeklyRecapMoreThanWeekBefore(int count);

  /// No description provided for @weeklyRecapFewerThanWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} fewer than the week before'**
  String weeklyRecapFewerThanWeekBefore(int count);

  /// No description provided for @weeklyRecapSameAsWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'Same as the week before'**
  String get weeklyRecapSameAsWeekBefore;

  /// No description provided for @weeklyRecapHabitProgress.
  ///
  /// In en, this message translates to:
  /// **'{doneCount} of {expectedCount}'**
  String weeklyRecapHabitProgress(int doneCount, int expectedCount);

  /// No description provided for @weeklyRecapHabitProgressSemantics.
  ///
  /// In en, this message translates to:
  /// **'{habitTitle}: {doneCount} of {expectedCount}'**
  String weeklyRecapHabitProgressSemantics(String habitTitle, int doneCount, int expectedCount);

  /// No description provided for @weeklyRecapBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {habitTitle}, {streak}'**
  String weeklyRecapBestStreak(String habitTitle, String streak);

  /// No description provided for @dismissWeeklyRecap.
  ///
  /// In en, this message translates to:
  /// **'Dismiss the recap'**
  String get dismissWeeklyRecap;

  /// No description provided for @checkForUpdatesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get checkForUpdatesAutomatically;

  /// No description provided for @checkForUpdatesAutomaticallyDescription.
  ///
  /// In en, this message translates to:
  /// **'At most once a day, by asking GitHub for the latest version.'**
  String get checkForUpdatesAutomaticallyDescription;

  /// No description provided for @restoreAutomaticBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore an automatic backup'**
  String get restoreAutomaticBackup;

  /// No description provided for @automaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get automaticBackups;

  /// No description provided for @automaticBackupsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Komit keeps a copy of your data on this phone before each import or update, and once a day when something changed. The {count} most recent are kept.'**
  String automaticBackupsExplanation(int count);

  /// No description provided for @noAutomaticBackupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No automatic backup yet'**
  String get noAutomaticBackupsTitle;

  /// No description provided for @noAutomaticBackupsMessage.
  ///
  /// In en, this message translates to:
  /// **'The first one is made today, once you have logged something.'**
  String get noAutomaticBackupsMessage;

  /// No description provided for @automaticBackupBeforeImport.
  ///
  /// In en, this message translates to:
  /// **'Before an import'**
  String get automaticBackupBeforeImport;

  /// No description provided for @automaticBackupBeforeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Before an update'**
  String get automaticBackupBeforeUpdate;

  /// No description provided for @automaticBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily copy'**
  String get automaticBackupDaily;

  /// No description provided for @restoreAutomaticBackupConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get restoreAutomaticBackupConfirmationTitle;

  /// No description provided for @restoreAutomaticBackupConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Everything in the app will be replaced by the copy from {date}. Your current data is saved as an automatic backup first.'**
  String restoreAutomaticBackupConfirmationMessage(String date);

  /// No description provided for @preImportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Nothing was replaced: Komit could not save a copy of your current data first. Free up some space and try again.'**
  String get preImportBackupFailed;

  /// No description provided for @lastExportDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Last export: {days} days ago'**
  String lastExportDaysAgo(int days);

  /// No description provided for @exportEncryptedData.
  ///
  /// In en, this message translates to:
  /// **'Export with a passphrase'**
  String get exportEncryptedData;

  /// No description provided for @exportEncryptedDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Only someone who knows it can open the file.'**
  String get exportEncryptedDataDescription;

  /// No description provided for @encryptBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect the export'**
  String get encryptBackupTitle;

  /// No description provided for @encryptBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase. Komit cannot recover it: without it, this file can never be imported.'**
  String get encryptBackupMessage;

  /// No description provided for @decryptBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup'**
  String get decryptBackupTitle;

  /// No description provided for @decryptBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase chosen when this file was exported.'**
  String get decryptBackupMessage;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @confirmPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase again'**
  String get confirmPassphrase;

  /// No description provided for @showPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Show passphrase'**
  String get showPassphrase;

  /// No description provided for @hidePassphrase.
  ///
  /// In en, this message translates to:
  /// **'Hide passphrase'**
  String get hidePassphrase;

  /// No description provided for @passphraseTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String passphraseTooShort(int count);

  /// No description provided for @passphraseRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase.'**
  String get passphraseRequired;

  /// No description provided for @passphrasesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passphrases differ.'**
  String get passphrasesDoNotMatch;

  /// No description provided for @wrongBackupPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Wrong passphrase, or the file was damaged.'**
  String get wrongBackupPassphrase;

  /// No description provided for @encryptAndExport.
  ///
  /// In en, this message translates to:
  /// **'Encrypt and export'**
  String get encryptAndExport;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @privacyAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacyAndSecurity;

  /// No description provided for @appLockSetting.
  ///
  /// In en, this message translates to:
  /// **'Lock Komit'**
  String get appLockSetting;

  /// No description provided for @appLockSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint, face or screen lock when Komit opens and after a minute away.'**
  String get appLockSettingDescription;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock in your phone\'s settings to use this.'**
  String get appLockUnavailable;

  /// No description provided for @hideScreenContentSetting.
  ///
  /// In en, this message translates to:
  /// **'Hide from screenshots'**
  String get hideScreenContentSetting;

  /// No description provided for @hideScreenContentSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'Blocks screenshots and screen recordings, and blanks Komit in recent apps.'**
  String get hideScreenContentSettingDescription;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Komit is locked'**
  String get appLockTitle;

  /// No description provided for @appLockMessage.
  ///
  /// In en, this message translates to:
  /// **'Komo is keeping your habits safe while you were away.'**
  String get appLockMessage;

  /// No description provided for @appLockCancelled.
  ///
  /// In en, this message translates to:
  /// **'Unlocking was cancelled. Your habits stay hidden until you unlock.'**
  String get appLockCancelled;

  /// No description provided for @appLockFailed.
  ///
  /// In en, this message translates to:
  /// **'Komit could not be unlocked. Wait a moment, then try again.'**
  String get appLockFailed;

  /// No description provided for @appLockPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Komit'**
  String get appLockPromptTitle;

  /// No description provided for @appLockPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint, face or screen lock'**
  String get appLockPromptSubtitle;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy'**
  String get privacyTitle;

  /// No description provided for @privacyLink.
  ///
  /// In en, this message translates to:
  /// **'What stays on your phone'**
  String get privacyLink;

  /// No description provided for @privacyIntroduction.
  ///
  /// In en, this message translates to:
  /// **'Komit has no account, no ads and no analytics. Your habits, notes and first name are stored only in Komit\'s private space on this phone.'**
  String get privacyIntroduction;

  /// No description provided for @privacyWhatLeavesTitle.
  ///
  /// In en, this message translates to:
  /// **'What leaves your phone'**
  String get privacyWhatLeavesTitle;

  /// No description provided for @privacyUpdateCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'The update check, and nothing else'**
  String get privacyUpdateCheckTitle;

  /// No description provided for @privacyUpdateCheckBody.
  ///
  /// In en, this message translates to:
  /// **'At most once a day, Komit asks GitHub for its latest version, which shows GitHub your IP address. An update you accept is downloaded from GitHub too. Turn the automatic check off in Settings, under Updates.'**
  String get privacyUpdateCheckBody;

  /// No description provided for @privacyNoTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'No tracking'**
  String get privacyNoTrackingTitle;

  /// No description provided for @privacyNoTrackingBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing about your habits, notes or use of the app is ever sent anywhere.'**
  String get privacyNoTrackingBody;

  /// No description provided for @privacyBackupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Backups and exports'**
  String get privacyBackupsTitle;

  /// No description provided for @privacyCloudBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Not in your cloud backup'**
  String get privacyCloudBackupTitle;

  /// No description provided for @privacyCloudBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Android\'s backup to Google\'s cloud skips Komit. Moving to a new phone with a cable or Wi-Fi transfer still copies everything (Android 9 and later); otherwise, use an export.'**
  String get privacyCloudBackupBody;

  /// No description provided for @privacyAutomaticBackupsBody.
  ///
  /// In en, this message translates to:
  /// **'Copies made before an import or an update, and once a day, stay in Komit\'s private space on this phone. The {count} most recent are kept.'**
  String privacyAutomaticBackupsBody(int count);

  /// No description provided for @privacyPlainExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Plain exports'**
  String get privacyPlainExportTitle;

  /// No description provided for @privacyPlainExportBody.
  ///
  /// In en, this message translates to:
  /// **'A plain export is a readable file: anyone who opens it can read your habits and notes. Keep it somewhere private.'**
  String get privacyPlainExportBody;

  /// No description provided for @privacyEncryptedExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Exports with a passphrase'**
  String get privacyEncryptedExportTitle;

  /// No description provided for @privacyEncryptedExportBody.
  ///
  /// In en, this message translates to:
  /// **'Encrypted with AES-256 on this phone. Only your passphrase opens the file, and nobody can recover a forgotten one.'**
  String get privacyEncryptedExportBody;

  /// No description provided for @privacyErrorLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get privacyErrorLogTitle;

  /// No description provided for @privacyErrorLogBody.
  ///
  /// In en, this message translates to:
  /// **'Komit notes its own errors on this phone, without your habit names, notes or first name. It is never sent.'**
  String get privacyErrorLogBody;

  /// No description provided for @privacyPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get privacyPermissionsTitle;

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'For the reminders you set. Komit asks only when you add your first reminder.'**
  String get permissionNotificationsBody;

  /// No description provided for @permissionStartupTitle.
  ///
  /// In en, this message translates to:
  /// **'Run at startup'**
  String get permissionStartupTitle;

  /// No description provided for @permissionStartupBody.
  ///
  /// In en, this message translates to:
  /// **'Puts your reminders back after the phone restarts or the time zone changes.'**
  String get permissionStartupBody;

  /// No description provided for @permissionInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install apps'**
  String get permissionInstallTitle;

  /// No description provided for @permissionInstallBody.
  ///
  /// In en, this message translates to:
  /// **'Only to install a Komit update you accepted. Android asks you once.'**
  String get permissionInstallBody;

  /// No description provided for @permissionInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get permissionInternetTitle;

  /// No description provided for @permissionInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Only for the update check and download, over HTTPS.'**
  String get permissionInternetBody;

  /// No description provided for @permissionVibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get permissionVibrationTitle;

  /// No description provided for @permissionVibrationBody.
  ///
  /// In en, this message translates to:
  /// **'Light taps when you log a day, following your phone\'s settings.'**
  String get permissionVibrationBody;

  /// No description provided for @permissionBiometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint and face'**
  String get permissionBiometricTitle;

  /// No description provided for @permissionBiometricBody.
  ///
  /// In en, this message translates to:
  /// **'Only for the optional app lock. Android checks them; Komit never sees them.'**
  String get permissionBiometricBody;
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
