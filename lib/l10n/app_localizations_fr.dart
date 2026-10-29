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
  String greeting(String name) {
    return 'Bonjour, $name !';
  }

  @override
  String get greetingWithoutName => 'Bonjour !';

  @override
  String get habitsTab => 'Habitudes';

  @override
  String get notesTab => 'Notes';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String lastActivity(String date) {
    return 'Dernière activité : $date';
  }

  @override
  String get noActivityYet => 'Aucune activité';

  @override
  String get newHabit => 'Nouvelle habitude';

  @override
  String get emptyHabitsMessage => 'Crée ta première habitude pour commencer le suivi.';

  @override
  String get genericError => 'Une erreur est survenue. Réessaie.';

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
  String logForDate(String date) {
    return 'Journée du $date';
  }

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
      'Les notifications sont désactivées pour Komit. Active-les dans les réglages système pour recevoir les rappels.';

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
      'autorise Komit à installer des applis dans les réglages qui viennent de s\'ouvrir, puis réessaie.';

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
  String get onboardingRemindersTitle => 'Un petit rappel le soir ?';

  @override
  String get onboardingRemindersMessage =>
      'Quand tu ajoutes un rappel à une habitude, Komit t\'envoie une notification par jour, à l\'heure que tu choisis. Android te demande l\'autorisation juste après.';

  @override
  String get allowNotifications => 'Autoriser les notifications';

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
}
