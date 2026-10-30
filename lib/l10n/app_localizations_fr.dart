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
  String get reminderLockedNotificationTitle => 'C\'est l\'heure d\'une habitude';

  @override
  String get reminderLockedNotificationBody => 'Ouvre Komit pour la noter.';

  @override
  String get reminderChannelName => 'Rappels d\'habitudes';

  @override
  String get notificationsDenied =>
      'Les rappels ont besoin des notifications, désactivées pour Komit. Tu peux les activer dans les paramètres du système.';

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
  String whatsNewTitle(String version) {
    return 'Bienvenue dans la $version';
  }

  @override
  String get whatsNewMessage => 'Komit est à jour. Voici ce qui change :';

  @override
  String get whatsNewDismiss => 'C\'est parti';

  @override
  String upToDateCheckedToday(String time) {
    return 'À jour · vérifié aujourd\'hui à $time';
  }

  @override
  String upToDateCheckedOn(String date) {
    return 'À jour · vérifié le $date';
  }

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
      'Komit n’a pas encore le droit d’installer des applications. Autorise-le dans les paramètres, puis réessaie.';

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
  String get onboardingRemindersTitle => 'Des rappels, seulement si tu le veux';

  @override
  String get onboardingRemindersMessage =>
      'Les rappels sont facultatifs et se règlent habitude par habitude, à l’heure de ton choix. Komit demande l’autorisation seulement quand tu en actives un.';

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
      other: 'Série de $count jours. Continue aujourd’hui.',
      one: 'Premier jour de série validé. Continue aujourd’hui.',
    );
    return '$_temp0';
  }

  @override
  String reminderNotificationBodyWithWeekStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count semaines. Continue aujourd’hui.',
      one: 'Série d’une semaine. Continue aujourd’hui.',
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
    return 'Te rappeler $habit ?';
  }

  @override
  String reminderPermissionMessage(String time) {
    return 'Komit enverra une notification à $time les jours où cette habitude est prévue, avec des boutons pour la noter tout de suite. Android te demande ensuite l’autorisation.';
  }

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsStatusEnabled => 'Activées : tes rappels peuvent s’afficher.';

  @override
  String get notificationsStatusDisabled => 'Désactivées : tes rappels ne s’afficheront pas.';

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
      'Android ouvre ensuite une page de paramètres. Active « Autoriser cette source », puis reviens : la mise à jour reprend toute seule.';

  @override
  String get confirmInstallInSystemWindow => 'Confirme l’installation dans la fenêtre d’Android.';

  @override
  String get updateErrorInstallCancelled => 'l’installation a été annulée.';

  @override
  String get updateErrorInstallConflict =>
      'une autre version de Komit sur ce téléphone l’empêche. Désinstalle-la après avoir exporté tes données, puis réessaie.';

  @override
  String get updateErrorInstallIncompatible => 'cette version n’est pas compatible avec ton téléphone.';

  @override
  String get updateErrorInstallStorage => 'il n’y a pas assez d’espace libre sur ton téléphone.';

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
  String get celebrationKeepGoingTomorrow => 'Continue demain pour la prolonger.';

  @override
  String get celebrationKeepGoingNextWeek => 'Continue la semaine prochaine pour la prolonger.';

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
  String get achievementsIntro => 'Les succès suivent tes suivis : effacer des jours peut en verrouiller un à nouveau.';

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
  String get achievementPerfectWeekDescription => 'Toutes tes habitudes ont suivi leur programme une semaine entière.';

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
  String get achievementOneYearVeteranDescription => 'Ton premier suivi a un an.';

  @override
  String get achievementFirstStepTitle => 'Premier pas';

  @override
  String get achievementFirstStepDescription => 'Ton premier jour réussi.';

  @override
  String get achievementMonthStreakTitle => 'Un mois d’affilée';

  @override
  String get achievementMonthStreakDescription => 'Trente jours d’affilée sur une habitude.';

  @override
  String get achievementHundredDayStreakTitle => '100 jours d’affilée';

  @override
  String get achievementHundredDayStreakDescription => 'Cent jours d’affilée sur une habitude.';

  @override
  String get achievementYearStreakTitle => 'Un an d’affilée';

  @override
  String get achievementYearStreakDescription => 'Une année entière d’affilée sur une habitude.';

  @override
  String get achievementPerfectDayTitle => 'Journée parfaite';

  @override
  String get achievementPerfectDayDescription => 'Toutes les habitudes prévues un jour, faites ce jour-là.';

  @override
  String get achievementFiveHundredTotalSuccessDaysTitle => '500 réussites';

  @override
  String get achievementFiveHundredTotalSuccessDaysDescription =>
      'Cinq cents jours réussis, toutes habitudes confondues.';

  @override
  String get achievementThousandTotalSuccessDaysTitle => '1 000 réussites';

  @override
  String get achievementThousandTotalSuccessDaysDescription => 'Mille jours réussis, toutes habitudes confondues.';

  @override
  String get achievementThreeHabitsTitle => 'Touche-à-tout';

  @override
  String get achievementThreeHabitsDescription => 'Des jours réussis sur trois habitudes différentes.';

  @override
  String get achievementTwoYearVeteranTitle => 'Deux ans';

  @override
  String get achievementTwoYearVeteranDescription => 'Ton premier suivi a deux ans.';

  @override
  String get achievementFirstMonthWithKomitTitle => 'Un mois ensemble';

  @override
  String get achievementFirstMonthWithKomitDescription => 'Ton premier suivi a un mois.';

  @override
  String get achievementTwoWeekStreakTitle => 'Deux semaines d’affilée';

  @override
  String get achievementTwoWeekStreakDescription => 'Quatorze jours d’affilée sur une habitude.';

  @override
  String get achievementTwoHundredDayStreakTitle => '200 jours d’affilée';

  @override
  String get achievementTwoHundredDayStreakDescription => 'Deux cents jours d’affilée sur une habitude.';

  @override
  String get achievementTenPerfectDaysTitle => 'Dix journées parfaites';

  @override
  String get achievementTenPerfectDaysDescription => 'Dix jours où toutes les habitudes prévues sont faites.';

  @override
  String get achievementFiftyPerfectDaysTitle => 'Cinquante journées parfaites';

  @override
  String get achievementFiftyPerfectDaysDescription => 'Cinquante jours où toutes les habitudes prévues sont faites.';

  @override
  String get achievementPerfectMonthTitle => 'Mois parfait';

  @override
  String get achievementPerfectMonthDescription => 'Tous les jours prévus d’un mois faits sur une habitude.';

  @override
  String get achievementHundredTotalSuccessDaysTitle => '100 réussites';

  @override
  String get achievementHundredTotalSuccessDaysDescription => 'Cent jours réussis, toutes habitudes confondues.';

  @override
  String get achievementYearOfSuccessDaysTitle => 'Une année de réussites';

  @override
  String get achievementYearOfSuccessDaysDescription => '365 jours réussis sur une même habitude.';

  @override
  String get achievementTwoThousandFiveHundredTotalSuccessDaysTitle => '2 500 réussites';

  @override
  String get achievementTwoThousandFiveHundredTotalSuccessDaysDescription =>
      'Deux mille cinq cents jours réussis, toutes habitudes confondues.';

  @override
  String get achievementFiveHabitsTitle => 'Jongleur';

  @override
  String get achievementFiveHabitsDescription => 'Des jours réussis sur cinq habitudes différentes.';

  @override
  String get achievementThreeObjectivesOnOneHabitTitle => 'Toutes les nuances';

  @override
  String get achievementThreeObjectivesOnOneHabitDescription =>
      'Trois objectifs réussis différents sur une même habitude.';

  @override
  String get achievementWeekendWarriorTitle => 'Week-end actif';

  @override
  String get achievementWeekendWarriorDescription => 'Une habitude faite un samedi et le dimanche qui suit.';

  @override
  String get achievementNewYearsDayTitle => 'Bonne résolution';

  @override
  String get achievementNewYearsDayDescription => 'Un jour réussi le 1ᵉʳ janvier.';

  @override
  String get achievementChristmasDayTitle => 'Même à Noël';

  @override
  String get achievementChristmasDayDescription => 'Un jour réussi le 25 décembre.';

  @override
  String get achievementLeapDayTitle => 'Tous les quatre ans';

  @override
  String get achievementLeapDayDescription => 'Un jour réussi le 29 février.';

  @override
  String get achievementPhoenixTitle => 'Phénix';

  @override
  String get achievementPhoenixDescription => 'Reprendre une habitude après un mois de jours manqués.';

  @override
  String get achievementHalloweenTitle => 'Un bonbon ou un sort';

  @override
  String get achievementHalloweenDescription => 'Un jour réussi le soir d’Halloween.';

  @override
  String get achievementEasterSundayTitle => 'Chasse aux œufs';

  @override
  String get achievementEasterSundayDescription => 'Un jour réussi le dimanche de Pâques.';

  @override
  String get seasonGreetingHalloween => 'Joyeux Halloween';

  @override
  String get seasonGreetingChristmas => 'Joyeuses fêtes';

  @override
  String get seasonGreetingEaster => 'Joyeuses Pâques';

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
      'À chaque ouverture, une fois par heure au plus, en demandant la dernière version à GitHub.';

  @override
  String get restoreAutomaticBackup => 'Restaurer une sauvegarde automatique';

  @override
  String get automaticBackups => 'Sauvegardes automatiques';

  @override
  String automaticBackupsExplanation(int count) {
    return 'Komit garde une copie de tes données sur ce téléphone avant chaque import ou mise à jour, et une fois par jour quand quelque chose a changé. Les $count plus récentes sont conservées.';
  }

  @override
  String get noAutomaticBackupsTitle => 'Aucune sauvegarde automatique';

  @override
  String get noAutomaticBackupsMessage => 'La première est faite aujourd\'hui, dès que tu auras noté quelque chose.';

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
    return 'Tout le contenu de l\'application sera remplacé par la copie du $date. Tes données actuelles sont d\'abord enregistrées dans une sauvegarde automatique.';
  }

  @override
  String get preImportBackupFailed =>
      'Rien n\'a été remplacé : Komit n\'a pas pu enregistrer d\'abord une copie de tes données actuelles. Libère de l\'espace et réessaie.';

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
      'Choisis une phrase secrète. Komit ne peut pas la retrouver : sans elle, ce fichier ne pourra jamais être importé.';

  @override
  String get decryptBackupTitle => 'Sauvegarde chiffrée';

  @override
  String get decryptBackupMessage => 'Saisis la phrase secrète choisie lors de l\'export de ce fichier.';

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
    return 'Utilise au moins $count caractères.';
  }

  @override
  String get passphraseRequired => 'Saisis la phrase secrète.';

  @override
  String get passphrasesDoNotMatch => 'Les deux phrases secrètes sont différentes.';

  @override
  String get wrongBackupPassphrase => 'Phrase secrète incorrecte, ou fichier endommagé.';

  @override
  String get encryptAndExport => 'Chiffrer et exporter';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get privacyAndSecurity => 'Confidentialité et sécurité';

  @override
  String get appLockSetting => 'Verrouiller Komit';

  @override
  String get appLockSettingDescription =>
      'Demander ton empreinte, ton visage ou le verrouillage de l\'écran à l\'ouverture de Komit et après une minute d\'absence. Les rappels et le widget masquent alors tes habitudes.';

  @override
  String get appLockUnavailable =>
      'Configure un verrouillage de l\'écran dans les réglages du téléphone pour l\'utiliser.';

  @override
  String get hideScreenContentSetting => 'Masquer des captures d\'écran';

  @override
  String get hideScreenContentSettingDescription =>
      'Bloque les captures et enregistrements d\'écran, et masque Komit dans les applications récentes.';

  @override
  String get appLockTitle => 'Komit est verrouillé';

  @override
  String get appLockMessage => 'Komo garde tes habitudes à l\'abri pendant ton absence.';

  @override
  String get appLockCancelled =>
      'Le déverrouillage a été annulé. Tes habitudes restent masquées jusqu\'au déverrouillage.';

  @override
  String get appLockFailed => 'Komit n\'a pas pu être déverrouillé. Patiente un instant, puis réessaie.';

  @override
  String get appLockPromptTitle => 'Déverrouiller Komit';

  @override
  String get appLockPromptSubtitle => 'Utilise ton empreinte, ton visage ou le verrouillage de l\'écran';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get privacyTitle => 'Ta vie privée';

  @override
  String get privacyLink => 'Ce qui reste sur ton téléphone';

  @override
  String get privacyIntroduction =>
      'Komit n\'a ni compte, ni publicité, ni statistiques d\'usage. Tes habitudes, tes notes et ton prénom sont enregistrés uniquement dans l\'espace privé de Komit sur ce téléphone.';

  @override
  String get privacyWhatLeavesTitle => 'Ce qui quitte ton téléphone';

  @override
  String get privacyUpdateCheckTitle => 'La recherche de mises à jour, rien d\'autre';

  @override
  String get privacyUpdateCheckBody =>
      'Quand tu ouvres Komit, une fois par heure au plus, il demande sa dernière version à GitHub, qui voit alors ton adresse IP. Une mise à jour acceptée est aussi téléchargée depuis GitHub. Désactive la recherche automatique dans les Réglages, rubrique Mises à jour.';

  @override
  String get privacyNoTrackingTitle => 'Aucun pistage';

  @override
  String get privacyNoTrackingBody =>
      'Rien sur tes habitudes, tes notes ou ton usage de l\'application n\'est jamais envoyé nulle part.';

  @override
  String get privacyBackupsTitle => 'Sauvegardes et exports';

  @override
  String get privacyCloudBackupTitle => 'Absent de ta sauvegarde cloud';

  @override
  String get privacyCloudBackupBody =>
      'La sauvegarde Android vers le cloud de Google ignore Komit. Le transfert vers un nouveau téléphone par câble ou Wi-Fi copie quand même tout (Android 9 et plus) ; sinon, utilise un export.';

  @override
  String privacyAutomaticBackupsBody(int count) {
    return 'Les copies faites avant un import ou une mise à jour, et une fois par jour, restent dans l\'espace privé de Komit sur ce téléphone. Les $count plus récentes sont conservées.';
  }

  @override
  String get privacyPlainExportTitle => 'Exports simples';

  @override
  String get privacyPlainExportBody =>
      'Un export simple est un fichier lisible : toute personne qui l\'ouvre peut lire tes habitudes et tes notes. Garde-le en lieu sûr.';

  @override
  String get privacyEncryptedExportTitle => 'Exports avec phrase secrète';

  @override
  String get privacyEncryptedExportBody =>
      'Chiffrés en AES-256 sur ce téléphone. Seule ta phrase secrète ouvre le fichier, et personne ne peut en retrouver une oubliée.';

  @override
  String get privacyErrorLogTitle => 'Journal d\'erreurs';

  @override
  String get privacyErrorLogBody =>
      'Komit note ses propres erreurs sur ce téléphone, sans le nom de tes habitudes, tes notes ni ton prénom. Ce journal n\'est jamais envoyé.';

  @override
  String get privacyPermissionsTitle => 'Autorisations';

  @override
  String get permissionNotificationsTitle => 'Notifications';

  @override
  String get permissionNotificationsBody =>
      'Pour les rappels que tu programmes. Komit ne demande qu\'au premier rappel ajouté.';

  @override
  String get permissionStartupTitle => 'Lancement au démarrage';

  @override
  String get permissionStartupBody =>
      'Remet tes rappels en place après un redémarrage du téléphone ou un changement de fuseau horaire.';

  @override
  String get permissionInstallTitle => 'Installation d\'applications';

  @override
  String get permissionInstallBody =>
      'Uniquement pour installer une mise à jour de Komit que tu as acceptée. Android te le demande une fois.';

  @override
  String get permissionInternetTitle => 'Internet';

  @override
  String get permissionInternetBody => 'Uniquement pour rechercher et télécharger les mises à jour, en HTTPS.';

  @override
  String get permissionVibrationTitle => 'Vibreur';

  @override
  String get permissionVibrationBody =>
      'De légères vibrations quand tu notes un jour, selon les réglages du téléphone.';

  @override
  String get permissionBiometricTitle => 'Empreinte et visage';

  @override
  String get permissionBiometricBody =>
      'Uniquement pour le verrouillage facultatif. Android les vérifie ; Komit ne les voit jamais.';

  @override
  String get habitEditorEveryDayHint => '7 jours sur 7';

  @override
  String get habitEditorSomeDaysHint => 'Seulement les jours choisis';

  @override
  String get habitEditorPerWeekHint => 'Les jours qui t\'arrangent';

  @override
  String get habitEditorWeekdaysOnly => 'En semaine';

  @override
  String get habitEditorWeekendsOnly => 'Le week-end';

  @override
  String habitEditorDaysPerWeekUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'jours par semaine',
      one: 'jour par semaine',
    );
    return '$_temp0';
  }

  @override
  String habitEditorColorSwatch(int position, int count) {
    return 'Couleur $position sur $count';
  }

  @override
  String get habitEditorObjectivesHelp => 'Ce que tu coches chaque jour, comme « Marche » ou « 5 km ».';

  @override
  String get habitEditorDiscardTitle => 'Abandonner tes modifications ?';

  @override
  String get habitEditorDiscardMessage => 'Ce que tu as modifié sur cette habitude sera perdu.';

  @override
  String get habitEditorDiscardConfirm => 'Abandonner';

  @override
  String get habitEditorKeepEditing => 'Continuer à modifier';
}
