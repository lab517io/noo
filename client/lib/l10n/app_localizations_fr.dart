// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appMenuFile => 'Fichier';

  @override
  String get appMenuEdit => 'Édition';

  @override
  String get appMenuView => 'Affichage';

  @override
  String get appMenuTools => 'Outils';

  @override
  String get appMenuDebug => 'Débogage';

  @override
  String get appMenuHelp => 'Aide';

  @override
  String get appMenuWindow => 'Fenêtre';

  @override
  String get appMenuOpen => 'Ouvrir...';

  @override
  String get appMenuOpenDatabase => 'Ouvrir une base de données...';

  @override
  String get appMenuNewDatabase => 'Nouvelle base de données...';

  @override
  String get appMenuExportObsidian => 'Exporter vers Obsidian...';

  @override
  String get appMenuImportObsidian => 'Importer depuis Obsidian...';

  @override
  String get appMenuExit => 'Quitter';

  @override
  String get appMenuFind => 'Rechercher...';

  @override
  String get appMenuTheme => 'Thème';

  @override
  String get appMenuThemeEllipsis => 'Thème...';

  @override
  String get appThemeSystem => 'Système';

  @override
  String get appThemeLight => 'Clair';

  @override
  String get appThemeDark => 'Sombre';

  @override
  String get appMenuTimeline => 'Chronologie...';

  @override
  String get appMenuTimeReport => 'Rapport de temps...';

  @override
  String get appMenuCompactDatabase => 'Compacter la base de données...';

  @override
  String get appMenuSyncNow => 'Synchroniser maintenant';

  @override
  String get appMenuSyncP2p => 'Sync P2P...';

  @override
  String get appMenuPreferences => 'Préférences...';

  @override
  String get appMenuViewChangeHistory =>
      'Afficher l’historique des modifications...';

  @override
  String get appMenuGenerateTestData => 'Générer des données de test';

  @override
  String get appMenuGenerateLargeDataset => 'Générer un grand jeu de données';

  @override
  String get appMenuClearAllData => 'Effacer toutes les données';

  @override
  String get appMenuCheckForUpdate => 'Rechercher une mise à jour...';

  @override
  String get appMenuLogs => 'Journaux';

  @override
  String get appMenuSyncLog => 'Journal de synchronisation...';

  @override
  String get appMenuAppLog => 'Journal de l’application...';

  @override
  String appMenuAbout(String appName) {
    return 'À propos de $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Rechercher une mise à jour…';

  @override
  String get appMacMenuSettings => 'Réglages…';

  @override
  String appMacMenuQuit(String appName) {
    return 'Quitter $appName';
  }

  @override
  String get appMacMenuOpen => 'Ouvrir…';

  @override
  String get appMacMenuNewDatabase => 'Nouvelle base de données…';

  @override
  String get appMacMenuExportObsidian => 'Exporter vers Obsidian…';

  @override
  String get appMacMenuImportObsidian => 'Importer depuis Obsidian…';

  @override
  String get appMacMenuUndo => 'Annuler';

  @override
  String get appMacMenuRedo => 'Rétablir';

  @override
  String get appMacMenuCut => 'Couper';

  @override
  String get appMacMenuPaste => 'Coller';

  @override
  String get appMacMenuSelectAll => 'Tout sélectionner';

  @override
  String get appMacMenuFind => 'Rechercher…';

  @override
  String get appMacMenuTimeline => 'Chronologie…';

  @override
  String get appMacMenuTimeReport => 'Rapport de temps…';

  @override
  String get appMacMenuCompactDatabase => 'Compacter la base de données…';

  @override
  String get appMacMenuSyncP2p => 'Sync P2P…';

  @override
  String get appMacMenuViewChangeHistory =>
      'Afficher l’historique des modifications…';

  @override
  String get appMacMenuSyncLog => 'Journal de synchronisation…';

  @override
  String get appMacMenuAppLog => 'Journal de l’application…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Ouvrir une base de données';

  @override
  String get appCreateDatabaseDialogTitle => 'Créer une base de données';

  @override
  String get appIncorrectPasswordRetry =>
      'Mot de passe incorrect. Veuillez réessayer.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Ouvert : $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Impossible d’ouvrir la base de données : $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Créé : $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Impossible de créer la base de données : $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Ouvrez d’abord une base de données';

  @override
  String get appNoDatabaseOpen => 'Aucune base de données ouverte';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Impossible de lire le fichier de base de données : $error';
  }

  @override
  String get appWrongPasswordOrCorrupt =>
      'Mot de passe incorrect ou base de données endommagée';

  @override
  String get appExportObsidianDialogTitle =>
      'Exporter vers un dossier Obsidian';

  @override
  String get appImportObsidianDialogTitle =>
      'Importer depuis un dossier Obsidian';

  @override
  String get appImportObsidianZipDialogTitle => 'Importer un .zip Obsidian';

  @override
  String get appExportingObsidian => 'Export au format Obsidian...';

  @override
  String get appImportingObsidian => 'Import depuis le format Obsidian...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tâches',
      one: '$count tâche',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers de chronologie',
      one: '$count fichier de chronologie',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '$count image',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements de temps',
      one: '$count enregistrement de temps',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Exporté : $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'Importé : $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Échec de l’export : $error';
  }

  @override
  String appImportFailed(String error) {
    return 'Échec de l’import : $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Export Obsidian ($count tâches)',
      one: 'Export Obsidian ($count tâche)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'Le dossier n’existe pas : $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Synchronisation non configurée. Ouvrez d’abord les réglages de synchronisation.';

  @override
  String get appNoSyncServer =>
      'Aucun serveur de synchronisation configuré. Utilisez Sync P2P... (Shift+F5) ou ajoutez un serveur dans les Préférences.';

  @override
  String get appUnsyncedChangesTitle => 'Modifications non synchronisées';

  @override
  String get appUnsyncedChangesBody =>
      'Certaines modifications ne sont pas synchronisées. Voulez-vous les synchroniser ?';

  @override
  String get appDontSync => 'Ne pas synchroniser';

  @override
  String get appSync => 'Synchroniser';

  @override
  String get appSelectTaskFirst => 'Sélectionnez d’abord une tâche';

  @override
  String get appGenerateTestDataBody =>
      'Des tâches d’exemple avec une hiérarchie et des enregistrements de temps vont être créées.\n\nContinuer ?';

  @override
  String get appGenerate => 'Générer';

  @override
  String get appTestDataGenerated => 'Données de test générées';

  @override
  String get appGenerateLargeDatasetBody =>
      'Un grand jeu de données va être créé :\n- 20 tâches de premier niveau\n- Jusqu’à 5 niveaux de profondeur\n- Jusqu’à 6 enfants par tâche\n- Des enregistrements de temps pour de nombreuses tâches\n\nCela peut prendre un moment. Continuer ?';

  @override
  String get appGeneratingData => 'Génération des données...';

  @override
  String get appLargeDatasetGenerated => 'Grand jeu de données généré';

  @override
  String get appClearAllDataBody =>
      'Toutes les tâches, tous les enregistrements de temps et toutes les pièces jointes vont être définitivement supprimés.\n\nCette action est irréversible. Voulez-vous continuer ?';

  @override
  String get appDeleteAll => 'Tout supprimer';

  @override
  String get appAllDataCleared => 'Toutes les données ont été effacées';

  @override
  String get appCompactDatabaseTitle => 'Compacter la base de données';

  @override
  String get appCompactDatabaseBody =>
      'Réécrit le fichier de base de données pour rendre au disque l’espace occupé par les tâches et pièces jointes supprimées et par l’ancien historique des modifications.\n\nLe contenu des pièces jointes supprimées est lui aussi libéré ; il sera de nouveau téléchargé depuis le serveur si vous en restaurez une.\n\nRien de ce qui est encore visible n’est supprimé. Sur une grande base de données, cela prend un certain temps et l’application est inutilisable jusqu’à la fin.';

  @override
  String get appCompact => 'Compacter';

  @override
  String get appCompactingDatabase => 'Compactage de la base de données...';

  @override
  String appCompactingFailed(String error) {
    return 'Échec du compactage : $error';
  }

  @override
  String get appDatabaseCompacted => 'Base de données compactée';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'Base de données compactée — $freed libérés (désormais $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'Base de données compactée — déjà compacte ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Rechercher';

  @override
  String get appSyncNowTooltip => 'Synchroniser maintenant';

  @override
  String get appBiometricFailed =>
      'Échec de la vérification biométrique. Veuillez saisir le mot de passe.';

  @override
  String get appSavedPasswordIncorrect =>
      'Le mot de passe enregistré est incorrect. Veuillez saisir le mot de passe.';

  @override
  String get appLoading => 'Chargement...';

  @override
  String get appFailedToOpenDatabaseTitle =>
      'Impossible d’ouvrir la base de données';

  @override
  String get appOpenAnotherDatabase => 'Ouvrir une autre base de données…';

  @override
  String get appBiometricReason => 'Déverrouiller votre base de données Noo';

  @override
  String appWelcomeTitle(String appName) {
    return 'Bienvenue dans $appName';
  }

  @override
  String get appWelcomeIntro =>
      'Choisissez où stocker votre base de données chiffrée. Vous pourrez modifier ce choix plus tard depuis le menu Fichier.';

  @override
  String get appUseDefaultLocation => 'Utiliser l’emplacement par défaut';

  @override
  String get appResolving => 'Détermination…';

  @override
  String get appCreateNewDatabaseOption => 'Créer une base de données…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Choisir un emplacement personnalisé pour une nouvelle base de données chiffrée.';

  @override
  String get appOpenExistingDatabaseOption =>
      'Ouvrir une base de données existante…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Utiliser un fichier .noo existant situé ailleurs.';

  @override
  String get appQuit => 'Quitter';

  @override
  String get appWelcomeSyncHint =>
      'Vous avez déjà une base de données sur un autre appareil ? Créez-en une nouvelle ici avec le même mot de passe, puis configurez la synchronisation dans Préférences → Synchronisation avec le même nom d’utilisateur : vos notes arriveront à la première synchronisation.';

  @override
  String get appTaskFallbackTitle => 'Tâche';

  @override
  String get appTabNotes => 'Notes';

  @override
  String get appTabTime => 'Temps';

  @override
  String get appTabFiles => 'Fichiers';

  @override
  String appTabFilesCount(int count) {
    return 'Fichiers ($count)';
  }

  @override
  String get appStartTracking => 'Démarrer le suivi';

  @override
  String get appStopTracking => 'Arrêter le suivi';

  @override
  String get appNoTaskSelected => 'Aucune tâche sélectionnée.';

  @override
  String get appAttachmentsHeading => 'Pièces jointes';

  @override
  String get appModified => 'Modifié';

  @override
  String get appWordWrapOnTooltip =>
      'Retour à la ligne activé — cliquer pour le désactiver';

  @override
  String get appWordWrapOffTooltip =>
      'Retour à la ligne désactivé — cliquer pour l’activer';

  @override
  String get appTimeTodayTap => 'Temps suivi aujourd’hui — toucher pour ouvrir';

  @override
  String get appHideTimeTracking => 'Masquer le suivi du temps';

  @override
  String get appTimeTodayClick =>
      'Temps suivi aujourd’hui — cliquer pour les détails';

  @override
  String get appViewTimeline => 'Afficher la chronologie';

  @override
  String get appAttachmentsTap => 'Pièces jointes — toucher pour ouvrir';

  @override
  String get appHideAttachments => 'Masquer les pièces jointes';

  @override
  String get appAttachmentsClick => 'Pièces jointes — cliquer pour afficher';

  @override
  String get appAddAttachment => 'Ajouter une pièce jointe';

  @override
  String get appUntitledInPath => '(sans titre)';

  @override
  String get appSyncStatusDisabled =>
      'Synchronisation désactivée — cliquer pour synchroniser';

  @override
  String get appSyncStatusUnknown =>
      'Pas encore synchronisé — cliquer pour synchroniser';

  @override
  String get appSyncStatusIdle => 'Synchronisé — cliquer pour synchroniser';

  @override
  String get appSyncStatusSyncing => 'Synchronisation...';

  @override
  String get appSyncStatusError =>
      'Erreur de synchronisation — cliquer pour réessayer';

  @override
  String get appSyncStatusPending =>
      'Modifications en attente — cliquer pour synchroniser';

  @override
  String get appSyncStatusIncoming =>
      'D’autres appareils ont envoyé des modifications — cliquer pour synchroniser';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Suivi du temps sur « $title » — cliquer pour y aller';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Arrêter le suivi de « $title »';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String appPendingMore(int count) {
    return '+$count de plus';
  }

  @override
  String appPendingItemDetail(String fields, String ago) {
    return '$fields · $ago';
  }

  @override
  String appCountItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '$count élément',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications',
      one: '$count modification',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'En attente de synchronisation : $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'titre';

  @override
  String get appPendingFieldContent => 'contenu';

  @override
  String get appPendingFieldMoved => 'déplacé';

  @override
  String get appPendingFieldReordered => 'réordonné';

  @override
  String get appPendingFieldFlags => 'indicateurs';

  @override
  String get appPendingFieldDeleted => 'supprimé';

  @override
  String get appPendingFieldName => 'nom';

  @override
  String get appPendingFieldStartTime => 'heure de début';

  @override
  String get appPendingFieldEndTime => 'heure de fin';

  @override
  String get appJustNow => 'à l’instant';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count min',
      one: 'il y a $count min',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count h',
      one: 'il y a $count h',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count j',
      one: 'il y a $count j',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Saisir le mot de passe';

  @override
  String get appSetDatabasePasswordTitle =>
      'Définir le mot de passe de la base de données';

  @override
  String get appPasswordLabel => 'Mot de passe';

  @override
  String get appConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get appPleaseEnterPassword => 'Veuillez saisir un mot de passe';

  @override
  String get appPasswordTooShort =>
      'Le mot de passe doit comporter au moins 4 caractères';

  @override
  String get appPasswordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get appPasswordWarning =>
      'Le mot de passe sert à chiffrer votre base de données. Si vous l’oubliez, les données ne pourront pas être récupérées.';

  @override
  String get appCreate => 'Créer';

  @override
  String get appStrengthVeryWeak => 'Très faible';

  @override
  String get appStrengthWeak => 'Faible';

  @override
  String get appStrengthFair => 'Moyen';

  @override
  String get appStrengthGood => 'Bon';

  @override
  String get appStrengthStrong => 'Fort';

  @override
  String get appTagline => 'Petit outliner avec suivi du temps';

  @override
  String get appAboutDescription =>
      'Un outliner multiplateforme pour organiser vos idées, vos tâches et vos projets, avec suivi du temps intégré.';

  @override
  String get appBuiltWithFlutter => 'Conçu avec Flutter';

  @override
  String get appCheckForUpdateTitle => 'Rechercher une mise à jour';

  @override
  String appCouldNotOpen(String url) {
    return 'Impossible d’ouvrir $url';
  }

  @override
  String get appOpenReleasePage => 'Ouvrir la page de la version';

  @override
  String get appDownloadApk => 'Télécharger l’APK';

  @override
  String get appDownloadDiskImage => 'Télécharger l’image disque';

  @override
  String get appCheckingForUpdate => 'Recherche d’une nouvelle version...';

  @override
  String get appUpdateCheckFailed => 'Échec de la recherche de mise à jour';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version est la dernière version.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version est disponible (version installée : $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return 'Téléchargement de $appName $version...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received sur $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version est téléchargé et vérifié. L’installation ferme $appName, remplace les fichiers du programme et le redémarre. Vos bases de données ne sont pas modifiées.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version est installé. Redémarrez pour l’utiliser.';
  }

  @override
  String get appLater => 'Plus tard';

  @override
  String get appInstall => 'Installer';

  @override
  String get appInstallAndRestart => 'Installer et redémarrer';

  @override
  String get appRestartNow => 'Redémarrer maintenant';

  @override
  String get appUpdGithubTimeout => 'GitHub n’a pas répondu à temps';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'Impossible de joindre GitHub : $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub a répondu $status pour la dernière version';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Données de version inattendues : $error';
  }

  @override
  String get appUpdUnexpectedData => 'Données de version inattendues';

  @override
  String get appUpdNoInPlace =>
      'Pas de mise à jour sur place sur cette plateforme';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'La version $version ne comporte pas de programme d’installation Windows';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'La version $version ne comporte pas de ZIP Windows';
  }

  @override
  String appUpdCannotWrite(String path) {
    return 'Impossible d’écrire dans $path ; téléchargez la nouvelle version manuellement';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName ne contient pas $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'Le téléchargement n’est pas un ZIP valide : $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'Le ZIP contient un chemin dangereux : $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'Impossible de décompresser le téléchargement : $error';
  }

  @override
  String get appUpdNotAppImage =>
      'L’application ne s’exécute pas depuis une AppImage';

  @override
  String appUpdNoAppImage(String version) {
    return 'La version $version ne comporte pas d’AppImage Linux';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Impossible de rendre la nouvelle AppImage exécutable : $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return 'Impossible de remplacer $path : $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'Échec du téléchargement : le serveur a répondu $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'Impossible d’enregistrer le téléchargement : $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'Téléchargement interrompu : $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'Le fichier téléchargé ne correspond pas à sa somme de contrôle publiée';

  @override
  String appUpdNoChecksums(String version) {
    return 'La version $version ne publie aucune somme de contrôle ; téléchargez-la manuellement';
  }

  @override
  String get appUpdChecksumTimeout =>
      'Délai dépassé pour le téléchargement des sommes de contrôle';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Échec du téléchargement des sommes de contrôle : $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Échec du téléchargement des sommes de contrôle : le serveur a répondu $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName ne figure pas dans $checksumsFile';
  }

  @override
  String get appLogCopied =>
      'Journal de l’application copié dans le presse-papiers';

  @override
  String get appLogTitle => 'Journal de l’application';

  @override
  String get appLogSaveDialogTitle => 'Enregistrer le journal de l’application';

  @override
  String appSavedTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String get appShare => 'Partager';

  @override
  String get appClearLogTooltip => 'Effacer le journal';

  @override
  String get appClearLogButton => 'Effacer le journal';

  @override
  String get appSaveEllipsis => 'Enregistrer...';

  @override
  String get appSearchHint => 'Rechercher';

  @override
  String get appLogLevelAll => 'Tout';

  @override
  String get appLogLevelWarnings => 'Avertissements et erreurs';

  @override
  String get appLogLevelErrors => 'Erreurs';

  @override
  String get appLogEmpty => 'Rien n’a encore été journalisé.';

  @override
  String get appLogNoMatch => 'Aucune ligne ne correspond.';

  @override
  String get appHistoryTitle => 'Historique des modifications';

  @override
  String get appHistoryFilter => 'Filtre : ';

  @override
  String appHistoryAll(int count) {
    return 'Tout ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Tâches ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'Fichiers ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Chronologie ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get appHistoryEmpty => 'Aucune entrée d’historique';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs modifiés',
      one: '$count champ modifié',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return '$shown entrées groupées affichées sur $total ($changes modifications de champs au total)';
  }

  @override
  String get appHistoryOld => 'Ancien :';

  @override
  String get appHistoryNew => 'Nouveau :';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaveAs => 'Enregistrer sous...';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRename => 'Renommer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonOpen => 'Ouvrir';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonApply => 'Appliquer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonBrowse => 'Parcourir...';

  @override
  String get commonError => 'Erreur';

  @override
  String get commonShow => 'Afficher';

  @override
  String get commonHide => 'Masquer';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonTest => 'Tester';

  @override
  String get commonDownload => 'Télécharger';

  @override
  String get commonNone => 'Aucun';

  @override
  String get commonSystemDefault => 'Valeur par défaut du système';

  @override
  String get commonUntitled => 'Sans titre';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get editorImageNotAvailable => 'Image indisponible';

  @override
  String get editorImageResize => 'Redimensionner...';

  @override
  String get editorImageReplace => 'Remplacer l’image...';

  @override
  String get editorImageSaveAs => 'Enregistrer l’image sous...';

  @override
  String get editorImageRemoveFromText => 'Retirer du texte';

  @override
  String get editorImageRemoveFromTextHint =>
      'Conserve le fichier dans les pièces jointes';

  @override
  String get editorImageDelete => 'Supprimer l’image';

  @override
  String get editorImageDeleteHint => 'Supprime aussi la pièce jointe';

  @override
  String get editorImageKeptInOtherTask =>
      'Image retirée du texte. Le fichier appartient à une autre tâche et y a été conservé.';

  @override
  String get editorResizeImageTitle => 'Redimensionner l’image';

  @override
  String get editorResizeWidth => 'Largeur';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$percent % de $natural px';
  }

  @override
  String get editorResizeOriginalSize => 'Taille d’origine';

  @override
  String get editorInsertImage => 'Insérer une image';

  @override
  String get editorReplaceImageDialogTitle => 'Remplacer l’image';

  @override
  String get editorSaveImageDialogTitle => 'Enregistrer l’image';

  @override
  String editorSavedFile(String name) {
    return 'Enregistré : $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Joindre un fichier\n(appui long pour afficher les pièces jointes)';

  @override
  String get editorAttachFileTooltip =>
      'Joindre un fichier\n(appui long pour afficher ou masquer les pièces jointes)';

  @override
  String get editorStopRecording => 'Arrêter l’enregistrement';

  @override
  String get editorRecordVoiceMemo => 'Enregistrer un mémo vocal';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Enregistrer un mémo vocal\n(appui long pour enregistrer sans transcrire)';

  @override
  String editorAttachedOne(String name) {
    return '$name joint';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers joints',
      one: '$count fichier joint',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Police';

  @override
  String get editorFontSize => 'Taille de police';

  @override
  String get editorSizeLabel => 'Taille';

  @override
  String get editorSizeSmall => 'Petite';

  @override
  String get editorSizeLarge => 'Grande';

  @override
  String get editorSizeHuge => 'Très grande';

  @override
  String get editorStartTyping => 'Commencez à écrire...';

  @override
  String get editorLinkedTaskGone => 'La tâche liée n’existe plus.';

  @override
  String get editorRemoveFormatting => 'Supprimer la mise en forme';

  @override
  String editorFormatAsTable(String separator) {
    return 'Mettre en forme comme tableau ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Désactiver le retour à la ligne';

  @override
  String get editorWordWrapOn => 'Activer le retour à la ligne';

  @override
  String editorErrorMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get editorTaskNotFound => 'Tâche introuvable';

  @override
  String get editorSelectTask => 'Sélectionnez une tâche à modifier';

  @override
  String editorSaveFailed(String error) {
    return 'Impossible d’enregistrer la tâche : $error';
  }

  @override
  String get editorChangesMerged =>
      'Cette note a été modifiée ailleurs pendant que vous la modifiiez. Les deux modifications ont été fusionnées.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'Cette note a été modifiée ailleurs pendant que vous la modifiiez. Votre texte a été enregistré ; l’autre version est conservée sous le nom « $copyTitle ».';
  }

  @override
  String get treeNewTask => 'Nouvelle tâche (Ctrl+N)';

  @override
  String get treeNewChildTask => 'Nouvelle sous-tâche (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Supprimer la tâche';

  @override
  String get treeExpandAll => 'Tout développer';

  @override
  String get treeCollapseAll => 'Tout réduire';

  @override
  String get treeNoTasks => 'Aucune tâche pour l’instant';

  @override
  String get treeCreateFirstTask => 'Créer votre première tâche';

  @override
  String get treeTrackedHere => 'Le temps est suivi sur cette tâche';

  @override
  String get treeTrackedInside =>
      'Le temps est suivi sur une tâche à l’intérieur';

  @override
  String get treeHiddenFromAgents =>
      'Masquée aux agents IA, avec tout ce qu’elle contient';

  @override
  String get treeMoveUp => 'Monter';

  @override
  String get treeMoveDown => 'Descendre';

  @override
  String get treeMoveToParentLevel => 'Déplacer au niveau parent';

  @override
  String get treeMoveUnderPrevious => 'Déplacer sous la précédente';

  @override
  String get treeAddChildTask => 'Ajouter une sous-tâche';

  @override
  String get treeStartTracking => 'Démarrer le suivi';

  @override
  String get treeStopTracking => 'Arrêter le suivi';

  @override
  String get treeTimeline => 'Chronologie...';

  @override
  String get searchHint => 'Rechercher des tâches...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '$count résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Aucun résultat';

  @override
  String get searchUntitled => '(sans titre)';

  @override
  String get attachImageNotAvailable => 'Image indisponible';

  @override
  String get attachTryAgain => 'Réessayer';

  @override
  String get attachPlay => 'Lire';

  @override
  String get attachPause => 'Pause';

  @override
  String attachLoadFailed(String error) {
    return 'Impossible de charger les pièces jointes : $error';
  }

  @override
  String get attachNone => 'Aucune pièce jointe';

  @override
  String get attachAddFile => 'Ajouter un fichier';

  @override
  String get attachNotDownloaded =>
      'Cette pièce jointe n’a pas encore été téléchargée — synchronisez pour la récupérer';

  @override
  String get attachContentLoadFailed =>
      'Impossible de charger le contenu de la pièce jointe';

  @override
  String get attachDownloading => 'Téléchargement de la pièce jointe…';

  @override
  String get attachExportDialogTitle => 'Exporter la pièce jointe';

  @override
  String attachExported(String name) {
    return 'Exporté : $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'Aucune application ne peut ouvrir $name';
  }

  @override
  String get attachImageInNoteTitle => 'L’image figure dans la note';

  @override
  String attachImageInNoteBody(String name) {
    return '« $name » est affiché dans la note de cette tâche et ne peut donc pas être supprimé ici.\n\nCliquez sur l’image dans la note et choisissez « Supprimer l’image » pour supprimer à la fois l’image et le fichier, ou « Retirer du texte » pour conserver le fichier et le supprimer ici ensuite.';
  }

  @override
  String get attachDeleteTitle => 'Supprimer la pièce jointe ?';

  @override
  String attachDeleteConfirm(String name) {
    return 'Voulez-vous vraiment supprimer « $name » ?';
  }

  @override
  String get attachRenameTitle => 'Renommer la pièce jointe';

  @override
  String get attachFileName => 'Nom du fichier';

  @override
  String get attachShowPreview => 'Afficher l’aperçu';

  @override
  String get attachHidePreview => 'Masquer l’aperçu';

  @override
  String get attachShare => 'Partager';

  @override
  String get attachExport => 'Exporter';

  @override
  String get attachTranscribe => 'Transcrire';

  @override
  String get attachCannotPlay => 'Impossible de lire ce fichier';

  @override
  String get attachPlaybackUnavailable => 'La lecture est indisponible';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return 'Enregistrement arrêté à la limite de $_temp0. Le mémo a été enregistré.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return 'Limite de $_temp0 atteinte';
  }

  @override
  String get voiceDismiss => 'Fermer';

  @override
  String get voiceOpeningMic => 'Ouverture du microphone…';

  @override
  String get voiceSaving => 'Enregistrement…';

  @override
  String get voiceSavedTranscribing => 'Enregistré. Transcription…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Enregistré. Transcription… $percent %';
  }

  @override
  String get voiceDiscard => 'Abandonner';

  @override
  String get voiceStop => 'Arrêter';

  @override
  String get voiceChooseModelFirst =>
      'Choisissez d’abord un modèle de transcription dans les Préférences';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'Le modèle $model n’a pas encore été téléchargé — voir les Préférences';
  }

  @override
  String get voiceTranscribing => 'Transcription…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Transcription… $percent %';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Impossible de transcrire : $error';
  }

  @override
  String get voiceNoSpeech => 'Aucune parole détectée dans ce mémo';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Transcrit, mais la note correspondante n’est pas ouverte';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'L’enregistrement a été abandonné car une autre base de données a été ouverte.';

  @override
  String get voiceMicPermissionRefused => 'L’accès au microphone a été refusé';

  @override
  String voiceStartFailed(String error) {
    return 'Impossible de démarrer l’enregistrement : $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Impossible de terminer l’enregistrement : $error';
  }

  @override
  String get voiceNoDatabase =>
      'Aucune base de données ouverte : le mémo n’a pas pu être enregistré';

  @override
  String voiceSaveFailed(String error) {
    return 'Impossible d’enregistrer le mémo : $error';
  }

  @override
  String get timeTimelineTitle => 'Chronologie';

  @override
  String get timeStatsToday => 'Aujourd’hui :';

  @override
  String get timeStatsThisMonth => 'Ce mois-ci :';

  @override
  String timeRecordingSince(String time) {
    return 'Enregistrement depuis $time';
  }

  @override
  String get timeEndBeforeStart =>
      'L’heure de fin doit être postérieure à l’heure de début';

  @override
  String get timeOverlaps => 'Chevauche un intervalle existant';

  @override
  String get timeAddIntervalTitle => 'Ajouter un intervalle de temps';

  @override
  String get timeEditIntervalTitle => 'Modifier l’intervalle de temps';

  @override
  String get timeStartTime => 'Début :';

  @override
  String get timeFinishTime => 'Fin :';

  @override
  String get timeDurationLabel => 'Durée :';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '$hours heure',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '$hours heure',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '$minutes minute',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String timeShortHours(int hours) {
    return '$hours h';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get timeAddEllipsis => 'Ajouter...';

  @override
  String get timeNoRecords => 'Aucun enregistrement de temps';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'maintenant';

  @override
  String get timeRemoveIntervalTitle => 'Supprimer l’intervalle ?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Voulez-vous vraiment supprimer cet intervalle de temps ?';

  @override
  String get timeNotTracking => 'Aucun suivi';

  @override
  String get timeStopTracking => 'Arrêter le suivi';

  @override
  String get timeStartTracking => 'Démarrer le suivi';

  @override
  String get timeBackToFullWindow => 'Revenir à la fenêtre complète';

  @override
  String get timeReportTitle => 'Rapport de temps';

  @override
  String get timeReportSaveTitle => 'Enregistrer le rapport de temps';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Impossible de générer le rapport : $error';
  }

  @override
  String get timeReportCopied => 'Rapport copié dans le presse-papiers';

  @override
  String timeReportSavedTo(String path) {
    return 'Enregistré dans $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String get timeReportTasks => 'Tâches';

  @override
  String get timeReportNoTasks => 'Aucune tâche disponible.';

  @override
  String get timeReportClearSelection => 'Effacer la sélection';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnées',
      one: '$count sélectionnée',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Inclure les descendants';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Inclure aussi le temps des sous-tâches de chaque nœud sélectionné.';

  @override
  String get timeReportDateRange => 'Période';

  @override
  String timeReportFrom(String date) {
    return 'Du : $date';
  }

  @override
  String timeReportTo(String date) {
    return 'Au : $date';
  }

  @override
  String get timeReportFormat => 'Format';

  @override
  String get timeReportFormatTree => 'Arborescence (totaux uniquement)';

  @override
  String get timeReportFormatTreeWithDays =>
      'Arborescence avec détail par jour';

  @override
  String get timeReportFormatFlat => 'Liste simple des intervalles';

  @override
  String get timeReportShowEmpty => 'Afficher les tâches vides';

  @override
  String get timeReportUntitled => '(sans titre)';

  @override
  String get timeReportSelectTasks =>
      'Sélectionnez une ou plusieurs tâches pour générer un rapport.';

  @override
  String get timeReportNoRecordsInPeriod =>
      'Aucun enregistrement de temps sur la période sélectionnée.';

  @override
  String get timeReportTextPeriod => 'Période :';

  @override
  String get timeReportTextTotal => 'Total :';

  @override
  String get timeReportTextGenerated => 'Généré le :';

  @override
  String get timeReportTextClipped =>
      'Les enregistrements qui dépassent les limites de la période sont tronqués à celle-ci.';

  @override
  String timeReportTextSelf(String duration) {
    return 'propre : $duration';
  }

  @override
  String get timeReportTextOngoing => 'en cours';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '$count enregistrement',
    );
    return 'Total : $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Régénérer';

  @override
  String get timeReportShare => 'Partager…';

  @override
  String get timeReportSave => 'Enregistrer…';

  @override
  String get timeReportPresetToday => 'Aujourd’hui';

  @override
  String get timeReportPresetThisWeek => 'Cette semaine';

  @override
  String get timeReportPresetThisMonth => 'Ce mois-ci';

  @override
  String get timeReportPresetLastMonth => 'Le mois dernier';

  @override
  String get timeReportPresetThisYear => 'Cette année';

  @override
  String get prefsTitle => 'Préférences';

  @override
  String get prefsTabAppearance => 'Apparence';

  @override
  String get prefsTabBehavior => 'Comportement';

  @override
  String get prefsTabVoiceMemos => 'Mémos vocaux';

  @override
  String get prefsTabSync => 'Synchronisation';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label :';
  }

  @override
  String get prefsGroupLanguage => 'Langue';

  @override
  String get prefsInterfaceLanguage => 'Interface';

  @override
  String get prefsLanguageHint =>
      'Les traductions autres que l’anglais sont automatiques ; les corrections sont les bienvenues.';

  @override
  String get prefsGroupTheme => 'Thème';

  @override
  String get prefsThemeMode => 'Mode';

  @override
  String get prefsThemeSystem => 'Système';

  @override
  String get prefsThemeLight => 'Clair';

  @override
  String get prefsThemeDark => 'Sombre';

  @override
  String get prefsGroupStyle => 'Style';

  @override
  String get prefsGroupColour => 'Couleur';

  @override
  String get prefsLook => 'Aspect';

  @override
  String get prefsLookHint =>
      'Classique : coins carrés, boutons plats à bordure, sans effet d’ondulation, barres de défilement toujours visibles, et une barre de titre dans la couleur d’accentuation avec le menu en dessous.';

  @override
  String get prefsUiStyleModern => 'Moderne';

  @override
  String get prefsUiStyleClassic => 'Classique';

  @override
  String get prefsAccentColour => 'Couleur d’accentuation';

  @override
  String get prefsAccentTeal => 'Sarcelle';

  @override
  String get prefsAccentBlue => 'Bleu';

  @override
  String get prefsAccentIndigo => 'Indigo';

  @override
  String get prefsAccentPurple => 'Violet';

  @override
  String get prefsAccentPink => 'Rose';

  @override
  String get prefsAccentRed => 'Rouge';

  @override
  String get prefsAccentOrange => 'Orange';

  @override
  String get prefsAccentAmber => 'Ambre';

  @override
  String get prefsAccentGreen => 'Vert';

  @override
  String get prefsAccentGraphite => 'Graphite';

  @override
  String get prefsGroupWindow => 'Fenêtre';

  @override
  String get prefsSystemTitleBar => 'Utiliser la barre de titre du système';

  @override
  String get prefsSystemTitleBarHint =>
      'Le cadre, le titre et les boutons de la fenêtre tels que le bureau les dessine, avec la barre de menus en dessous.';

  @override
  String get prefsGroupEditorFont =>
      'Police de l’éditeur (le texte d’une note)';

  @override
  String get prefsGroupTreeFont => 'Police de l’arborescence (le plan)';

  @override
  String get prefsGroupInterfaceFont =>
      'Police de l’interface (menus et boîtes de dialogue)';

  @override
  String get prefsFontFamily => 'Famille';

  @override
  String get prefsFontCustom => 'Personnalisée…';

  @override
  String get prefsCustomName => 'Nom personnalisé';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'p. ex. $font';
  }

  @override
  String get prefsFontSize => 'Taille';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'Style';

  @override
  String get prefsBold => 'Gras';

  @override
  String get prefsItalic => 'Italique';

  @override
  String get prefsPreview => 'Aperçu';

  @override
  String get prefsPreviewText =>
      'Portez ce vieux whisky au juge blond qui fume.';

  @override
  String get prefsScale => 'Échelle';

  @override
  String get prefsFontSansSerif => 'Sans empattement';

  @override
  String get prefsFontSerif => 'Avec empattement';

  @override
  String get prefsFontMonospace => 'Chasse fixe';

  @override
  String get prefsGroupTimeTracking => 'Suivi du temps';

  @override
  String get prefsEnableTimeTracking => 'Activer le suivi du temps';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Démarrage/arrêt du suivi, chronologies et rapports de temps. Le désactiver les masque ; le temps enregistré est conservé';

  @override
  String get prefsShowSeconds => 'Afficher les secondes';

  @override
  String get prefsShowSecondsHint => 'Afficher les secondes dans les durées';

  @override
  String get prefsMiniTracker => 'Afficher une mini-fenêtre pendant le suivi';

  @override
  String get prefsMiniTrackerHint =>
      'Pendant qu’un chrono tourne, réduire la fenêtre la transforme plutôt en petit chrono toujours au premier plan';

  @override
  String get prefsGroupSaving => 'Enregistrement';

  @override
  String get prefsAutoSaveEvery => 'Enregistrement automatique toutes les';

  @override
  String get prefsUnitSec => 's';

  @override
  String get prefsGroupEditor => 'Éditeur';

  @override
  String get prefsTabWidth => 'Largeur de tabulation';

  @override
  String get prefsUnitSpaces => 'espaces';

  @override
  String get prefsTabAsSpaces => 'Insérer les tabulations sous forme d’espaces';

  @override
  String get prefsTabAsSpacesHint =>
      'La touche Tab insère des espaces au lieu d’une tabulation';

  @override
  String get prefsWordWrap => 'Retour à la ligne automatique';

  @override
  String get prefsWordWrapHint =>
      'Désactivé : les longues lignes continuent et la note défile horizontalement (Shift + molette). Aussi dans le menu contextuel de l’éditeur et la barre d’état';

  @override
  String get prefsMonospaceOnly => 'Polices à chasse fixe uniquement';

  @override
  String get prefsMonospaceOnlyHint =>
      'Le menu Police de la barre d’outils ne propose que les familles à chasse fixe, pour que le texte destiné à être aligné le reste';

  @override
  String get prefsFloatingButtons => 'Boutons flottants';

  @override
  String get prefsFloatingButtonsHint =>
      'Joindre un fichier et Enregistrer un mémo vocal par-dessus la note ; la barre d’outils garde ses propres boutons dans tous les cas';

  @override
  String get prefsPaste => 'Coller';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V colle toujours du texte brut';

  @override
  String get prefsPasteKeep => 'Conserver la mise en forme';

  @override
  String get prefsPasteStrip => 'Supprimer les couleurs et les polices';

  @override
  String get prefsPastePlain => 'Texte brut uniquement';

  @override
  String get prefsTableColumns => 'Colonnes de tableau';

  @override
  String get prefsTableColumnsHint =>
      'Le caractère sur lequel Mettre en forme comme tableau (menu contextuel de l’éditeur) sépare les colonnes. Jamais à l’intérieur d’URL ou de texte entre guillemets';

  @override
  String get prefsSeparatorColon => 'Deux-points  ( : )';

  @override
  String get prefsSeparatorEquals => 'Signe égal  ( = )';

  @override
  String get prefsSeparatorPipe => 'Barre verticale  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Point-virgule  ( ; )';

  @override
  String get prefsSeparatorComma => 'Virgule  ( , )';

  @override
  String get prefsSeparatorTab => 'Tabulation';

  @override
  String get prefsGroupToolbarButtons => 'Boutons de la barre d’outils';

  @override
  String get prefsToolbarButtonsHint =>
      'Décochez un bouton pour le retirer de la barre d’outils de l’éditeur.';

  @override
  String get prefsToolbarUndoRedo => 'Annuler / Rétablir';

  @override
  String get prefsToolbarFont => 'Police';

  @override
  String get prefsToolbarSize => 'Taille';

  @override
  String get prefsToolbarBold => 'Gras';

  @override
  String get prefsToolbarItalic => 'Italique';

  @override
  String get prefsToolbarUnderline => 'Souligné';

  @override
  String get prefsToolbarStrikeThrough => 'Barré';

  @override
  String get prefsToolbarInlineCode => 'Code';

  @override
  String get prefsToolbarTextColor => 'Couleur du texte';

  @override
  String get prefsToolbarHighlightColor => 'Couleur de surlignage';

  @override
  String get prefsToolbarClearFormat => 'Effacer la mise en forme';

  @override
  String get prefsToolbarHeadings => 'Titres';

  @override
  String get prefsToolbarNumberedList => 'Liste numérotée';

  @override
  String get prefsToolbarBulletedList => 'Liste à puces';

  @override
  String get prefsToolbarChecklist => 'Liste de cases à cocher';

  @override
  String get prefsToolbarCodeBlock => 'Bloc de code';

  @override
  String get prefsToolbarQuote => 'Citation';

  @override
  String get prefsToolbarIndent => 'Retrait';

  @override
  String get prefsToolbarLink => 'Lien';

  @override
  String get prefsToolbarInsertImage => 'Insérer une image';

  @override
  String get prefsToolbarVoiceMemo => 'Mémo vocal';

  @override
  String get prefsGroupSecurity => 'Sécurité';

  @override
  String get prefsRememberPassword => 'Mémoriser le mot de passe';

  @override
  String get prefsRememberPasswordHint =>
      'Stocker le mot de passe de la base de données dans le trousseau du système';

  @override
  String get prefsBiometricUnlock => 'Déverrouillage biométrique';

  @override
  String get prefsBiometricUnavailableHint =>
      'Indisponible — configurez d’abord une empreinte digitale ou un verrouillage de l’écran dans les paramètres Android';

  @override
  String get prefsBiometricHint =>
      'Confirmer par empreinte digitale, visage ou verrouillage de l’écran avant d’utiliser le mot de passe mémorisé';

  @override
  String get prefsBlockScreenshots => 'Bloquer les captures d’écran';

  @override
  String get prefsBlockScreenshotsHint =>
      'Masquer le contenu de l’application dans les captures d’écran, les enregistrements d’écran et la liste des applications récentes';

  @override
  String get prefsGroupStartup => 'Démarrage';

  @override
  String get prefsSingleInstance => 'Instance unique';

  @override
  String get prefsSingleInstanceHint =>
      'N’autoriser qu’une seule fenêtre ; un nouveau lancement active la fenêtre existante. Prend effet au prochain lancement.';

  @override
  String get prefsVoiceGroupDevices => 'Périphériques';

  @override
  String get prefsVoiceMicrophone => 'Microphone';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Utilisé pour les mémos vocaux et pour le test ci-dessous.';

  @override
  String get prefsVoiceSpeaker => 'Haut-parleur';

  @override
  String get prefsVoiceSpeakerHint =>
      'S’applique aux mémos vocaux. Les autres pièces jointes audio sont lues par la sortie par défaut du système.';

  @override
  String get prefsVoiceDevicesLooking => 'Recherche…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'Impossible de lister les périphériques audio : $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Indisponible';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (par défaut)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (non connecté)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Transcription';

  @override
  String get prefsVoiceModel => 'Modèle';

  @override
  String get prefsVoiceModelHintNone =>
      'Les mémos sont enregistrés et stockés uniquement sous forme audio.';

  @override
  String get prefsVoiceModelHintLocal =>
      'S’exécute sur cet appareil. Rien n’est envoyé nulle part.';

  @override
  String get prefsVoiceModelOff => 'Désactivé';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · recommandé';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count Mo';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Transcrire après l’enregistrement';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'Un mémo est d’abord stocké, puis transcrit à partir de l’audio stocké. Désactivé, il est stocké sans transcription ; « Transcrire » dans le menu de la pièce jointe reste disponible plus tard.';

  @override
  String get prefsVoiceLanguage => 'Langue';

  @override
  String get prefsVoiceLanguageAuto => 'Détection automatique';

  @override
  String get prefsVoiceFooter =>
      'L’enregistrement fonctionne sans modèle : les mémos sont toujours stockés sous forme audio et se lisent comme toute autre pièce jointe. Un modèle ne fait qu’ajouter le texte.';

  @override
  String get prefsVoiceGroupCheck => 'Test';

  @override
  String get prefsVoiceCheckIntro =>
      'Enregistre quelques secondes, les relit et les transcrit avec les périphériques et le modèle ci-dessus. Rien n’est enregistré.';

  @override
  String get prefsVoiceStop => 'Arrêter';

  @override
  String get prefsVoiceTestAgain => 'Tester à nouveau';

  @override
  String get prefsVoiceCheckRecording =>
      'Enregistrement — dites une phrase, puis appuyez sur Arrêter.';

  @override
  String get prefsVoiceCheckPlaying => 'Relecture…';

  @override
  String get prefsVoiceCheckTranscribing => 'Transcription…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Transcription… $percent %';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return '$duration enregistrées.';
  }

  @override
  String get prefsVoiceCheckFailed => 'Le test ne s’est pas terminé.';

  @override
  String get prefsVoiceDownloading => 'Téléchargement…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$percent % de $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model est téléchargé et prêt.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'Non téléchargé — $size depuis HuggingFace.';
  }

  @override
  String get prefsCheckBusy =>
      'Un mémo vocal est en cours d’enregistrement. Terminez-le d’abord.';

  @override
  String get prefsCheckPermissionRefused =>
      'L’accès au microphone a été refusé.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'Le microphone n’a pas pu être ouvert : $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'L’enregistrement n’a pas pu être terminé : $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Rien n’a été enregistré. Prolongez un peu le test ou choisissez un autre microphone.';

  @override
  String get prefsCheckMalformed =>
      'L’enregistrement est revenu mal formé et n’a pas pu être lu.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Échec de la lecture : $error';
  }

  @override
  String get prefsCheckNoModel =>
      'L’enregistrement et la lecture fonctionnent. Aucun modèle n’est sélectionné : il n’y a rien à transcrire.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'L’enregistrement et la lecture fonctionnent. $model n’a pas encore été téléchargé : rien n’a été transcrit.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Échec de la transcription : $error';
  }

  @override
  String get prefsCheckSilence =>
      'Le microphone n’a produit que du silence — l’indicateur de niveau n’a jamais bougé. Vérifiez que le bon périphérique est sélectionné et que l’application est autorisée à l’utiliser.';

  @override
  String get prefsCheckNoSpeech =>
      'L’enregistrement et la lecture fonctionnent, mais whisper n’a détecté aucune parole. Essayez de parler plus près du microphone ou dans une autre langue.';

  @override
  String get prefsCheckQuiet =>
      'L’indicateur de niveau n’a jamais bougé : l’entrée est très faible.';

  @override
  String get prefsDownloadCancelled => 'Téléchargement annulé.';

  @override
  String prefsDownloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get prefsUntitled => '(sans titre)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Enregistré pour cette session uniquement : le trousseau du système l’a refusé. Si votre trousseau est verrouillé, déverrouillez-le et appuyez sur Régénérer.';

  @override
  String get prefsMcpRegenerateTitle => 'Régénérer le jeton ?';

  @override
  String get prefsMcpRegenerateBody =>
      'Les agents configurés avec le jeton actuel cesseront de fonctionner jusqu’à ce que vous colliez le nouveau dans leurs paramètres.';

  @override
  String get prefsMcpRegenerate => 'Régénérer';

  @override
  String get prefsMcpGroupAccess => 'Accès des agents';

  @override
  String get prefsMcpEnable => 'Activer le serveur MCP';

  @override
  String get prefsMcpEnableHint =>
      'Permettre aux agents de programmation IA locaux de lire ce plan via 127.0.0.1. Désactivé par défaut.';

  @override
  String get prefsMcpReadOnly => 'Lecture seule';

  @override
  String get prefsMcpReadOnlyHint =>
      'Les agents peuvent rechercher et lire les tâches, mais pas les créer, les modifier, les déplacer ni les supprimer.';

  @override
  String get prefsMcpGroupEndpoint => 'Point d’accès';

  @override
  String get prefsMcpPort => 'Port';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'Copier l’URL';

  @override
  String get prefsMcpToken => 'Jeton';

  @override
  String get prefsMcpTokenHint =>
      'Toute personne pouvant exécuter des programmes sous votre compte peut utiliser ce jeton. Traitez-le comme un mot de passe.';

  @override
  String get prefsMcpNoTokenYet =>
      'Pas encore de jeton — activez le serveur pour en créer un';

  @override
  String get prefsMcpShowToken => 'Afficher le jeton';

  @override
  String get prefsMcpHideToken => 'Masquer le jeton';

  @override
  String get prefsMcpCopyToken => 'Copier le jeton';

  @override
  String get prefsMcpCopied => 'Copié.';

  @override
  String get prefsMcpGroupExcluded => 'Branches exclues';

  @override
  String get prefsMcpExcludedIntro =>
      'Tâches masquées au serveur MCP, avec tout ce qu’elles contiennent.';

  @override
  String get prefsMcpLoading => 'Chargement…';

  @override
  String get prefsMcpOutlineReadError => 'Impossible de lire le plan.';

  @override
  String get prefsMcpChoose => 'Choisir…';

  @override
  String get prefsMcpNothingExcluded =>
      'Rien n’est exclu : les agents voient tout le plan.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'et $count autres',
      one: 'et $count autre',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'À l’écoute sur $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'Le port $port n’est pas disponible. Choisissez un autre port.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'Aucun jeton d’accès. Appuyez sur Régénérer pour en créer un.';

  @override
  String get prefsMcpWaitingDatabase =>
      'En attente de l’ouverture d’une base de données.';

  @override
  String get prefsMcpNotRunning => 'Arrêté.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Dernière requête à $time';
  }

  @override
  String get prefsMcpNoRequests => 'Aucune requête pour l’instant';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count refusées (jeton erroné ou absent)',
      one: '$count refusée (jeton erroné ou absent)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<activez d’abord le serveur>';

  @override
  String get prefsMcpGroupSetup => 'Configurer votre agent';

  @override
  String get prefsMcpClient => 'Client';

  @override
  String get prefsMcpStdioBridge =>
      'Un agent qui ne parle que stdio peut passer par la passerelle suivante :';

  @override
  String get prefsMcpTargetTerminal => 'Exécutez ceci dans un terminal :';

  @override
  String prefsMcpTargetFile(String file) {
    return 'Ajoutez à $file :';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Limité à votre utilisateur : le plan est disponible dans tous les projets.';

  @override
  String get prefsMcpNoteCodex =>
      'Pour ne pas laisser le jeton dans le fichier, remplacez http_headers par bearer_token_env_var = \"NOO_MCP_TOKEN\" et définissez cette variable dans votre shell.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false est important : sans cela, OpenCode interprète la réponse 401 de ce serveur comme une invitation à lancer un enregistrement OAuth qu’il ne peut pas mener à bien.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'Une tâche cochée est masquée au serveur MCP avec tout ce qu’elle contient : les agents ne peuvent ni la lire, ni la modifier, ni supprimer quoi que ce soit qui la contient.';

  @override
  String get prefsMcpNoDatabase => 'Aucune base de données ouverte.';

  @override
  String get prefsMcpNoTasks => 'Ce plan ne contient encore aucune tâche.';

  @override
  String get prefsMcpCollapse => 'Réduire';

  @override
  String get prefsMcpExpand => 'Développer';

  @override
  String get prefsMcpHiddenWithParent => 'masquée avec le parent';

  @override
  String get syncGroupSynchronization => 'Synchronisation';

  @override
  String get syncEnable => 'Activer la synchronisation';

  @override
  String get syncEnableHint =>
      'Garder cette base de données synchronisée avec un serveur';

  @override
  String get syncGroupIdentity => 'Identité';

  @override
  String get syncNeedsUserName =>
      'Saisissez un nom d’utilisateur pour commencer à synchroniser. Rien n’est synchronisé sans lui, avec ou sans serveur.';

  @override
  String get syncUserName => 'Nom d’utilisateur';

  @override
  String get syncUserNameHint =>
      'Le même sur tous vos appareils. Avec le mot de passe de la base de données, il sert à dériver les clés de chiffrement : les appareils ne se synchronisent que si les deux correspondent.';

  @override
  String get syncDeviceName => 'Nom de l’appareil';

  @override
  String get syncDeviceNameHint =>
      'Le nom sous lequel cet appareil se présente aux appareils à proximité';

  @override
  String get syncGroupServer => 'Serveur de synchronisation (facultatif)';

  @override
  String get syncServerIntro =>
      'Laissez vide pour synchroniser uniquement avec les appareils à proximité sur le même réseau. Un serveur permet en plus aux appareils de se synchroniser lorsqu’ils sont éloignés ; il stocke des données chiffrées qu’il ne peut pas lire.';

  @override
  String get syncServerUrl => 'URL du serveur';

  @override
  String get syncServerPassword => 'Mot de passe';

  @override
  String get syncServerPasswordHint =>
      'Le mot de passe de votre compte sur le serveur. Ce n’est pas le mot de passe de la base de données, et il n’est jamais utilisé comme clé de chiffrement.';

  @override
  String get syncTestConnection => 'Tester la connexion';

  @override
  String get syncRegister => 'Créer un compte';

  @override
  String get syncGroupSchedule => 'Planification';

  @override
  String get syncScheduleNeedsServer =>
      'La synchronisation au démarrage et à la fermeture nécessite un serveur. Les appareils d’un même réseau se synchronisent à votre demande, depuis Outils → Sync P2P...';

  @override
  String get syncAutosyncOnStart => 'Synchroniser au démarrage';

  @override
  String get syncAutosyncOnStartHint =>
      'Synchroniser lorsque l’application ouvre la base de données';

  @override
  String get syncCheckOnStart =>
      'Rechercher les modifications entrantes au démarrage';

  @override
  String get syncCheckOnStartHint =>
      'Demander au serveur si d’autres appareils ont envoyé des modifications, sans synchroniser, et l’indiquer sur l’icône de synchronisation. Inutile si Synchroniser au démarrage est activé';

  @override
  String get syncAskOnExit => 'Proposer de synchroniser à la fermeture';

  @override
  String get syncAskOnExitHint =>
      'Proposer de synchroniser les modifications en attente avant la fermeture de l’application';

  @override
  String get syncGroupServerStorage => 'Stockage sur le serveur';

  @override
  String get syncGroupPeerToPeer => 'Pair à pair';

  @override
  String get syncPeerToPeerIntro =>
      'Les appareils d’un même réseau qui partagent votre nom d’utilisateur et le mot de passe de la base de données peuvent se synchroniser directement, sans serveur. Ouvrez Outils → Sync P2P... sur chacun d’eux : ils se trouvent et se synchronisent tant que cette fenêtre est ouverte, et ne sont pas détectables le reste du temps.';

  @override
  String get syncStorageNoServer =>
      'Rien n’est stocké sur un serveur dans cette configuration. La synchronisation pair à pair conserve chaque paquet sur les appareils eux-mêmes.';

  @override
  String get syncStorageIntro =>
      'Le serveur conserve chaque modification chiffrée jamais effectuée : sa taille augmente avec les modifications, pas avec la taille de votre plan.';

  @override
  String get syncStorageReading => 'Lecture…';

  @override
  String get syncStoragePressRefresh =>
      'Appuyez sur Actualiser pour lire l’utilisation actuelle.';

  @override
  String get syncStorageEmpty => 'Rien n’est encore stocké sur le serveur.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size dans $count paquets',
      one: '$size dans $count paquet',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Compteurs $first–$last';
  }

  @override
  String syncStorageDeviceCountersSnapshots(
    int snapshots,
    int first,
    int last,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      snapshots,
      locale: localeName,
      other: 'Compteurs $first–$last, $snapshots instantanés',
      one: 'Compteurs $first–$last, $snapshots instantané',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Plus $count pièces jointes ($size), stockées une seule fois et partagées par tous les paquets qui y font référence.',
      one:
          'Plus $count pièce jointe ($size), stockée une seule fois et partagée par tous les paquets qui y font référence.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cet appareil en détient $count en local ($size).',
      one: 'Cet appareil en détient $count en local ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Compacter les données sur le serveur';

  @override
  String get syncResetIdentity => 'Réinitialiser l’identité de l’appareil';

  @override
  String get syncNotConfiguredOnDevice =>
      'La synchronisation n’est pas configurée sur cet appareil.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Impossible de lire le stockage du serveur : $error';
  }

  @override
  String get syncResetConfirm =>
      'Cet appareil va se synchroniser sous une nouvelle identité, et sa prochaine synchronisation publiera une copie complète de la base de données actuelle. Vos autres appareils la fusionneront normalement : rien n’est perdu.\n\nFaites-le lorsque la synchronisation signale que l’historique de cet appareil a divergé, ce qui signifie généralement que cette base de données a été restaurée depuis une sauvegarde après avoir déjà été synchronisée.\n\nL’ancienne identité reste visible dans la liste de stockage du serveur jusqu’à ce que vous compactiez.';

  @override
  String get syncReset => 'Réinitialiser';

  @override
  String syncResetFailed(String error) {
    return 'Impossible de réinitialiser l’identité de l’appareil : $error';
  }

  @override
  String get syncCompactConfirm =>
      'Cet appareil va se synchroniser, puis envoyer un instantané de toute la base de données. Le serveur supprime ensuite toutes les modifications stockées que l’instantané contient déjà, et chaque appareil fait de même lorsqu’il récupère l’instantané.\n\nVos notes, temps et pièces jointes ne sont pas affectés : ce qui est supprimé, c’est l’enregistrement des modifications individuelles antérieures à l’instantané.\n\nMettez d’abord Noo à jour sur vos autres appareils : une version plus ancienne ne peut pas lire un flux dont le début a été supprimé.';

  @override
  String get syncCompact => 'Compacter';

  @override
  String get syncCompactFailed => 'Échec du compactage.';

  @override
  String get syncCompactNothing => 'Rien à compacter pour l’instant.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size libérés sur le serveur ($count paquets)',
      one: '$size libérés sur le serveur ($count paquet)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Instantané envoyé, mais ce serveur ne prend pas encore en charge le compactage : il a conservé ses copies';

  @override
  String get syncCompactRelayNothing =>
      'Instantané envoyé ; le serveur n’avait plus rien à supprimer';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cet appareil a libéré $size ($count paquets)',
      one: 'Cet appareil a libéré $size ($count paquet)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. L’instantané lui-même fait $size.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. L’instantané lui-même fait $size.';
  }

  @override
  String get syncTestSuccess => 'Réussite : le serveur est joignable';

  @override
  String get syncTestUnreachable => 'Erreur : le serveur n’est pas joignable';

  @override
  String syncErrorWith(String error) {
    return 'Erreur : $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Erreur : nom d’utilisateur et mot de passe requis';

  @override
  String syncRegisterSuccess(String user) {
    return 'Réussite : compte « $user » créé. Paramètres enregistrés.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Réussite : compte « $user » créé avec un stockage illimité sur le serveur. Paramètres enregistrés.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Réussite : compte « $user » créé avec $size de stockage sur le serveur. Paramètres enregistrés.';
  }

  @override
  String get syncStagePreparing => 'Préparation';

  @override
  String get syncStageAuthenticating => 'Vérification des identifiants';

  @override
  String get syncStagePushing => 'Envoi des modifications';

  @override
  String get syncStageApplying => 'Application des modifications';

  @override
  String get syncStatePending => 'En attente';

  @override
  String get syncStateActive => 'En cours…';

  @override
  String get syncStateDone => 'Terminé';

  @override
  String get syncStateSkipped => 'Ignoré';

  @override
  String get syncStateFailed => 'Échec';

  @override
  String get syncCancelling => 'Annulation…';

  @override
  String get syncSynchronizing => 'Synchronisation…';

  @override
  String get syncCancelled => 'Synchronisation annulée';

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String get syncTitle => 'Synchronisation';

  @override
  String get syncComplete => 'Synchronisation terminée';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncShowFullLogTooltip => 'Afficher le journal complet';

  @override
  String get syncShowFullLog => 'Afficher le journal complet';

  @override
  String get syncMoreSeeFullLog => 'voir Afficher le journal complet';

  @override
  String get syncGroupProgress => 'Progression';

  @override
  String get syncNoRunYet =>
      'Aucune synchronisation n’a encore eu lieu. Utilisez « Synchroniser maintenant » pour synchroniser ; les détails de la dernière synchronisation apparaîtront ici.';

  @override
  String get syncCancelledNote =>
      'Arrêtée à votre demande. Tout ce qui a été synchronisé jusque-là est conservé ; la prochaine synchronisation reprendra à partir de là.';

  @override
  String get syncGroupSummary => 'Résumé';

  @override
  String get syncChangesPushed => 'Modifications envoyées';

  @override
  String get syncChangesApplied => 'Modifications appliquées';

  @override
  String get syncGroupApplied => 'Appliquées — depuis d’autres appareils';

  @override
  String get syncGroupPushed => 'Envoyées — depuis cet appareil';

  @override
  String get syncGroupLwwSkipped =>
      'Non appliquées — cet appareil avait déjà une valeur plus récente';

  @override
  String get syncGroupUnreadable => 'Illisibles';

  @override
  String get syncLwwTieNote =>
      'Les horodatages strictement identiques sont conservés tels quels sur les deux appareils, qui restent donc différents. Modifiez de nouveau l’élément sur l’appareil dont vous voulez garder la version.';

  @override
  String get syncLwwOlderNote =>
      'La valeur entrante était plus ancienne que celle de cet appareil : elle n’a donc pas été écrite. Si elle aurait dû l’emporter, vérifiez que les horloges des deux appareils concordent.';

  @override
  String get syncSkewSame => 'même horodatage';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'local en avance de $seconds s',
      one: 'local en avance de $seconds s',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'local en avance de $minutes min $seconds s';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'local en avance de $hours h $minutes min';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'local en avance de $days jours',
      one: 'local en avance de $days jour',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'entrant $incoming · local $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  échec de $stage  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'Ces paquets n’ont pas pu être déchiffrés : le mot de passe de cette base de données diffère de celui de l’appareil qui les a écrits. La synchronisation ne réessaie pas : faites correspondre les mots de passe, puis réenregistrez les éléments concernés sur l’autre appareil pour qu’ils soient renvoyés.';

  @override
  String get syncSkippedUnreadableNote =>
      'Ces paquets n’ont pas pu être lus et la synchronisation les a dépassés : leurs modifications n’arriveront pas d’elles-mêmes. Réenregistrez les éléments concernés sur l’autre appareil pour les renvoyer.';

  @override
  String get syncP2pNotConfigured =>
      'La synchronisation n’est pas configurée. Définissez d’abord un nom d’utilisateur dans Préférences → Synchronisation.';

  @override
  String syncP2pStartFailed(String error) {
    return 'Impossible de démarrer la synchronisation pair à pair : $error';
  }

  @override
  String get syncP2pStarting => 'Démarrage...';

  @override
  String get syncP2pLooking => 'Recherche d’appareils sur ce réseau...';

  @override
  String get syncP2pIntro =>
      'Ouvrez aussi Sync P2P... sur l’autre appareil. Les appareils se synchronisent dès qu’ils se trouvent ; ils cessent d’être visibles lorsque cette fenêtre est fermée.';

  @override
  String get syncP2pTitle => 'Sync P2P';

  @override
  String get syncP2pSyncAgain => 'Synchroniser à nouveau';

  @override
  String get syncP2pFound => 'Trouvé — en attente de synchronisation';

  @override
  String get syncP2pSyncing => 'Synchronisation...';

  @override
  String get syncP2pUpToDate => 'Synchronisé — déjà à jour';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronisé — $count modifications reçues',
      one: 'Synchronisé — $count modification reçue',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Échec — $error';
  }

  @override
  String get syncP2pUnknownError => 'erreur inconnue';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return 'Reçu de $device ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return 'Envoyé à $device ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$used utilisés sur $quota ($percent %)';
  }

  @override
  String get syncQuotaSemantics => 'Stockage utilisé sur le serveur';

  @override
  String get syncQuotaFull =>
      'Plein : le serveur refuse les nouvelles modifications jusqu’à ce que vous compactiez ou supprimiez des pièces jointes.';

  @override
  String get syncQuotaNearlyFull =>
      'Presque plein. Le compactage en libère généralement la plus grande partie.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'La synchronisation n’est pas configurée. Ouvrez d’abord les réglages de synchronisation.';

  @override
  String get syncNoServerConfigured =>
      'Aucun serveur de synchronisation n’est configuré. Utilisez « Sync P2P... » pour une synchronisation locale, ou ajoutez un serveur dans Préférences → Synchronisation.';

  @override
  String get syncAlreadyInProgress => 'Synchronisation déjà en cours';

  @override
  String get syncAlreadyInProgressSentence =>
      'Une synchronisation est déjà en cours.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done sur $totalText modifications',
      one: '$done sur $totalText modification',
    );
    return '$_temp0';
  }

  @override
  String syncApplyPacketOf(
    int count,
    String countText,
    int current,
    int packets,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText modifications · paquet $current sur $packets',
      one: '$countText modification · paquet $current sur $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText modifications',
      one: '$countText modification',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · environ $seconds s restantes';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · environ $minutes min restantes';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Bifurcation du flux de l’appareil détectée : un nœud distant détient le compteur de paquets $remote pour cet appareil, alors que cet appareil en est à $local, et il ne peut pas confirmer que les deux concordent sur ce qui précède (base de données restaurée depuis une sauvegarde ?). Utilisez « Réinitialiser l’identité de l’appareil » dans Préférences → Synchronisation pour reprendre la synchronisation.';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Le flux de l’appareil a divergé au compteur de paquets $counter : cet appareil et $source détiennent des contenus différents sous la même identité ($localHash ici contre $remoteHash là-bas). Cette base de données a très probablement été restaurée depuis une sauvegarde et a réutilisé des numéros de paquets qu’elle avait déjà publiés. Utilisez « Réinitialiser l’identité de l’appareil » dans Préférences → Synchronisation pour reprendre la synchronisation ; la base de données est republiée sous une nouvelle identité et rien n’est perdu.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'Il manque au serveur une partie de l’historique de cet appareil : il attend le paquet n° $expected, mais le plus ancien paquet que cet appareil détient encore est le n° $local, et ceux qui se trouvent entre les deux ne sont plus là (le serveur a très probablement été restauré depuis une sauvegarde plus ancienne après le compactage de cet appareil). Utilisez « Réinitialiser l’identité de l’appareil » dans Préférences → Synchronisation pour reprendre la synchronisation ; la base de données est republiée sous une nouvelle identité et rien n’est perdu.';
  }

  @override
  String get syncIdentityReset =>
      'Cet appareil se synchronise désormais sous une nouvelle identité. Sa prochaine synchronisation publiera une copie complète de la base de données actuelle, que tous les autres appareils fusionneront normalement.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cet appareil se synchronise désormais sous une nouvelle identité. Sa prochaine synchronisation publiera une copie complète de la base de données actuelle, que tous les autres appareils fusionneront normalement. $count paquets inutilisables ont été supprimés.',
      one:
          'Cet appareil se synchronise désormais sous une nouvelle identité. Sa prochaine synchronisation publiera une copie complète de la base de données actuelle, que tous les autres appareils fusionneront normalement. $count paquet inutilisable a été supprimé.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Dérivation de la clé de chiffrement';

  @override
  String get syncDetailSignedIn => 'Déjà connecté';

  @override
  String get syncDetailPackaging => 'Empaquetage des modifications locales';

  @override
  String get syncDetailRecovering =>
      'Récupération de l’historique propre à cet appareil';

  @override
  String get syncDetailUploading => 'Envoi vers le serveur';

  @override
  String get syncDetailNoLocalChanges => 'Aucune modification locale';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications envoyées',
      one: '$count modification envoyée',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading =>
      'Téléchargement des modifications distantes';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes téléchargées',
      one: '$count pièce jointe téléchargée',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pièces jointes encore à télécharger',
      one: '$count pièce jointe encore à télécharger',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Déjà à jour';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications appliquées',
      one: '$count modification appliquée',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'Annulé';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return 'La pièce jointe « $name » n’a pas encore été téléchargée sur cet appareil, et une modification faite sur cet appareil y fait référence : les modifications de cet appareil ne peuvent donc pas atteindre le serveur avant son arrivée. Synchronisez de nouveau une fois qu’elle est arrivée, ou synchronisez avec un appareil à proximité qui la détient.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'Le serveur a refusé la pièce jointe « $name » ($size), jugée trop volumineuse. Tout le reste se synchronise ; la pièce jointe elle-même n’atteint les autres appareils que via Sync P2P.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'Le serveur a refusé la pièce jointe « $name » ($size), jugée trop volumineuse (sa limite est de $limit). Tout le reste se synchronise ; la pièce jointe elle-même n’atteint les autres appareils que via Sync P2P.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return 'La pièce jointe « $name » ($size) ne tient pas dans votre espace de stockage sur le serveur. Tout le reste se synchronise ; compactez les données sur le serveur ou supprimez des pièces jointes volumineuses pour faire de la place. D’ici là, la pièce jointe n’atteint les autres appareils que via Sync P2P.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return 'La pièce jointe « $name » ($size) ne tient pas dans votre espace de stockage sur le serveur ($used utilisés sur $quota). Tout le reste se synchronise ; compactez les données sur le serveur ou supprimez des pièces jointes volumineuses pour faire de la place. D’ici là, la pièce jointe n’atteint les autres appareils que via Sync P2P.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count octets',
      one: '$count octet',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'Aucun serveur de synchronisation n’est configuré. Le compactage publie un instantané sur le relais ; avec la seule synchronisation entre appareils à proximité, il n’y a pas de stockage de relais à récupérer.';

  @override
  String get syncCompactStageSyncing => 'Synchronisation avant compactage';

  @override
  String get syncCompactStageChecking =>
      'Vérification que cet appareil est à jour';

  @override
  String get syncCompactStagePackaging =>
      'Empaquetage d’un instantané de toute la base de données';

  @override
  String get syncCompactStageAttachments =>
      'Envoi des pièces jointes référencées par l’instantané';

  @override
  String get syncCompactStageUploading => 'Envoi de l’instantané';

  @override
  String get syncCompactStageReclaiming =>
      'Récupération de l’espace sur cet appareil';

  @override
  String get syncCompactStageReadingUsage => 'Lecture du stockage du relais';

  @override
  String syncCompactNeedsSync(String error) {
    return 'Le compactage nécessite d’abord une synchronisation terminée : $error';
  }

  @override
  String get syncCompactDidNotFinish => 'Le compactage ne s’est pas terminé.';

  @override
  String get syncCompactRaced =>
      'Une autre synchronisation a empaqueté en premier. Relancez le compactage.';

  @override
  String get syncCompactSnapshotMissing =>
      'L’instantané a été empaqueté mais ne se trouve pas dans le stockage local.';

  @override
  String get syncCompactMissingAttachments =>
      'Il manque encore des pièces jointes sur cet appareil. Synchronisez jusqu’à ce que toutes les pièces jointes soient téléchargées, puis compactez.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Le relais a refusé l’instantané : $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Échec du compactage : $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cet appareil n’a pas pu lire $count paquets ($packets) : son état n’est donc pas la fusion de tout le journal. Le compactage supprimerait des paquets que cet appareil n’a jamais appliqués.',
      one:
          'Cet appareil n’a pas pu lire $count paquet ($packets) : son état n’est donc pas la fusion de tout le journal. Le compactage supprimerait des paquets que cet appareil n’a jamais appliqués.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'Cet appareil a encore des modifications non synchronisées. Synchronisez d’abord, puis compactez.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Il manque encore des pièces jointes sur cet appareil ($count à télécharger) : son instantané ne pourrait pas les fournir et le serveur les supprimerait. Synchronisez jusqu’à ce que toutes les pièces jointes soient téléchargées, puis compactez.',
      one:
          'Il manque encore des pièces jointes sur cet appareil ($count à télécharger) : son instantané ne pourrait pas les fournir et le serveur les supprimerait. Synchronisez jusqu’à ce que toutes les pièces jointes soient téléchargées, puis compactez.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cet appareil n’a pas appliqué tout ce qu’il détient pour $count appareils. Synchronisez de nouveau, puis compactez.',
      one:
          'Cet appareil n’a pas appliqué tout ce qu’il détient pour $count appareil. Synchronisez de nouveau, puis compactez.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'La synchronisation entre appareils à proximité ne peut pas garantir qu’un autre appareil détient encore une pièce jointe supprimée : aucune n’a donc été libérée.';

  @override
  String get syncCollectUnsynced =>
      'Cet appareil a des modifications que le serveur n’a pas encore stockées. Synchronisez d’abord, puis compactez.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Instantané de $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs — toute la base de données',
      one: '$count champ — toute la base de données',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Nœud « $name »';
  }

  @override
  String syncSummaryFile(String name) {
    return 'Fichier « $name »';
  }

  @override
  String get syncSummaryFileFallback => 'fichier';

  @override
  String get syncSummaryTimeChunk => 'Plage de temps';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'renommé en « $title »';
  }

  @override
  String get syncSummaryContentEdited => 'contenu modifié';

  @override
  String get syncSummaryMoved => 'déplacé';

  @override
  String get syncSummaryReordered => 'réordonné';

  @override
  String get syncSummaryFlagsChanged => 'indicateurs modifiés';

  @override
  String get syncSummaryRenamed => 'renommé';

  @override
  String get syncSummaryContentUpdated => 'contenu mis à jour';

  @override
  String syncSummaryFrom(String time) {
    return 'à partir de $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'jusqu’à $time';
  }

  @override
  String get syncValueTopLevel => 'premier niveau';

  @override
  String get syncStorageFull =>
      'L’espace de stockage sur le serveur est plein. Compactez les données sur le serveur (Préférences → Synchronisation → Stockage sur le serveur) ou supprimez des pièces jointes volumineuses ; ce qui n’a pas été envoyé reste sur cet appareil.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'L’espace de stockage sur le serveur est plein ($used utilisés sur $quota). Compactez les données sur le serveur (Préférences → Synchronisation → Stockage sur le serveur) ou supprimez des pièces jointes volumineuses ; ce qui n’a pas été envoyé reste sur cet appareil.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'Le serveur refuse un flux d’appareil supplémentaire pour ce compte : $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'Le serveur manque d’espace disque. Rien n’a été perdu ; synchronisez plus tard.';

  @override
  String syncStorageRefused(String detail) {
    return 'Le serveur a refusé de stocker davantage : $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'Ce serveur n’accepte pas de nouveaux comptes : il a atteint sa limite de comptes.';

  @override
  String get syncRegClosed =>
      'Ce serveur n’accepte pas les inscriptions. Demandez un compte à son administrateur.';

  @override
  String get syncRegTaken => 'Ce nom d’utilisateur est déjà pris.';

  @override
  String get syncRegInvalid =>
      'Le nom d’utilisateur doit comporter de 3 à 50 caractères, et le mot de passe du serveur de 8 à 128.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Trop de comptes ont été créés depuis ce réseau aujourd’hui.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Trop de comptes ont été créés depuis ce réseau aujourd’hui. Réessayez dans $wait.';
  }

  @override
  String get syncRegTooManyAttempts => 'Trop de tentatives.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Trop de tentatives. Réessayez dans $wait.';
  }

  @override
  String get syncRegBusy => 'Le serveur est occupé. Réessayez dans un instant.';

  @override
  String syncRegFailed(int status) {
    return 'Échec de l’inscription (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Échec de l’inscription (HTTP $status) : $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondes',
      one: '$count seconde',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '$count minute',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '$count heure',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return 'Aucune réponse de $host en $seconds s';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'La réponse de $host est bloquée depuis $seconds s';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '… et $count autres — $where',
      one: '… et $count autre — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'voir le journal de synchronisation';

  @override
  String get traceAtTopLevel => 'au premier niveau';

  @override
  String traceInPath(String path) {
    return 'dans $path';
  }

  @override
  String get traceRowNew => '(nouveau)';

  @override
  String get traceRowRemoved => '(supprimé)';

  @override
  String get traceShowHowTooltip =>
      'Montrer comment cette modification s’est produite';

  @override
  String traceBytes(int count) {
    return '$count o';
  }

  @override
  String traceKilobytes(String size) {
    return '$size Ko';
  }

  @override
  String traceMegabytes(String size) {
    return '$size Mo';
  }

  @override
  String get traceDecisionApplied => 'appliquée';

  @override
  String get traceDecisionCreated => 'créé ici';

  @override
  String get traceDecisionConflictCopy =>
      'appliquée — la valeur remplacée a été conservée comme copie de conflit';

  @override
  String get traceDecisionMerged =>
      'fusionnée avec la modification faite ici — les deux modifications sont conservées';

  @override
  String get traceDecisionCycleToRoot =>
      'déplacé au premier niveau — son parent aurait créé une boucle';

  @override
  String get traceDecisionParentMissing =>
      'placé au premier niveau en attendant l’arrivée de son parent';

  @override
  String get traceDecisionBlobPending =>
      'appliquée — les octets de la pièce jointe suivent séparément';

  @override
  String get traceDecisionSent => 'envoyée';

  @override
  String get traceDecisionForwarded => 'relayée';

  @override
  String get traceRouteRelay => 'Téléchargé depuis le relais.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Téléchargé depuis le relais, qui l’a stocké $time.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Relayé par $peer sur le réseau local — écrit par $author.';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Directement depuis $peer sur le réseau local.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Déjà présent sur cet appareil depuis un échange précédent ; appliqué lors de celui-ci.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Déjà présent sur cet appareil — reçu $time ; appliqué lors de cet échange.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Déjà présent sur cet appareil — reçu $time de $source ; appliqué lors de cet échange.';
  }

  @override
  String get traceRoutePackagedUploaded => 'Empaqueté ici et envoyé au relais.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Empaqueté ici ; le relais l’avait déjà reçu par une autre voie.';

  @override
  String get traceRoutePackagedBlocked =>
      'Empaqueté ici ; pas encore envoyé — une pièce jointe dont il a besoin n’a pas pu être envoyée.';

  @override
  String get traceRoutePackagedWaiting =>
      'Empaqueté ici ; en attente de prise en charge par le relais ou un pair.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Récupéré par $peer sur le réseau local — relayé pour le compte de $author.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Récupéré par $peer sur le réseau local.';
  }

  @override
  String get traceBlobDownloaded => 'téléchargé à l’instant';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'téléchargé à l’instant ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'téléchargé à l’instant depuis $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'téléchargé à l’instant depuis $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'pas encore téléchargé — il suivra lors d’une prochaine synchronisation ou à l’ouverture';

  @override
  String get traceBlobHeld => 'déjà présent sur cet appareil';

  @override
  String get traceBlobUploaded => 'envoyé au relais';

  @override
  String traceBlobUploadedSized(String size) {
    return 'envoyé au relais ($size)';
  }

  @override
  String get traceBlobOnRelay => 'le relais les avait déjà';

  @override
  String get traceBlobOffered => 'sur cet appareil, à disposition des autres';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'Un instantané de compactage : toute la base de données de $device, en un seul paquet.';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Fait partie d’un instantané complet de $device. Un instantané contient toute la base de données de son auteur ; cet élément est listé parce qu’il différait ici.';
  }

  @override
  String get traceFieldsHeading => 'Champs';

  @override
  String traceTimeEdited(String time) {
    return 'modifié $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'le leur $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'cet appareil $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Paquet $device n° $counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Paquet $device n° $counter (instantané)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'écrit $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifications',
      one: '$count modification',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Appareil auteur $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'de l’appareil $id';
  }

  @override
  String get traceCopyHashTooltip => 'Copier le hachage du paquet';

  @override
  String get traceAttachmentBytesHeading => 'Octets de la pièce jointe';

  @override
  String get traceShowInSyncLog =>
      'Afficher dans le journal de synchronisation';

  @override
  String get traceTriggerRelay => 'Synchronisation avec le serveur';

  @override
  String get traceTriggerCheck => 'Recherche de modifications entrantes';

  @override
  String get traceTriggerLan => 'Appareils à proximité';

  @override
  String get traceTriggerLanReturn => 'Appareil à proximité (sur demande)';

  @override
  String get traceTriggerLanServe => 'Servi à un appareil à proximité';

  @override
  String get traceTriggerPackage => 'Modifications locales empaquetées';

  @override
  String get traceTriggerCompaction => 'Compactage';

  @override
  String get traceTriggerIdentityReset =>
      'Réinitialisation de l’identité de l’appareil';

  @override
  String get traceTriggerAttachment => 'Téléchargement de pièce jointe';

  @override
  String get traceTriggerBlobCollect => 'Nettoyage des pièces jointes';

  @override
  String get traceOutcomeRunning => 'en cours';

  @override
  String get traceOutcomeFailed => 'échec';

  @override
  String get traceOutcomeDeclined => 'refusé';

  @override
  String get traceOutcomeBusy => 'occupé';

  @override
  String get traceOutcomeInterrupted => 'interrompu';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements copiés au format JSON',
      one: '$count événement copié au format JSON',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Effacer le journal de synchronisation ?';

  @override
  String get traceClearBody =>
      'Toutes les exécutions et tous les événements enregistrés sur cet appareil sont supprimés. Les données synchronisées ne sont pas affectées.';

  @override
  String get traceTitle => 'Journal de synchronisation';

  @override
  String get traceCopyAsJson => 'Copier en JSON';

  @override
  String get traceClearLogTooltip => 'Effacer le journal';

  @override
  String get traceClearLogButton => 'Effacer le journal';

  @override
  String traceSummaryApplied(int count) {
    return '$count appliquées';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avertissements',
      one: '$count avertissement',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erreurs',
      one: '$count erreur',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Rien n’a été échangé';

  @override
  String get traceNoRuns =>
      'Aucune synchronisation n’a encore été enregistrée. Les exécutions apparaissent ici à mesure que cet appareil se synchronise avec le serveur ou avec des appareils à proximité.';

  @override
  String get traceAllRuns => 'Toutes les exécutions';

  @override
  String traceRunsRecorded(int count) {
    return '$count enregistrées';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'Toutes les exécutions ($count)';
  }

  @override
  String get traceRunLabel => 'Exécution';

  @override
  String get traceSearchHint =>
      'Rechercher : nom de nœud, id, hachage, appareil, type…';

  @override
  String get traceLevelAll => 'Tout';

  @override
  String get traceLevelWarnings => 'Avertissements';

  @override
  String get traceLevelErrors => 'Erreurs';

  @override
  String get traceDirectionAll => 'Entrant et sortant';

  @override
  String get traceDirectionIncoming => 'Entrant';

  @override
  String get traceDirectionOutgoing => 'Sortant';

  @override
  String get traceDirectionLocal => 'Local';

  @override
  String get traceNoEvents => 'Aucun événement ne correspond.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Affichage des $count premiers événements. Affinez la recherche ou choisissez une exécution pour voir le reste.',
      one:
          'Affichage du premier événement. Affinez la recherche ou choisissez une exécution pour voir le reste.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Exécution n° $id';
  }

  @override
  String get traceEmptyValue => '(vide)';

  @override
  String traceSubHash(String hash) {
    return 'hachage $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'valeur $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'distant $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'local $time';
  }

  @override
  String get traceDetailAt => 'Date';

  @override
  String get traceDetailDirection => 'Sens';

  @override
  String get traceDetailOriginDevice => 'Appareil d’origine';

  @override
  String get traceDetailCounter => 'Compteur';

  @override
  String get traceDetailHash => 'Hachage du paquet / blob';

  @override
  String get traceDetailEntity => 'Entité';

  @override
  String get traceDetailWorldId => 'World id';

  @override
  String get traceDetailName => 'Nom';

  @override
  String get traceDetailField => 'Champ';

  @override
  String get traceDetailRemoteTs => 'Horodatage distant';

  @override
  String get traceDetailLocalTs => 'Horodatage local';

  @override
  String get traceDetailValueHash => 'Hachage de la valeur';

  @override
  String get traceDetailValuePreview => 'Aperçu de la valeur';

  @override
  String get traceDetailMessage => 'Message';

  @override
  String get traceDetailDetail => 'Détail';
}
