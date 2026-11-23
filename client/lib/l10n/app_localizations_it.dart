// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appMenuFile => 'File';

  @override
  String get appMenuEdit => 'Modifica';

  @override
  String get appMenuView => 'Visualizza';

  @override
  String get appMenuTools => 'Strumenti';

  @override
  String get appMenuDebug => 'Debug';

  @override
  String get appMenuHelp => 'Aiuto';

  @override
  String get appMenuWindow => 'Finestra';

  @override
  String get appMenuOpen => 'Apri...';

  @override
  String get appMenuOpenDatabase => 'Apri database...';

  @override
  String get appMenuNewDatabase => 'Nuovo database...';

  @override
  String get appMenuExportObsidian => 'Esporta in Obsidian...';

  @override
  String get appMenuImportObsidian => 'Importa da Obsidian...';

  @override
  String get appMenuExit => 'Esci';

  @override
  String get appMenuFind => 'Trova...';

  @override
  String get appMenuTheme => 'Tema';

  @override
  String get appMenuThemeEllipsis => 'Tema...';

  @override
  String get appThemeSystem => 'Sistema';

  @override
  String get appThemeLight => 'Chiaro';

  @override
  String get appThemeDark => 'Scuro';

  @override
  String get appMenuTimeline => 'Timeline...';

  @override
  String get appMenuTimeReport => 'Report dei tempi...';

  @override
  String get appMenuCompactDatabase => 'Compatta database...';

  @override
  String get appMenuSyncNow => 'Sincronizza ora';

  @override
  String get appMenuSyncP2p => 'Sincronizza P2P...';

  @override
  String get appMenuPreferences => 'Preferenze...';

  @override
  String get appMenuViewChangeHistory => 'Mostra cronologia modifiche...';

  @override
  String get appMenuGenerateTestData => 'Genera dati di prova';

  @override
  String get appMenuGenerateLargeDataset => 'Genera grande set di dati';

  @override
  String get appMenuClearAllData => 'Cancella tutti i dati';

  @override
  String get appMenuCheckForUpdate => 'Verifica aggiornamenti...';

  @override
  String get appMenuLogs => 'Log';

  @override
  String get appMenuSyncLog => 'Log di sincronizzazione...';

  @override
  String get appMenuAppLog => 'Log dell\'app...';

  @override
  String appMenuAbout(String appName) {
    return 'Informazioni su $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Verifica aggiornamenti…';

  @override
  String get appMacMenuSettings => 'Impostazioni…';

  @override
  String appMacMenuQuit(String appName) {
    return 'Esci da $appName';
  }

  @override
  String get appMacMenuOpen => 'Apri…';

  @override
  String get appMacMenuNewDatabase => 'Nuovo database…';

  @override
  String get appMacMenuExportObsidian => 'Esporta in Obsidian…';

  @override
  String get appMacMenuImportObsidian => 'Importa da Obsidian…';

  @override
  String get appMacMenuUndo => 'Annulla';

  @override
  String get appMacMenuRedo => 'Ripeti';

  @override
  String get appMacMenuCut => 'Taglia';

  @override
  String get appMacMenuPaste => 'Incolla';

  @override
  String get appMacMenuSelectAll => 'Seleziona tutto';

  @override
  String get appMacMenuFind => 'Trova…';

  @override
  String get appMacMenuTimeline => 'Timeline…';

  @override
  String get appMacMenuTimeReport => 'Report dei tempi…';

  @override
  String get appMacMenuCompactDatabase => 'Compatta database…';

  @override
  String get appMacMenuSyncP2p => 'Sincronizza P2P…';

  @override
  String get appMacMenuViewChangeHistory => 'Mostra cronologia modifiche…';

  @override
  String get appMacMenuSyncLog => 'Log di sincronizzazione…';

  @override
  String get appMacMenuAppLog => 'Log dell\'app…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Apri database';

  @override
  String get appCreateDatabaseDialogTitle => 'Crea nuovo database';

  @override
  String get appIncorrectPasswordRetry => 'Password errata. Riprova.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Aperto: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Impossibile aprire il database: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Creato: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Impossibile creare il database: $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Apri prima un database';

  @override
  String get appNoDatabaseOpen => 'Nessun database aperto';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Impossibile leggere il file del database: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt =>
      'Password errata o database danneggiato';

  @override
  String get appExportObsidianDialogTitle => 'Esporta in una cartella Obsidian';

  @override
  String get appImportObsidianDialogTitle => 'Importa da una cartella Obsidian';

  @override
  String get appImportObsidianZipDialogTitle => 'Importa .zip di Obsidian';

  @override
  String get appExportingObsidian => 'Esportazione nel formato Obsidian...';

  @override
  String get appImportingObsidian => 'Importazione dal formato Obsidian...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attività',
      one: '$count attività',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file di timeline',
      one: '$count file di timeline',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count immagini',
      one: '$count immagine',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrazioni di tempo',
      one: '$count registrazione di tempo',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Esportati: $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'Importati: $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String appImportFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Esportazione Obsidian ($count attività)',
      one: 'Esportazione Obsidian ($count attività)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'La cartella non esiste: $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Sincronizzazione non configurata. Apri prima le impostazioni di sincronizzazione.';

  @override
  String get appNoSyncServer =>
      'Nessun server di sincronizzazione configurato. Usa Sincronizza P2P... (Shift+F5) oppure aggiungi un server nelle Preferenze.';

  @override
  String get appUnsyncedChangesTitle => 'Modifiche non sincronizzate';

  @override
  String get appUnsyncedChangesBody =>
      'Ci sono modifiche non sincronizzate; vuoi sincronizzarle?';

  @override
  String get appDontSync => 'Non sincronizzare';

  @override
  String get appSync => 'Sincronizza';

  @override
  String get appSelectTaskFirst => 'Seleziona prima un\'attività';

  @override
  String get appGenerateTestDataBody =>
      'Verranno create attività di esempio con gerarchia e registrazioni di tempo.\n\nContinuare?';

  @override
  String get appGenerate => 'Genera';

  @override
  String get appTestDataGenerated => 'Dati di prova generati';

  @override
  String get appGenerateLargeDatasetBody =>
      'Verrà creato un grande set di dati con:\n- 20 attività di primo livello\n- Fino a 5 livelli di profondità\n- Fino a 6 figli per attività\n- Registrazioni di tempo per molte attività\n\nPotrebbe richiedere qualche istante. Continuare?';

  @override
  String get appGeneratingData => 'Generazione dei dati...';

  @override
  String get appLargeDatasetGenerated => 'Grande set di dati generato';

  @override
  String get appClearAllDataBody =>
      'Verranno eliminati definitivamente tutte le attività, le registrazioni di tempo e gli allegati.\n\nL\'operazione non può essere annullata. Sei sicuro?';

  @override
  String get appDeleteAll => 'Elimina tutto';

  @override
  String get appAllDataCleared => 'Tutti i dati sono stati cancellati';

  @override
  String get appCompactDatabaseTitle => 'Compatta database';

  @override
  String get appCompactDatabaseBody =>
      'Riscrive il file del database in modo che lo spazio occupato da attività eliminate, allegati e vecchia cronologia delle modifiche torni disponibile sul disco.\n\nViene liberato anche il contenuto degli allegati eliminati, che verrà riscaricato dal server se un giorno ne ripristini uno.\n\nNulla di ciò che vedi ancora viene rimosso. Su un database grande richiede un po\' di tempo, e l\'app non può essere usata finché non termina.';

  @override
  String get appCompact => 'Compatta';

  @override
  String get appCompactingDatabase => 'Compattazione del database...';

  @override
  String appCompactingFailed(String error) {
    return 'Compattazione non riuscita: $error';
  }

  @override
  String get appDatabaseCompacted => 'Database compattato';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'Database compattato — liberati $freed (ora $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'Database compattato — era già compatto ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Trova';

  @override
  String get appSyncNowTooltip => 'Sincronizza ora';

  @override
  String get appBiometricFailed =>
      'Verifica biometrica non riuscita. Inserisci la password.';

  @override
  String get appSavedPasswordIncorrect =>
      'La password salvata non è corretta. Inserisci la password.';

  @override
  String get appLoading => 'Caricamento...';

  @override
  String get appFailedToOpenDatabaseTitle => 'Impossibile aprire il database';

  @override
  String get appOpenAnotherDatabase => 'Apri un altro database…';

  @override
  String get appBiometricReason => 'Sblocca il tuo database Noo';

  @override
  String appWelcomeTitle(String appName) {
    return 'Benvenuto in $appName';
  }

  @override
  String get appWelcomeIntro =>
      'Scegli dove salvare il database cifrato. Potrai cambiarlo in seguito dal menu File.';

  @override
  String get appUseDefaultLocation => 'Usa la posizione predefinita';

  @override
  String get appResolving => 'Determinazione…';

  @override
  String get appCreateNewDatabaseOption => 'Crea nuovo database…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Scegli una posizione personalizzata per un nuovo database cifrato.';

  @override
  String get appOpenExistingDatabaseOption => 'Apri database esistente…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Usa un file .noo esistente da un\'altra posizione.';

  @override
  String get appQuit => 'Esci';

  @override
  String get appWelcomeSyncHint =>
      'Hai già un database su un altro dispositivo? Creane uno nuovo qui con la stessa password, poi configura la sincronizzazione in Preferenze → Sincronizzazione con lo stesso nome utente: le tue note arriveranno con la prima sincronizzazione.';

  @override
  String get appTaskFallbackTitle => 'Attività';

  @override
  String get appTabNotes => 'Note';

  @override
  String get appTabTime => 'Tempo';

  @override
  String get appTabFiles => 'File';

  @override
  String appTabFilesCount(int count) {
    return 'File ($count)';
  }

  @override
  String get appStartTracking => 'Avvia monitoraggio';

  @override
  String get appStopTracking => 'Interrompi monitoraggio';

  @override
  String get appNoTaskSelected => 'Nessuna attività selezionata.';

  @override
  String get appAttachmentsHeading => 'Allegati';

  @override
  String get appModified => 'Modificato';

  @override
  String get appWordWrapOnTooltip =>
      'A capo automatico attivo — fai clic per disattivarlo';

  @override
  String get appWordWrapOffTooltip =>
      'A capo automatico disattivato — fai clic per attivarlo';

  @override
  String get appTimeTodayTap => 'Tempo monitorato oggi — tocca per aprire';

  @override
  String get appHideTimeTracking => 'Nascondi monitoraggio del tempo';

  @override
  String get appTimeTodayClick =>
      'Tempo monitorato oggi — fai clic per i dettagli';

  @override
  String get appViewTimeline => 'Mostra timeline';

  @override
  String get appAttachmentsTap => 'Allegati — tocca per aprire';

  @override
  String get appHideAttachments => 'Nascondi allegati';

  @override
  String get appAttachmentsClick => 'Allegati — fai clic per mostrarli';

  @override
  String get appAddAttachment => 'Aggiungi allegato';

  @override
  String get appUntitledInPath => '(senza titolo)';

  @override
  String get appSyncStatusDisabled =>
      'Sincronizzazione disattivata — fai clic per sincronizzare';

  @override
  String get appSyncStatusUnknown =>
      'Non ancora sincronizzato — fai clic per sincronizzare';

  @override
  String get appSyncStatusIdle => 'Sincronizzato — fai clic per sincronizzare';

  @override
  String get appSyncStatusSyncing => 'Sincronizzazione...';

  @override
  String get appSyncStatusError =>
      'Errore di sincronizzazione — fai clic per riprovare';

  @override
  String get appSyncStatusPending =>
      'Modifiche in attesa — fai clic per sincronizzare';

  @override
  String get appSyncStatusIncoming =>
      'Altri dispositivi hanno inviato modifiche — fai clic per sincronizzare';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Monitoraggio del tempo su \"$title\" — fai clic per andarci';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Interrompi monitoraggio di \"$title\"';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String appPendingMore(int count) {
    return '+$count altri';
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
      other: '$count elementi',
      one: '1 elemento',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche',
      one: '1 modifica',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'In attesa di sincronizzazione: $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'titolo';

  @override
  String get appPendingFieldContent => 'contenuto';

  @override
  String get appPendingFieldMoved => 'spostata';

  @override
  String get appPendingFieldReordered => 'riordinata';

  @override
  String get appPendingFieldFlags => 'flag';

  @override
  String get appPendingFieldDeleted => 'eliminata';

  @override
  String get appPendingFieldName => 'nome';

  @override
  String get appPendingFieldStartTime => 'ora di inizio';

  @override
  String get appPendingFieldEndTime => 'ora di fine';

  @override
  String get appJustNow => 'adesso';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min fa',
      one: '$count min fa',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h fa',
      one: '$count h fa',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count g fa',
      one: '$count g fa',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Inserisci password';

  @override
  String get appSetDatabasePasswordTitle => 'Imposta password del database';

  @override
  String get appPasswordLabel => 'Password';

  @override
  String get appConfirmPasswordLabel => 'Conferma password';

  @override
  String get appPleaseEnterPassword => 'Inserisci una password';

  @override
  String get appPasswordTooShort =>
      'La password deve contenere almeno 4 caratteri';

  @override
  String get appPasswordsDoNotMatch => 'Le password non coincidono';

  @override
  String get appPasswordWarning =>
      'La password verrà usata per cifrare il database. Se la dimentichi, i dati non potranno essere recuperati.';

  @override
  String get appCreate => 'Crea';

  @override
  String get appStrengthVeryWeak => 'Molto debole';

  @override
  String get appStrengthWeak => 'Debole';

  @override
  String get appStrengthFair => 'Discreta';

  @override
  String get appStrengthGood => 'Buona';

  @override
  String get appStrengthStrong => 'Forte';

  @override
  String get appTagline => 'Piccolo outliner con monitoraggio del tempo';

  @override
  String get appAboutDescription =>
      'Un outliner desktop multipiattaforma per organizzare idee, attività e progetti, con monitoraggio del tempo integrato.';

  @override
  String get appBuiltWithFlutter => 'Realizzato con Flutter';

  @override
  String get appCheckForUpdateTitle => 'Verifica aggiornamenti';

  @override
  String appCouldNotOpen(String url) {
    return 'Impossibile aprire $url';
  }

  @override
  String get appOpenReleasePage => 'Apri pagina della release';

  @override
  String get appDownloadApk => 'Scarica APK';

  @override
  String get appDownloadDiskImage => 'Scarica immagine disco';

  @override
  String get appCheckingForUpdate => 'Ricerca di una nuova versione...';

  @override
  String get appUpdateCheckFailed => 'Verifica aggiornamenti non riuscita';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version è la versione più recente.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return 'È disponibile $appName $version (hai la $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return 'Download di $appName $version...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received di $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version è stato scaricato e verificato. L\'installazione chiude $appName, sostituisce i file del programma e lo riavvia. I tuoi database non vengono toccati.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version è installato. Riavvia per iniziare a usarlo.';
  }

  @override
  String get appLater => 'Più tardi';

  @override
  String get appInstall => 'Installa';

  @override
  String get appInstallAndRestart => 'Installa e riavvia';

  @override
  String get appRestartNow => 'Riavvia ora';

  @override
  String get appUpdGithubTimeout => 'GitHub non ha risposto in tempo';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'Impossibile raggiungere GitHub: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub ha risposto $status per la release più recente';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Dati della release inattesi: $error';
  }

  @override
  String get appUpdUnexpectedData => 'Dati della release inattesi';

  @override
  String get appUpdNoInPlace =>
      'Aggiornamento sul posto non disponibile su questa piattaforma';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'La release $version non ha un programma di installazione per Windows';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'La release $version non ha uno ZIP per Windows';
  }

  @override
  String appUpdCannotWrite(String path) {
    return 'Impossibile scrivere in $path; scarica la nuova versione manualmente';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName non contiene $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'Il download non è uno ZIP valido: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'Lo ZIP contiene un percorso non sicuro: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'Impossibile estrarre il download: $error';
  }

  @override
  String get appUpdNotAppImage => 'Non in esecuzione da un AppImage';

  @override
  String appUpdNoAppImage(String version) {
    return 'La release $version non ha un AppImage per Linux';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Impossibile rendere eseguibile il nuovo AppImage: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return 'Impossibile sostituire $path: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'Download non riuscito: il server ha risposto $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'Impossibile salvare il download: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'Download interrotto: $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'Il file scaricato non corrisponde al checksum pubblicato';

  @override
  String appUpdNoChecksums(String version) {
    return 'La release $version non pubblica checksum; scaricala manualmente';
  }

  @override
  String get appUpdChecksumTimeout => 'Timeout nel download dei checksum';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Download dei checksum non riuscito: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Download dei checksum non riuscito: il server ha risposto $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName non è elencato in $checksumsFile';
  }

  @override
  String get appLogCopied => 'Log dell\'app copiato negli appunti';

  @override
  String get appLogTitle => 'Log dell\'app';

  @override
  String get appLogSaveDialogTitle => 'Salva log dell\'app';

  @override
  String appSavedTo(String path) {
    return 'Salvato in $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Salvataggio non riuscito: $error';
  }

  @override
  String get appShare => 'Condividi';

  @override
  String get appClearLogTooltip => 'Cancella log';

  @override
  String get appClearLogButton => 'Cancella log';

  @override
  String get appSaveEllipsis => 'Salva...';

  @override
  String get appSearchHint => 'Cerca';

  @override
  String get appLogLevelAll => 'Tutto';

  @override
  String get appLogLevelWarnings => 'Avvisi ed errori';

  @override
  String get appLogLevelErrors => 'Errori';

  @override
  String get appLogEmpty => 'Non è stato ancora registrato nulla.';

  @override
  String get appLogNoMatch => 'Nessuna riga corrisponde.';

  @override
  String get appHistoryTitle => 'Cronologia modifiche';

  @override
  String get appHistoryFilter => 'Filtro: ';

  @override
  String appHistoryAll(int count) {
    return 'Tutto ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Attività ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'File ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Timeline ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Errore: $error';
  }

  @override
  String get appHistoryEmpty => 'Nessuna voce di cronologia trovata';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campi modificati',
      one: '1 campo modificato',
      zero: '0 campi modificati',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return '$shown di $total voci raggruppate ($changes modifiche di campo in totale)';
  }

  @override
  String get appHistoryOld => 'Prima:';

  @override
  String get appHistoryNew => 'Dopo:';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonSaveAs => 'Salva con nome...';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonRename => 'Rinomina';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get commonAdd => 'Aggiungi';

  @override
  String get commonOpen => 'Apri';

  @override
  String get commonCopy => 'Copia';

  @override
  String get commonApply => 'Applica';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonYes => 'Sì';

  @override
  String get commonNo => 'No';

  @override
  String get commonBrowse => 'Sfoglia...';

  @override
  String get commonError => 'Errore';

  @override
  String get commonShow => 'Mostra';

  @override
  String get commonHide => 'Nascondi';

  @override
  String get commonClear => 'Cancella';

  @override
  String get commonRefresh => 'Aggiorna';

  @override
  String get commonTest => 'Prova';

  @override
  String get commonDownload => 'Scarica';

  @override
  String get commonNone => 'Nessuno';

  @override
  String get commonSystemDefault => 'Predefinito di sistema';

  @override
  String get commonUntitled => 'Senza titolo';

  @override
  String get languageSystem => 'Lingua di sistema';

  @override
  String get editorImageNotAvailable => 'Immagine non disponibile';

  @override
  String get editorImageResize => 'Ridimensiona...';

  @override
  String get editorImageReplace => 'Sostituisci immagine...';

  @override
  String get editorImageSaveAs => 'Salva immagine con nome...';

  @override
  String get editorImageRemoveFromText => 'Rimuovi dal testo';

  @override
  String get editorImageRemoveFromTextHint => 'Mantiene il file negli allegati';

  @override
  String get editorImageDelete => 'Elimina immagine';

  @override
  String get editorImageDeleteHint => 'Elimina anche l\'allegato';

  @override
  String get editorImageKeptInOtherTask =>
      'Immagine rimossa dal testo. Il file appartiene a un\'altra attività ed è stato mantenuto lì.';

  @override
  String get editorResizeImageTitle => 'Ridimensiona immagine';

  @override
  String get editorResizeWidth => 'Larghezza';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$percent% di $natural px';
  }

  @override
  String get editorResizeOriginalSize => 'Dimensione originale';

  @override
  String get editorInsertImage => 'Inserisci immagine';

  @override
  String get editorReplaceImageDialogTitle => 'Sostituisci immagine';

  @override
  String get editorSaveImageDialogTitle => 'Salva immagine';

  @override
  String editorSavedFile(String name) {
    return 'Salvato: $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Allega file\n(tieni premuto per mostrare gli allegati)';

  @override
  String get editorAttachFileTooltip =>
      'Allega file\n(tieni premuto per mostrare o nascondere gli allegati)';

  @override
  String get editorStopRecording => 'Interrompi registrazione';

  @override
  String get editorRecordVoiceMemo => 'Registra memo vocale';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Registra memo vocale\n(tieni premuto per registrare senza trascrivere)';

  @override
  String editorAttachedOne(String name) {
    return 'Allegato $name';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Allegati $count file',
      one: 'Allegato 1 file',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Tipo di carattere';

  @override
  String get editorFontSize => 'Dimensione carattere';

  @override
  String get editorSizeLabel => 'Dimensione';

  @override
  String get editorSizeSmall => 'Piccolo';

  @override
  String get editorSizeLarge => 'Grande';

  @override
  String get editorSizeHuge => 'Enorme';

  @override
  String get editorStartTyping => 'Inizia a scrivere...';

  @override
  String get editorLinkedTaskGone => 'L\'attività collegata non esiste più.';

  @override
  String get editorRemoveFormatting => 'Rimuovi formattazione';

  @override
  String editorFormatAsTable(String separator) {
    return 'Formatta come tabella ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Disattiva a capo automatico';

  @override
  String get editorWordWrapOn => 'Attiva a capo automatico';

  @override
  String editorErrorMessage(String error) {
    return 'Errore: $error';
  }

  @override
  String get editorTaskNotFound => 'Attività non trovata';

  @override
  String get editorSelectTask => 'Seleziona un\'attività da modificare';

  @override
  String editorSaveFailed(String error) {
    return 'Impossibile salvare l\'attività: $error';
  }

  @override
  String get editorChangesMerged =>
      'Questa nota è stata modificata altrove mentre la stavi modificando. Le due modifiche sono state unite.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'Questa nota è stata modificata altrove mentre la stavi modificando. Il tuo testo è stato salvato; l\'altra versione è conservata come \"$copyTitle\".';
  }

  @override
  String get treeNewTask => 'Nuova attività (Ctrl+N)';

  @override
  String get treeNewChildTask => 'Nuova attività figlia (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Elimina attività';

  @override
  String get treeExpandAll => 'Espandi tutto';

  @override
  String get treeCollapseAll => 'Comprimi tutto';

  @override
  String get treeNoTasks => 'Ancora nessuna attività';

  @override
  String get treeCreateFirstTask => 'Crea la tua prima attività';

  @override
  String get treeTrackedHere => 'Il tempo viene monitorato su questa attività';

  @override
  String get treeTrackedInside =>
      'Il tempo viene monitorato su un\'attività interna';

  @override
  String get treeHiddenFromAgents =>
      'Nascosta agli agenti IA, insieme a tutto ciò che contiene';

  @override
  String get treeMoveUp => 'Sposta su';

  @override
  String get treeMoveDown => 'Sposta giù';

  @override
  String get treeMoveToParentLevel => 'Sposta al livello superiore';

  @override
  String get treeMoveUnderPrevious => 'Sposta sotto la precedente';

  @override
  String get treeAddChildTask => 'Aggiungi attività figlia';

  @override
  String get treeStartTracking => 'Avvia monitoraggio';

  @override
  String get treeStopTracking => 'Interrompi monitoraggio';

  @override
  String get treeTimeline => 'Timeline...';

  @override
  String get searchHint => 'Cerca attività...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count risultati',
      one: '1 risultato',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Nessuna corrispondenza';

  @override
  String get searchUntitled => '(senza titolo)';

  @override
  String get attachImageNotAvailable => 'Immagine non disponibile';

  @override
  String get attachTryAgain => 'Riprova';

  @override
  String get attachPlay => 'Riproduci';

  @override
  String get attachPause => 'Pausa';

  @override
  String attachLoadFailed(String error) {
    return 'Impossibile caricare gli allegati: $error';
  }

  @override
  String get attachNone => 'Nessun allegato';

  @override
  String get attachAddFile => 'Aggiungi file';

  @override
  String get attachNotDownloaded =>
      'Questo allegato non è ancora stato scaricato — sincronizza per ottenerlo';

  @override
  String get attachContentLoadFailed =>
      'Impossibile caricare il contenuto dell\'allegato';

  @override
  String get attachDownloading => 'Download dell\'allegato…';

  @override
  String get attachExportDialogTitle => 'Esporta allegato';

  @override
  String attachExported(String name) {
    return 'Esportato: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'Nessuna app può aprire $name';
  }

  @override
  String get attachImageInNoteTitle => 'L\'immagine è nella nota';

  @override
  String attachImageInNoteBody(String name) {
    return '\"$name\" è mostrato nella nota di questa attività, quindi non può essere eliminato da qui.\n\nFai clic sull\'immagine nella nota e scegli \"Elimina immagine\" per rimuovere sia l\'immagine sia il file, oppure \"Rimuovi dal testo\" per mantenere il file ed eliminarlo poi da qui.';
  }

  @override
  String get attachDeleteTitle => 'Eliminare l\'allegato?';

  @override
  String attachDeleteConfirm(String name) {
    return 'Vuoi davvero eliminare \"$name\"?';
  }

  @override
  String get attachRenameTitle => 'Rinomina allegato';

  @override
  String get attachFileName => 'Nome file';

  @override
  String get attachShowPreview => 'Mostra anteprima';

  @override
  String get attachHidePreview => 'Nascondi anteprima';

  @override
  String get attachShare => 'Condividi';

  @override
  String get attachExport => 'Esporta';

  @override
  String get attachTranscribe => 'Trascrivi';

  @override
  String get attachCannotPlay => 'Impossibile riprodurre questo file';

  @override
  String get attachPlaybackUnavailable => 'Riproduzione non disponibile';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '$minutes minuto',
    );
    return 'Registrazione interrotta al limite di $_temp0. Il memo è stato salvato.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '$minutes minuto',
    );
    return 'Raggiunto il limite di $_temp0';
  }

  @override
  String get voiceDismiss => 'Chiudi';

  @override
  String get voiceOpeningMic => 'Apertura del microfono…';

  @override
  String get voiceSaving => 'Salvataggio…';

  @override
  String get voiceSavedTranscribing => 'Salvato. Trascrizione…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Salvato. Trascrizione… $percent%';
  }

  @override
  String get voiceDiscard => 'Scarta';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceChooseModelFirst =>
      'Scegli prima un modello di trascrizione nelle Preferenze';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'Il modello $model non è ancora stato scaricato — vedi Preferenze';
  }

  @override
  String get voiceTranscribing => 'Trascrizione…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Trascrizione… $percent%';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Impossibile trascrivere: $error';
  }

  @override
  String get voiceNoSpeech => 'Nessun parlato trovato in questo memo';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Trascritto, ma la nota a cui appartiene non è aperta';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'La registrazione è stata scartata perché è stato aperto un altro database.';

  @override
  String get voiceMicPermissionRefused =>
      'L\'autorizzazione al microfono è stata negata';

  @override
  String voiceStartFailed(String error) {
    return 'Impossibile avviare la registrazione: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Registrazione non riuscita: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Impossibile completare la registrazione: $error';
  }

  @override
  String get voiceNoDatabase =>
      'Nessun database aperto, quindi il memo non è stato salvato';

  @override
  String voiceSaveFailed(String error) {
    return 'Impossibile salvare il memo: $error';
  }

  @override
  String get timeTimelineTitle => 'Timeline';

  @override
  String get timeStatsToday => 'Oggi:';

  @override
  String get timeStatsThisMonth => 'Questo mese:';

  @override
  String timeRecordingSince(String time) {
    return 'In registrazione dalle $time';
  }

  @override
  String get timeEndBeforeStart =>
      'L\'ora di fine deve essere successiva all\'ora di inizio';

  @override
  String get timeOverlaps => 'Si sovrappone a un intervallo esistente';

  @override
  String get timeAddIntervalTitle => 'Aggiungi intervallo di tempo';

  @override
  String get timeEditIntervalTitle => 'Modifica intervallo di tempo';

  @override
  String get timeStartTime => 'Inizio:';

  @override
  String get timeFinishTime => 'Fine:';

  @override
  String get timeDurationLabel => 'Durata:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ore',
      one: '$hours ora',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '$minutes minuto',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours ore',
      one: '$hours ora',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minuti',
      one: '$minutes minuto',
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
  String get timeAddEllipsis => 'Aggiungi...';

  @override
  String get timeNoRecords => 'Nessuna registrazione di tempo';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'ora';

  @override
  String get timeRemoveIntervalTitle => 'Rimuovere l\'intervallo?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Vuoi davvero rimuovere questo intervallo di tempo?';

  @override
  String get timeNotTracking => 'Nessun monitoraggio';

  @override
  String get timeStopTracking => 'Interrompi monitoraggio';

  @override
  String get timeStartTracking => 'Avvia monitoraggio';

  @override
  String get timeBackToFullWindow => 'Torna alla finestra completa';

  @override
  String get timeReportTitle => 'Report dei tempi';

  @override
  String get timeReportSaveTitle => 'Salva report dei tempi';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Impossibile generare il report: $error';
  }

  @override
  String get timeReportCopied => 'Report copiato negli appunti';

  @override
  String timeReportSavedTo(String path) {
    return 'Salvato in $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Salvataggio non riuscito: $error';
  }

  @override
  String get timeReportTasks => 'Attività';

  @override
  String get timeReportNoTasks => 'Nessuna attività disponibile.';

  @override
  String get timeReportClearSelection => 'Annulla selezione';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selezionate',
      one: '$count selezionata',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Includi discendenti';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Riporta anche il tempo delle attività figlie di ogni nodo selezionato.';

  @override
  String get timeReportDateRange => 'Intervallo di date';

  @override
  String timeReportFrom(String date) {
    return 'Da: $date';
  }

  @override
  String timeReportTo(String date) {
    return 'A: $date';
  }

  @override
  String get timeReportFormat => 'Formato';

  @override
  String get timeReportFormatTree => 'Albero (solo totali)';

  @override
  String get timeReportFormatTreeWithDays => 'Albero con dettaglio giornaliero';

  @override
  String get timeReportFormatFlat => 'Elenco semplice degli intervalli';

  @override
  String get timeReportShowEmpty => 'Mostra attività vuote';

  @override
  String get timeReportUntitled => '(senza titolo)';

  @override
  String get timeReportSelectTasks =>
      'Seleziona una o più attività per generare un report.';

  @override
  String get timeReportNoRecordsInPeriod =>
      'Nessuna registrazione di tempo nel periodo selezionato.';

  @override
  String get timeReportTextPeriod => 'Periodo:';

  @override
  String get timeReportTextTotal => 'Totale:';

  @override
  String get timeReportTextGenerated => 'Generato:';

  @override
  String get timeReportTextClipped =>
      'Le registrazioni a cavallo dei limiti del periodo sono troncate all\'intervallo.';

  @override
  String timeReportTextSelf(String duration) {
    return 'proprio: $duration';
  }

  @override
  String get timeReportTextOngoing => 'in corso';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrazioni',
      one: '1 registrazione',
    );
    return 'Totale: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Rigenera';

  @override
  String get timeReportShare => 'Condividi…';

  @override
  String get timeReportSave => 'Salva…';

  @override
  String get timeReportPresetToday => 'Oggi';

  @override
  String get timeReportPresetThisWeek => 'Questa settimana';

  @override
  String get timeReportPresetThisMonth => 'Questo mese';

  @override
  String get timeReportPresetLastMonth => 'Mese scorso';

  @override
  String get timeReportPresetThisYear => 'Quest\'anno';

  @override
  String get prefsTitle => 'Preferenze';

  @override
  String get prefsTabAppearance => 'Aspetto';

  @override
  String get prefsTabBehavior => 'Comportamento';

  @override
  String get prefsTabVoiceMemos => 'Memo vocali';

  @override
  String get prefsTabSync => 'Sincronizzazione';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => 'Lingua';

  @override
  String get prefsInterfaceLanguage => 'Interfaccia';

  @override
  String get prefsLanguageHint =>
      'Le traduzioni diverse dall\'inglese sono automatiche; le correzioni sono benvenute.';

  @override
  String get prefsGroupTheme => 'Tema';

  @override
  String get prefsThemeMode => 'Modalità';

  @override
  String get prefsThemeSystem => 'Sistema';

  @override
  String get prefsThemeLight => 'Chiaro';

  @override
  String get prefsThemeDark => 'Scuro';

  @override
  String get prefsGroupStyle => 'Stile';

  @override
  String get prefsGroupColour => 'Colore';

  @override
  String get prefsLook => 'Aspetto';

  @override
  String get prefsLookHint =>
      'Classico: angoli squadrati, pulsanti piatti con bordo, nessun effetto a onda, barre di scorrimento sempre visibili e una barra del titolo nel colore principale con il menu sotto.';

  @override
  String get prefsUiStyleModern => 'Moderno';

  @override
  String get prefsUiStyleClassic => 'Classico';

  @override
  String get prefsAccentColour => 'Colore principale';

  @override
  String get prefsAccentTeal => 'Verde acqua';

  @override
  String get prefsAccentBlue => 'Blu';

  @override
  String get prefsAccentIndigo => 'Indaco';

  @override
  String get prefsAccentPurple => 'Viola';

  @override
  String get prefsAccentPink => 'Rosa';

  @override
  String get prefsAccentRed => 'Rosso';

  @override
  String get prefsAccentOrange => 'Arancione';

  @override
  String get prefsAccentAmber => 'Ambra';

  @override
  String get prefsAccentGreen => 'Verde';

  @override
  String get prefsAccentGraphite => 'Grafite';

  @override
  String get prefsGroupWindow => 'Finestra';

  @override
  String get prefsSystemTitleBar => 'Usa la barra del titolo di sistema';

  @override
  String get prefsSystemTitleBarHint =>
      'Cornice, titolo e pulsanti della finestra come li disegna il desktop, con la barra dei menu sotto.';

  @override
  String get prefsGroupEditorFont =>
      'Carattere dell\'editor (il testo di una nota)';

  @override
  String get prefsGroupTreeFont => 'Carattere dell\'albero (la struttura)';

  @override
  String get prefsGroupInterfaceFont =>
      'Carattere dell\'interfaccia (menu e finestre di dialogo)';

  @override
  String get prefsFontFamily => 'Famiglia';

  @override
  String get prefsFontCustom => 'Personalizzato…';

  @override
  String get prefsCustomName => 'Nome personalizzato';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'es. $font';
  }

  @override
  String get prefsFontSize => 'Dimensione';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'Stile';

  @override
  String get prefsBold => 'Grassetto';

  @override
  String get prefsItalic => 'Corsivo';

  @override
  String get prefsPreview => 'Anteprima';

  @override
  String get prefsPreviewText =>
      'Ma la volpe, col suo balzo, ha raggiunto il quieto Fido.';

  @override
  String get prefsScale => 'Scala';

  @override
  String get prefsFontSansSerif => 'Sans Serif';

  @override
  String get prefsFontSerif => 'Serif';

  @override
  String get prefsFontMonospace => 'Monospace';

  @override
  String get prefsGroupTimeTracking => 'Monitoraggio del tempo';

  @override
  String get prefsEnableTimeTracking => 'Attiva monitoraggio del tempo';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Avvio/arresto del monitoraggio, timeline e report dei tempi. Disattivandolo vengono nascosti; il tempo registrato viene conservato';

  @override
  String get prefsShowSeconds => 'Mostra secondi';

  @override
  String get prefsShowSecondsHint => 'Mostra i secondi nelle durate';

  @override
  String get prefsMiniTracker => 'Mostra mini finestra durante il monitoraggio';

  @override
  String get prefsMiniTrackerHint =>
      'Mentre un cronometro è in corso, ridurre a icona la finestra la trasforma invece in un piccolo orologio sempre in primo piano';

  @override
  String get prefsGroupSaving => 'Salvataggio';

  @override
  String get prefsAutoSaveEvery => 'Salvataggio automatico ogni';

  @override
  String get prefsUnitSec => 's';

  @override
  String get prefsGroupEditor => 'Editor';

  @override
  String get prefsTabWidth => 'Larghezza tabulazione';

  @override
  String get prefsUnitSpaces => 'spazi';

  @override
  String get prefsTabAsSpaces => 'Inserisci tabulazioni come spazi';

  @override
  String get prefsTabAsSpacesHint =>
      'Premendo Tab vengono inseriti spazi invece di una tabulazione';

  @override
  String get prefsWordWrap => 'A capo automatico';

  @override
  String get prefsWordWrapHint =>
      'Disattivato: le righe lunghe proseguono e la nota scorre lateralmente (Shift + rotellina). Disponibile anche nel menu contestuale dell\'editor e nella barra di stato';

  @override
  String get prefsMonospaceOnly => 'Solo caratteri a spaziatura fissa';

  @override
  String get prefsMonospaceOnlyHint =>
      'Il menu Carattere della barra degli strumenti offre solo le famiglie a spaziatura fissa, così il testo da allineare resta allineato';

  @override
  String get prefsFloatingButtons => 'Pulsanti mobili';

  @override
  String get prefsFloatingButtonsHint =>
      'Allega file e Registra memo vocale sopra la nota; la barra degli strumenti mantiene comunque i propri pulsanti';

  @override
  String get prefsPaste => 'Incolla';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V incolla sempre testo semplice';

  @override
  String get prefsPasteKeep => 'Mantieni formattazione';

  @override
  String get prefsPasteStrip => 'Rimuovi colori e caratteri';

  @override
  String get prefsPastePlain => 'Solo testo semplice';

  @override
  String get prefsTableColumns => 'Colonne tabella';

  @override
  String get prefsTableColumnsHint =>
      'Il separatore su cui Formatta come tabella (menu contestuale dell\'editor) divide le colonne. Non all\'interno di URL o testo tra virgolette';

  @override
  String get prefsSeparatorColon => 'Due punti  ( : )';

  @override
  String get prefsSeparatorEquals => 'Segno di uguale  ( = )';

  @override
  String get prefsSeparatorPipe => 'Barra verticale  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Punto e virgola  ( ; )';

  @override
  String get prefsSeparatorComma => 'Virgola  ( , )';

  @override
  String get prefsSeparatorTab => 'Tab';

  @override
  String get prefsGroupToolbarButtons => 'Pulsanti della barra degli strumenti';

  @override
  String get prefsToolbarButtonsHint =>
      'Deseleziona un pulsante per toglierlo dalla barra degli strumenti dell\'editor.';

  @override
  String get prefsToolbarUndoRedo => 'Annulla / Ripeti';

  @override
  String get prefsToolbarFont => 'Carattere';

  @override
  String get prefsToolbarSize => 'Dimensione';

  @override
  String get prefsToolbarBold => 'Grassetto';

  @override
  String get prefsToolbarItalic => 'Corsivo';

  @override
  String get prefsToolbarUnderline => 'Sottolineato';

  @override
  String get prefsToolbarStrikeThrough => 'Barrato';

  @override
  String get prefsToolbarInlineCode => 'Codice';

  @override
  String get prefsToolbarTextColor => 'Colore testo';

  @override
  String get prefsToolbarHighlightColor => 'Colore evidenziazione';

  @override
  String get prefsToolbarClearFormat => 'Cancella formattazione';

  @override
  String get prefsToolbarHeadings => 'Titoli';

  @override
  String get prefsToolbarNumberedList => 'Elenco numerato';

  @override
  String get prefsToolbarBulletedList => 'Elenco puntato';

  @override
  String get prefsToolbarChecklist => 'Lista di controllo';

  @override
  String get prefsToolbarCodeBlock => 'Blocco di codice';

  @override
  String get prefsToolbarQuote => 'Citazione';

  @override
  String get prefsToolbarIndent => 'Rientro';

  @override
  String get prefsToolbarLink => 'Collegamento';

  @override
  String get prefsToolbarInsertImage => 'Inserisci immagine';

  @override
  String get prefsToolbarVoiceMemo => 'Memo vocale';

  @override
  String get prefsGroupSecurity => 'Sicurezza';

  @override
  String get prefsRememberPassword => 'Ricorda password';

  @override
  String get prefsRememberPasswordHint =>
      'Salva la password del database nel portachiavi di sistema';

  @override
  String get prefsBiometricUnlock => 'Sblocco biometrico';

  @override
  String get prefsBiometricUnavailableHint =>
      'Non disponibile — configura prima un\'impronta digitale o un blocco schermo nelle impostazioni di Android';

  @override
  String get prefsBiometricHint =>
      'Conferma impronta, volto o blocco schermo prima di usare la password memorizzata';

  @override
  String get prefsBlockScreenshots => 'Blocca screenshot';

  @override
  String get prefsBlockScreenshotsHint =>
      'Nascondi il contenuto dell\'app negli screenshot, nelle registrazioni dello schermo e nell\'elenco delle app recenti';

  @override
  String get prefsGroupStartup => 'Avvio';

  @override
  String get prefsSingleInstance => 'Istanza singola';

  @override
  String get prefsSingleInstanceHint =>
      'Consenti una sola finestra in esecuzione; un nuovo avvio porta in primo piano quella esistente. Ha effetto dal prossimo avvio.';

  @override
  String get prefsVoiceGroupDevices => 'Dispositivi';

  @override
  String get prefsVoiceMicrophone => 'Microfono';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Usato per i memo vocali e per la verifica qui sotto.';

  @override
  String get prefsVoiceSpeaker => 'Altoparlante';

  @override
  String get prefsVoiceSpeakerHint =>
      'Vale per i memo vocali. Gli altri allegati audio vengono riprodotti tramite il dispositivo predefinito di sistema.';

  @override
  String get prefsVoiceDevicesLooking => 'Ricerca…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'Impossibile elencare i dispositivi audio: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Non disponibile';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (predefinito)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (non collegato)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Trascrizione';

  @override
  String get prefsVoiceModel => 'Modello';

  @override
  String get prefsVoiceModelHintNone =>
      'I memo vengono registrati e salvati solo come audio.';

  @override
  String get prefsVoiceModelHintLocal =>
      'Viene eseguito su questo dispositivo. Non viene inviato nulla.';

  @override
  String get prefsVoiceModelOff => 'Disattivato';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · consigliato';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Trascrivi dopo la registrazione';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'Un memo viene prima salvato e poi trascritto dall\'audio salvato. Se disattivato viene salvato senza trascrizione; \"Trascrivi\" nel menu dell\'allegato funziona comunque in seguito.';

  @override
  String get prefsVoiceLanguage => 'Lingua';

  @override
  String get prefsVoiceLanguageAuto => 'Rileva automaticamente';

  @override
  String get prefsVoiceFooter =>
      'La registrazione funziona anche senza modello: i memo vengono sempre salvati come audio e si riproducono come qualsiasi altro allegato. Un modello aggiunge solo il testo.';

  @override
  String get prefsVoiceGroupCheck => 'Verifica';

  @override
  String get prefsVoiceCheckIntro =>
      'Registra qualche secondo, lo riproduce e lo trascrive, usando i dispositivi e il modello indicati sopra. Non viene salvato nulla.';

  @override
  String get prefsVoiceStop => 'Stop';

  @override
  String get prefsVoiceTestAgain => 'Riprova il test';

  @override
  String get prefsVoiceCheckRecording =>
      'Registrazione in corso — pronuncia una frase, poi premi Stop.';

  @override
  String get prefsVoiceCheckPlaying => 'Riproduzione…';

  @override
  String get prefsVoiceCheckTranscribing => 'Trascrizione…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Trascrizione… $percent%';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return 'Registrati $duration.';
  }

  @override
  String get prefsVoiceCheckFailed => 'La verifica non è stata completata.';

  @override
  String get prefsVoiceDownloading => 'Download…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$percent% di $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model è scaricato e pronto.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'Non scaricato — $size da HuggingFace.';
  }

  @override
  String get prefsCheckBusy =>
      'È in corso la registrazione di un memo vocale. Completala prima.';

  @override
  String get prefsCheckPermissionRefused =>
      'L\'autorizzazione al microfono è stata negata.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'Impossibile aprire il microfono: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Registrazione non riuscita: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'Impossibile completare la registrazione: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Non è stato registrato nulla. Prolunga un po\' il test o scegli un altro microfono.';

  @override
  String get prefsCheckMalformed =>
      'La registrazione è risultata danneggiata e non può essere riprodotta.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Riproduzione non riuscita: $error';
  }

  @override
  String get prefsCheckNoModel =>
      'Registrazione e riproduzione funzionano. Nessun modello è selezionato, quindi non c\'è nulla da trascrivere.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'Registrazione e riproduzione funzionano. $model non è ancora stato scaricato, quindi non è stato trascritto nulla.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Trascrizione non riuscita: $error';
  }

  @override
  String get prefsCheckSilence =>
      'Il microfono ha prodotto solo silenzio — l\'indicatore di livello non si è mai mosso. Verifica che sia selezionato il dispositivo giusto e che l\'app possa usarlo.';

  @override
  String get prefsCheckNoSpeech =>
      'Registrazione e riproduzione funzionano, ma whisper non ha trovato parlato. Prova a parlare più vicino al microfono o in un\'altra lingua.';

  @override
  String get prefsCheckQuiet =>
      'L\'indicatore di livello non si è mai mosso, quindi l\'ingresso è molto debole.';

  @override
  String get prefsDownloadCancelled => 'Download annullato.';

  @override
  String prefsDownloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get prefsUntitled => '(senza titolo)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Salvato solo per questa sessione: il portachiavi di sistema lo ha rifiutato. Se il portachiavi è bloccato, sbloccalo e premi Rigenera.';

  @override
  String get prefsMcpRegenerateTitle => 'Rigenerare il token?';

  @override
  String get prefsMcpRegenerateBody =>
      'Gli agenti configurati con il token attuale smetteranno di funzionare finché non incollerai quello nuovo nelle loro impostazioni.';

  @override
  String get prefsMcpRegenerate => 'Rigenera';

  @override
  String get prefsMcpGroupAccess => 'Accesso degli agenti';

  @override
  String get prefsMcpEnable => 'Attiva server MCP';

  @override
  String get prefsMcpEnableHint =>
      'Consenti agli agenti IA di programmazione locali di leggere questa struttura tramite 127.0.0.1. Disattivato per impostazione predefinita.';

  @override
  String get prefsMcpReadOnly => 'Sola lettura';

  @override
  String get prefsMcpReadOnlyHint =>
      'Gli agenti possono cercare e leggere le attività, ma non crearle, modificarle, spostarle o eliminarle.';

  @override
  String get prefsMcpGroupEndpoint => 'Endpoint';

  @override
  String get prefsMcpPort => 'Porta';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'Copia URL';

  @override
  String get prefsMcpToken => 'Token';

  @override
  String get prefsMcpTokenHint =>
      'Chiunque possa eseguire programmi con il tuo utente può usare questo token. Trattalo come una password.';

  @override
  String get prefsMcpNoTokenYet =>
      'Ancora nessun token — attiva il server per crearne uno';

  @override
  String get prefsMcpShowToken => 'Mostra token';

  @override
  String get prefsMcpHideToken => 'Nascondi token';

  @override
  String get prefsMcpCopyToken => 'Copia token';

  @override
  String get prefsMcpCopied => 'Copiato.';

  @override
  String get prefsMcpGroupExcluded => 'Rami esclusi';

  @override
  String get prefsMcpExcludedIntro =>
      'Attività nascoste al server MCP, insieme a tutto ciò che contengono.';

  @override
  String get prefsMcpLoading => 'Caricamento…';

  @override
  String get prefsMcpOutlineReadError => 'Impossibile leggere la struttura.';

  @override
  String get prefsMcpChoose => 'Scegli…';

  @override
  String get prefsMcpNothingExcluded =>
      'Nulla è escluso — gli agenti vedono l\'intera struttura.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'e altri $count',
      one: 'e $count altro',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'In ascolto su $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'La porta $port non è disponibile. Scegli un\'altra porta.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'Nessun token di accesso. Premi Rigenera per crearne uno.';

  @override
  String get prefsMcpWaitingDatabase =>
      'In attesa dell\'apertura di un database.';

  @override
  String get prefsMcpNotRunning => 'Non in esecuzione.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Ultima richiesta $time';
  }

  @override
  String get prefsMcpNoRequests => 'Ancora nessuna richiesta';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rifiutate (token errato o mancante)',
      one: '$count rifiutata (token errato o mancante)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<attiva prima il server>';

  @override
  String get prefsMcpGroupSetup => 'Configura il tuo agente';

  @override
  String get prefsMcpClient => 'Client';

  @override
  String get prefsMcpStdioBridge =>
      'Un agente che supporta solo stdio può fare da ponte con:';

  @override
  String get prefsMcpTargetTerminal => 'Esegui in un terminale:';

  @override
  String prefsMcpTargetFile(String file) {
    return 'Aggiungi a $file:';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Con ambito utente, così la struttura è disponibile in ogni progetto.';

  @override
  String get prefsMcpNoteCodex =>
      'Per tenere il token fuori dal file, sostituisci http_headers con bearer_token_env_var = \"NOO_MCP_TOKEN\" e imposta quella variabile nella tua shell.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false è importante — senza, OpenCode interpreta il 401 di questo server come un invito ad avviare una registrazione OAuth che non può completare.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'Un\'attività spuntata viene nascosta al server MCP insieme a tutto ciò che contiene — gli agenti non possono leggerla, modificarla né eliminare nulla che la contenga.';

  @override
  String get prefsMcpNoDatabase => 'Nessun database aperto.';

  @override
  String get prefsMcpNoTasks =>
      'Questa struttura non contiene ancora attività.';

  @override
  String get prefsMcpCollapse => 'Comprimi';

  @override
  String get prefsMcpExpand => 'Espandi';

  @override
  String get prefsMcpHiddenWithParent => 'nascosta con il genitore';

  @override
  String get syncGroupSynchronization => 'Sincronizzazione';

  @override
  String get syncEnable => 'Attiva sincronizzazione';

  @override
  String get syncEnableHint =>
      'Mantieni questo database sincronizzato con un server';

  @override
  String get syncGroupIdentity => 'Identità';

  @override
  String get syncNeedsUserName =>
      'Inserisci un nome utente per iniziare a sincronizzare. Senza, non si sincronizza nulla — con o senza server.';

  @override
  String get syncUserName => 'Nome utente';

  @override
  String get syncUserNameHint =>
      'Lo stesso su tutti i tuoi dispositivi. Insieme alla password del database deriva le chiavi di cifratura, quindi i dispositivi si sincronizzano solo se entrambi coincidono.';

  @override
  String get syncDeviceName => 'Nome dispositivo';

  @override
  String get syncDeviceNameHint =>
      'Come questo dispositivo si presenta ai dispositivi vicini';

  @override
  String get syncGroupServer => 'Server di sincronizzazione (facoltativo)';

  @override
  String get syncServerIntro =>
      'Lascia vuoto per sincronizzare solo con i dispositivi vicini sulla stessa rete. Un server permette inoltre ai dispositivi di sincronizzarsi quando sono lontani; conserva dati cifrati che non può leggere.';

  @override
  String get syncServerUrl => 'URL del server';

  @override
  String get syncServerPassword => 'Password';

  @override
  String get syncServerPasswordHint =>
      'La password del tuo account sul server. Non è la password del database e non viene mai usata come chiave di cifratura.';

  @override
  String get syncTestConnection => 'Prova connessione';

  @override
  String get syncRegister => 'Registrati';

  @override
  String get syncGroupSchedule => 'Pianificazione';

  @override
  String get syncScheduleNeedsServer =>
      'La sincronizzazione all\'avvio e all\'uscita richiede un server. I dispositivi sulla stessa rete si sincronizzano quando lo chiedi, da Strumenti → Sincronizza P2P...';

  @override
  String get syncAutosyncOnStart => 'Sincronizza all\'avvio';

  @override
  String get syncAutosyncOnStartHint =>
      'Sincronizza quando l\'app apre il database';

  @override
  String get syncCheckOnStart => 'Cerca modifiche in arrivo all\'avvio';

  @override
  String get syncCheckOnStartHint =>
      'Chiede al server se altri dispositivi hanno inviato modifiche, senza sincronizzare, e lo mostra sull\'icona di sincronizzazione. Non serve se Sincronizza all\'avvio è attivo';

  @override
  String get syncAskOnExit => 'Chiedi di sincronizzare all\'uscita';

  @override
  String get syncAskOnExitHint =>
      'Proponi di sincronizzare le modifiche in attesa prima della chiusura dell\'app';

  @override
  String get syncGroupServerStorage => 'Spazio sul server';

  @override
  String get syncGroupPeerToPeer => 'Peer-to-peer';

  @override
  String get syncPeerToPeerIntro =>
      'I dispositivi sulla stessa rete che condividono il tuo nome utente e la password del database possono sincronizzarsi direttamente, senza server. Apri Strumenti → Sincronizza P2P... su ciascuno: si trovano a vicenda e si sincronizzano finché quella finestra è aperta, e altrimenti non sono rilevabili.';

  @override
  String get syncStorageNoServer =>
      'In questa configurazione nulla viene salvato su un server. La sincronizzazione peer-to-peer conserva ogni pacchetto sui dispositivi stessi.';

  @override
  String get syncStorageIntro =>
      'Il server conserva ogni modifica cifrata mai effettuata, quindi la sua dimensione cresce con le modifiche e non con la dimensione della struttura.';

  @override
  String get syncStorageReading => 'Lettura…';

  @override
  String get syncStoragePressRefresh =>
      'Premi Aggiorna per leggere l\'utilizzo attuale.';

  @override
  String get syncStorageEmpty => 'Ancora nulla salvato sul server.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size in $count pacchetti',
      one: '$size in 1 pacchetto',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Contatori $first–$last';
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
      other: 'Contatori $first–$last, $snapshots snapshot',
      one: 'Contatori $first–$last, $snapshots snapshot',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Più $count allegati ($size), salvati una sola volta e condivisi da tutti i pacchetti che li referenziano.',
      one:
          'Più 1 allegato ($size), salvato una sola volta e condiviso da tutti i pacchetti che lo referenziano.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Questo dispositivo ne conserva $count in locale ($size).',
      one: 'Questo dispositivo ne conserva $count in locale ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Compatta i dati sul server';

  @override
  String get syncResetIdentity => 'Reimposta identità del dispositivo';

  @override
  String get syncNotConfiguredOnDevice =>
      'La sincronizzazione non è configurata su questo dispositivo.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Impossibile leggere lo spazio sul server: $error';
  }

  @override
  String get syncResetConfirm =>
      'Questo dispositivo inizierà a sincronizzarsi con una nuova identità, e la prossima sincronizzazione pubblicherà una copia completa del database attuale. Gli altri dispositivi la uniranno normalmente — non si perde nulla.\n\nFallo quando la sincronizzazione segnala che la cronologia di questo dispositivo è divergente, il che di solito significa che il database è stato ripristinato da un backup dopo essere già stato sincronizzato.\n\nLa vecchia identità continuerà a comparire nell’elenco dello spazio sul server finché non esegui la compattazione.';

  @override
  String get syncReset => 'Reimposta';

  @override
  String syncResetFailed(String error) {
    return 'Impossibile reimpostare l\'identità del dispositivo: $error';
  }

  @override
  String get syncCompactConfirm =>
      'Questo dispositivo eseguirà la sincronizzazione, poi caricherà uno snapshot dell\'intero database. Il server eliminerà quindi ogni modifica salvata già contenuta nello snapshot, e lo stesso farà ogni dispositivo quando riceverà lo snapshot.\n\nNote, tempi e allegati non vengono toccati — ciò che viene scartato è la registrazione delle singole modifiche passate precedenti allo snapshot.\n\nAggiorna prima Noo sugli altri dispositivi: una versione precedente non può leggere un flusso il cui inizio è stato rimosso.';

  @override
  String get syncCompact => 'Compatta';

  @override
  String get syncCompactFailed => 'Compattazione non riuscita.';

  @override
  String get syncCompactNothing => 'Ancora nulla da compattare.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liberati $size sul server ($count pacchetti)',
      one: 'Liberati $size sul server ($count pacchetto)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Snapshot caricato, ma questo server non supporta ancora la compattazione e ha mantenuto le sue copie';

  @override
  String get syncCompactRelayNothing =>
      'Snapshot caricato; il server non aveva più nulla da eliminare';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Questo dispositivo ha liberato $size ($count pacchetti)',
      one: 'Questo dispositivo ha liberato $size ($count pacchetto)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. Lo snapshot occupa $size.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. Lo snapshot occupa $size.';
  }

  @override
  String get syncTestSuccess => 'Riuscito: il server è raggiungibile';

  @override
  String get syncTestUnreachable => 'Errore: server non raggiungibile';

  @override
  String syncErrorWith(String error) {
    return 'Errore: $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Errore: nome utente e password obbligatori';

  @override
  String syncRegisterSuccess(String user) {
    return 'Riuscito: account \"$user\" creato. Impostazioni salvate.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Riuscito: account \"$user\" creato con spazio illimitato sul server. Impostazioni salvate.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Riuscito: account \"$user\" creato con $size di spazio sul server. Impostazioni salvate.';
  }

  @override
  String get syncStagePreparing => 'Preparazione';

  @override
  String get syncStageAuthenticating => 'Verifica delle credenziali';

  @override
  String get syncStagePushing => 'Invio delle modifiche';

  @override
  String get syncStageApplying => 'Applicazione delle modifiche';

  @override
  String get syncStatePending => 'In attesa';

  @override
  String get syncStateActive => 'In corso…';

  @override
  String get syncStateDone => 'Completato';

  @override
  String get syncStateSkipped => 'Saltato';

  @override
  String get syncStateFailed => 'Non riuscito';

  @override
  String get syncCancelling => 'Annullamento…';

  @override
  String get syncSynchronizing => 'Sincronizzazione…';

  @override
  String get syncCancelled => 'Sincronizzazione annullata';

  @override
  String get syncFailed => 'Sincronizzazione non riuscita';

  @override
  String get syncTitle => 'Sincronizzazione';

  @override
  String get syncComplete => 'Sincronizzazione completata';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get syncShowFullLogTooltip => 'Mostra log completo';

  @override
  String get syncShowFullLog => 'Mostra log completo';

  @override
  String get syncMoreSeeFullLog => 'vedi Mostra log completo';

  @override
  String get syncGroupProgress => 'Avanzamento';

  @override
  String get syncNoRunYet =>
      'Non è ancora stata eseguita alcuna sincronizzazione. Usa “Sincronizza ora” per sincronizzare; qui compariranno i dettagli dell\'ultima sincronizzazione.';

  @override
  String get syncCancelledNote =>
      'Interrotta su tua richiesta. Tutto ciò che è stato sincronizzato fino a quel momento viene mantenuto; la prossima sincronizzazione riprende da lì.';

  @override
  String get syncGroupSummary => 'Riepilogo';

  @override
  String get syncChangesPushed => 'Modifiche inviate';

  @override
  String get syncChangesApplied => 'Modifiche applicate';

  @override
  String get syncGroupApplied => 'Applicate — da altri dispositivi';

  @override
  String get syncGroupPushed => 'Inviate — da questo dispositivo';

  @override
  String get syncGroupLwwSkipped =>
      'Non applicate — questo dispositivo aveva già un valore più recente';

  @override
  String get syncGroupUnreadable => 'Impossibile leggere';

  @override
  String get syncLwwTieNote =>
      'I timestamp esattamente uguali vengono lasciati come sono su entrambi i dispositivi, quindi i due restano diversi. Modifica di nuovo l\'elemento sul dispositivo di cui vuoi mantenere la versione.';

  @override
  String get syncLwwOlderNote =>
      'Il valore in arrivo era più vecchio di quello di questo dispositivo, quindi non è stato scritto. Se avrebbe dovuto prevalere, verifica che gli orologi dei due dispositivi coincidano.';

  @override
  String get syncSkewSame => 'stesso timestamp';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'locale avanti di $seconds s',
      one: 'locale avanti di $seconds s',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'locale avanti di $minutes min $seconds s';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'locale avanti di $hours h $minutes min';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'locale avanti di $days giorni',
      one: 'locale avanti di $days giorno',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'in arrivo $incoming · locale $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage non riuscito  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'Questi pacchetti non hanno potuto essere decifrati: la password di questo database è diversa da quella del dispositivo che li ha scritti. La sincronizzazione non li riprova: fai coincidere le password, poi salva di nuovo gli elementi interessati sull\'altro dispositivo perché vengano reinviati.';

  @override
  String get syncSkippedUnreadableNote =>
      'Questi pacchetti non hanno potuto essere letti e la sincronizzazione li ha superati — le loro modifiche non arriveranno da sole. Salva di nuovo gli elementi interessati sull\'altro dispositivo per reinviarli.';

  @override
  String get syncP2pNotConfigured =>
      'La sincronizzazione non è configurata. Imposta prima un nome utente in Preferenze → Sincronizzazione.';

  @override
  String syncP2pStartFailed(String error) {
    return 'Impossibile avviare la sincronizzazione peer-to-peer: $error';
  }

  @override
  String get syncP2pStarting => 'Avvio...';

  @override
  String get syncP2pLooking => 'Ricerca di dispositivi su questa rete...';

  @override
  String get syncP2pIntro =>
      'Apri Sincronizza P2P... anche sull\'altro dispositivo. I dispositivi si sincronizzano appena si trovano; smettono di essere visibili quando questa finestra viene chiusa.';

  @override
  String get syncP2pTitle => 'Sincronizza P2P';

  @override
  String get syncP2pSyncAgain => 'Sincronizza di nuovo';

  @override
  String get syncP2pFound => 'Trovato — in attesa di sincronizzazione';

  @override
  String get syncP2pSyncing => 'Sincronizzazione...';

  @override
  String get syncP2pUpToDate => 'Sincronizzato — già aggiornato';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sincronizzato — $count modifiche ricevute',
      one: 'Sincronizzato — 1 modifica ricevuta',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Non riuscito — $error';
  }

  @override
  String get syncP2pUnknownError => 'errore sconosciuto';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return 'Ricevute da $device ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return 'Inviate a $device ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$used di $quota usati ($percent%)';
  }

  @override
  String get syncQuotaSemantics => 'Spazio usato sul server';

  @override
  String get syncQuotaFull =>
      'Pieno: il server rifiuta nuove modifiche finché non compatti o rimuovi allegati.';

  @override
  String get syncQuotaNearlyFull =>
      'Quasi pieno. La compattazione di solito ne libera la maggior parte.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'La sincronizzazione non è configurata. Apri prima le impostazioni di sincronizzazione.';

  @override
  String get syncNoServerConfigured =>
      'Nessun server di sincronizzazione configurato. Usa \"Sincronizza P2P...\" per la sincronizzazione locale oppure aggiungi un server in Preferenze → Sincronizzazione.';

  @override
  String get syncAlreadyInProgress => 'Sincronizzazione già in corso';

  @override
  String get syncAlreadyInProgressSentence =>
      'Una sincronizzazione è già in corso.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done di $totalText modifiche',
      one: '$done di $totalText modifica',
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
      other: '$countText modifiche · pacchetto $current di $packets',
      one: '$countText modifica · pacchetto $current di $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText modifiche',
      one: '$countText modifica',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · circa $seconds s rimanenti';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · circa $minutes min rimanenti';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Rilevata una biforcazione del flusso del dispositivo: un nodo remoto ha il contatore di pacchetti $remote per questo dispositivo, ma questo dispositivo è a $local e non può confermare che i due concordino su ciò che precede (database ripristinato da un backup?). Usa \"Reimposta identità del dispositivo\" in Preferenze → Sincronizzazione per riprendere la sincronizzazione.';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Il flusso del dispositivo è divergente al contatore di pacchetti $counter: questo dispositivo e $source hanno contenuti diversi con la stessa identità ($localHash qui contro $remoteHash là). Molto probabilmente questo database è stato ripristinato da un backup e ha riutilizzato numeri di pacchetto già pubblicati. Usa \"Reimposta identità del dispositivo\" in Preferenze → Sincronizzazione per riprendere la sincronizzazione; ripubblica questo database con una nuova identità e non si perde nulla.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'Al server manca parte della cronologia di questo dispositivo: si aspetta come prossimo il pacchetto #$expected, ma il primo pacchetto che questo dispositivo conserva è il #$local, e quelli intermedi non ci sono più (molto probabilmente il server è stato ripristinato da un backup più vecchio dopo che questo dispositivo ha eseguito la compattazione). Usa \"Reimposta identità del dispositivo\" in Preferenze → Sincronizzazione per riprendere la sincronizzazione; ripubblica questo database con una nuova identità e non si perde nulla.';
  }

  @override
  String get syncIdentityReset =>
      'Questo dispositivo ora si sincronizza con una nuova identità. La prossima sincronizzazione pubblica una copia completa del database attuale, che tutti gli altri dispositivi uniscono normalmente.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questo dispositivo ora si sincronizza con una nuova identità. La prossima sincronizzazione pubblica una copia completa del database attuale, che tutti gli altri dispositivi uniscono normalmente. Sono stati scartati $count pacchetti inutilizzabili.',
      one:
          'Questo dispositivo ora si sincronizza con una nuova identità. La prossima sincronizzazione pubblica una copia completa del database attuale, che tutti gli altri dispositivi uniscono normalmente. È stato scartato $count pacchetto inutilizzabile.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Derivazione della chiave di cifratura';

  @override
  String get syncDetailSignedIn => 'Accesso già effettuato';

  @override
  String get syncDetailPackaging => 'Preparazione delle modifiche locali';

  @override
  String get syncDetailRecovering =>
      'Recupero della cronologia di questo dispositivo';

  @override
  String get syncDetailUploading => 'Caricamento sul server';

  @override
  String get syncDetailNoLocalChanges => 'Nessuna modifica locale';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche inviate',
      one: '1 modifica inviata',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => 'Download delle modifiche remote';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allegati scaricati',
      one: '1 allegato scaricato',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count allegati ancora da scaricare',
      one: '1 allegato ancora da scaricare',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Già aggiornato';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche applicate',
      one: '1 modifica applicata',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'Annullato';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return 'L\'allegato \"$name\" non è ancora stato scaricato su questo dispositivo e una modifica fatta qui vi fa riferimento, quindi le modifiche di questo dispositivo non possono raggiungere il server finché non arriva — sincronizza di nuovo quando sarà arrivato, oppure sincronizza con un dispositivo vicino che lo possiede.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'Il server ha rifiutato l\'allegato \"$name\" ($size) perché troppo grande. Tutto il resto viene sincronizzato; l\'allegato raggiunge gli altri dispositivi solo tramite Sincronizza P2P.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'Il server ha rifiutato l\'allegato \"$name\" ($size) perché troppo grande (il limite è $limit). Tutto il resto viene sincronizzato; l\'allegato raggiunge gli altri dispositivi solo tramite Sincronizza P2P.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return 'L\'allegato \"$name\" ($size) non entra nel tuo spazio sul server. Tutto il resto viene sincronizzato; compatta i dati sul server o rimuovi allegati grandi per fare spazio, e fino ad allora l\'allegato raggiunge gli altri dispositivi solo tramite Sincronizza P2P.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return 'L\'allegato \"$name\" ($size) non entra nel tuo spazio sul server ($used di $quota usati). Tutto il resto viene sincronizzato; compatta i dati sul server o rimuovi allegati grandi per fare spazio, e fino ad allora l\'allegato raggiunge gli altri dispositivi solo tramite Sincronizza P2P.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count byte',
      one: '$count byte',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'Nessun server di sincronizzazione configurato. La compattazione pubblica uno snapshot sul relay; con la sola sincronizzazione tra dispositivi vicini non c\'è spazio sul relay da recuperare.';

  @override
  String get syncCompactStageSyncing =>
      'Sincronizzazione prima della compattazione';

  @override
  String get syncCompactStageChecking =>
      'Verifica che questo dispositivo sia aggiornato';

  @override
  String get syncCompactStagePackaging =>
      'Preparazione di uno snapshot dell\'intero database';

  @override
  String get syncCompactStageAttachments =>
      'Caricamento degli allegati a cui fa riferimento lo snapshot';

  @override
  String get syncCompactStageUploading => 'Caricamento dello snapshot';

  @override
  String get syncCompactStageReclaiming =>
      'Recupero dello spazio su questo dispositivo';

  @override
  String get syncCompactStageReadingUsage => 'Lettura dello spazio sul relay';

  @override
  String syncCompactNeedsSync(String error) {
    return 'La compattazione richiede prima una sincronizzazione completata: $error';
  }

  @override
  String get syncCompactDidNotFinish =>
      'La compattazione non è stata completata.';

  @override
  String get syncCompactRaced =>
      'Un\'altra sincronizzazione ha preparato i dati prima. Riprova la compattazione.';

  @override
  String get syncCompactSnapshotMissing =>
      'Lo snapshot è stato preparato ma non è presente nell\'archivio locale.';

  @override
  String get syncCompactMissingAttachments =>
      'A questo dispositivo mancano ancora alcuni allegati. Sincronizza finché tutti gli allegati non sono stati scaricati, poi compatta.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Il relay ha rifiutato lo snapshot: $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Compattazione non riuscita: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questo dispositivo non ha potuto leggere $count pacchetti ($packets), quindi il suo stato non è l\'unione di tutto ciò che c\'è nel log. La compattazione scarterebbe pacchetti che questo dispositivo non ha mai applicato.',
      one:
          'Questo dispositivo non ha potuto leggere $count pacchetto ($packets), quindi il suo stato non è l\'unione di tutto ciò che c\'è nel log. La compattazione scarterebbe pacchetti che questo dispositivo non ha mai applicato.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'Questo dispositivo ha ancora modifiche non sincronizzate. Sincronizza prima, poi compatta.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'A questo dispositivo mancano ancora alcuni allegati ($count da scaricare), quindi il suo snapshot non potrebbe fornirli e il server li eliminerebbe. Sincronizza finché tutti gli allegati non sono stati scaricati, poi compatta.',
      one:
          'A questo dispositivo mancano ancora alcuni allegati ($count da scaricare), quindi il suo snapshot non potrebbe fornirli e il server li eliminerebbe. Sincronizza finché tutti gli allegati non sono stati scaricati, poi compatta.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questo dispositivo non ha applicato tutto ciò che possiede per $count dispositivi. Sincronizza di nuovo, poi compatta.',
      one:
          'Questo dispositivo non ha applicato tutto ciò che possiede per $count dispositivo. Sincronizza di nuovo, poi compatta.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'La sola sincronizzazione tra dispositivi vicini non può garantire che un altro dispositivo conservi ancora un allegato eliminato, quindi nessuno è stato liberato.';

  @override
  String get syncCollectUnsynced =>
      'Questo dispositivo ha modifiche che il server non ha ancora salvato. Sincronizza prima, poi compatta.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Snapshot di $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count campi — l\'intero database',
      one: '$count campo — l\'intero database',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Nodo \"$name\"';
  }

  @override
  String syncSummaryFile(String name) {
    return 'File \"$name\"';
  }

  @override
  String get syncSummaryFileFallback => 'file';

  @override
  String get syncSummaryTimeChunk => 'Intervallo di tempo';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'rinominata in \"$title\"';
  }

  @override
  String get syncSummaryContentEdited => 'contenuto modificato';

  @override
  String get syncSummaryMoved => 'spostata';

  @override
  String get syncSummaryReordered => 'riordinato';

  @override
  String get syncSummaryFlagsChanged => 'flag modificati';

  @override
  String get syncSummaryRenamed => 'rinominato';

  @override
  String get syncSummaryContentUpdated => 'contenuto aggiornato';

  @override
  String syncSummaryFrom(String time) {
    return 'dalle $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'fino alle $time';
  }

  @override
  String get syncValueTopLevel => 'primo livello';

  @override
  String get syncStorageFull =>
      'Lo spazio sul server è pieno. Compatta i dati sul server (Preferenze → Sincronizzazione → Spazio sul server) o rimuovi allegati grandi; ciò che non è stato caricato resta su questo dispositivo.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'Lo spazio sul server è pieno ($used di $quota usati). Compatta i dati sul server (Preferenze → Sincronizzazione → Spazio sul server) o rimuovi allegati grandi; ciò che non è stato caricato resta su questo dispositivo.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'Il server rifiuta un ulteriore flusso di dispositivo per questo account: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'Il server ha esaurito lo spazio su disco. Non è andato perso nulla; sincronizza di nuovo più tardi.';

  @override
  String syncStorageRefused(String detail) {
    return 'Il server ha rifiutato di salvare altri dati: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'Questo server non accetta nuovi account: ha raggiunto il limite di account.';

  @override
  String get syncRegClosed =>
      'Questo server non accetta registrazioni. Chiedi un account al suo gestore.';

  @override
  String get syncRegTaken => 'Questo nome utente è già in uso.';

  @override
  String get syncRegInvalid =>
      'Il nome utente deve avere 3–50 caratteri e la password del server 8–128.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Oggi sono stati registrati troppi account da questa rete.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Oggi sono stati registrati troppi account da questa rete. Riprova tra $wait.';
  }

  @override
  String get syncRegTooManyAttempts => 'Troppi tentativi.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Troppi tentativi. Riprova tra $wait.';
  }

  @override
  String get syncRegBusy => 'Il server è occupato. Riprova tra poco.';

  @override
  String syncRegFailed(int status) {
    return 'Registrazione non riuscita (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Registrazione non riuscita (HTTP $status): $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondi',
      one: '$count secondo',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti',
      one: '$count minuto',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore',
      one: '$count ora',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return 'Nessuna risposta da $host entro ${seconds}s';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'La risposta da $host si è bloccata per ${seconds}s';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…e altri $count — $where',
      one: '…e $count altro — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'vedi il Log di sincronizzazione';

  @override
  String get traceAtTopLevel => 'al primo livello';

  @override
  String traceInPath(String path) {
    return 'in $path';
  }

  @override
  String get traceRowNew => '(nuovo)';

  @override
  String get traceRowRemoved => '(rimosso)';

  @override
  String get traceShowHowTooltip => 'Mostra come è avvenuta questa modifica';

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
  String get traceDecisionApplied => 'applicato';

  @override
  String get traceDecisionCreated => 'creato qui';

  @override
  String get traceDecisionConflictCopy =>
      'applicato — il valore sostituito è stato conservato come copia di conflitto';

  @override
  String get traceDecisionMerged =>
      'unito alla modifica fatta qui — entrambe le modifiche conservate';

  @override
  String get traceDecisionCycleToRoot =>
      'spostato al primo livello — il suo genitore avrebbe creato un ciclo';

  @override
  String get traceDecisionParentMissing =>
      'posto al primo livello finché non arriva il genitore';

  @override
  String get traceDecisionBlobPending =>
      'applicato — i byte dell\'allegato arrivano separatamente';

  @override
  String get traceDecisionSent => 'inviato';

  @override
  String get traceDecisionForwarded => 'inoltrato';

  @override
  String get traceRouteRelay => 'Scaricato dal relay.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Scaricato dal relay, che lo ha salvato $time.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Inoltrato da $peer tramite la rete locale — scritto da $author.';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Direttamente da $peer tramite la rete locale.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Già presente su questo dispositivo da uno scambio precedente; applicato in questo.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Già presente su questo dispositivo — ricevuto $time; applicato in questo.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Già presente su questo dispositivo — ricevuto $time da $source; applicato in questo.';
  }

  @override
  String get traceRoutePackagedUploaded =>
      'Preparato qui e caricato sul relay.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Preparato qui; il relay lo aveva già ricevuto per un\'altra via.';

  @override
  String get traceRoutePackagedBlocked =>
      'Preparato qui; non ancora caricato — un allegato necessario non è stato caricato.';

  @override
  String get traceRoutePackagedWaiting =>
      'Preparato qui; in attesa che il relay o un peer lo prenda.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Prelevato da $peer tramite la rete locale — inoltrato per conto di $author.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Prelevato da $peer tramite la rete locale.';
  }

  @override
  String get traceBlobDownloaded => 'scaricato ora';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'scaricato ora ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'scaricato ora da $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'scaricato ora da $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'non ancora scaricato — arriverà con una prossima sincronizzazione o all\'apertura';

  @override
  String get traceBlobHeld => 'già presente su questo dispositivo';

  @override
  String get traceBlobUploaded => 'caricato sul relay';

  @override
  String traceBlobUploadedSized(String size) {
    return 'caricato sul relay ($size)';
  }

  @override
  String get traceBlobOnRelay => 'il relay li aveva già';

  @override
  String get traceBlobOffered =>
      'su questo dispositivo, a disposizione degli altri';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'Uno snapshot di compattazione: l\'intero database di $device, in un solo pacchetto.';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Parte di uno snapshot completo da $device. Uno snapshot contiene l\'intero database dell\'autore; questo elemento è elencato perché qui era diverso.';
  }

  @override
  String get traceFieldsHeading => 'Campi';

  @override
  String traceTimeEdited(String time) {
    return 'modificato $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'loro $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'questo dispositivo $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Pacchetto $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Pacchetto $device #$counter (snapshot)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'scritto $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modifiche',
      one: '1 modifica',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Dispositivo autore $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'dal dispositivo $id';
  }

  @override
  String get traceCopyHashTooltip => 'Copia l\'hash del pacchetto';

  @override
  String get traceAttachmentBytesHeading => 'Byte dell\'allegato';

  @override
  String get traceShowInSyncLog => 'Mostra nel Log di sincronizzazione';

  @override
  String get traceTriggerRelay => 'Sincronizzazione con il server';

  @override
  String get traceTriggerCheck => 'Ricerca di modifiche in arrivo';

  @override
  String get traceTriggerLan => 'Dispositivi vicini';

  @override
  String get traceTriggerLanReturn => 'Dispositivo vicino (richiesta)';

  @override
  String get traceTriggerLanServe => 'Servito a un dispositivo vicino';

  @override
  String get traceTriggerPackage => 'Modifiche locali preparate';

  @override
  String get traceTriggerCompaction => 'Compattazione';

  @override
  String get traceTriggerIdentityReset =>
      'Reimpostazione identità del dispositivo';

  @override
  String get traceTriggerAttachment => 'Download di allegato';

  @override
  String get traceTriggerBlobCollect => 'Pulizia degli allegati';

  @override
  String get traceOutcomeRunning => 'in corso';

  @override
  String get traceOutcomeFailed => 'non riuscita';

  @override
  String get traceOutcomeDeclined => 'rifiutata';

  @override
  String get traceOutcomeBusy => 'occupato';

  @override
  String get traceOutcomeInterrupted => 'interrotta';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copiati $count eventi come JSON',
      one: 'Copiato $count evento come JSON',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Cancellare il log di sincronizzazione?';

  @override
  String get traceClearBody =>
      'Tutte le esecuzioni e gli eventi registrati su questo dispositivo vengono eliminati. I dati sincronizzati non vengono toccati.';

  @override
  String get traceTitle => 'Log di sincronizzazione';

  @override
  String get traceCopyAsJson => 'Copia come JSON';

  @override
  String get traceClearLogTooltip => 'Cancella log';

  @override
  String get traceClearLogButton => 'Cancella log';

  @override
  String traceSummaryApplied(int count) {
    return '$count applicate';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avvisi',
      one: '1 avviso',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errori',
      one: '1 errore',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Nulla scambiato';

  @override
  String get traceNoRuns =>
      'Non è ancora stata registrata alcuna sincronizzazione. Le esecuzioni compaiono qui quando questo dispositivo si sincronizza con il server o con dispositivi vicini.';

  @override
  String get traceAllRuns => 'Tutte le esecuzioni';

  @override
  String traceRunsRecorded(int count) {
    return '$count registrate';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'Tutte le esecuzioni ($count)';
  }

  @override
  String get traceRunLabel => 'Esecuzione';

  @override
  String get traceSearchHint =>
      'Cerca: nome del nodo, id, hash, dispositivo, tipo…';

  @override
  String get traceLevelAll => 'Tutti';

  @override
  String get traceLevelWarnings => 'Avvisi';

  @override
  String get traceLevelErrors => 'Errori';

  @override
  String get traceDirectionAll => 'In entrata e in uscita';

  @override
  String get traceDirectionIncoming => 'In entrata';

  @override
  String get traceDirectionOutgoing => 'In uscita';

  @override
  String get traceDirectionLocal => 'Locale';

  @override
  String get traceNoEvents => 'Nessun evento corrispondente.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vengono mostrati i primi $count eventi. Restringi la ricerca o scegli un\'esecuzione per vedere il resto.',
      one:
          'Viene mostrato il primo evento. Restringi la ricerca o scegli un\'esecuzione per vedere il resto.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Esecuzione #$id';
  }

  @override
  String get traceEmptyValue => '(vuoto)';

  @override
  String traceSubHash(String hash) {
    return 'hash $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'valore $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'remoto $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'locale $time';
  }

  @override
  String get traceDetailAt => 'Quando';

  @override
  String get traceDetailDirection => 'Direzione';

  @override
  String get traceDetailOriginDevice => 'Dispositivo di origine';

  @override
  String get traceDetailCounter => 'Contatore';

  @override
  String get traceDetailHash => 'Hash pacchetto / blob';

  @override
  String get traceDetailEntity => 'Entità';

  @override
  String get traceDetailWorldId => 'World id';

  @override
  String get traceDetailName => 'Nome';

  @override
  String get traceDetailField => 'Campo';

  @override
  String get traceDetailRemoteTs => 'Timestamp remoto';

  @override
  String get traceDetailLocalTs => 'Timestamp locale';

  @override
  String get traceDetailValueHash => 'Hash del valore';

  @override
  String get traceDetailValuePreview => 'Anteprima del valore';

  @override
  String get traceDetailMessage => 'Messaggio';

  @override
  String get traceDetailDetail => 'Dettaglio';
}
