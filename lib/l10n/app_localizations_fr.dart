// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Komit';

  @override
  String get habitsTab => 'Habitudes';

  @override
  String get notesTab => 'Notes';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get noActivityYet => 'Aucune activité';

  @override
  String get newHabit => 'Nouvelle habitude';

  @override
  String get genericError => 'Une erreur est survenue. Réessaie.';

  @override
  String get loadErrorTitle => 'Impossible d\'afficher cet écran';

  @override
  String get loadErrorMessage =>
      'Tes données sont toujours en sécurité sur ton téléphone. Réessaie, et redémarre Komit si ça continue.';

  @override
  String get retryLoading => 'Réessayer';

  @override
  String get logThisDayAction => 'Noter ce jour';

  @override
  String get habitNotFound => 'Habitude introuvable';

  @override
  String get currentStreak => 'Série en cours';

  @override
  String get bestStreak => 'Meilleure série';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String weekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
      zero: '0 semaine',
    );
    return '$_temp0';
  }

  @override
  String get yearlyProgress => 'Progression annuelle';

  @override
  String get logToday => 'Noter aujourd\'hui';

  @override
  String get objectivesLegend => 'Objectifs';

  @override
  String get clearLog => 'Effacer cette journée';

  @override
  String get chooseYear => 'Année';

  @override
  String get statisticsTooltip => 'Statistiques';

  @override
  String get moreActionsTooltip => 'Plus d\'actions';

  @override
  String get editHabit => 'Modifier l\'habitude';

  @override
  String get deleteHabit => 'Supprimer l\'habitude';

  @override
  String deleteHabitConfirmation(String title) {
    return 'Supprimer « $title » et tout son historique ? Action irréversible.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get back => 'Retour';

  @override
  String statisticsTitle(int year) {
    return 'Statistiques $year';
  }

  @override
  String get daysLogged => 'Jours renseignés';

  @override
  String get objectiveDistribution => 'Répartition des objectifs';

  @override
  String get monthlyActivity => 'Activité mensuelle';

  @override
  String get noLogsThisYear => 'Rien de renseigné cette année.';

  @override
  String get createHabit => 'Nouvelle habitude';

  @override
  String get habitName => 'Nom de l\'habitude';

  @override
  String get descriptionOptional => 'Description (facultatif)';

  @override
  String get appearance => 'Apparence';

  @override
  String get color => 'Couleur';

  @override
  String get icon => 'Icône';

  @override
  String get dailyReminder => 'Rappel quotidien';

  @override
  String reminderEnabledAt(String time) {
    return 'Activé à $time';
  }

  @override
  String get reminderDisabled => 'Désactivé';

  @override
  String get reminderTime => 'Heure du rappel';

  @override
  String get objectives => 'Objectifs';

  @override
  String get addObjective => 'Ajouter un objectif';

  @override
  String get objectiveName => 'Nom de l\'objectif';

  @override
  String get removeObjective => 'Retirer l\'objectif';

  @override
  String get reorderObjective => 'Glisser pour réordonner';

  @override
  String removeObjectiveWithLogsConfirmation(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count journées utilisent cet objectif. Elles seront supprimées à l\'enregistrement.',
      one: '1 journée utilise cet objectif. Elle sera supprimée à l\'enregistrement.',
    );
    return '$_temp0';
  }

  @override
  String get remove => 'Retirer';

  @override
  String get habitNameRequired => 'Donne un nom à ton habitude.';

  @override
  String get objectiveRequired => 'Ajoute au moins un objectif.';

  @override
  String get objectiveNamesMustBeFilledAndUnique => 'Chaque objectif doit avoir un nom unique.';

  @override
  String get chooseColor => 'Choisir une couleur';

  @override
  String get chooseIcon => 'Choisir une icône';

  @override
  String reminderNotificationTitle(String habit) {
    return '$habit';
  }

  @override
  String get reminderNotificationBody => 'Comment ça s\'est passé aujourd\'hui ? Note-le dans Komit.';

  @override
  String get reminderChannelName => 'Rappels d\'habitudes';

  @override
  String get notificationsDenied =>
      'Les rappels ont besoin des notifications, désactivées pour Komit. Vous pouvez les activer dans les paramètres du système.';

  @override
  String get secondBrain => 'Second cerveau';

  @override
  String get newNote => 'Nouvelle note';

  @override
  String get myNotes => 'Mes notes';

  @override
  String get noNotesYet => 'Aucune note pour l\'instant.';

  @override
  String get noteHint => 'Qu\'as-tu en tête ?';

  @override
  String get deleteNote => 'Supprimer la note';

  @override
  String get deleteNoteConfirmation => 'Supprimer cette note ? Action irréversible.';

  @override
  String get settings => 'Paramètres';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get yourName => 'Ton prénom';

  @override
  String get dataAndStorage => 'Données et stockage';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get importData => 'Importer des données';

  @override
  String get importConfirmationTitle => 'Remplacer toutes les données ?';

  @override
  String importConfirmationMessage(int habits, int logs, int notes) {
    return 'Ce fichier contient $habits habitudes, $logs journées renseignées et $notes notes. Tout le contenu actuel de l\'app sera remplacé.';
  }

  @override
  String get replace => 'Remplacer';

  @override
  String importSucceeded(int logs) {
    return 'Import terminé : $logs journées restaurées.';
  }

  @override
  String importFailed(String reason) {
    return 'Ce fichier n\'a pas pu être importé : $reason';
  }

  @override
  String get exportFailed => 'L\'export a échoué. Réessaie.';

  @override
  String get updates => 'Mises à jour';

  @override
  String get checkForUpdates => 'Rechercher une mise à jour';

  @override
  String get upToDate => 'Komit est à jour.';

  @override
  String get updateCheckFailed => 'Impossible de vérifier les mises à jour. Vérifie ta connexion.';

  @override
  String updateAvailableTitle(String version) {
    return 'Komit $version est disponible';
  }

  @override
  String get whatsNew => 'Nouveautés';

  @override
  String get later => 'Plus tard';

  @override
  String get installUpdate => 'Installer';

  @override
  String downloadingUpdate(int percent) {
    return 'Téléchargement… $percent %';
  }

  @override
  String updateFailed(String reason) {
    return 'La mise à jour n\'a pas pu être installée : $reason';
  }

  @override
  String versionLabel(String version) {
    return 'Komit v$version';
  }

  @override
  String get onboardingTitle => 'Salut, moi c\'est Komo.';

  @override
  String get onboardingSubtitle =>
      'Je garde un œil sur tes habitudes. Un geste par jour, et ton année se remplit, case après case.';

  @override
  String get onboardingNameLabel => 'Ton prénom';

  @override
  String get getStarted => 'Commencer';

  @override
  String get restoreFromBackup => 'Restaurer une sauvegarde';

  @override
  String get loading => 'Chargement…';

  @override
  String get updateErrorInstallPermission =>
      'Komit n’a pas encore le droit d’installer des applications. Autorisez-le dans les paramètres, puis réessayez.';

  @override
  String get updateErrorNetwork => 'le téléchargement a été interrompu. Vérifie ta connexion et réessaie.';

  @override
  String get updateErrorInvalidRelease => 'cette version n\'est pas disponible à l\'installation.';

  @override
  String get updateErrorCorruptedDownload => 'le fichier téléchargé est endommagé. Réessaie.';

  @override
  String get updateErrorInstallFailed => 'Android a refusé l\'installation.';

  @override
  String get logAnotherDay => 'Noter un autre jour';

  @override
  String get habitNameTooLong => 'Le nom de l\'habitude est trop long.';

  @override
  String get exportPrivacyNote => 'Le fichier exporté n\'est pas chiffré : garde-le dans un endroit privé.';

  @override
  String get onboardingNameTitle => 'Comment je t\'appelle ?';

  @override
  String get onboardingNameMessage => 'Ton prénom s\'affiche seulement sur ton accueil. Tu peux passer cette étape.';

  @override
  String get onboardingRemindersTitle => 'Des rappels, seulement si vous le voulez';

  @override
  String get onboardingRemindersMessage =>
      'Les rappels sont facultatifs et se règlent habitude par habitude, à l’heure de votre choix. Komit demande l’autorisation seulement quand vous en activez un.';

  @override
  String get continueAction => 'Continuer';

  @override
  String get skip => 'Passer';

  @override
  String onboardingStepProgress(int currentStep, int stepCount) {
    return 'Étape $currentStep sur $stepCount';
  }

  @override
  String get dashboardEmptyTitle => 'Ta première habitude t\'attend';

  @override
  String get dashboardEmptyMessage =>
      'Choisis une chose à faire chaque jour, avec tes propres objectifs. Je m\'occupe du calendrier.';

  @override
  String get createFirstHabit => 'Créer une habitude';

  @override
  String get noNotesYetMessage => 'Note une idée, un ressenti ou une petite victoire. Tout reste ici.';

  @override
  String greetingMorning(String name) {
    return 'Bonjour, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Bon après-midi, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Bonsoir, $name';
  }

  @override
  String get greetingMorningWithoutName => 'Bonjour';

  @override
  String get greetingAfternoonWithoutName => 'Bon après-midi';

  @override
  String get greetingEveningWithoutName => 'Bonsoir';

  @override
  String todayProgress(int done, int total) {
    return '$done/$total faites aujourd\'hui';
  }

  @override
  String todayProgressSemantics(int done, int total) {
    return '$done habitudes sur $total faites aujourd\'hui';
  }

  @override
  String get allDoneToday => 'Tout est fait aujourd\'hui';

  @override
  String get nothingPlannedToday => 'Rien de prévu aujourd\'hui';

  @override
  String get lastLoggedToday => 'Noté aujourd\'hui';

  @override
  String get lastLoggedYesterday => 'Noté hier';

  @override
  String lastLoggedDaysAgo(int count) {
    return 'Noté il y a $count jours';
  }

  @override
  String lastLoggedOn(String date) {
    return 'Noté le $date';
  }

  @override
  String get notToday => 'Pas aujourd\'hui';

  @override
  String weeklyProgress(int done, int target) {
    return '$done/$target cette semaine';
  }

  @override
  String currentStreakSemantics(String streak) {
    return 'Série en cours : $streak';
  }

  @override
  String habitRowLoggedToday(String habit, String objective) {
    return '$habit, noté aujourd\'hui : $objective';
  }

  @override
  String habitRowNotLoggedToday(String habit) {
    return '$habit, pas encore noté aujourd\'hui';
  }

  @override
  String habitRowNotPlannedToday(String habit) {
    return '$habit, pas prévu aujourd\'hui';
  }

  @override
  String logHabitToday(String habit) {
    return 'Noter $habit pour aujourd\'hui';
  }

  @override
  String changeTodayLog(String habit) {
    return 'Modifier la journée de $habit';
  }

  @override
  String get chooseAnObjectiveHint => 'choisir un objectif';

  @override
  String dayLoggedMessage(String objective, String habit) {
    return '« $objective » noté pour $habit';
  }

  @override
  String dayClearedMessage(String habit) {
    return 'Journée effacée pour $habit';
  }

  @override
  String get undo => 'Annuler';

  @override
  String stripDayLogged(String date, String objective) {
    return '$date : $objective';
  }

  @override
  String stripDayNotLogged(String date) {
    return '$date : non noté';
  }

  @override
  String stripDayNotAvailableYet(String date) {
    return '$date : pas encore disponible';
  }

  @override
  String get relativeToday => 'Aujourd\'hui';

  @override
  String get relativeYesterday => 'Hier';

  @override
  String get futureLogExplanation =>
      'Ce jour à venir a été noté dans l\'ancienne app Komit. Tu peux seulement l\'effacer.';

  @override
  String get countsTowardStreak => 'Compte pour la série';

  @override
  String get schedule => 'Fréquence';

  @override
  String get scheduleEveryDay => 'Tous les jours';

  @override
  String get scheduleSomeDays => 'Certains jours';

  @override
  String get schedulePerWeek => 'Par semaine';

  @override
  String targetDaysPerWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours par semaine',
      one: '1 jour par semaine',
    );
    return '$_temp0';
  }

  @override
  String get fewerDaysPerWeek => 'Moins de jours par semaine';

  @override
  String get moreDaysPerWeek => 'Plus de jours par semaine';

  @override
  String get pickAtLeastOneDay => 'Choisis au moins un jour.';

  @override
  String get preview => 'Aperçu';

  @override
  String get habitNamePlaceholder => 'Ton habitude';

  @override
  String get saveHabit => 'Enregistrer';

  @override
  String get createHabitAction => 'Créer l\'habitude';

  @override
  String get archiveHabit => 'Archiver l\'habitude';

  @override
  String get unarchiveHabit => 'Remettre dans ma liste';

  @override
  String habitArchivedMessage(String habit) {
    return '$habit archivée';
  }

  @override
  String habitUnarchivedMessage(String habit) {
    return '$habit est de retour dans ta liste';
  }

  @override
  String archivedHabitsRow(int count) {
    return 'Archivées ($count)';
  }

  @override
  String get archivedHabitsTitle => 'Archivées';

  @override
  String archivedOn(String date) {
    return 'Archivée le $date';
  }

  @override
  String get noArchivedHabitsTitle => 'Rien d\'archivé';

  @override
  String get noArchivedHabitsMessage =>
      'Archive une habitude depuis sa page pour la mettre en pause sans perdre son historique.';

  @override
  String get moveUp => 'Monter';

  @override
  String get moveDown => 'Descendre';

  @override
  String get noteSaveFailed => 'La note n\'a pas pu être enregistrée. Copie son texte, puis réessaie.';

  @override
  String reminderNotificationBodyWithDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours. Continuez aujourd’hui.',
      one: 'Premier jour de série validé. Continuez aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String reminderNotificationBodyWithWeekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count semaines. Continuez aujourd’hui.',
      one: 'Série d’une semaine. Continuez aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String get reminderChannelDescription =>
      'Une notification les jours où une habitude est prévue, à l’heure choisie pour elle.';

  @override
  String get reminderActionDone => 'Fait';

  @override
  String get reminderActionLater => 'Plus tard';

  @override
  String reminderPermissionTitle(String habit) {
    return 'Vous rappeler $habit ?';
  }

  @override
  String reminderPermissionMessage(String time) {
    return 'Komit enverra une notification à $time les jours où cette habitude est prévue, avec des boutons pour la noter tout de suite. Android vous demande ensuite l’autorisation.';
  }

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsStatusEnabled => 'Activées : vos rappels peuvent s’afficher.';

  @override
  String get notificationsStatusDisabled => 'Désactivées : vos rappels ne s’afficheront pas.';

  @override
  String get notificationsStatusUnavailable => 'Non disponibles sur cet appareil.';

  @override
  String get notificationsStatusTitle => 'État des notifications';

  @override
  String get openSystemSettings => 'Ouvrir les paramètres du système';

  @override
  String get languageSystem => 'Système';

  @override
  String get about => 'À propos';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get allVersionsOnGitHub => 'Toutes les versions sur GitHub';

  @override
  String get installPermissionTitle => 'Autoriser Komit à installer ses mises à jour';

  @override
  String get installPermissionMessage =>
      'Android ouvre ensuite une page de paramètres. Activez « Autoriser cette source », puis revenez : la mise à jour reprend toute seule.';

  @override
  String get confirmInstallInSystemWindow => 'Confirmez l’installation dans la fenêtre d’Android.';

  @override
  String get updateErrorInstallCancelled => 'l’installation a été annulée.';

  @override
  String get updateErrorInstallConflict =>
      'une autre version de Komit sur ce téléphone l’empêche. Désinstallez-la après avoir exporté vos données, puis réessayez.';

  @override
  String get updateErrorInstallIncompatible => 'cette version n’est pas compatible avec votre téléphone.';

  @override
  String get updateErrorInstallStorage => 'il n’y a pas assez d’espace libre sur votre téléphone.';

  @override
  String get updateErrorInstallBlocked => 'Android a bloqué l’installation.';

  @override
  String get settingsUnavailable => 'Les paramètres n’ont pas pu s’ouvrir.';

  @override
  String get thisHabit => 'cette habitude';

  @override
  String get celebrationFirstLogTitle => 'Premier jour enregistré';

  @override
  String get celebrationFirstLogMessage => 'Chaque série commence par un jour.';

  @override
  String celebrationStreakDaysTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours d’affilée',
      one: '1 jour d’affilée',
    );
    return '$_temp0';
  }

  @override
  String celebrationStreakWeeksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines d’affilée',
      one: '1 semaine réussie',
    );
    return '$_temp0';
  }

  @override
  String get celebrationKeepGoingTomorrow => 'Continuez demain pour la prolonger.';

  @override
  String get celebrationKeepGoingNextWeek => 'Continuez la semaine prochaine pour la prolonger.';

  @override
  String get dismissCelebration => 'fermer';

  @override
  String get achievementUnlocked => 'Succès débloqué';

  @override
  String get achievementsTitle => 'Succès';

  @override
  String get achievementsTooltip => 'Succès';

  @override
  String achievementsSummary(int unlockedCount, int totalCount) {
    return '$unlockedCount sur $totalCount débloqués';
  }

  @override
  String get achievementsIntro => 'Les succès suivent vos suivis : effacer des jours peut en verrouiller un à nouveau.';

  @override
  String get achievementUnlockedStatus => 'Débloqué';

  @override
  String get achievementLockedStatus => 'Verrouillé';

  @override
  String get achievementFirstWeekTitle => 'Première semaine';

  @override
  String get achievementFirstWeekDescription => 'Sept jours d’affilée sur une habitude, ou une semaine à l’objectif.';

  @override
  String get achievementPerfectWeekTitle => 'Semaine parfaite';

  @override
  String get achievementPerfectWeekDescription => 'Toutes vos habitudes ont suivi leur programme une semaine entière.';

  @override
  String get achievementHundredSuccessDaysTitle => '100 jours';

  @override
  String get achievementHundredSuccessDaysDescription => 'Cent jours réussis sur une même habitude.';

  @override
  String get achievementComebackTitle => 'Retour en force';

  @override
  String get achievementComebackDescription => 'Reprendre une habitude après une semaine de jours manqués.';

  @override
  String get achievementOneYearVeteranTitle => 'Un an';

  @override
  String get achievementOneYearVeteranDescription => 'Votre premier suivi a un an.';

  @override
  String get weeklyRecapTitle => 'La semaine dernière';

  @override
  String weeklyRecapSuccessDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours réussis',
      one: '1 jour réussi',
      zero: 'Aucun jour réussi',
    );
    return '$_temp0';
  }

  @override
  String weeklyRecapMoreThanWeekBefore(int count) {
    return '$count de plus que la semaine d’avant';
  }

  @override
  String weeklyRecapFewerThanWeekBefore(int count) {
    return '$count de moins que la semaine d’avant';
  }

  @override
  String get weeklyRecapSameAsWeekBefore => 'Autant que la semaine d’avant';

  @override
  String weeklyRecapHabitProgress(int doneCount, int expectedCount) {
    return '$doneCount sur $expectedCount';
  }

  @override
  String weeklyRecapHabitProgressSemantics(String habitTitle, int doneCount, int expectedCount) {
    return '$habitTitle : $doneCount sur $expectedCount';
  }

  @override
  String weeklyRecapBestStreak(String habitTitle, String streak) {
    return 'Plus longue série : $habitTitle, $streak';
  }

  @override
  String get dismissWeeklyRecap => 'Masquer le bilan';

  @override
  String get checkForUpdatesAutomatically => 'Rechercher les mises à jour automatiquement';

  @override
  String get checkForUpdatesAutomaticallyDescription =>
      'Une fois par jour au plus, en demandant la dernière version à GitHub.';

  @override
  String get restoreAutomaticBackup => 'Restaurer une sauvegarde automatique';

  @override
  String get automaticBackups => 'Sauvegardes automatiques';

  @override
  String automaticBackupsExplanation(int count) {
    return 'Komit garde une copie de vos données sur ce téléphone avant chaque import ou mise à jour, et une fois par jour quand quelque chose a changé. Les $count plus récentes sont conservées.';
  }

  @override
  String get noAutomaticBackupsTitle => 'Aucune sauvegarde automatique';

  @override
  String get noAutomaticBackupsMessage => 'La première est faite aujourd\'hui, dès que vous aurez noté quelque chose.';

  @override
  String get automaticBackupBeforeImport => 'Avant un import';

  @override
  String get automaticBackupBeforeUpdate => 'Avant une mise à jour';

  @override
  String get automaticBackupDaily => 'Copie quotidienne';

  @override
  String get restoreAutomaticBackupConfirmationTitle => 'Restaurer cette sauvegarde ?';

  @override
  String restoreAutomaticBackupConfirmationMessage(String date) {
    return 'Tout le contenu de l\'application sera remplacé par la copie du $date. Vos données actuelles sont d\'abord enregistrées dans une sauvegarde automatique.';
  }

  @override
  String get preImportBackupFailed =>
      'Rien n\'a été remplacé : Komit n\'a pas pu enregistrer d\'abord une copie de vos données actuelles. Libérez de l\'espace et réessayez.';

  @override
  String lastExportDaysAgo(int days) {
    return 'Dernier export : il y a $days jours';
  }

  @override
  String get exportEncryptedData => 'Exporter avec une phrase secrète';

  @override
  String get exportEncryptedDataDescription => 'Seule une personne qui la connaît peut ouvrir le fichier.';

  @override
  String get encryptBackupTitle => 'Protéger l\'export';

  @override
  String get encryptBackupMessage =>
      'Choisissez une phrase secrète. Komit ne peut pas la retrouver : sans elle, ce fichier ne pourra jamais être importé.';

  @override
  String get decryptBackupTitle => 'Sauvegarde chiffrée';

  @override
  String get decryptBackupMessage => 'Saisissez la phrase secrète choisie lors de l\'export de ce fichier.';

  @override
  String get passphrase => 'Phrase secrète';

  @override
  String get confirmPassphrase => 'Phrase secrète, à nouveau';

  @override
  String get showPassphrase => 'Afficher la phrase secrète';

  @override
  String get hidePassphrase => 'Masquer la phrase secrète';

  @override
  String passphraseTooShort(int count) {
    return 'Utilisez au moins $count caractères.';
  }

  @override
  String get passphraseRequired => 'Saisissez la phrase secrète.';

  @override
  String get passphrasesDoNotMatch => 'Les deux phrases secrètes sont différentes.';

  @override
  String get wrongBackupPassphrase => 'Phrase secrète incorrecte, ou fichier endommagé.';

  @override
  String get encryptAndExport => 'Chiffrer et exporter';

  @override
  String get unlock => 'Déverrouiller';
}
