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
