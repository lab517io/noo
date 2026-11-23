// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appMenuFile => 'Datei';

  @override
  String get appMenuEdit => 'Bearbeiten';

  @override
  String get appMenuView => 'Ansicht';

  @override
  String get appMenuTools => 'Extras';

  @override
  String get appMenuDebug => 'Debug';

  @override
  String get appMenuHelp => 'Hilfe';

  @override
  String get appMenuWindow => 'Fenster';

  @override
  String get appMenuOpen => 'Öffnen...';

  @override
  String get appMenuOpenDatabase => 'Datenbank öffnen...';

  @override
  String get appMenuNewDatabase => 'Neue Datenbank...';

  @override
  String get appMenuExportObsidian => 'Nach Obsidian exportieren...';

  @override
  String get appMenuImportObsidian => 'Aus Obsidian importieren...';

  @override
  String get appMenuExit => 'Beenden';

  @override
  String get appMenuFind => 'Suchen...';

  @override
  String get appMenuTheme => 'Design';

  @override
  String get appMenuThemeEllipsis => 'Design...';

  @override
  String get appThemeSystem => 'System';

  @override
  String get appThemeLight => 'Hell';

  @override
  String get appThemeDark => 'Dunkel';

  @override
  String get appMenuTimeline => 'Zeitverlauf...';

  @override
  String get appMenuTimeReport => 'Zeitbericht...';

  @override
  String get appMenuCompactDatabase => 'Datenbank komprimieren...';

  @override
  String get appMenuSyncNow => 'Jetzt synchronisieren';

  @override
  String get appMenuSyncP2p => 'Sync P2P...';

  @override
  String get appMenuPreferences => 'Einstellungen...';

  @override
  String get appMenuViewChangeHistory => 'Änderungsverlauf anzeigen...';

  @override
  String get appMenuGenerateTestData => 'Testdaten erzeugen';

  @override
  String get appMenuGenerateLargeDataset => 'Großen Datensatz erzeugen';

  @override
  String get appMenuClearAllData => 'Alle Daten löschen';

  @override
  String get appMenuCheckForUpdate => 'Nach Updates suchen...';

  @override
  String get appMenuLogs => 'Protokolle';

  @override
  String get appMenuSyncLog => 'Sync-Protokoll...';

  @override
  String get appMenuAppLog => 'App-Protokoll...';

  @override
  String appMenuAbout(String appName) {
    return 'Über $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Nach Updates suchen…';

  @override
  String get appMacMenuSettings => 'Einstellungen…';

  @override
  String appMacMenuQuit(String appName) {
    return '$appName beenden';
  }

  @override
  String get appMacMenuOpen => 'Öffnen…';

  @override
  String get appMacMenuNewDatabase => 'Neue Datenbank…';

  @override
  String get appMacMenuExportObsidian => 'Nach Obsidian exportieren…';

  @override
  String get appMacMenuImportObsidian => 'Aus Obsidian importieren…';

  @override
  String get appMacMenuUndo => 'Widerrufen';

  @override
  String get appMacMenuRedo => 'Wiederholen';

  @override
  String get appMacMenuCut => 'Ausschneiden';

  @override
  String get appMacMenuPaste => 'Einsetzen';

  @override
  String get appMacMenuSelectAll => 'Alles auswählen';

  @override
  String get appMacMenuFind => 'Suchen…';

  @override
  String get appMacMenuTimeline => 'Zeitverlauf…';

  @override
  String get appMacMenuTimeReport => 'Zeitbericht…';

  @override
  String get appMacMenuCompactDatabase => 'Datenbank komprimieren…';

  @override
  String get appMacMenuSyncP2p => 'Sync P2P…';

  @override
  String get appMacMenuViewChangeHistory => 'Änderungsverlauf anzeigen…';

  @override
  String get appMacMenuSyncLog => 'Sync-Protokoll…';

  @override
  String get appMacMenuAppLog => 'App-Protokoll…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Datenbank öffnen';

  @override
  String get appCreateDatabaseDialogTitle => 'Neue Datenbank erstellen';

  @override
  String get appIncorrectPasswordRetry =>
      'Falsches Passwort. Bitte versuchen Sie es erneut.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Geöffnet: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Datenbank konnte nicht geöffnet werden: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Erstellt: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Datenbank konnte nicht erstellt werden: $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Öffnen Sie zuerst eine Datenbank';

  @override
  String get appNoDatabaseOpen => 'Keine Datenbank geöffnet';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Datenbankdatei kann nicht gelesen werden: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt =>
      'Falsches Passwort oder beschädigte Datenbank';

  @override
  String get appExportObsidianDialogTitle =>
      'In Obsidian-Verzeichnis exportieren';

  @override
  String get appImportObsidianDialogTitle =>
      'Aus Obsidian-Verzeichnis importieren';

  @override
  String get appImportObsidianZipDialogTitle => 'Obsidian-.zip importieren';

  @override
  String get appExportingObsidian => 'Export ins Obsidian-Format...';

  @override
  String get appImportingObsidian => 'Import aus dem Obsidian-Format...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufgaben',
      one: '$count Aufgabe',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeitverlaufsdateien',
      one: '$count Zeitverlaufsdatei',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder',
      one: '$count Bild',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeiteinträge',
      one: '$count Zeiteintrag',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Exportiert: $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'Importiert: $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String appImportFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obsidian-Export ($count Aufgaben)',
      one: 'Obsidian-Export ($count Aufgabe)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'Verzeichnis existiert nicht: $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Synchronisierung nicht eingerichtet. Öffnen Sie zuerst die Sync-Einstellungen.';

  @override
  String get appNoSyncServer =>
      'Kein Sync-Server eingerichtet. Verwenden Sie Sync P2P... (Shift+F5) oder fügen Sie in den Einstellungen einen Server hinzu.';

  @override
  String get appUnsyncedChangesTitle => 'Nicht synchronisierte Änderungen';

  @override
  String get appUnsyncedChangesBody =>
      'Es gibt nicht synchronisierte Änderungen. Möchten Sie sie synchronisieren?';

  @override
  String get appDontSync => 'Nicht synchronisieren';

  @override
  String get appSync => 'Synchronisieren';

  @override
  String get appSelectTaskFirst => 'Wählen Sie zuerst eine Aufgabe aus';

  @override
  String get appGenerateTestDataBody =>
      'Es werden Beispielaufgaben mit Hierarchie und Zeiteinträgen erstellt.\n\nFortfahren?';

  @override
  String get appGenerate => 'Erzeugen';

  @override
  String get appTestDataGenerated => 'Testdaten erfolgreich erzeugt';

  @override
  String get appGenerateLargeDatasetBody =>
      'Es wird ein großer Datensatz erstellt mit:\n- 20 Aufgaben auf oberster Ebene\n- bis zu 5 Ebenen Tiefe\n- bis zu 6 Unteraufgaben pro Aufgabe\n- Zeiteinträgen für viele Aufgaben\n\nDas kann einen Moment dauern. Fortfahren?';

  @override
  String get appGeneratingData => 'Daten werden erzeugt...';

  @override
  String get appLargeDatasetGenerated => 'Großer Datensatz erfolgreich erzeugt';

  @override
  String get appClearAllDataBody =>
      'Alle Aufgaben, Zeiteinträge und Anhänge werden endgültig gelöscht.\n\nDies kann nicht rückgängig gemacht werden. Sind Sie sicher?';

  @override
  String get appDeleteAll => 'Alle löschen';

  @override
  String get appAllDataCleared => 'Alle Daten gelöscht';

  @override
  String get appCompactDatabaseTitle => 'Datenbank komprimieren';

  @override
  String get appCompactDatabaseBody =>
      'Schreibt die Datenbankdatei neu, sodass der Platz, den gelöschte Aufgaben, Anhänge und alter Änderungsverlauf belegen, an den Datenträger zurückgegeben wird.\n\nAuch die Inhalte gelöschter Anhänge werden freigegeben; stellen Sie einen davon wieder her, wird er erneut vom Server heruntergeladen.\n\nNichts, was Sie noch sehen, wird entfernt. Bei einer großen Datenbank dauert das eine Weile, und die App ist bis zum Abschluss nicht bedienbar.';

  @override
  String get appCompact => 'Komprimieren';

  @override
  String get appCompactingDatabase => 'Datenbank wird komprimiert...';

  @override
  String appCompactingFailed(String error) {
    return 'Komprimieren fehlgeschlagen: $error';
  }

  @override
  String get appDatabaseCompacted => 'Datenbank komprimiert';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'Datenbank komprimiert — $freed freigegeben (jetzt $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'Datenbank komprimiert — bereits kompakt ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Suchen';

  @override
  String get appSyncNowTooltip => 'Jetzt synchronisieren';

  @override
  String get appBiometricFailed =>
      'Biometrische Prüfung fehlgeschlagen. Bitte geben Sie das Passwort ein.';

  @override
  String get appSavedPasswordIncorrect =>
      'Das gespeicherte Passwort ist falsch. Bitte geben Sie das Passwort ein.';

  @override
  String get appLoading => 'Wird geladen...';

  @override
  String get appFailedToOpenDatabaseTitle =>
      'Datenbank konnte nicht geöffnet werden';

  @override
  String get appOpenAnotherDatabase => 'Andere Datenbank öffnen…';

  @override
  String get appBiometricReason => 'Noo-Datenbank entsperren';

  @override
  String appWelcomeTitle(String appName) {
    return 'Willkommen bei $appName';
  }

  @override
  String get appWelcomeIntro =>
      'Wählen Sie, wo Ihre verschlüsselte Datenbank gespeichert werden soll. Sie können das später im Menü „Datei“ ändern.';

  @override
  String get appUseDefaultLocation => 'Standardort verwenden';

  @override
  String get appResolving => 'Wird ermittelt…';

  @override
  String get appCreateNewDatabaseOption => 'Neue Datenbank erstellen…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Einen eigenen Speicherort für eine neue verschlüsselte Datenbank wählen.';

  @override
  String get appOpenExistingDatabaseOption => 'Vorhandene Datenbank öffnen…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Eine vorhandene .noo-Datei von einem anderen Ort verwenden.';

  @override
  String get appQuit => 'Beenden';

  @override
  String get appWelcomeSyncHint =>
      'Sie haben bereits eine Datenbank auf einem anderen Gerät? Erstellen Sie hier eine neue mit demselben Passwort und richten Sie dann unter Einstellungen → Synchronisierung die Synchronisierung mit demselben Benutzernamen ein — Ihre Notizen kommen mit der ersten Synchronisierung an.';

  @override
  String get appTaskFallbackTitle => 'Aufgabe';

  @override
  String get appTabNotes => 'Notizen';

  @override
  String get appTabTime => 'Zeit';

  @override
  String get appTabFiles => 'Dateien';

  @override
  String appTabFilesCount(int count) {
    return 'Dateien ($count)';
  }

  @override
  String get appStartTracking => 'Zeiterfassung starten';

  @override
  String get appStopTracking => 'Zeiterfassung beenden';

  @override
  String get appNoTaskSelected => 'Keine Aufgabe ausgewählt.';

  @override
  String get appAttachmentsHeading => 'Anhänge';

  @override
  String get appModified => 'Geändert';

  @override
  String get appWordWrapOnTooltip =>
      'Zeilenumbruch ist an — klicken zum Ausschalten';

  @override
  String get appWordWrapOffTooltip =>
      'Zeilenumbruch ist aus — klicken zum Einschalten';

  @override
  String get appTimeTodayTap => 'Heute erfasste Zeit — tippen zum Öffnen';

  @override
  String get appHideTimeTracking => 'Zeiterfassung ausblenden';

  @override
  String get appTimeTodayClick => 'Heute erfasste Zeit — klicken für Details';

  @override
  String get appViewTimeline => 'Zeitverlauf anzeigen';

  @override
  String get appAttachmentsTap => 'Anhänge — tippen zum Öffnen';

  @override
  String get appHideAttachments => 'Anhänge ausblenden';

  @override
  String get appAttachmentsClick => 'Anhänge — klicken zum Anzeigen';

  @override
  String get appAddAttachment => 'Anhang hinzufügen';

  @override
  String get appUntitledInPath => '(ohne Titel)';

  @override
  String get appSyncStatusDisabled =>
      'Synchronisierung deaktiviert — klicken zum Synchronisieren';

  @override
  String get appSyncStatusUnknown =>
      'Noch nicht synchronisiert — klicken zum Synchronisieren';

  @override
  String get appSyncStatusIdle =>
      'Synchronisiert — klicken zum Synchronisieren';

  @override
  String get appSyncStatusSyncing => 'Wird synchronisiert...';

  @override
  String get appSyncStatusError =>
      'Synchronisierungsfehler — klicken zum Wiederholen';

  @override
  String get appSyncStatusPending =>
      'Ausstehende Änderungen — klicken zum Synchronisieren';

  @override
  String get appSyncStatusIncoming =>
      'Andere Geräte haben Änderungen gesendet — klicken zum Synchronisieren';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Zeiterfassung für „$title“ läuft — klicken, um dorthin zu wechseln';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Zeiterfassung für „$title“ beenden';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String appPendingMore(int count) {
    return '+$count weitere';
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
      other: '$count Elemente',
      one: '1 Element',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen',
      one: '1 Änderung',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'Warten auf Synchronisierung: $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'Titel';

  @override
  String get appPendingFieldContent => 'Inhalt';

  @override
  String get appPendingFieldMoved => 'verschoben';

  @override
  String get appPendingFieldReordered => 'umsortiert';

  @override
  String get appPendingFieldFlags => 'Flags';

  @override
  String get appPendingFieldDeleted => 'gelöscht';

  @override
  String get appPendingFieldName => 'Name';

  @override
  String get appPendingFieldStartTime => 'Startzeit';

  @override
  String get appPendingFieldEndTime => 'Endzeit';

  @override
  String get appJustNow => 'gerade eben';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count min',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count h',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor $count Tag',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Passwort eingeben';

  @override
  String get appSetDatabasePasswordTitle => 'Datenbankpasswort festlegen';

  @override
  String get appPasswordLabel => 'Passwort';

  @override
  String get appConfirmPasswordLabel => 'Passwort bestätigen';

  @override
  String get appPleaseEnterPassword => 'Bitte geben Sie ein Passwort ein';

  @override
  String get appPasswordTooShort =>
      'Das Passwort muss mindestens 4 Zeichen lang sein';

  @override
  String get appPasswordsDoNotMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get appPasswordWarning =>
      'Mit dem Passwort wird Ihre Datenbank verschlüsselt. Wenn Sie es vergessen, lassen sich die Daten nicht wiederherstellen.';

  @override
  String get appCreate => 'Erstellen';

  @override
  String get appStrengthVeryWeak => 'Sehr schwach';

  @override
  String get appStrengthWeak => 'Schwach';

  @override
  String get appStrengthFair => 'Mittel';

  @override
  String get appStrengthGood => 'Gut';

  @override
  String get appStrengthStrong => 'Stark';

  @override
  String get appTagline => 'Kleiner Outliner mit Zeiterfassung';

  @override
  String get appAboutDescription =>
      'Eine plattformübergreifende Outliner-Anwendung, mit der Sie Gedanken, Aufgaben und Projekte ordnen — mit integrierter Zeiterfassung.';

  @override
  String get appBuiltWithFlutter => 'Erstellt mit Flutter';

  @override
  String get appCheckForUpdateTitle => 'Nach Updates suchen';

  @override
  String appCouldNotOpen(String url) {
    return '$url konnte nicht geöffnet werden';
  }

  @override
  String get appOpenReleasePage => 'Release-Seite öffnen';

  @override
  String get appDownloadApk => 'APK herunterladen';

  @override
  String get appDownloadDiskImage => 'Disk-Image herunterladen';

  @override
  String get appCheckingForUpdate => 'Suche nach einer neuen Version...';

  @override
  String get appUpdateCheckFailed => 'Update-Prüfung fehlgeschlagen';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version ist die neueste Version.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version ist verfügbar (installiert: $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return '$appName $version wird heruntergeladen...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received von $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version ist heruntergeladen und geprüft. Bei der Installation wird $appName geschlossen, die Programmdateien werden ersetzt und die App wird neu gestartet. Ihre Datenbanken bleiben unberührt.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version ist installiert. Starten Sie neu, um die neue Version zu verwenden.';
  }

  @override
  String get appLater => 'Später';

  @override
  String get appInstall => 'Installieren';

  @override
  String get appInstallAndRestart => 'Installieren und neu starten';

  @override
  String get appRestartNow => 'Jetzt neu starten';

  @override
  String get appUpdGithubTimeout => 'GitHub hat nicht rechtzeitig geantwortet';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'GitHub ist nicht erreichbar: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub hat für das neueste Release mit $status geantwortet';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Unerwartete Release-Daten: $error';
  }

  @override
  String get appUpdUnexpectedData => 'Unerwartete Release-Daten';

  @override
  String get appUpdNoInPlace =>
      'Auf dieser Plattform ist keine direkte Aktualisierung möglich';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'Release $version enthält kein Windows-Installationsprogramm';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'Release $version enthält kein Windows-ZIP';
  }

  @override
  String appUpdCannotWrite(String path) {
    return '$path ist nicht beschreibbar; laden Sie die neue Version manuell herunter';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName enthält $path nicht';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'Der Download ist kein gültiges ZIP: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'Das ZIP enthält einen unsicheren Pfad: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'Der Download kann nicht entpackt werden: $error';
  }

  @override
  String get appUpdNotAppImage => 'Die App läuft nicht aus einem AppImage';

  @override
  String appUpdNoAppImage(String version) {
    return 'Release $version enthält kein Linux-AppImage';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Das neue AppImage kann nicht ausführbar gemacht werden: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return '$path kann nicht ersetzt werden: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'Download fehlgeschlagen: Server antwortete mit $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'Der Download kann nicht gespeichert werden: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'Download unterbrochen: $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'Die heruntergeladene Datei stimmt nicht mit ihrer veröffentlichten Prüfsumme überein';

  @override
  String appUpdNoChecksums(String version) {
    return 'Release $version veröffentlicht keine Prüfsummen; laden Sie es manuell herunter';
  }

  @override
  String get appUpdChecksumTimeout =>
      'Zeitüberschreitung beim Herunterladen der Prüfsummen';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Download der Prüfsummen fehlgeschlagen: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Download der Prüfsummen fehlgeschlagen: Server antwortete mit $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName ist in $checksumsFile nicht aufgeführt';
  }

  @override
  String get appLogCopied => 'App-Protokoll in die Zwischenablage kopiert';

  @override
  String get appLogTitle => 'App-Protokoll';

  @override
  String get appLogSaveDialogTitle => 'App-Protokoll speichern';

  @override
  String appSavedTo(String path) {
    return 'Gespeichert unter $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get appShare => 'Teilen';

  @override
  String get appClearLogTooltip => 'Protokoll leeren';

  @override
  String get appClearLogButton => 'Protokoll leeren';

  @override
  String get appSaveEllipsis => 'Speichern...';

  @override
  String get appSearchHint => 'Suchen';

  @override
  String get appLogLevelAll => 'Alle';

  @override
  String get appLogLevelWarnings => 'Warnungen und Fehler';

  @override
  String get appLogLevelErrors => 'Fehler';

  @override
  String get appLogEmpty => 'Es wurde noch nichts protokolliert.';

  @override
  String get appLogNoMatch => 'Keine passenden Zeilen.';

  @override
  String get appHistoryTitle => 'Änderungsverlauf';

  @override
  String get appHistoryFilter => 'Filter: ';

  @override
  String appHistoryAll(int count) {
    return 'Alle ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Aufgaben ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'Dateien ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Zeitverlauf ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get appHistoryEmpty => 'Keine Verlaufseinträge gefunden';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Felder geändert',
      one: '1 Feld geändert',
      zero: '0 Felder geändert',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return '$shown von $total gruppierten Einträgen ($changes Feldänderungen insgesamt)';
  }

  @override
  String get appHistoryOld => 'Alt:';

  @override
  String get appHistoryNew => 'Neu:';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSaveAs => 'Speichern unter...';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRename => 'Umbenennen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonApply => 'Übernehmen';

  @override
  String get commonRetry => 'Wiederholen';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nein';

  @override
  String get commonBrowse => 'Durchsuchen...';

  @override
  String get commonError => 'Fehler';

  @override
  String get commonShow => 'Anzeigen';

  @override
  String get commonHide => 'Ausblenden';

  @override
  String get commonClear => 'Leeren';

  @override
  String get commonRefresh => 'Aktualisieren';

  @override
  String get commonTest => 'Testen';

  @override
  String get commonDownload => 'Herunterladen';

  @override
  String get commonNone => 'Keine';

  @override
  String get commonSystemDefault => 'Systemstandard';

  @override
  String get commonUntitled => 'Ohne Titel';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get editorImageNotAvailable => 'Bild nicht verfügbar';

  @override
  String get editorImageResize => 'Größe ändern...';

  @override
  String get editorImageReplace => 'Bild ersetzen...';

  @override
  String get editorImageSaveAs => 'Bild speichern unter...';

  @override
  String get editorImageRemoveFromText => 'Aus dem Text entfernen';

  @override
  String get editorImageRemoveFromTextHint =>
      'Die Datei bleibt in den Anhängen';

  @override
  String get editorImageDelete => 'Bild löschen';

  @override
  String get editorImageDeleteHint => 'Löscht auch den Anhang';

  @override
  String get editorImageKeptInOtherTask =>
      'Bild aus dem Text entfernt. Die Datei gehört zu einer anderen Aufgabe und wurde dort behalten.';

  @override
  String get editorResizeImageTitle => 'Bildgröße ändern';

  @override
  String get editorResizeWidth => 'Breite';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$percent % von $natural px';
  }

  @override
  String get editorResizeOriginalSize => 'Originalgröße';

  @override
  String get editorInsertImage => 'Bild einfügen';

  @override
  String get editorReplaceImageDialogTitle => 'Bild ersetzen';

  @override
  String get editorSaveImageDialogTitle => 'Bild speichern';

  @override
  String editorSavedFile(String name) {
    return 'Gespeichert: $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Datei anhängen\n(lange drücken, um Anhänge anzuzeigen)';

  @override
  String get editorAttachFileTooltip =>
      'Datei anhängen\n(lange drücken, um Anhänge ein- oder auszublenden)';

  @override
  String get editorStopRecording => 'Aufnahme beenden';

  @override
  String get editorRecordVoiceMemo => 'Sprachmemo aufnehmen';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Sprachmemo aufnehmen\n(lange drücken, um ohne Transkription aufzunehmen)';

  @override
  String editorAttachedOne(String name) {
    return '$name angehängt';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien angehängt',
      one: '1 Datei angehängt',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Schriftart';

  @override
  String get editorFontSize => 'Schriftgröße';

  @override
  String get editorSizeLabel => 'Größe';

  @override
  String get editorSizeSmall => 'Klein';

  @override
  String get editorSizeLarge => 'Groß';

  @override
  String get editorSizeHuge => 'Riesig';

  @override
  String get editorStartTyping => 'Hier schreiben...';

  @override
  String get editorLinkedTaskGone =>
      'Die verlinkte Aufgabe existiert nicht mehr.';

  @override
  String get editorRemoveFormatting => 'Formatierung entfernen';

  @override
  String editorFormatAsTable(String separator) {
    return 'Als Tabelle formatieren ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Zeilenumbruch ausschalten';

  @override
  String get editorWordWrapOn => 'Zeilenumbruch einschalten';

  @override
  String editorErrorMessage(String error) {
    return 'Fehler: $error';
  }

  @override
  String get editorTaskNotFound => 'Aufgabe nicht gefunden';

  @override
  String get editorSelectTask => 'Wählen Sie eine Aufgabe zum Bearbeiten aus';

  @override
  String editorSaveFailed(String error) {
    return 'Aufgabe konnte nicht gespeichert werden: $error';
  }

  @override
  String get editorChangesMerged =>
      'Diese Notiz wurde an anderer Stelle geändert, während Sie sie bearbeitet haben. Beide Änderungen wurden zusammengeführt.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'Diese Notiz wurde an anderer Stelle geändert, während Sie sie bearbeitet haben. Ihr Text wurde gespeichert; die andere Fassung bleibt als „$copyTitle“ erhalten.';
  }

  @override
  String get treeNewTask => 'Neue Aufgabe (Ctrl+N)';

  @override
  String get treeNewChildTask => 'Neue Unteraufgabe (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Aufgabe löschen';

  @override
  String get treeExpandAll => 'Alle ausklappen';

  @override
  String get treeCollapseAll => 'Alle einklappen';

  @override
  String get treeNoTasks => 'Noch keine Aufgaben';

  @override
  String get treeCreateFirstTask => 'Erste Aufgabe erstellen';

  @override
  String get treeTrackedHere => 'Für diese Aufgabe wird Zeit erfasst';

  @override
  String get treeTrackedInside =>
      'Für eine untergeordnete Aufgabe wird Zeit erfasst';

  @override
  String get treeHiddenFromAgents =>
      'Vor KI-Agenten verborgen, einschließlich allem darunter';

  @override
  String get treeMoveUp => 'Nach oben';

  @override
  String get treeMoveDown => 'Nach unten';

  @override
  String get treeMoveToParentLevel => 'Eine Ebene höher';

  @override
  String get treeMoveUnderPrevious => 'Unter die vorherige verschieben';

  @override
  String get treeAddChildTask => 'Unteraufgabe hinzufügen';

  @override
  String get treeStartTracking => 'Zeiterfassung starten';

  @override
  String get treeStopTracking => 'Zeiterfassung beenden';

  @override
  String get treeTimeline => 'Zeitverlauf...';

  @override
  String get searchHint => 'Aufgaben durchsuchen...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Treffer',
      one: '1 Treffer',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Keine Treffer';

  @override
  String get searchUntitled => '(ohne Titel)';

  @override
  String get attachImageNotAvailable => 'Bild nicht verfügbar';

  @override
  String get attachTryAgain => 'Erneut versuchen';

  @override
  String get attachPlay => 'Abspielen';

  @override
  String get attachPause => 'Pause';

  @override
  String attachLoadFailed(String error) {
    return 'Anhänge konnten nicht geladen werden: $error';
  }

  @override
  String get attachNone => 'Keine Anhänge';

  @override
  String get attachAddFile => 'Datei hinzufügen';

  @override
  String get attachNotDownloaded =>
      'Dieser Anhang wurde noch nicht heruntergeladen — synchronisieren Sie, um ihn abzurufen';

  @override
  String get attachContentLoadFailed =>
      'Inhalt des Anhangs konnte nicht geladen werden';

  @override
  String get attachDownloading => 'Anhang wird heruntergeladen…';

  @override
  String get attachExportDialogTitle => 'Anhang exportieren';

  @override
  String attachExported(String name) {
    return 'Exportiert: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'Keine App kann $name öffnen';
  }

  @override
  String get attachImageInNoteTitle => 'Bild ist in der Notiz';

  @override
  String attachImageInNoteBody(String name) {
    return '„$name“ wird in der Notiz dieser Aufgabe angezeigt und kann daher hier nicht gelöscht werden.\n\nKlicken Sie in der Notiz auf das Bild und wählen Sie „Bild löschen“, um Bild und Datei zu entfernen, oder „Aus dem Text entfernen“, um die Datei zu behalten und sie anschließend hier zu löschen.';
  }

  @override
  String get attachDeleteTitle => 'Anhang löschen?';

  @override
  String attachDeleteConfirm(String name) {
    return 'Möchten Sie „$name“ wirklich löschen?';
  }

  @override
  String get attachRenameTitle => 'Anhang umbenennen';

  @override
  String get attachFileName => 'Dateiname';

  @override
  String get attachShowPreview => 'Vorschau anzeigen';

  @override
  String get attachHidePreview => 'Vorschau ausblenden';

  @override
  String get attachShare => 'Teilen';

  @override
  String get attachExport => 'Exportieren';

  @override
  String get attachTranscribe => 'Transkribieren';

  @override
  String get attachCannotPlay => 'Diese Datei kann nicht abgespielt werden';

  @override
  String get attachPlaybackUnavailable => 'Wiedergabe nicht verfügbar';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '$minutes Minute',
    );
    return 'Die Aufnahme wurde bei der Höchstdauer von $_temp0 beendet. Das Memo wurde gespeichert.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '$minutes Minute',
    );
    return 'Höchstdauer von $_temp0 erreicht';
  }

  @override
  String get voiceDismiss => 'Schließen';

  @override
  String get voiceOpeningMic => 'Mikrofon wird geöffnet…';

  @override
  String get voiceSaving => 'Wird gespeichert…';

  @override
  String get voiceSavedTranscribing => 'Gespeichert. Wird transkribiert…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Gespeichert. Wird transkribiert… $percent %';
  }

  @override
  String get voiceDiscard => 'Verwerfen';

  @override
  String get voiceStop => 'Stopp';

  @override
  String get voiceChooseModelFirst =>
      'Wählen Sie zuerst in den Einstellungen ein Transkriptionsmodell';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'Das Modell $model wurde noch nicht heruntergeladen — siehe Einstellungen';
  }

  @override
  String get voiceTranscribing => 'Wird transkribiert…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Wird transkribiert… $percent %';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Transkription nicht möglich: $error';
  }

  @override
  String get voiceNoSpeech => 'In diesem Memo wurde keine Sprache gefunden';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Transkribiert, aber die zugehörige Notiz ist nicht geöffnet';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'Die Aufnahme wurde verworfen, weil eine andere Datenbank geöffnet wurde.';

  @override
  String get voiceMicPermissionRefused =>
      'Der Zugriff auf das Mikrofon wurde verweigert';

  @override
  String voiceStartFailed(String error) {
    return 'Aufnahme konnte nicht gestartet werden: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Aufnahme fehlgeschlagen: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Aufnahme konnte nicht abgeschlossen werden: $error';
  }

  @override
  String get voiceNoDatabase =>
      'Keine Datenbank geöffnet, daher konnte das Memo nicht gespeichert werden';

  @override
  String voiceSaveFailed(String error) {
    return 'Memo konnte nicht gespeichert werden: $error';
  }

  @override
  String get timeTimelineTitle => 'Zeitverlauf';

  @override
  String get timeStatsToday => 'Heute:';

  @override
  String get timeStatsThisMonth => 'Diesen Monat:';

  @override
  String timeRecordingSince(String time) {
    return 'Erfassung seit $time';
  }

  @override
  String get timeEndBeforeStart => 'Die Endzeit muss nach der Startzeit liegen';

  @override
  String get timeOverlaps =>
      'Überschneidet sich mit einem vorhandenen Intervall';

  @override
  String get timeAddIntervalTitle => 'Zeitintervall hinzufügen';

  @override
  String get timeEditIntervalTitle => 'Zeitintervall bearbeiten';

  @override
  String get timeStartTime => 'Beginn:';

  @override
  String get timeFinishTime => 'Ende:';

  @override
  String get timeDurationLabel => 'Dauer:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '$hours Stunde',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '$minutes Minute',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours Stunden',
      one: '$hours Stunde',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '$minutes Minute',
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
  String get timeAddEllipsis => 'Hinzufügen...';

  @override
  String get timeNoRecords => 'Keine Zeiteinträge';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'jetzt';

  @override
  String get timeRemoveIntervalTitle => 'Intervall entfernen?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Möchten Sie dieses Zeitintervall wirklich entfernen?';

  @override
  String get timeNotTracking => 'Keine Erfassung';

  @override
  String get timeStopTracking => 'Zeiterfassung beenden';

  @override
  String get timeStartTracking => 'Zeiterfassung starten';

  @override
  String get timeBackToFullWindow => 'Zurück zum vollen Fenster';

  @override
  String get timeReportTitle => 'Zeitbericht';

  @override
  String get timeReportSaveTitle => 'Zeitbericht speichern';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Bericht konnte nicht erstellt werden: $error';
  }

  @override
  String get timeReportCopied => 'Bericht in die Zwischenablage kopiert';

  @override
  String timeReportSavedTo(String path) {
    return 'Gespeichert unter $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get timeReportTasks => 'Aufgaben';

  @override
  String get timeReportNoTasks => 'Keine Aufgaben vorhanden.';

  @override
  String get timeReportClearSelection => 'Auswahl aufheben';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Untergeordnete einbeziehen';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Auch die Zeit der Unteraufgaben jedes ausgewählten Knotens berücksichtigen.';

  @override
  String get timeReportDateRange => 'Zeitraum';

  @override
  String timeReportFrom(String date) {
    return 'Von: $date';
  }

  @override
  String timeReportTo(String date) {
    return 'Bis: $date';
  }

  @override
  String get timeReportFormat => 'Format';

  @override
  String get timeReportFormatTree => 'Baum (nur Summen)';

  @override
  String get timeReportFormatTreeWithDays =>
      'Baum mit Aufschlüsselung nach Tagen';

  @override
  String get timeReportFormatFlat => 'Flache Intervallliste';

  @override
  String get timeReportShowEmpty => 'Aufgaben ohne Zeit anzeigen';

  @override
  String get timeReportUntitled => '(ohne Titel)';

  @override
  String get timeReportSelectTasks =>
      'Wählen Sie eine oder mehrere Aufgaben aus, um einen Bericht zu erstellen.';

  @override
  String get timeReportNoRecordsInPeriod =>
      'Keine Zeiteinträge im gewählten Zeitraum.';

  @override
  String get timeReportTextPeriod => 'Zeitraum:';

  @override
  String get timeReportTextTotal => 'Gesamt:';

  @override
  String get timeReportTextGenerated => 'Erstellt:';

  @override
  String get timeReportTextClipped =>
      'Einträge, die über die Grenzen des Zeitraums hinausreichen, werden auf den Zeitraum gekürzt.';

  @override
  String timeReportTextSelf(String duration) {
    return 'eigene: $duration';
  }

  @override
  String get timeReportTextOngoing => 'läuft';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
    return 'Gesamt: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Neu erstellen';

  @override
  String get timeReportShare => 'Teilen…';

  @override
  String get timeReportSave => 'Speichern…';

  @override
  String get timeReportPresetToday => 'Heute';

  @override
  String get timeReportPresetThisWeek => 'Diese Woche';

  @override
  String get timeReportPresetThisMonth => 'Dieser Monat';

  @override
  String get timeReportPresetLastMonth => 'Letzter Monat';

  @override
  String get timeReportPresetThisYear => 'Dieses Jahr';

  @override
  String get prefsTitle => 'Einstellungen';

  @override
  String get prefsTabAppearance => 'Darstellung';

  @override
  String get prefsTabBehavior => 'Verhalten';

  @override
  String get prefsTabVoiceMemos => 'Sprachmemos';

  @override
  String get prefsTabSync => 'Synchronisierung';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => 'Sprache';

  @override
  String get prefsInterfaceLanguage => 'Oberfläche';

  @override
  String get prefsLanguageHint =>
      'Übersetzungen außer Englisch sind maschinell erstellt; Korrekturen sind willkommen.';

  @override
  String get prefsGroupTheme => 'Design';

  @override
  String get prefsThemeMode => 'Modus';

  @override
  String get prefsThemeSystem => 'System';

  @override
  String get prefsThemeLight => 'Hell';

  @override
  String get prefsThemeDark => 'Dunkel';

  @override
  String get prefsGroupStyle => 'Stil';

  @override
  String get prefsGroupColour => 'Farbe';

  @override
  String get prefsLook => 'Aussehen';

  @override
  String get prefsLookHint =>
      'Klassisch: eckige Ecken, flache umrandete Schaltflächen, keine Welleneffekte, stets sichtbare Bildlaufleisten und eine Titelleiste in der Akzentfarbe mit dem Menü darunter.';

  @override
  String get prefsUiStyleModern => 'Modern';

  @override
  String get prefsUiStyleClassic => 'Klassisch';

  @override
  String get prefsAccentColour => 'Akzentfarbe';

  @override
  String get prefsAccentTeal => 'Petrol';

  @override
  String get prefsAccentBlue => 'Blau';

  @override
  String get prefsAccentIndigo => 'Indigo';

  @override
  String get prefsAccentPurple => 'Lila';

  @override
  String get prefsAccentPink => 'Pink';

  @override
  String get prefsAccentRed => 'Rot';

  @override
  String get prefsAccentOrange => 'Orange';

  @override
  String get prefsAccentAmber => 'Bernstein';

  @override
  String get prefsAccentGreen => 'Grün';

  @override
  String get prefsAccentGraphite => 'Graphit';

  @override
  String get prefsGroupWindow => 'Fenster';

  @override
  String get prefsSystemTitleBar => 'Titelleiste des Systems verwenden';

  @override
  String get prefsSystemTitleBarHint =>
      'Fensterrahmen, Titel und Schaltflächen so, wie der Desktop sie zeichnet, mit der Menüleiste darunter.';

  @override
  String get prefsGroupEditorFont => 'Editor-Schrift (Text einer Notiz)';

  @override
  String get prefsGroupTreeFont => 'Baum-Schrift (die Gliederung)';

  @override
  String get prefsGroupInterfaceFont => 'Oberflächen-Schrift (Menüs & Dialoge)';

  @override
  String get prefsFontFamily => 'Schriftart';

  @override
  String get prefsFontCustom => 'Benutzerdefiniert…';

  @override
  String get prefsCustomName => 'Eigener Name';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'z. B. $font';
  }

  @override
  String get prefsFontSize => 'Größe';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'Stil';

  @override
  String get prefsBold => 'Fett';

  @override
  String get prefsItalic => 'Kursiv';

  @override
  String get prefsPreview => 'Vorschau';

  @override
  String get prefsPreviewText =>
      'Victor jagt zwölf Boxkämpfer quer über den großen Sylter Deich.';

  @override
  String get prefsScale => 'Skalierung';

  @override
  String get prefsFontSansSerif => 'Sans Serif';

  @override
  String get prefsFontSerif => 'Serif';

  @override
  String get prefsFontMonospace => 'Monospace';

  @override
  String get prefsGroupTimeTracking => 'Zeiterfassung';

  @override
  String get prefsEnableTimeTracking => 'Zeiterfassung aktivieren';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Erfassung starten/beenden, Zeitverläufe und Zeitberichte. Ausgeschaltet werden sie ausgeblendet; erfasste Zeit bleibt erhalten';

  @override
  String get prefsShowSeconds => 'Sekunden anzeigen';

  @override
  String get prefsShowSecondsHint => 'Sekunden in Zeitdauern anzeigen';

  @override
  String get prefsMiniTracker => 'Während der Erfassung Mini-Fenster zeigen';

  @override
  String get prefsMiniTrackerHint =>
      'Läuft eine Uhr, wird das Fenster beim Minimieren stattdessen zu einer kleinen, stets sichtbaren Uhr verkleinert';

  @override
  String get prefsGroupSaving => 'Speichern';

  @override
  String get prefsAutoSaveEvery => 'Automatisch speichern alle';

  @override
  String get prefsUnitSec => 's';

  @override
  String get prefsGroupEditor => 'Editor';

  @override
  String get prefsTabWidth => 'Tabulatorbreite';

  @override
  String get prefsUnitSpaces => 'Leerzeichen';

  @override
  String get prefsTabAsSpaces => 'Tabulatoren als Leerzeichen einfügen';

  @override
  String get prefsTabAsSpacesHint =>
      'Die Tab-Taste fügt Leerzeichen statt eines Tabulators ein';

  @override
  String get prefsWordWrap => 'Zeilenumbruch';

  @override
  String get prefsWordWrapHint =>
      'Aus: Lange Zeilen laufen weiter und die Notiz scrollt seitlich (Shift + Mausrad). Auch im Kontextmenü des Editors und in der Statusleiste';

  @override
  String get prefsMonospaceOnly => 'Nur Festbreitenschriften';

  @override
  String get prefsMonospaceOnlyHint =>
      'Das Schriftmenü der Symbolleiste bietet nur Schriften mit fester Breite an, damit ausgerichteter Text ausgerichtet bleibt';

  @override
  String get prefsFloatingButtons => 'Schwebende Schaltflächen';

  @override
  String get prefsFloatingButtonsHint =>
      '„Datei anhängen“ und „Sprachmemo aufnehmen“ über der Notiz; die Symbolleiste behält ihre eigenen Schaltflächen in jedem Fall';

  @override
  String get prefsPaste => 'Einfügen';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V fügt immer reinen Text ein';

  @override
  String get prefsPasteKeep => 'Formatierung beibehalten';

  @override
  String get prefsPasteStrip => 'Farben und Schriften entfernen';

  @override
  String get prefsPastePlain => 'Nur reiner Text';

  @override
  String get prefsTableColumns => 'Tabellenspalten';

  @override
  String get prefsTableColumnsHint =>
      'Wonach „Als Tabelle formatieren“ (Kontextmenü des Editors) Spalten trennt. Nicht innerhalb von URLs oder Text in Anführungszeichen';

  @override
  String get prefsSeparatorColon => 'Doppelpunkt  ( : )';

  @override
  String get prefsSeparatorEquals => 'Gleichheitszeichen  ( = )';

  @override
  String get prefsSeparatorPipe => 'Senkrechter Strich  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Semikolon  ( ; )';

  @override
  String get prefsSeparatorComma => 'Komma  ( , )';

  @override
  String get prefsSeparatorTab => 'Tab';

  @override
  String get prefsGroupToolbarButtons => 'Symbolleisten-Schaltflächen';

  @override
  String get prefsToolbarButtonsHint =>
      'Entfernen Sie das Häkchen, um eine Schaltfläche aus der Editor-Symbolleiste zu nehmen.';

  @override
  String get prefsToolbarUndoRedo => 'Rückgängig / Wiederholen';

  @override
  String get prefsToolbarFont => 'Schriftart';

  @override
  String get prefsToolbarSize => 'Größe';

  @override
  String get prefsToolbarBold => 'Fett';

  @override
  String get prefsToolbarItalic => 'Kursiv';

  @override
  String get prefsToolbarUnderline => 'Unterstrichen';

  @override
  String get prefsToolbarStrikeThrough => 'Durchgestrichen';

  @override
  String get prefsToolbarInlineCode => 'Code';

  @override
  String get prefsToolbarTextColor => 'Textfarbe';

  @override
  String get prefsToolbarHighlightColor => 'Hervorhebungsfarbe';

  @override
  String get prefsToolbarClearFormat => 'Formatierung löschen';

  @override
  String get prefsToolbarHeadings => 'Überschriften';

  @override
  String get prefsToolbarNumberedList => 'Nummerierte Liste';

  @override
  String get prefsToolbarBulletedList => 'Aufzählung';

  @override
  String get prefsToolbarChecklist => 'Checkliste';

  @override
  String get prefsToolbarCodeBlock => 'Codeblock';

  @override
  String get prefsToolbarQuote => 'Zitat';

  @override
  String get prefsToolbarIndent => 'Einzug';

  @override
  String get prefsToolbarLink => 'Link';

  @override
  String get prefsToolbarInsertImage => 'Bild einfügen';

  @override
  String get prefsToolbarVoiceMemo => 'Sprachmemo';

  @override
  String get prefsGroupSecurity => 'Sicherheit';

  @override
  String get prefsRememberPassword => 'Passwort merken';

  @override
  String get prefsRememberPasswordHint =>
      'Datenbankpasswort im Schlüsselbund des Systems speichern';

  @override
  String get prefsBiometricUnlock => 'Biometrische Entsperrung';

  @override
  String get prefsBiometricUnavailableHint =>
      'Nicht verfügbar — richten Sie zuerst in den Android-Einstellungen einen Fingerabdruck oder eine Displaysperre ein';

  @override
  String get prefsBiometricHint =>
      'Fingerabdruck, Gesicht oder Displaysperre bestätigen, bevor das gemerkte Passwort verwendet wird';

  @override
  String get prefsBlockScreenshots => 'Screenshots blockieren';

  @override
  String get prefsBlockScreenshotsHint =>
      'App-Inhalte in Screenshots, Bildschirmaufnahmen und der Übersicht der letzten Apps verbergen';

  @override
  String get prefsGroupStartup => 'Start';

  @override
  String get prefsSingleInstance => 'Nur eine Instanz';

  @override
  String get prefsSingleInstanceHint =>
      'Nur ein laufendes Fenster zulassen; ein erneuter Start holt das vorhandene in den Vordergrund. Wirksam ab dem nächsten Start.';

  @override
  String get prefsVoiceGroupDevices => 'Geräte';

  @override
  String get prefsVoiceMicrophone => 'Mikrofon';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Für Sprachmemos und für den Test unten.';

  @override
  String get prefsVoiceSpeaker => 'Lautsprecher';

  @override
  String get prefsVoiceSpeakerHint =>
      'Gilt für Sprachmemos. Andere Audioanhänge werden über das Standardgerät des Systems wiedergegeben.';

  @override
  String get prefsVoiceDevicesLooking => 'Wird gesucht…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'Es konnten keine Audiogeräte aufgelistet werden: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Nicht verfügbar';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (Standard)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (nicht verbunden)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Transkription';

  @override
  String get prefsVoiceModel => 'Modell';

  @override
  String get prefsVoiceModelHintNone =>
      'Memos werden nur als Audio aufgenommen und gespeichert.';

  @override
  String get prefsVoiceModelHintLocal =>
      'Läuft auf diesem Gerät. Es wird nichts gesendet.';

  @override
  String get prefsVoiceModelOff => 'Aus';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · empfohlen';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Nach der Aufnahme transkribieren';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'Ein Memo wird zuerst gespeichert und dann aus dem gespeicherten Audio transkribiert. Ausgeschaltet wird es ohne Transkription gespeichert; „Transkribieren“ im Anhangsmenü funktioniert später trotzdem.';

  @override
  String get prefsVoiceLanguage => 'Sprache';

  @override
  String get prefsVoiceLanguageAuto => 'Automatisch erkennen';

  @override
  String get prefsVoiceFooter =>
      'Aufnehmen funktioniert auch ohne Modell — Memos werden immer als Audio gespeichert und wie jeder andere Anhang wiedergegeben. Ein Modell fügt nur den Text hinzu.';

  @override
  String get prefsVoiceGroupCheck => 'Test';

  @override
  String get prefsVoiceCheckIntro =>
      'Nimmt ein paar Sekunden auf, spielt sie ab und transkribiert sie — mit den Geräten und dem Modell oben. Es wird nichts gespeichert.';

  @override
  String get prefsVoiceStop => 'Stopp';

  @override
  String get prefsVoiceTestAgain => 'Erneut testen';

  @override
  String get prefsVoiceCheckRecording =>
      'Aufnahme läuft — sprechen Sie einen Satz und drücken Sie dann „Stopp“.';

  @override
  String get prefsVoiceCheckPlaying => 'Wird abgespielt…';

  @override
  String get prefsVoiceCheckTranscribing => 'Wird transkribiert…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Wird transkribiert… $percent %';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return '$duration aufgenommen.';
  }

  @override
  String get prefsVoiceCheckFailed => 'Der Test wurde nicht abgeschlossen.';

  @override
  String get prefsVoiceDownloading => 'Wird heruntergeladen…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$percent % von $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model ist heruntergeladen und bereit.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'Nicht heruntergeladen — $size von HuggingFace.';
  }

  @override
  String get prefsCheckBusy =>
      'Gerade wird ein Sprachmemo aufgenommen. Beenden Sie es zuerst.';

  @override
  String get prefsCheckPermissionRefused =>
      'Der Zugriff auf das Mikrofon wurde verweigert.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'Das Mikrofon ließ sich nicht öffnen: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Aufnahme fehlgeschlagen: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'Die Aufnahme konnte nicht abgeschlossen werden: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Es wurde nichts aufgenommen. Lassen Sie den Test etwas länger laufen oder wählen Sie ein anderes Mikrofon.';

  @override
  String get prefsCheckMalformed =>
      'Die Aufnahme kam fehlerhaft zurück und ließ sich nicht abspielen.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Wiedergabe fehlgeschlagen: $error';
  }

  @override
  String get prefsCheckNoModel =>
      'Aufnahme und Wiedergabe funktionieren. Es ist kein Modell ausgewählt, daher gibt es nichts zu transkribieren.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'Aufnahme und Wiedergabe funktionieren. $model wurde noch nicht heruntergeladen, daher wurde nichts transkribiert.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Transkription fehlgeschlagen: $error';
  }

  @override
  String get prefsCheckSilence =>
      'Das Mikrofon lieferte nur Stille — der Pegel hat sich nie bewegt. Prüfen Sie, ob das richtige Gerät ausgewählt ist und die App es verwenden darf.';

  @override
  String get prefsCheckNoSpeech =>
      'Aufnahme und Wiedergabe funktionieren, aber whisper hat keine Sprache erkannt. Sprechen Sie näher am Mikrofon oder versuchen Sie eine andere Sprache.';

  @override
  String get prefsCheckQuiet =>
      'Der Pegel hat sich nie bewegt, die Eingabe ist also sehr leise.';

  @override
  String get prefsDownloadCancelled => 'Download abgebrochen.';

  @override
  String prefsDownloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get prefsUntitled => '(ohne Titel)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Nur für diese Sitzung gespeichert: Der Schlüsselbund des Systems hat ihn abgelehnt. Ist Ihr Schlüsselbund gesperrt, entsperren Sie ihn und drücken Sie „Neu erzeugen“.';

  @override
  String get prefsMcpRegenerateTitle => 'Token neu erzeugen?';

  @override
  String get prefsMcpRegenerateBody =>
      'Agenten, die mit dem aktuellen Token eingerichtet sind, funktionieren erst wieder, wenn Sie den neuen in ihre Einstellungen einfügen.';

  @override
  String get prefsMcpRegenerate => 'Neu erzeugen';

  @override
  String get prefsMcpGroupAccess => 'Agentenzugriff';

  @override
  String get prefsMcpEnable => 'MCP-Server aktivieren';

  @override
  String get prefsMcpEnableHint =>
      'Lokalen KI-Coding-Agenten erlauben, diese Gliederung über 127.0.0.1 zu lesen. Standardmäßig aus.';

  @override
  String get prefsMcpReadOnly => 'Schreibgeschützt';

  @override
  String get prefsMcpReadOnlyHint =>
      'Agenten können Aufgaben suchen und lesen, aber nicht erstellen, ändern, verschieben oder löschen.';

  @override
  String get prefsMcpGroupEndpoint => 'Endpunkt';

  @override
  String get prefsMcpPort => 'Port';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'URL kopieren';

  @override
  String get prefsMcpToken => 'Token';

  @override
  String get prefsMcpTokenHint =>
      'Jeder, der unter Ihrem Benutzer Programme ausführen kann, kann dieses Token verwenden. Behandeln Sie es wie ein Passwort.';

  @override
  String get prefsMcpNoTokenYet =>
      'Noch kein Token — aktivieren Sie den Server, um eines zu erzeugen';

  @override
  String get prefsMcpShowToken => 'Token anzeigen';

  @override
  String get prefsMcpHideToken => 'Token verbergen';

  @override
  String get prefsMcpCopyToken => 'Token kopieren';

  @override
  String get prefsMcpCopied => 'Kopiert.';

  @override
  String get prefsMcpGroupExcluded => 'Ausgeschlossene Zweige';

  @override
  String get prefsMcpExcludedIntro =>
      'Aufgaben, die vor dem MCP-Server verborgen sind, samt allem darunter.';

  @override
  String get prefsMcpLoading => 'Wird geladen…';

  @override
  String get prefsMcpOutlineReadError =>
      'Die Gliederung konnte nicht gelesen werden.';

  @override
  String get prefsMcpChoose => 'Auswählen…';

  @override
  String get prefsMcpNothingExcluded =>
      'Nichts ausgeschlossen — Agenten sehen die gesamte Gliederung.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'und $count weitere',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'Empfangsbereit unter $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'Port $port ist nicht verfügbar. Wählen Sie einen anderen Port.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'Kein Zugriffstoken. Drücken Sie „Neu erzeugen“, um eines zu erstellen.';

  @override
  String get prefsMcpWaitingDatabase =>
      'Warten auf das Öffnen einer Datenbank.';

  @override
  String get prefsMcpNotRunning => 'Läuft nicht.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Letzte Anfrage $time';
  }

  @override
  String get prefsMcpNoRequests => 'Noch keine Anfragen';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count abgelehnt (falsches oder fehlendes Token)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<zuerst den Server aktivieren>';

  @override
  String get prefsMcpGroupSetup => 'Agent einrichten';

  @override
  String get prefsMcpClient => 'Client';

  @override
  String get prefsMcpStdioBridge =>
      'Ein Agent, der nur stdio spricht, kann so angebunden werden:';

  @override
  String get prefsMcpTargetTerminal => 'Im Terminal ausführen:';

  @override
  String prefsMcpTargetFile(String file) {
    return 'In $file einfügen:';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Gilt für Ihren Benutzer, daher steht die Gliederung in jedem Projekt zur Verfügung.';

  @override
  String get prefsMcpNoteCodex =>
      'Um das Token nicht in der Datei zu haben, ersetzen Sie http_headers durch bearer_token_env_var = \"NOO_MCP_TOKEN\" und setzen Sie diese Variable in Ihrer Shell.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false ist wichtig — ohne diese Angabe versteht OpenCode die 401-Antwort dieses Servers als Aufforderung, eine OAuth-Registrierung zu beginnen, die es nicht abschließen kann.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'Eine angehakte Aufgabe ist samt allem darunter vor dem MCP-Server verborgen — Agenten können sie weder lesen noch ändern und nichts löschen, das sie enthält.';

  @override
  String get prefsMcpNoDatabase => 'Keine Datenbank geöffnet.';

  @override
  String get prefsMcpNoTasks => 'Diese Gliederung enthält noch keine Aufgaben.';

  @override
  String get prefsMcpCollapse => 'Einklappen';

  @override
  String get prefsMcpExpand => 'Ausklappen';

  @override
  String get prefsMcpHiddenWithParent => 'mit übergeordneter verborgen';

  @override
  String get syncGroupSynchronization => 'Synchronisierung';

  @override
  String get syncEnable => 'Synchronisierung aktivieren';

  @override
  String get syncEnableHint =>
      'Diese Datenbank mit einem Server synchron halten';

  @override
  String get syncGroupIdentity => 'Identität';

  @override
  String get syncNeedsUserName =>
      'Geben Sie einen Benutzernamen ein, um die Synchronisierung zu starten. Ohne ihn wird nichts synchronisiert — mit oder ohne Server.';

  @override
  String get syncUserName => 'Benutzername';

  @override
  String get syncUserNameHint =>
      'Auf allen Ihren Geräten gleich. Zusammen mit dem Datenbankpasswort werden daraus die Schlüssel abgeleitet; Geräte synchronisieren also nur, wenn beides übereinstimmt.';

  @override
  String get syncDeviceName => 'Gerätename';

  @override
  String get syncDeviceNameHint =>
      'So stellt sich dieses Gerät Geräten in der Nähe vor';

  @override
  String get syncGroupServer => 'Sync-Server (optional)';

  @override
  String get syncServerIntro =>
      'Leer lassen, um nur mit Geräten im selben Netzwerk zu synchronisieren. Mit einem Server können Geräte zusätzlich synchronisieren, wenn sie voneinander entfernt sind; er speichert verschlüsselte Daten, die er nicht lesen kann.';

  @override
  String get syncServerUrl => 'Server-URL';

  @override
  String get syncServerPassword => 'Passwort';

  @override
  String get syncServerPasswordHint =>
      'Ihr Kontopasswort auf dem Server. Nicht das Datenbankpasswort und nie als Schlüssel verwendet.';

  @override
  String get syncTestConnection => 'Verbindung testen';

  @override
  String get syncRegister => 'Registrieren';

  @override
  String get syncGroupSchedule => 'Zeitplan';

  @override
  String get syncScheduleNeedsServer =>
      'Synchronisieren beim Start und Beenden erfordert einen Server. Geräte im selben Netzwerk synchronisieren auf Anforderung über Extras → Sync P2P...';

  @override
  String get syncAutosyncOnStart => 'Beim Start automatisch synchronisieren';

  @override
  String get syncAutosyncOnStartHint =>
      'Synchronisieren, wenn die App die Datenbank öffnet';

  @override
  String get syncCheckOnStart =>
      'Beim Start nach eingehenden Änderungen suchen';

  @override
  String get syncCheckOnStartHint =>
      'Den Server fragen, ob andere Geräte Änderungen gesendet haben, ohne zu synchronisieren, und das am Sync-Symbol anzeigen. Nicht nötig, solange „Beim Start automatisch synchronisieren“ aktiv ist';

  @override
  String get syncAskOnExit => 'Beim Beenden nach Synchronisierung fragen';

  @override
  String get syncAskOnExitHint =>
      'Vor dem Schließen der App anbieten, ausstehende Änderungen zu synchronisieren';

  @override
  String get syncGroupServerStorage => 'Serverspeicher';

  @override
  String get syncGroupPeerToPeer => 'Peer-to-Peer';

  @override
  String get syncPeerToPeerIntro =>
      'Geräte im selben Netzwerk mit demselben Benutzernamen und Datenbankpasswort können direkt synchronisieren — ohne Server. Öffnen Sie auf jedem davon Extras → Sync P2P...: Sie finden sich gegenseitig und synchronisieren, solange das Fenster offen ist, und sind sonst nicht auffindbar.';

  @override
  String get syncStorageNoServer =>
      'In dieser Konfiguration wird nichts auf einem Server gespeichert. Bei der Peer-to-Peer-Synchronisierung bleibt jedes Paket auf den Geräten selbst.';

  @override
  String get syncStorageIntro =>
      'Der Server bewahrt jede verschlüsselte Änderung auf, die je gemacht wurde; seine Größe wächst daher mit den Bearbeitungen, nicht mit der Größe Ihrer Gliederung.';

  @override
  String get syncStorageReading => 'Wird gelesen…';

  @override
  String get syncStoragePressRefresh =>
      'Drücken Sie „Aktualisieren“, um die aktuelle Belegung zu lesen.';

  @override
  String get syncStorageEmpty => 'Auf dem Server ist noch nichts gespeichert.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size in $count Paketen',
      one: '$size in 1 Paket',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Zähler $first–$last';
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
      other: 'Zähler $first–$last, $snapshots Snapshots',
      one: 'Zähler $first–$last, $snapshots Snapshot',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dazu $count Anhänge ($size), einmal gespeichert und von allen Paketen geteilt, die darauf verweisen.',
      one:
          'Dazu 1 Anhang ($size), einmal gespeichert und von allen Paketen geteilt, die darauf verweisen.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dieses Gerät hält $count davon lokal ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Daten auf dem Server komprimieren';

  @override
  String get syncResetIdentity => 'Geräteidentität zurücksetzen';

  @override
  String get syncNotConfiguredOnDevice =>
      'Die Synchronisierung ist auf diesem Gerät nicht eingerichtet.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Serverspeicher konnte nicht gelesen werden: $error';
  }

  @override
  String get syncResetConfirm =>
      'Dieses Gerät synchronisiert künftig unter einer neuen Identität, und bei der nächsten Synchronisierung veröffentlicht es eine vollständige Kopie der aktuellen Datenbank. Ihre anderen Geräte führen diese ganz normal zusammen — es geht nichts verloren.\n\nTun Sie das, wenn die Synchronisierung meldet, dass der Verlauf dieses Geräts abweicht. Das bedeutet meist, dass diese Datenbank aus einer Sicherung wiederhergestellt wurde, nachdem sie bereits synchronisiert war.\n\nDie alte Identität erscheint weiter in der Speicherliste des Servers, bis Sie komprimieren.';

  @override
  String get syncReset => 'Zurücksetzen';

  @override
  String syncResetFailed(String error) {
    return 'Die Geräteidentität konnte nicht zurückgesetzt werden: $error';
  }

  @override
  String get syncCompactConfirm =>
      'Dieses Gerät synchronisiert und lädt dann einen Snapshot der gesamten Datenbank hoch. Anschließend löscht der Server jede gespeicherte Änderung, die der Snapshot bereits enthält — ebenso jedes Gerät, sobald es den Snapshot übernimmt.\n\nIhre Notizen, Zeiten und Anhänge bleiben unberührt — verworfen werden nur die Aufzeichnungen einzelner früherer Bearbeitungen unterhalb des Snapshots.\n\nAktualisieren Sie Noo zuerst auf Ihren anderen Geräten: Eine ältere Version kann einen Datenstrom nicht lesen, dessen Anfang entfernt wurde.';

  @override
  String get syncCompact => 'Komprimieren';

  @override
  String get syncCompactFailed => 'Komprimierung fehlgeschlagen.';

  @override
  String get syncCompactNothing => 'Noch nichts zu komprimieren.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size auf dem Server freigegeben ($count Pakete)',
      one: '$size auf dem Server freigegeben ($count Paket)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Snapshot hochgeladen, aber dieser Server unterstützt noch keine Komprimierung und hat seine Kopien behalten';

  @override
  String get syncCompactRelayNothing =>
      'Snapshot hochgeladen; auf dem Server war nichts mehr zu entfernen';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dieses Gerät hat $size freigegeben ($count Pakete)',
      one: 'Dieses Gerät hat $size freigegeben ($count Paket)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. Der Snapshot selbst ist $size groß.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. Der Snapshot selbst ist $size groß.';
  }

  @override
  String get syncTestSuccess => 'Erfolg: Server ist erreichbar';

  @override
  String get syncTestUnreachable => 'Fehler: Server nicht erreichbar';

  @override
  String syncErrorWith(String error) {
    return 'Fehler: $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Fehler: Benutzername und Passwort erforderlich';

  @override
  String syncRegisterSuccess(String user) {
    return 'Erfolg: Konto „$user“ erstellt. Einstellungen gespeichert.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Erfolg: Konto „$user“ mit unbegrenztem Serverspeicher erstellt. Einstellungen gespeichert.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Erfolg: Konto „$user“ mit $size Serverspeicher erstellt. Einstellungen gespeichert.';
  }

  @override
  String get syncStagePreparing => 'Vorbereitung';

  @override
  String get syncStageAuthenticating => 'Zugangsdaten werden geprüft';

  @override
  String get syncStagePushing => 'Änderungen senden';

  @override
  String get syncStageApplying => 'Änderungen übernehmen';

  @override
  String get syncStatePending => 'Ausstehend';

  @override
  String get syncStateActive => 'Läuft…';

  @override
  String get syncStateDone => 'Fertig';

  @override
  String get syncStateSkipped => 'Übersprungen';

  @override
  String get syncStateFailed => 'Fehlgeschlagen';

  @override
  String get syncCancelling => 'Wird abgebrochen…';

  @override
  String get syncSynchronizing => 'Wird synchronisiert…';

  @override
  String get syncCancelled => 'Synchronisierung abgebrochen';

  @override
  String get syncFailed => 'Synchronisierung fehlgeschlagen';

  @override
  String get syncTitle => 'Synchronisierung';

  @override
  String get syncComplete => 'Synchronisierung abgeschlossen';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncShowFullLogTooltip => 'Vollständiges Protokoll anzeigen';

  @override
  String get syncShowFullLog => 'Vollständiges Protokoll';

  @override
  String get syncMoreSeeFullLog => 'siehe „Vollständiges Protokoll“';

  @override
  String get syncGroupProgress => 'Fortschritt';

  @override
  String get syncNoRunYet =>
      'Es wurde noch keine Synchronisierung ausgeführt. Mit „Jetzt synchronisieren“ starten Sie eine; die Details der letzten Synchronisierung erscheinen hier.';

  @override
  String get syncCancelledNote =>
      'Auf Ihren Wunsch angehalten. Alles bis dahin Synchronisierte bleibt erhalten; die nächste Synchronisierung setzt dort fort.';

  @override
  String get syncGroupSummary => 'Zusammenfassung';

  @override
  String get syncChangesPushed => 'Gesendete Änderungen';

  @override
  String get syncChangesApplied => 'Übernommene Änderungen';

  @override
  String get syncGroupApplied => 'Übernommen — von anderen Geräten';

  @override
  String get syncGroupPushed => 'Gesendet — von diesem Gerät';

  @override
  String get syncGroupLwwSkipped =>
      'Nicht übernommen — dieses Gerät hatte bereits einen neueren Wert';

  @override
  String get syncGroupUnreadable => 'Konnte nicht gelesen werden';

  @override
  String get syncLwwTieNote =>
      'Exakt gleiche Zeitstempel werden auf beiden Geräten so belassen, wie sie sind; die beiden bleiben also unterschiedlich. Bearbeiten Sie das Element erneut auf dem Gerät, dessen Fassung Sie behalten möchten.';

  @override
  String get syncLwwOlderNote =>
      'Der eingehende Wert war älter als der dieses Geräts und wurde daher nicht geschrieben. Hätte er gewinnen sollen, prüfen Sie, ob die Uhren beider Geräte übereinstimmen.';

  @override
  String get syncSkewSame => 'gleicher Zeitstempel';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'lokal $seconds s voraus',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'lokal $minutes min $seconds s voraus';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'lokal $hours h $minutes min voraus';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'lokal $days Tage voraus',
      one: 'lokal $days Tag voraus',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'eingehend $incoming · lokal $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage fehlgeschlagen  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'Diese Pakete konnten nicht entschlüsselt werden. Das Passwort dieser Datenbank weicht also von dem auf dem Gerät ab, das sie geschrieben hat. Die Synchronisierung versucht sie nicht erneut: Gleichen Sie die Passwörter an und speichern Sie die betroffenen Elemente auf dem anderen Gerät erneut, damit sie noch einmal gesendet werden.';

  @override
  String get syncSkippedUnreadableNote =>
      'Diese Pakete konnten nicht gelesen werden, und die Synchronisierung ist über sie hinweggegangen — ihre Änderungen kommen nicht von selbst an. Speichern Sie die betroffenen Elemente auf dem anderen Gerät erneut, um sie noch einmal zu senden.';

  @override
  String get syncP2pNotConfigured =>
      'Die Synchronisierung ist nicht eingerichtet. Legen Sie zuerst unter Einstellungen → Synchronisierung einen Benutzernamen fest.';

  @override
  String syncP2pStartFailed(String error) {
    return 'Peer-to-Peer-Synchronisierung konnte nicht gestartet werden: $error';
  }

  @override
  String get syncP2pStarting => 'Wird gestartet...';

  @override
  String get syncP2pLooking => 'Suche nach Geräten in diesem Netzwerk...';

  @override
  String get syncP2pIntro =>
      'Öffnen Sie Sync P2P... auch auf dem anderen Gerät. Geräte synchronisieren, sobald sie sich finden; sie sind nicht mehr sichtbar, wenn dieses Fenster geschlossen wird.';

  @override
  String get syncP2pTitle => 'Sync P2P';

  @override
  String get syncP2pSyncAgain => 'Erneut synchronisieren';

  @override
  String get syncP2pFound => 'Gefunden — wartet auf Synchronisierung';

  @override
  String get syncP2pSyncing => 'Wird synchronisiert...';

  @override
  String get syncP2pUpToDate =>
      'Synchronisiert — bereits auf dem neuesten Stand';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synchronisiert — $count Änderungen empfangen',
      one: 'Synchronisiert — 1 Änderung empfangen',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Fehlgeschlagen — $error';
  }

  @override
  String get syncP2pUnknownError => 'unbekannter Fehler';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return 'Empfangen von $device ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return 'Gesendet an $device ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$used von $quota belegt ($percent %)';
  }

  @override
  String get syncQuotaSemantics => 'Belegter Serverspeicher';

  @override
  String get syncQuotaFull =>
      'Voll: Der Server lehnt neue Änderungen ab, bis Sie komprimieren oder Anhänge entfernen.';

  @override
  String get syncQuotaNearlyFull =>
      'Fast voll. Komprimieren gibt meist den Großteil frei.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'Die Synchronisierung ist nicht eingerichtet. Öffnen Sie zuerst die Sync-Einstellungen.';

  @override
  String get syncNoServerConfigured =>
      'Kein Sync-Server eingerichtet. Verwenden Sie „Sync P2P...“ zur lokalen Synchronisierung oder fügen Sie unter Einstellungen → Synchronisierung einen Server hinzu.';

  @override
  String get syncAlreadyInProgress => 'Synchronisierung läuft bereits';

  @override
  String get syncAlreadyInProgressSentence =>
      'Eine Synchronisierung läuft bereits.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done von $totalText Änderungen',
      one: '$done von $totalText Änderung',
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
      other: '$countText Änderungen · Paket $current von $packets',
      one: '$countText Änderung · Paket $current von $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText Änderungen',
      one: '$countText Änderung',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · noch etwa $seconds s';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · noch etwa $minutes min';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Abzweigung im Gerätedatenstrom erkannt: Ein entfernter Knoten hält für dieses Gerät den Paketzähler $remote, dieses Gerät steht aber bei $local und kann nicht bestätigen, dass beide beim Vorangegangenen übereinstimmen (Datenbank aus einer Sicherung wiederhergestellt?). Verwenden Sie „Geräteidentität zurücksetzen“ unter Einstellungen → Synchronisierung, um die Synchronisierung fortzusetzen.';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Gerätedatenstrom bei Paketzähler $counter abgewichen: Dieses Gerät und $source halten unter derselben Identität unterschiedliche Inhalte ($localHash hier gegenüber $remoteHash dort). Diese Datenbank wurde höchstwahrscheinlich aus einer Sicherung wiederhergestellt und hat bereits veröffentlichte Paketnummern erneut verwendet. Verwenden Sie „Geräteidentität zurücksetzen“ unter Einstellungen → Synchronisierung, um die Synchronisierung fortzusetzen; dabei wird diese Datenbank unter einer neuen Identität erneut veröffentlicht, und es geht nichts verloren.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'Dem Server fehlt ein Teil des Verlaufs dieses Geräts: Er erwartet als Nächstes Paket #$expected, das früheste Paket auf diesem Gerät ist aber #$local, und die dazwischen sind nicht mehr vorhanden (der Server wurde höchstwahrscheinlich aus einer älteren Sicherung wiederhergestellt, nachdem dieses Gerät komprimiert hatte). Verwenden Sie „Geräteidentität zurücksetzen“ unter Einstellungen → Synchronisierung, um die Synchronisierung fortzusetzen; dabei wird diese Datenbank unter einer neuen Identität erneut veröffentlicht, und es geht nichts verloren.';
  }

  @override
  String get syncIdentityReset =>
      'Dieses Gerät synchronisiert jetzt unter einer neuen Identität. Bei der nächsten Synchronisierung veröffentlicht es eine vollständige Kopie der aktuellen Datenbank, die alle anderen Geräte ganz normal zusammenführen.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dieses Gerät synchronisiert jetzt unter einer neuen Identität. Bei der nächsten Synchronisierung veröffentlicht es eine vollständige Kopie der aktuellen Datenbank, die alle anderen Geräte ganz normal zusammenführen. $count unbrauchbare Pakete wurden verworfen.',
      one:
          'Dieses Gerät synchronisiert jetzt unter einer neuen Identität. Bei der nächsten Synchronisierung veröffentlicht es eine vollständige Kopie der aktuellen Datenbank, die alle anderen Geräte ganz normal zusammenführen. $count unbrauchbares Paket wurde verworfen.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Schlüssel wird abgeleitet';

  @override
  String get syncDetailSignedIn => 'Bereits angemeldet';

  @override
  String get syncDetailPackaging => 'Lokale Änderungen werden verpackt';

  @override
  String get syncDetailRecovering =>
      'Eigener Verlauf dieses Geräts wird wiederhergestellt';

  @override
  String get syncDetailUploading => 'Wird auf den Server hochgeladen';

  @override
  String get syncDetailNoLocalChanges => 'Keine lokalen Änderungen';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen gesendet',
      one: '1 Änderung gesendet',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading =>
      'Entfernte Änderungen werden heruntergeladen';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anhänge heruntergeladen',
      one: '1 Anhang heruntergeladen',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anhänge noch herunterzuladen',
      one: '1 Anhang noch herunterzuladen',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Bereits auf dem neuesten Stand';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen übernommen',
      one: '1 Änderung übernommen',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'Abgebrochen';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return 'Der Anhang „$name“ ist noch nicht auf dieses Gerät heruntergeladen, und eine Änderung dieses Geräts verweist darauf. Daher können die Änderungen dieses Geräts den Server erst erreichen, wenn er angekommen ist — synchronisieren Sie danach erneut oder mit einem Gerät in der Nähe, das ihn hat.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'Der Server hat den Anhang „$name“ ($size) als zu groß abgelehnt. Alles andere wird synchronisiert; der Anhang selbst erreicht andere Geräte nur über Sync P2P.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'Der Server hat den Anhang „$name“ ($size) als zu groß abgelehnt (Grenze: $limit). Alles andere wird synchronisiert; der Anhang selbst erreicht andere Geräte nur über Sync P2P.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return 'Der Anhang „$name“ ($size) passt nicht in Ihren Serverspeicher. Alles andere wird synchronisiert; komprimieren Sie die Daten auf dem Server oder entfernen Sie große Anhänge, um Platz zu schaffen. Bis dahin erreicht der Anhang andere Geräte nur über Sync P2P.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return 'Der Anhang „$name“ ($size) passt nicht in Ihren Serverspeicher ($used von $quota belegt). Alles andere wird synchronisiert; komprimieren Sie die Daten auf dem Server oder entfernen Sie große Anhänge, um Platz zu schaffen. Bis dahin erreicht der Anhang andere Geräte nur über Sync P2P.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bytes',
      one: '$count Byte',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'Kein Sync-Server eingerichtet. Die Komprimierung veröffentlicht einen Snapshot auf dem Relay; bei reiner Synchronisierung mit Geräten in der Nähe gibt es keinen Relay-Speicher, der freigegeben werden könnte.';

  @override
  String get syncCompactStageSyncing =>
      'Synchronisierung vor der Komprimierung';

  @override
  String get syncCompactStageChecking =>
      'Prüfen, ob dieses Gerät auf dem neuesten Stand ist';

  @override
  String get syncCompactStagePackaging =>
      'Snapshot der gesamten Datenbank wird verpackt';

  @override
  String get syncCompactStageAttachments =>
      'Vom Snapshot referenzierte Anhänge werden hochgeladen';

  @override
  String get syncCompactStageUploading => 'Snapshot wird hochgeladen';

  @override
  String get syncCompactStageReclaiming =>
      'Speicherplatz auf diesem Gerät wird freigegeben';

  @override
  String get syncCompactStageReadingUsage => 'Relay-Speicher wird gelesen';

  @override
  String syncCompactNeedsSync(String error) {
    return 'Für die Komprimierung ist zuerst eine abgeschlossene Synchronisierung nötig: $error';
  }

  @override
  String get syncCompactDidNotFinish =>
      'Die Komprimierung wurde nicht abgeschlossen.';

  @override
  String get syncCompactRaced =>
      'Eine andere Synchronisierung hat zuerst verpackt. Versuchen Sie die Komprimierung erneut.';

  @override
  String get syncCompactSnapshotMissing =>
      'Der Snapshot wurde verpackt, ist aber nicht im lokalen Speicher.';

  @override
  String get syncCompactMissingAttachments =>
      'Diesem Gerät fehlen noch einige Anhänge. Synchronisieren Sie, bis alle Anhänge heruntergeladen sind, und komprimieren Sie dann.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Das Relay hat den Snapshot abgelehnt: $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Komprimierung fehlgeschlagen: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dieses Gerät konnte $count Pakete nicht lesen ($packets), sein Zustand ist also nicht die Zusammenführung von allem im Protokoll. Eine Komprimierung würde Pakete verwerfen, die dieses Gerät nie übernommen hat.',
      one:
          'Dieses Gerät konnte $count Paket nicht lesen ($packets), sein Zustand ist also nicht die Zusammenführung von allem im Protokoll. Eine Komprimierung würde Pakete verwerfen, die dieses Gerät nie übernommen hat.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'Dieses Gerät hat noch nicht synchronisierte Bearbeitungen. Synchronisieren Sie zuerst und komprimieren Sie dann.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Diesem Gerät fehlen noch einige Anhänge ($count herunterzuladen), daher konnte sein Snapshot sie nicht liefern, und der Server würde sie verwerfen. Synchronisieren Sie, bis alle Anhänge heruntergeladen sind, und komprimieren Sie dann.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dieses Gerät hat noch nicht alles übernommen, was es für $count Geräte hält. Synchronisieren Sie erneut und komprimieren Sie dann.',
      one:
          'Dieses Gerät hat noch nicht alles übernommen, was es für $count Gerät hält. Synchronisieren Sie erneut und komprimieren Sie dann.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'Bei reiner Synchronisierung mit Geräten in der Nähe lässt sich nicht sicherstellen, dass ein anderes Gerät einen gelöschten Anhang noch hat; daher wurde keiner freigegeben.';

  @override
  String get syncCollectUnsynced =>
      'Dieses Gerät hat Änderungen, die der Server noch nicht gespeichert hat. Synchronisieren Sie zuerst und komprimieren Sie dann.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Snapshot von $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Felder — die gesamte Datenbank',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Knoten „$name“';
  }

  @override
  String syncSummaryFile(String name) {
    return 'Datei „$name“';
  }

  @override
  String get syncSummaryFileFallback => 'Datei';

  @override
  String get syncSummaryTimeChunk => 'Zeitabschnitt';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'umbenannt in „$title“';
  }

  @override
  String get syncSummaryContentEdited => 'Inhalt bearbeitet';

  @override
  String get syncSummaryMoved => 'verschoben';

  @override
  String get syncSummaryReordered => 'umsortiert';

  @override
  String get syncSummaryFlagsChanged => 'Flags geändert';

  @override
  String get syncSummaryRenamed => 'umbenannt';

  @override
  String get syncSummaryContentUpdated => 'Inhalt aktualisiert';

  @override
  String syncSummaryFrom(String time) {
    return 'ab $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'bis $time';
  }

  @override
  String get syncValueTopLevel => 'oberste Ebene';

  @override
  String get syncStorageFull =>
      'Der Serverspeicher ist voll. Komprimieren Sie die Daten auf dem Server (Einstellungen → Synchronisierung → Serverspeicher) oder entfernen Sie große Anhänge; was noch nicht hochgeladen ist, bleibt auf diesem Gerät.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'Der Serverspeicher ist voll ($used von $quota belegt). Komprimieren Sie die Daten auf dem Server (Einstellungen → Synchronisierung → Serverspeicher) oder entfernen Sie große Anhänge; was noch nicht hochgeladen ist, bleibt auf diesem Gerät.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'Der Server lehnt einen weiteren Gerätedatenstrom für dieses Konto ab: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'Auf dem Server ist kein Speicherplatz mehr frei. Es ging nichts verloren; synchronisieren Sie später erneut.';

  @override
  String syncStorageRefused(String detail) {
    return 'Der Server hat das Speichern weiterer Daten abgelehnt: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'Dieser Server nimmt keine neuen Konten an: Die Höchstzahl an Konten ist erreicht.';

  @override
  String get syncRegClosed =>
      'Dieser Server erlaubt keine Registrierung. Fragen Sie den Betreiber nach einem Konto.';

  @override
  String get syncRegTaken => 'Dieser Benutzername ist bereits vergeben.';

  @override
  String get syncRegInvalid =>
      'Der Benutzername muss 3–50 Zeichen lang sein, das Serverpasswort 8–128.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Aus diesem Netzwerk wurden heute zu viele Konten registriert.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Aus diesem Netzwerk wurden heute zu viele Konten registriert. Versuchen Sie es in $wait erneut.';
  }

  @override
  String get syncRegTooManyAttempts => 'Zu viele Versuche.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Zu viele Versuche. Versuchen Sie es in $wait erneut.';
  }

  @override
  String get syncRegBusy =>
      'Der Server ist ausgelastet. Versuchen Sie es gleich noch einmal.';

  @override
  String syncRegFailed(int status) {
    return 'Registrierung fehlgeschlagen (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Registrierung fehlgeschlagen (HTTP $status): $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sekunden',
      one: '$count Sekunde',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '$count Minute',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '$count Stunde',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return 'Keine Antwort von $host innerhalb von $seconds s';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'Antwort von $host stockt seit $seconds s';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…und $count weitere — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'siehe Sync-Protokoll';

  @override
  String get traceAtTopLevel => 'auf oberster Ebene';

  @override
  String traceInPath(String path) {
    return 'in $path';
  }

  @override
  String get traceRowNew => '(neu)';

  @override
  String get traceRowRemoved => '(entfernt)';

  @override
  String get traceShowHowTooltip => 'Zeigen, wie diese Änderung zustande kam';

  @override
  String traceBytes(int count) {
    return '$count B';
  }

  @override
  String traceKilobytes(String size) {
    return '$size KB';
  }

  @override
  String traceMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get traceDecisionApplied => 'übernommen';

  @override
  String get traceDecisionCreated => 'hier erstellt';

  @override
  String get traceDecisionConflictCopy =>
      'übernommen — der ersetzte Wert wurde als Konfliktkopie behalten';

  @override
  String get traceDecisionMerged =>
      'mit der hier gemachten Bearbeitung zusammengeführt — beide Änderungen behalten';

  @override
  String get traceDecisionCycleToRoot =>
      'auf die oberste Ebene verschoben — das übergeordnete Element hätte eine Schleife erzeugt';

  @override
  String get traceDecisionParentMissing =>
      'auf oberster Ebene abgelegt, bis das übergeordnete Element eintrifft';

  @override
  String get traceDecisionBlobPending =>
      'übernommen — die Daten des Anhangs folgen separat';

  @override
  String get traceDecisionSent => 'gesendet';

  @override
  String get traceDecisionForwarded => 'weitergeleitet';

  @override
  String get traceRouteRelay => 'Vom Relay heruntergeladen.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Vom Relay heruntergeladen, das es $time gespeichert hat.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Von $peer über das lokale Netzwerk weitergeleitet — geschrieben von $author.';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Direkt von $peer über das lokale Netzwerk.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Bereits von einem früheren Austausch auf diesem Gerät; in diesem übernommen.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Bereits auf diesem Gerät — empfangen $time; in diesem Austausch übernommen.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Bereits auf diesem Gerät — empfangen $time von $source; in diesem Austausch übernommen.';
  }

  @override
  String get traceRoutePackagedUploaded =>
      'Hier verpackt und auf das Relay hochgeladen.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Hier verpackt; das Relay hatte es bereits über einen anderen Weg.';

  @override
  String get traceRoutePackagedBlocked =>
      'Hier verpackt; noch nicht hochgeladen — ein benötigter Anhang konnte nicht hochgeladen werden.';

  @override
  String get traceRoutePackagedWaiting =>
      'Hier verpackt; wartet darauf, dass das Relay oder ein Peer es übernimmt.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Von $peer über das lokale Netzwerk abgerufen — im Auftrag von $author weitergeleitet.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Von $peer über das lokale Netzwerk abgerufen.';
  }

  @override
  String get traceBlobDownloaded => 'jetzt heruntergeladen';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'jetzt heruntergeladen ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'jetzt heruntergeladen von $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'jetzt heruntergeladen von $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'noch nicht heruntergeladen — folgt bei einer späteren Synchronisierung oder beim Öffnen';

  @override
  String get traceBlobHeld => 'bereits auf diesem Gerät';

  @override
  String get traceBlobUploaded => 'auf das Relay hochgeladen';

  @override
  String traceBlobUploadedSized(String size) {
    return 'auf das Relay hochgeladen ($size)';
  }

  @override
  String get traceBlobOnRelay => 'das Relay hatte sie bereits';

  @override
  String get traceBlobOffered => 'auf diesem Gerät zum Abruf durch andere';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'Ein Komprimierungs-Snapshot: die gesamte Datenbank von $device in einem Paket.';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Teil eines vollständigen Snapshots von $device. Ein Snapshot enthält die gesamte Datenbank des Autors; dieses Element wird aufgeführt, weil es hier abwich.';
  }

  @override
  String get traceFieldsHeading => 'Felder';

  @override
  String traceTimeEdited(String time) {
    return 'bearbeitet $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'dort $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'dieses Gerät $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Paket $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Paket $device #$counter (Snapshot)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'geschrieben $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen',
      one: '1 Änderung',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Autorgerät $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'von Gerät $id';
  }

  @override
  String get traceCopyHashTooltip => 'Paket-Hash kopieren';

  @override
  String get traceAttachmentBytesHeading => 'Anhangsdaten';

  @override
  String get traceShowInSyncLog => 'Im Sync-Protokoll anzeigen';

  @override
  String get traceTriggerRelay => 'Server-Synchronisierung';

  @override
  String get traceTriggerCheck => 'Suche nach eingehenden Änderungen';

  @override
  String get traceTriggerLan => 'Geräte in der Nähe';

  @override
  String get traceTriggerLanReturn => 'Gerät in der Nähe (angefordert)';

  @override
  String get traceTriggerLanServe => 'An Gerät in der Nähe ausgeliefert';

  @override
  String get traceTriggerPackage => 'Lokale Änderungen verpackt';

  @override
  String get traceTriggerCompaction => 'Komprimierung';

  @override
  String get traceTriggerIdentityReset => 'Geräteidentität zurückgesetzt';

  @override
  String get traceTriggerAttachment => 'Download eines Anhangs';

  @override
  String get traceTriggerBlobCollect => 'Bereinigung der Anhänge';

  @override
  String get traceOutcomeRunning => 'läuft';

  @override
  String get traceOutcomeFailed => 'fehlgeschlagen';

  @override
  String get traceOutcomeDeclined => 'abgelehnt';

  @override
  String get traceOutcomeBusy => 'belegt';

  @override
  String get traceOutcomeInterrupted => 'unterbrochen';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ereignisse als JSON kopiert',
      one: '$count Ereignis als JSON kopiert',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Sync-Protokoll leeren?';

  @override
  String get traceClearBody =>
      'Alle aufgezeichneten Läufe und Ereignisse auf diesem Gerät werden gelöscht. Synchronisierte Daten sind nicht betroffen.';

  @override
  String get traceTitle => 'Sync-Protokoll';

  @override
  String get traceCopyAsJson => 'Als JSON kopieren';

  @override
  String get traceClearLogTooltip => 'Protokoll leeren';

  @override
  String get traceClearLogButton => 'Protokoll leeren';

  @override
  String traceSummaryApplied(int count) {
    return '$count übernommen';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Warnungen',
      one: '1 Warnung',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fehler',
      one: '1 Fehler',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Nichts ausgetauscht';

  @override
  String get traceNoRuns =>
      'Es wurde noch keine Synchronisierung aufgezeichnet. Läufe erscheinen hier, sobald dieses Gerät mit dem Server oder mit Geräten in der Nähe synchronisiert.';

  @override
  String get traceAllRuns => 'Alle Läufe';

  @override
  String traceRunsRecorded(int count) {
    return '$count aufgezeichnet';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'Alle Läufe ($count)';
  }

  @override
  String get traceRunLabel => 'Lauf';

  @override
  String get traceSearchHint => 'Suche: Knotenname, ID, Hash, Gerät, Art…';

  @override
  String get traceLevelAll => 'Alle';

  @override
  String get traceLevelWarnings => 'Warnungen';

  @override
  String get traceLevelErrors => 'Fehler';

  @override
  String get traceDirectionAll => 'Ein- und ausgehend';

  @override
  String get traceDirectionIncoming => 'Eingehend';

  @override
  String get traceDirectionOutgoing => 'Ausgehend';

  @override
  String get traceDirectionLocal => 'Lokal';

  @override
  String get traceNoEvents => 'Keine passenden Ereignisse.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die ersten $count Ereignisse werden angezeigt. Grenzen Sie die Suche ein oder wählen Sie einen Lauf, um den Rest zu sehen.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Lauf #$id';
  }

  @override
  String get traceEmptyValue => '(leer)';

  @override
  String traceSubHash(String hash) {
    return 'Hash $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'Wert $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'entfernt $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'lokal $time';
  }

  @override
  String get traceDetailAt => 'Zeitpunkt';

  @override
  String get traceDetailDirection => 'Richtung';

  @override
  String get traceDetailOriginDevice => 'Ursprungsgerät';

  @override
  String get traceDetailCounter => 'Zähler';

  @override
  String get traceDetailHash => 'Paket-/Blob-Hash';

  @override
  String get traceDetailEntity => 'Entität';

  @override
  String get traceDetailWorldId => 'World-ID';

  @override
  String get traceDetailName => 'Name';

  @override
  String get traceDetailField => 'Feld';

  @override
  String get traceDetailRemoteTs => 'Entfernter Zeitstempel';

  @override
  String get traceDetailLocalTs => 'Lokaler Zeitstempel';

  @override
  String get traceDetailValueHash => 'Wert-Hash';

  @override
  String get traceDetailValuePreview => 'Wertvorschau';

  @override
  String get traceDetailMessage => 'Meldung';

  @override
  String get traceDetailDetail => 'Detail';
}
