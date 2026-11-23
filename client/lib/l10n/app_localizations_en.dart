// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appMenuFile => 'File';

  @override
  String get appMenuEdit => 'Edit';

  @override
  String get appMenuView => 'View';

  @override
  String get appMenuTools => 'Tools';

  @override
  String get appMenuDebug => 'Debug';

  @override
  String get appMenuHelp => 'Help';

  @override
  String get appMenuWindow => 'Window';

  @override
  String get appMenuOpen => 'Open...';

  @override
  String get appMenuOpenDatabase => 'Open Database...';

  @override
  String get appMenuNewDatabase => 'New Database...';

  @override
  String get appMenuExportObsidian => 'Export to Obsidian...';

  @override
  String get appMenuImportObsidian => 'Import from Obsidian...';

  @override
  String get appMenuExit => 'Exit';

  @override
  String get appMenuFind => 'Find...';

  @override
  String get appMenuTheme => 'Theme';

  @override
  String get appMenuThemeEllipsis => 'Theme...';

  @override
  String get appThemeSystem => 'System';

  @override
  String get appThemeLight => 'Light';

  @override
  String get appThemeDark => 'Dark';

  @override
  String get appMenuTimeline => 'Timeline...';

  @override
  String get appMenuTimeReport => 'Time Report...';

  @override
  String get appMenuCompactDatabase => 'Compact Database...';

  @override
  String get appMenuSyncNow => 'Sync Now';

  @override
  String get appMenuSyncP2p => 'Sync P2P...';

  @override
  String get appMenuPreferences => 'Preferences...';

  @override
  String get appMenuViewChangeHistory => 'View Change History...';

  @override
  String get appMenuGenerateTestData => 'Generate Test Data';

  @override
  String get appMenuGenerateLargeDataset => 'Generate Large Dataset';

  @override
  String get appMenuClearAllData => 'Clear All Data';

  @override
  String get appMenuCheckForUpdate => 'Check for Update...';

  @override
  String get appMenuLogs => 'Logs';

  @override
  String get appMenuSyncLog => 'Sync Log...';

  @override
  String get appMenuAppLog => 'App Log...';

  @override
  String appMenuAbout(String appName) {
    return 'About $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Check for Update…';

  @override
  String get appMacMenuSettings => 'Settings…';

  @override
  String appMacMenuQuit(String appName) {
    return 'Quit $appName';
  }

  @override
  String get appMacMenuOpen => 'Open…';

  @override
  String get appMacMenuNewDatabase => 'New Database…';

  @override
  String get appMacMenuExportObsidian => 'Export to Obsidian…';

  @override
  String get appMacMenuImportObsidian => 'Import from Obsidian…';

  @override
  String get appMacMenuUndo => 'Undo';

  @override
  String get appMacMenuRedo => 'Redo';

  @override
  String get appMacMenuCut => 'Cut';

  @override
  String get appMacMenuPaste => 'Paste';

  @override
  String get appMacMenuSelectAll => 'Select All';

  @override
  String get appMacMenuFind => 'Find…';

  @override
  String get appMacMenuTimeline => 'Timeline…';

  @override
  String get appMacMenuTimeReport => 'Time Report…';

  @override
  String get appMacMenuCompactDatabase => 'Compact Database…';

  @override
  String get appMacMenuSyncP2p => 'Sync P2P…';

  @override
  String get appMacMenuViewChangeHistory => 'View Change History…';

  @override
  String get appMacMenuSyncLog => 'Sync Log…';

  @override
  String get appMacMenuAppLog => 'App Log…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Open Database';

  @override
  String get appCreateDatabaseDialogTitle => 'Create New Database';

  @override
  String get appIncorrectPasswordRetry =>
      'Incorrect password. Please try again.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Opened: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Failed to open database: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Created: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Failed to create database: $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Open a database first';

  @override
  String get appNoDatabaseOpen => 'No database open';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Cannot read database file: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt =>
      'Incorrect password or corrupted database';

  @override
  String get appExportObsidianDialogTitle => 'Export to Obsidian Directory';

  @override
  String get appImportObsidianDialogTitle => 'Import from Obsidian Directory';

  @override
  String get appImportObsidianZipDialogTitle => 'Import Obsidian .zip';

  @override
  String get appExportingObsidian => 'Exporting to Obsidian format...';

  @override
  String get appImportingObsidian => 'Importing from Obsidian format...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count timeline files',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count time records',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Exported $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'Imported $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String appImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obsidian export ($count tasks)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'Directory does not exist: $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Sync not configured. Open Sync Settings first.';

  @override
  String get appNoSyncServer =>
      'No sync server configured. Use Sync P2P... (Shift+F5), or add a server in Preferences.';

  @override
  String get appUnsyncedChangesTitle => 'Unsynced changes';

  @override
  String get appUnsyncedChangesBody =>
      'There are unsynced changes; do you want to sync them?';

  @override
  String get appDontSync => 'Don\'t sync';

  @override
  String get appSync => 'Sync';

  @override
  String get appSelectTaskFirst => 'Select a task first';

  @override
  String get appGenerateTestDataBody =>
      'This will create sample tasks with hierarchy and time records.\n\nContinue?';

  @override
  String get appGenerate => 'Generate';

  @override
  String get appTestDataGenerated => 'Test data generated successfully';

  @override
  String get appGenerateLargeDatasetBody =>
      'This will create a large dataset with:\n- 20 top-level tasks\n- Up to 5 levels deep\n- Up to 6 children per task\n- Time records for many tasks\n\nThis may take a moment. Continue?';

  @override
  String get appGeneratingData => 'Generating data...';

  @override
  String get appLargeDatasetGenerated => 'Large dataset generated successfully';

  @override
  String get appClearAllDataBody =>
      'This will permanently delete all tasks, time records, and attachments.\n\nThis action cannot be undone. Are you sure?';

  @override
  String get appDeleteAll => 'Delete All';

  @override
  String get appAllDataCleared => 'All data cleared';

  @override
  String get appCompactDatabaseTitle => 'Compact Database';

  @override
  String get appCompactDatabaseBody =>
      'Rewrites the database file so the space held by deleted tasks, attachments and old change history is returned to the disk.\n\nThe contents of deleted attachments are released too, and are downloaded again from the server if you ever restore one.\n\nNothing you can still see is removed. On a large database this takes a while, and the app cannot be used until it finishes.';

  @override
  String get appCompact => 'Compact';

  @override
  String get appCompactingDatabase => 'Compacting database...';

  @override
  String appCompactingFailed(String error) {
    return 'Compacting failed: $error';
  }

  @override
  String get appDatabaseCompacted => 'Database compacted';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'Database compacted — $freed freed (now $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'Database compacted — already compact ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Find';

  @override
  String get appSyncNowTooltip => 'Sync now';

  @override
  String get appBiometricFailed =>
      'Biometric check failed. Please enter password.';

  @override
  String get appSavedPasswordIncorrect =>
      'Saved password is incorrect. Please enter password.';

  @override
  String get appLoading => 'Loading...';

  @override
  String get appFailedToOpenDatabaseTitle => 'Failed to Open Database';

  @override
  String get appOpenAnotherDatabase => 'Open another database…';

  @override
  String get appBiometricReason => 'Unlock your Noo database';

  @override
  String appWelcomeTitle(String appName) {
    return 'Welcome to $appName';
  }

  @override
  String get appWelcomeIntro =>
      'Choose where to store your encrypted database. You can change this later from the File menu.';

  @override
  String get appUseDefaultLocation => 'Use default location';

  @override
  String get appResolving => 'Resolving…';

  @override
  String get appCreateNewDatabaseOption => 'Create new database…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Pick a custom location for a new encrypted database.';

  @override
  String get appOpenExistingDatabaseOption => 'Open existing database…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Use an existing .noo file from another location.';

  @override
  String get appQuit => 'Quit';

  @override
  String get appWelcomeSyncHint =>
      'Already have a database on another device? Create a new one here with the same password, then set up sync in Preferences → Sync with the same user name — your notes will arrive with the first sync.';

  @override
  String get appTaskFallbackTitle => 'Task';

  @override
  String get appTabNotes => 'Notes';

  @override
  String get appTabTime => 'Time';

  @override
  String get appTabFiles => 'Files';

  @override
  String appTabFilesCount(int count) {
    return 'Files ($count)';
  }

  @override
  String get appStartTracking => 'Start tracking';

  @override
  String get appStopTracking => 'Stop tracking';

  @override
  String get appNoTaskSelected => 'No task selected.';

  @override
  String get appAttachmentsHeading => 'Attachments';

  @override
  String get appModified => 'Modified';

  @override
  String get appWordWrapOnTooltip => 'Word wrap is on — click to turn it off';

  @override
  String get appWordWrapOffTooltip => 'Word wrap is off — click to turn it on';

  @override
  String get appTimeTodayTap => 'Time tracked today — tap to open';

  @override
  String get appHideTimeTracking => 'Hide time tracking';

  @override
  String get appTimeTodayClick => 'Time tracked today — click for details';

  @override
  String get appViewTimeline => 'View timeline';

  @override
  String get appAttachmentsTap => 'Attachments — tap to open';

  @override
  String get appHideAttachments => 'Hide attachments';

  @override
  String get appAttachmentsClick => 'Attachments — click to show';

  @override
  String get appAddAttachment => 'Add attachment';

  @override
  String get appUntitledInPath => '(untitled)';

  @override
  String get appSyncStatusDisabled => 'Sync disabled — click to sync';

  @override
  String get appSyncStatusUnknown => 'Not synced yet — click to sync';

  @override
  String get appSyncStatusIdle => 'Synced — click to sync';

  @override
  String get appSyncStatusSyncing => 'Syncing...';

  @override
  String get appSyncStatusError => 'Sync error — click to retry';

  @override
  String get appSyncStatusPending => 'Pending changes — click to sync';

  @override
  String get appSyncStatusIncoming =>
      'Other devices have sent changes — click to sync';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Tracking time on \"$title\" — click to go to it';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Stop tracking \"$title\"';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String appPendingMore(int count) {
    return '+$count more';
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
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'Waiting to sync: $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'title';

  @override
  String get appPendingFieldContent => 'content';

  @override
  String get appPendingFieldMoved => 'moved';

  @override
  String get appPendingFieldReordered => 'reordered';

  @override
  String get appPendingFieldFlags => 'flags';

  @override
  String get appPendingFieldDeleted => 'deleted';

  @override
  String get appPendingFieldName => 'name';

  @override
  String get appPendingFieldStartTime => 'start time';

  @override
  String get appPendingFieldEndTime => 'end time';

  @override
  String get appJustNow => 'just now';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d ago',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Enter Password';

  @override
  String get appSetDatabasePasswordTitle => 'Set Database Password';

  @override
  String get appPasswordLabel => 'Password';

  @override
  String get appConfirmPasswordLabel => 'Confirm Password';

  @override
  String get appPleaseEnterPassword => 'Please enter a password';

  @override
  String get appPasswordTooShort => 'Password must be at least 4 characters';

  @override
  String get appPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get appPasswordWarning =>
      'The password will be used to encrypt your database. If you forget it, the data cannot be recovered.';

  @override
  String get appCreate => 'Create';

  @override
  String get appStrengthVeryWeak => 'Very weak';

  @override
  String get appStrengthWeak => 'Weak';

  @override
  String get appStrengthFair => 'Fair';

  @override
  String get appStrengthGood => 'Good';

  @override
  String get appStrengthStrong => 'Strong';

  @override
  String get appTagline => 'Tiny outliner with time tracking';

  @override
  String get appAboutDescription =>
      'A cross-platform desktop outliner application for organizing your thoughts, tasks, and projects with built-in time tracking.';

  @override
  String get appBuiltWithFlutter => 'Built with Flutter';

  @override
  String get appCheckForUpdateTitle => 'Check for Update';

  @override
  String appCouldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String get appOpenReleasePage => 'Open Release Page';

  @override
  String get appDownloadApk => 'Download APK';

  @override
  String get appDownloadDiskImage => 'Download Disk Image';

  @override
  String get appCheckingForUpdate => 'Checking for a new version...';

  @override
  String get appUpdateCheckFailed => 'Update check failed';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version is the latest version.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version is available (you have $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return 'Downloading $appName $version...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received of $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version is downloaded and verified. Installing it closes $appName, replaces the program files and starts it again. Your databases are not touched.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version is installed. Restart to start using it.';
  }

  @override
  String get appLater => 'Later';

  @override
  String get appInstall => 'Install';

  @override
  String get appInstallAndRestart => 'Install and Restart';

  @override
  String get appRestartNow => 'Restart Now';

  @override
  String get appUpdGithubTimeout => 'GitHub did not answer in time';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'Cannot reach GitHub: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub answered $status for the latest release';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Unexpected release data: $error';
  }

  @override
  String get appUpdUnexpectedData => 'Unexpected release data';

  @override
  String get appUpdNoInPlace => 'No in-place update on this platform';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'Release $version has no Windows installer';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'Release $version has no Windows ZIP';
  }

  @override
  String appUpdCannotWrite(String path) {
    return 'Cannot write to $path; download the new version manually';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName does not contain $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'The download is not a valid ZIP: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'The ZIP holds an unsafe path: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'Cannot unpack the download: $error';
  }

  @override
  String get appUpdNotAppImage => 'Not running from an AppImage';

  @override
  String appUpdNoAppImage(String version) {
    return 'Release $version has no Linux AppImage';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Cannot make the new AppImage executable: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return 'Cannot replace $path: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'Download failed: server answered $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'Cannot save the download: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'Download interrupted: $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'The downloaded file does not match its published checksum';

  @override
  String appUpdNoChecksums(String version) {
    return 'Release $version publishes no checksums; download it manually';
  }

  @override
  String get appUpdChecksumTimeout => 'Checksum download timed out';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Checksum download failed: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Checksum download failed: server answered $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName is not listed in $checksumsFile';
  }

  @override
  String get appLogCopied => 'App log copied to clipboard';

  @override
  String get appLogTitle => 'App Log';

  @override
  String get appLogSaveDialogTitle => 'Save App Log';

  @override
  String appSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get appShare => 'Share';

  @override
  String get appClearLogTooltip => 'Clear log';

  @override
  String get appClearLogButton => 'Clear Log';

  @override
  String get appSaveEllipsis => 'Save...';

  @override
  String get appSearchHint => 'Search';

  @override
  String get appLogLevelAll => 'All';

  @override
  String get appLogLevelWarnings => 'Warnings and errors';

  @override
  String get appLogLevelErrors => 'Errors';

  @override
  String get appLogEmpty => 'Nothing has been logged yet.';

  @override
  String get appLogNoMatch => 'No lines match.';

  @override
  String get appHistoryTitle => 'Change History';

  @override
  String get appHistoryFilter => 'Filter: ';

  @override
  String appHistoryAll(int count) {
    return 'All ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Tasks ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'Files ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Timeline ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Error: $error';
  }

  @override
  String get appHistoryEmpty => 'No history entries found';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields changed',
      one: '1 field changed',
      zero: '0 field changed',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return 'Showing $shown of $total grouped entries ($changes total field changes)';
  }

  @override
  String get appHistoryOld => 'Old:';

  @override
  String get appHistoryNew => 'New:';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveAs => 'Save as...';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonBrowse => 'Browse...';

  @override
  String get commonError => 'Error';

  @override
  String get commonShow => 'Show';

  @override
  String get commonHide => 'Hide';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonTest => 'Test';

  @override
  String get commonDownload => 'Download';

  @override
  String get commonNone => 'None';

  @override
  String get commonSystemDefault => 'System default';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get languageSystem => 'System default';

  @override
  String get editorImageNotAvailable => 'Image not available';

  @override
  String get editorImageResize => 'Resize...';

  @override
  String get editorImageReplace => 'Replace image...';

  @override
  String get editorImageSaveAs => 'Save image as...';

  @override
  String get editorImageRemoveFromText => 'Remove from text';

  @override
  String get editorImageRemoveFromTextHint => 'Keeps the file in Attachments';

  @override
  String get editorImageDelete => 'Delete image';

  @override
  String get editorImageDeleteHint => 'Also deletes the attachment';

  @override
  String get editorImageKeptInOtherTask =>
      'Image removed from the text. The file belongs to another task and was kept there.';

  @override
  String get editorResizeImageTitle => 'Resize image';

  @override
  String get editorResizeWidth => 'Width';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$percent% of $natural px';
  }

  @override
  String get editorResizeOriginalSize => 'Original size';

  @override
  String get editorInsertImage => 'Insert image';

  @override
  String get editorReplaceImageDialogTitle => 'Replace image';

  @override
  String get editorSaveImageDialogTitle => 'Save image';

  @override
  String editorSavedFile(String name) {
    return 'Saved: $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Attach file\n(long-press to show attachments)';

  @override
  String get editorAttachFileTooltip =>
      'Attach file\n(long-press to show or hide attachments)';

  @override
  String get editorStopRecording => 'Stop recording';

  @override
  String get editorRecordVoiceMemo => 'Record voice memo';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Record voice memo\n(long-press to record without transcribing)';

  @override
  String editorAttachedOne(String name) {
    return 'Attached $name';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Attached $count files',
      one: 'Attached 1 file',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Font family';

  @override
  String get editorFontSize => 'Font size';

  @override
  String get editorSizeLabel => 'Size';

  @override
  String get editorSizeSmall => 'Small';

  @override
  String get editorSizeLarge => 'Large';

  @override
  String get editorSizeHuge => 'Huge';

  @override
  String get editorStartTyping => 'Start typing...';

  @override
  String get editorLinkedTaskGone => 'The linked task no longer exists.';

  @override
  String get editorRemoveFormatting => 'Remove formatting';

  @override
  String editorFormatAsTable(String separator) {
    return 'Format as table ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Turn word wrap off';

  @override
  String get editorWordWrapOn => 'Turn word wrap on';

  @override
  String editorErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get editorTaskNotFound => 'Task not found';

  @override
  String get editorSelectTask => 'Select a task to edit';

  @override
  String editorSaveFailed(String error) {
    return 'Failed to save task: $error';
  }

  @override
  String get editorChangesMerged =>
      'This note was changed elsewhere while you were editing it. Both changes were merged.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'This note was changed elsewhere while you were editing it. Your text was saved; the other version is kept as \"$copyTitle\".';
  }

  @override
  String get treeNewTask => 'New task (Ctrl+N)';

  @override
  String get treeNewChildTask => 'New child task (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Delete task';

  @override
  String get treeExpandAll => 'Expand all';

  @override
  String get treeCollapseAll => 'Collapse all';

  @override
  String get treeNoTasks => 'No tasks yet';

  @override
  String get treeCreateFirstTask => 'Create your first task';

  @override
  String get treeTrackedHere => 'Time is being tracked on this task';

  @override
  String get treeTrackedInside => 'Time is being tracked on a task inside';

  @override
  String get treeHiddenFromAgents =>
      'Hidden from AI agents, including everything under it';

  @override
  String get treeMoveUp => 'Move up';

  @override
  String get treeMoveDown => 'Move down';

  @override
  String get treeMoveToParentLevel => 'Move to parent level';

  @override
  String get treeMoveUnderPrevious => 'Move under previous';

  @override
  String get treeAddChildTask => 'Add child task';

  @override
  String get treeStartTracking => 'Start tracking';

  @override
  String get treeStopTracking => 'Stop tracking';

  @override
  String get treeTimeline => 'Timeline...';

  @override
  String get searchHint => 'Search tasks...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'No matches';

  @override
  String get searchUntitled => '(untitled)';

  @override
  String get attachImageNotAvailable => 'Image not available';

  @override
  String get attachTryAgain => 'Try again';

  @override
  String get attachPlay => 'Play';

  @override
  String get attachPause => 'Pause';

  @override
  String attachLoadFailed(String error) {
    return 'Failed to load attachments: $error';
  }

  @override
  String get attachNone => 'No attachments';

  @override
  String get attachAddFile => 'Add file';

  @override
  String get attachNotDownloaded =>
      'This attachment has not been downloaded yet — sync to fetch it';

  @override
  String get attachContentLoadFailed => 'Failed to load attachment content';

  @override
  String get attachDownloading => 'Downloading attachment…';

  @override
  String get attachExportDialogTitle => 'Export attachment';

  @override
  String attachExported(String name) {
    return 'Exported: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'No app can open $name';
  }

  @override
  String get attachImageInNoteTitle => 'Image is in the note';

  @override
  String attachImageInNoteBody(String name) {
    return '\"$name\" is shown in this task\'s note, so it cannot be deleted from here.\n\nClick the image in the note and choose \"Delete image\" to remove both the picture and the file, or \"Remove from text\" to keep the file and delete it here afterwards.';
  }

  @override
  String get attachDeleteTitle => 'Delete attachment?';

  @override
  String attachDeleteConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get attachRenameTitle => 'Rename attachment';

  @override
  String get attachFileName => 'File name';

  @override
  String get attachShowPreview => 'Show preview';

  @override
  String get attachHidePreview => 'Hide preview';

  @override
  String get attachShare => 'Share';

  @override
  String get attachExport => 'Export';

  @override
  String get attachTranscribe => 'Transcribe';

  @override
  String get attachCannotPlay => 'Cannot play this file';

  @override
  String get attachPlaybackUnavailable => 'Playback is unavailable';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minute',
    );
    return 'Recording stopped at the $_temp0 limit. The memo was saved.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minute',
    );
    return 'Reached the $_temp0 limit';
  }

  @override
  String get voiceDismiss => 'Dismiss';

  @override
  String get voiceOpeningMic => 'Opening the microphone…';

  @override
  String get voiceSaving => 'Saving…';

  @override
  String get voiceSavedTranscribing => 'Saved. Transcribing…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Saved. Transcribing… $percent%';
  }

  @override
  String get voiceDiscard => 'Discard';

  @override
  String get voiceStop => 'Stop';

  @override
  String get voiceChooseModelFirst =>
      'Choose a transcription model in Preferences first';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'The $model model has not been downloaded yet — see Preferences';
  }

  @override
  String get voiceTranscribing => 'Transcribing…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Transcribing… $percent%';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Could not transcribe: $error';
  }

  @override
  String get voiceNoSpeech => 'No speech found in this memo';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Transcribed, but the note it belongs to is not open';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'The recording was discarded because another database was opened.';

  @override
  String get voiceMicPermissionRefused => 'Microphone permission was refused';

  @override
  String voiceStartFailed(String error) {
    return 'Could not start recording: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Recording failed: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Could not finish the recording: $error';
  }

  @override
  String get voiceNoDatabase =>
      'No database is open, so the memo could not be saved';

  @override
  String voiceSaveFailed(String error) {
    return 'Could not save the memo: $error';
  }

  @override
  String get timeTimelineTitle => 'Timeline';

  @override
  String get timeStatsToday => 'Today:';

  @override
  String get timeStatsThisMonth => 'This month:';

  @override
  String timeRecordingSince(String time) {
    return 'Recording since $time';
  }

  @override
  String get timeEndBeforeStart => 'End time must be after start time';

  @override
  String get timeOverlaps => 'Overlaps with an existing interval';

  @override
  String get timeAddIntervalTitle => 'Add Time Interval';

  @override
  String get timeEditIntervalTitle => 'Edit Time Interval';

  @override
  String get timeStartTime => 'Start time:';

  @override
  String get timeFinishTime => 'Finish time:';

  @override
  String get timeDurationLabel => 'Duration:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String timeShortHours(int hours) {
    return '${hours}h';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get timeAddEllipsis => 'Add...';

  @override
  String get timeNoRecords => 'No time records';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'now';

  @override
  String get timeRemoveIntervalTitle => 'Remove interval?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Are you sure you want to remove this time interval?';

  @override
  String get timeNotTracking => 'Not tracking';

  @override
  String get timeStopTracking => 'Stop tracking';

  @override
  String get timeStartTracking => 'Start tracking';

  @override
  String get timeBackToFullWindow => 'Back to the full window';

  @override
  String get timeReportTitle => 'Time Report';

  @override
  String get timeReportSaveTitle => 'Save Time Report';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Failed to generate report: $error';
  }

  @override
  String get timeReportCopied => 'Report copied to clipboard';

  @override
  String timeReportSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get timeReportTasks => 'Tasks';

  @override
  String get timeReportNoTasks => 'No tasks available.';

  @override
  String get timeReportClearSelection => 'Clear selection';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Include descendants';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Also report time from child tasks of each selected node.';

  @override
  String get timeReportDateRange => 'Date range';

  @override
  String timeReportFrom(String date) {
    return 'From: $date';
  }

  @override
  String timeReportTo(String date) {
    return 'To: $date';
  }

  @override
  String get timeReportFormat => 'Format';

  @override
  String get timeReportFormatTree => 'Tree (totals only)';

  @override
  String get timeReportFormatTreeWithDays => 'Tree with per-day breakdown';

  @override
  String get timeReportFormatFlat => 'Flat interval list';

  @override
  String get timeReportShowEmpty => 'Show empty tasks';

  @override
  String get timeReportUntitled => '(untitled)';

  @override
  String get timeReportSelectTasks =>
      'Select one or more tasks to generate a report.';

  @override
  String get timeReportNoRecordsInPeriod =>
      'No time records in the selected period.';

  @override
  String get timeReportTextPeriod => 'Period:';

  @override
  String get timeReportTextTotal => 'Total:';

  @override
  String get timeReportTextGenerated => 'Generated:';

  @override
  String get timeReportTextClipped =>
      'Records that straddle the period boundaries are clipped to the range.';

  @override
  String timeReportTextSelf(String duration) {
    return 'self: $duration';
  }

  @override
  String get timeReportTextOngoing => 'ongoing';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return 'Total: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Regenerate';

  @override
  String get timeReportShare => 'Share…';

  @override
  String get timeReportSave => 'Save…';

  @override
  String get timeReportPresetToday => 'Today';

  @override
  String get timeReportPresetThisWeek => 'This week';

  @override
  String get timeReportPresetThisMonth => 'This month';

  @override
  String get timeReportPresetLastMonth => 'Last month';

  @override
  String get timeReportPresetThisYear => 'This year';

  @override
  String get prefsTitle => 'Preferences';

  @override
  String get prefsTabAppearance => 'Appearance';

  @override
  String get prefsTabBehavior => 'Behavior';

  @override
  String get prefsTabVoiceMemos => 'Voice memos';

  @override
  String get prefsTabSync => 'Sync';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => 'Language';

  @override
  String get prefsInterfaceLanguage => 'Interface';

  @override
  String get prefsLanguageHint =>
      'Translations other than English are machine-made; corrections are welcome.';

  @override
  String get prefsGroupTheme => 'Theme';

  @override
  String get prefsThemeMode => 'Mode';

  @override
  String get prefsThemeSystem => 'System';

  @override
  String get prefsThemeLight => 'Light';

  @override
  String get prefsThemeDark => 'Dark';

  @override
  String get prefsGroupStyle => 'Style';

  @override
  String get prefsGroupColour => 'Colour';

  @override
  String get prefsLook => 'Look';

  @override
  String get prefsLookHint =>
      'Classic: square corners, flat bordered buttons, no ripples, scrollbars always shown, and a title bar in the accent colour with the menu beneath it.';

  @override
  String get prefsUiStyleModern => 'Modern';

  @override
  String get prefsUiStyleClassic => 'Classic';

  @override
  String get prefsAccentColour => 'Accent colour';

  @override
  String get prefsAccentTeal => 'Teal';

  @override
  String get prefsAccentBlue => 'Blue';

  @override
  String get prefsAccentIndigo => 'Indigo';

  @override
  String get prefsAccentPurple => 'Purple';

  @override
  String get prefsAccentPink => 'Pink';

  @override
  String get prefsAccentRed => 'Red';

  @override
  String get prefsAccentOrange => 'Orange';

  @override
  String get prefsAccentAmber => 'Amber';

  @override
  String get prefsAccentGreen => 'Green';

  @override
  String get prefsAccentGraphite => 'Graphite';

  @override
  String get prefsGroupWindow => 'Window';

  @override
  String get prefsSystemTitleBar => 'Use the system title bar';

  @override
  String get prefsSystemTitleBarHint =>
      'The window frame, title and buttons as the desktop draws them, with the menu bar beneath.';

  @override
  String get prefsGroupEditorFont => 'Editor font (the text of a note)';

  @override
  String get prefsGroupTreeFont => 'Tree font (the outline)';

  @override
  String get prefsGroupInterfaceFont => 'Interface font (menus & dialogs)';

  @override
  String get prefsFontFamily => 'Family';

  @override
  String get prefsFontCustom => 'Custom…';

  @override
  String get prefsCustomName => 'Custom name';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'e.g. $font';
  }

  @override
  String get prefsFontSize => 'Size';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'Style';

  @override
  String get prefsBold => 'Bold';

  @override
  String get prefsItalic => 'Italic';

  @override
  String get prefsPreview => 'Preview';

  @override
  String get prefsPreviewText => 'The quick brown fox jumps over the lazy dog.';

  @override
  String get prefsScale => 'Scale';

  @override
  String get prefsFontSansSerif => 'Sans Serif';

  @override
  String get prefsFontSerif => 'Serif';

  @override
  String get prefsFontMonospace => 'Monospace';

  @override
  String get prefsGroupTimeTracking => 'Time tracking';

  @override
  String get prefsEnableTimeTracking => 'Enable time tracking';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Start/stop tracking, timelines and time reports. Turning it off hides them; recorded time is kept';

  @override
  String get prefsShowSeconds => 'Show seconds';

  @override
  String get prefsShowSecondsHint => 'Display seconds in time durations';

  @override
  String get prefsMiniTracker => 'Show mini window while tracking';

  @override
  String get prefsMiniTrackerHint =>
      'While a clock runs, minimizing the window shrinks it to a small always-on-top clock instead';

  @override
  String get prefsGroupSaving => 'Saving';

  @override
  String get prefsAutoSaveEvery => 'Auto-save every';

  @override
  String get prefsUnitSec => 'sec';

  @override
  String get prefsGroupEditor => 'Editor';

  @override
  String get prefsTabWidth => 'Tab width';

  @override
  String get prefsUnitSpaces => 'spaces';

  @override
  String get prefsTabAsSpaces => 'Insert tabs as spaces';

  @override
  String get prefsTabAsSpacesHint =>
      'Pressing Tab inserts spaces instead of a tab';

  @override
  String get prefsWordWrap => 'Word wrap';

  @override
  String get prefsWordWrapHint =>
      'Off: long lines run on and the note scrolls sideways (Shift + wheel). Also in the editor\'s context menu and the status bar';

  @override
  String get prefsMonospaceOnly => 'Monospace fonts only';

  @override
  String get prefsMonospaceOnlyHint =>
      'The toolbar\'s Font menu offers only the fixed-width family, so text meant to line up stays lined up';

  @override
  String get prefsFloatingButtons => 'Floating buttons';

  @override
  String get prefsFloatingButtonsHint =>
      'Attach file and Record voice memo over the note; the toolbar keeps its own buttons either way';

  @override
  String get prefsPaste => 'Paste';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V always pastes plain text';

  @override
  String get prefsPasteKeep => 'Keep formatting';

  @override
  String get prefsPasteStrip => 'Remove colours and fonts';

  @override
  String get prefsPastePlain => 'Plain text only';

  @override
  String get prefsTableColumns => 'Table columns';

  @override
  String get prefsTableColumnsHint =>
      'What Format as table (editor context menu) splits columns on. Not inside URLs or quoted text';

  @override
  String get prefsSeparatorColon => 'Colon  ( : )';

  @override
  String get prefsSeparatorEquals => 'Equals sign  ( = )';

  @override
  String get prefsSeparatorPipe => 'Vertical bar  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Semicolon  ( ; )';

  @override
  String get prefsSeparatorComma => 'Comma  ( , )';

  @override
  String get prefsSeparatorTab => 'Tab';

  @override
  String get prefsGroupToolbarButtons => 'Toolbar buttons';

  @override
  String get prefsToolbarButtonsHint =>
      'Untick a button to take it off the editor toolbar.';

  @override
  String get prefsToolbarUndoRedo => 'Undo / Redo';

  @override
  String get prefsToolbarFont => 'Font';

  @override
  String get prefsToolbarSize => 'Size';

  @override
  String get prefsToolbarBold => 'Bold';

  @override
  String get prefsToolbarItalic => 'Italic';

  @override
  String get prefsToolbarUnderline => 'Underline';

  @override
  String get prefsToolbarStrikeThrough => 'Strikethrough';

  @override
  String get prefsToolbarInlineCode => 'Code';

  @override
  String get prefsToolbarTextColor => 'Text colour';

  @override
  String get prefsToolbarHighlightColor => 'Highlight colour';

  @override
  String get prefsToolbarClearFormat => 'Clear formatting';

  @override
  String get prefsToolbarHeadings => 'Headings';

  @override
  String get prefsToolbarNumberedList => 'Numbered list';

  @override
  String get prefsToolbarBulletedList => 'Bulleted list';

  @override
  String get prefsToolbarChecklist => 'Checklist';

  @override
  String get prefsToolbarCodeBlock => 'Code block';

  @override
  String get prefsToolbarQuote => 'Quote';

  @override
  String get prefsToolbarIndent => 'Indent';

  @override
  String get prefsToolbarLink => 'Link';

  @override
  String get prefsToolbarInsertImage => 'Insert image';

  @override
  String get prefsToolbarVoiceMemo => 'Voice memo';

  @override
  String get prefsGroupSecurity => 'Security';

  @override
  String get prefsRememberPassword => 'Remember password';

  @override
  String get prefsRememberPasswordHint =>
      'Store database password in system keychain';

  @override
  String get prefsBiometricUnlock => 'Biometric unlock';

  @override
  String get prefsBiometricUnavailableHint =>
      'Unavailable — set up a fingerprint or screen lock in Android settings first';

  @override
  String get prefsBiometricHint =>
      'Confirm fingerprint, face, or screen lock before the remembered password is used';

  @override
  String get prefsBlockScreenshots => 'Block screenshots';

  @override
  String get prefsBlockScreenshotsHint =>
      'Hide app content in screenshots, screen recording, and the recent-apps switcher';

  @override
  String get prefsGroupStartup => 'Startup';

  @override
  String get prefsSingleInstance => 'Single instance';

  @override
  String get prefsSingleInstanceHint =>
      'Allow only one running window; a new launch focuses the existing one. Takes effect on next launch.';

  @override
  String get prefsVoiceGroupDevices => 'Devices';

  @override
  String get prefsVoiceMicrophone => 'Microphone';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Used for voice memos and for the check below.';

  @override
  String get prefsVoiceSpeaker => 'Speaker';

  @override
  String get prefsVoiceSpeakerHint =>
      'Applies to voice memos. Other audio attachments play through the system default.';

  @override
  String get prefsVoiceDevicesLooking => 'Looking…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'No audio devices could be listed: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Unavailable';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (default)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (not connected)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Transcription';

  @override
  String get prefsVoiceModel => 'Model';

  @override
  String get prefsVoiceModelHintNone =>
      'Memos are recorded and stored as audio only.';

  @override
  String get prefsVoiceModelHintLocal =>
      'Runs on this device. Nothing is sent anywhere.';

  @override
  String get prefsVoiceModelOff => 'Off';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · recommended';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Transcribe after recording';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'A memo is stored first and transcribed from the stored audio. Off stores it untranscribed; \"Transcribe\" in the attachment menu still works later.';

  @override
  String get prefsVoiceLanguage => 'Language';

  @override
  String get prefsVoiceLanguageAuto => 'Detect automatically';

  @override
  String get prefsVoiceFooter =>
      'Recording works without a model — memos are always stored as audio, and play back like any other attachment. A model only adds the text.';

  @override
  String get prefsVoiceGroupCheck => 'Check';

  @override
  String get prefsVoiceCheckIntro =>
      'Records a few seconds, plays them back and transcribes them, using the devices and model above. Nothing is saved.';

  @override
  String get prefsVoiceStop => 'Stop';

  @override
  String get prefsVoiceTestAgain => 'Test again';

  @override
  String get prefsVoiceCheckRecording =>
      'Recording — say a sentence, then press Stop.';

  @override
  String get prefsVoiceCheckPlaying => 'Playing it back…';

  @override
  String get prefsVoiceCheckTranscribing => 'Transcribing…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Transcribing… $percent%';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return 'Recorded $duration.';
  }

  @override
  String get prefsVoiceCheckFailed => 'The check did not finish.';

  @override
  String get prefsVoiceDownloading => 'Downloading…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$percent% of $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model is downloaded and ready.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'Not downloaded — $size from HuggingFace.';
  }

  @override
  String get prefsCheckBusy =>
      'A voice memo is being recorded. Finish it first.';

  @override
  String get prefsCheckPermissionRefused =>
      'The microphone permission was refused.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'The microphone would not open: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Recording failed: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'The recording could not be finished: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Nothing was recorded. Hold the test a moment longer, or pick another microphone.';

  @override
  String get prefsCheckMalformed =>
      'The recording came back malformed and would not play.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String get prefsCheckNoModel =>
      'Recording and playback worked. No model is selected, so there is nothing to transcribe.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'Recording and playback worked. $model has not been downloaded yet, so nothing was transcribed.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Transcription failed: $error';
  }

  @override
  String get prefsCheckSilence =>
      'The microphone produced silence — the level meter never moved. Check that the right device is selected and that the app may use it.';

  @override
  String get prefsCheckNoSpeech =>
      'Recording and playback worked, but whisper found no speech. Try speaking closer to the microphone, or another language.';

  @override
  String get prefsCheckQuiet =>
      'The level meter never moved, so the input is very quiet.';

  @override
  String get prefsDownloadCancelled => 'Download cancelled.';

  @override
  String prefsDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get prefsUntitled => '(untitled)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Saved for this session only: the system keychain refused it. If your keyring is locked, unlock it and press Regenerate.';

  @override
  String get prefsMcpRegenerateTitle => 'Regenerate token?';

  @override
  String get prefsMcpRegenerateBody =>
      'Agents configured with the current token will stop working until you paste the new one into their settings.';

  @override
  String get prefsMcpRegenerate => 'Regenerate';

  @override
  String get prefsMcpGroupAccess => 'Agent access';

  @override
  String get prefsMcpEnable => 'Enable MCP server';

  @override
  String get prefsMcpEnableHint =>
      'Let local AI coding agents read this outline over 127.0.0.1. Off by default.';

  @override
  String get prefsMcpReadOnly => 'Read-only';

  @override
  String get prefsMcpReadOnlyHint =>
      'Agents can search and read tasks but cannot create, change, move or delete them.';

  @override
  String get prefsMcpGroupEndpoint => 'Endpoint';

  @override
  String get prefsMcpPort => 'Port';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'Copy URL';

  @override
  String get prefsMcpToken => 'Token';

  @override
  String get prefsMcpTokenHint =>
      'Anyone who can run programs as you can use this token. Treat it like a password.';

  @override
  String get prefsMcpNoTokenYet =>
      'No token yet — enable the server to create one';

  @override
  String get prefsMcpShowToken => 'Show token';

  @override
  String get prefsMcpHideToken => 'Hide token';

  @override
  String get prefsMcpCopyToken => 'Copy token';

  @override
  String get prefsMcpCopied => 'Copied.';

  @override
  String get prefsMcpGroupExcluded => 'Excluded branches';

  @override
  String get prefsMcpExcludedIntro =>
      'Tasks hidden from the MCP server, together with everything under them.';

  @override
  String get prefsMcpLoading => 'Loading…';

  @override
  String get prefsMcpOutlineReadError => 'Could not read the outline.';

  @override
  String get prefsMcpChoose => 'Choose…';

  @override
  String get prefsMcpNothingExcluded =>
      'Nothing is excluded — agents can see the whole outline.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'and $count more',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'Listening on $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'Port $port is not available. Choose another port.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'No access token. Press Regenerate to create one.';

  @override
  String get prefsMcpWaitingDatabase => 'Waiting for a database to be opened.';

  @override
  String get prefsMcpNotRunning => 'Not running.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Last request $time';
  }

  @override
  String get prefsMcpNoRequests => 'No requests yet';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rejected (wrong or missing token)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<enable the server first>';

  @override
  String get prefsMcpGroupSetup => 'Set up your agent';

  @override
  String get prefsMcpClient => 'Client';

  @override
  String get prefsMcpStdioBridge =>
      'An agent that only speaks stdio can bridge with:';

  @override
  String get prefsMcpTargetTerminal => 'Run this in a terminal:';

  @override
  String prefsMcpTargetFile(String file) {
    return 'Add to $file:';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Scoped to your user, so the outline is available in every project.';

  @override
  String get prefsMcpNoteCodex =>
      'To keep the token out of the file, replace http_headers with bearer_token_env_var = \"NOO_MCP_TOKEN\" and set that variable in your shell.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false matters — without it OpenCode reads this server\'s 401 as an invitation to start an OAuth registration it cannot finish.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'A ticked task is hidden from the MCP server together with everything under it — agents cannot read it, change it, or delete anything that contains it.';

  @override
  String get prefsMcpNoDatabase => 'No database is open.';

  @override
  String get prefsMcpNoTasks => 'This outline has no tasks yet.';

  @override
  String get prefsMcpCollapse => 'Collapse';

  @override
  String get prefsMcpExpand => 'Expand';

  @override
  String get prefsMcpHiddenWithParent => 'hidden with parent';

  @override
  String get syncGroupSynchronization => 'Synchronization';

  @override
  String get syncEnable => 'Enable sync';

  @override
  String get syncEnableHint => 'Keep this database in sync with a server';

  @override
  String get syncGroupIdentity => 'Identity';

  @override
  String get syncNeedsUserName =>
      'Enter a user name to start syncing. Nothing syncs without one — with or without a server.';

  @override
  String get syncUserName => 'User name';

  @override
  String get syncUserNameHint =>
      'The same on every device of yours. Together with the database password it derives the encryption keys, so devices only sync when both match.';

  @override
  String get syncDeviceName => 'Device name';

  @override
  String get syncDeviceNameHint =>
      'How this device introduces itself to nearby devices';

  @override
  String get syncGroupServer => 'Sync server (optional)';

  @override
  String get syncServerIntro =>
      'Leave empty to sync only with nearby devices on the same network. A server additionally lets devices sync when they are apart; it stores encrypted data it cannot read.';

  @override
  String get syncServerUrl => 'Server URL';

  @override
  String get syncServerPassword => 'Password';

  @override
  String get syncServerPasswordHint =>
      'Your account password on the server. Not the database password, and never used as an encryption key.';

  @override
  String get syncTestConnection => 'Test Connection';

  @override
  String get syncRegister => 'Register';

  @override
  String get syncGroupSchedule => 'Schedule';

  @override
  String get syncScheduleNeedsServer =>
      'Syncing on start and exit needs a server. Devices on the same network sync when you ask them to, from Tools → Sync P2P...';

  @override
  String get syncAutosyncOnStart => 'Autosync on start';

  @override
  String get syncAutosyncOnStartHint => 'Sync when the app opens the database';

  @override
  String get syncCheckOnStart => 'Check for incoming changes on start';

  @override
  String get syncCheckOnStartHint =>
      'Ask the server whether other devices have sent changes, without syncing, and show it on the sync icon. Not needed while Autosync on start is on';

  @override
  String get syncAskOnExit => 'Ask to sync on exit';

  @override
  String get syncAskOnExitHint =>
      'Prompt to sync pending changes before the app closes';

  @override
  String get syncGroupServerStorage => 'Server storage';

  @override
  String get syncGroupPeerToPeer => 'Peer-to-peer';

  @override
  String get syncPeerToPeerIntro =>
      'Devices on the same network that share your user name and database password can sync directly — no server needed. Open Tools → Sync P2P... on each of them: they find each other and sync while that window is open, and are not discoverable otherwise.';

  @override
  String get syncStorageNoServer =>
      'Nothing is stored on a server in this setup. Peer-to-peer sync keeps every packet on the devices themselves.';

  @override
  String get syncStorageIntro =>
      'The server keeps every encrypted change ever made, so its size grows with edits rather than with the size of your outline.';

  @override
  String get syncStorageReading => 'Reading…';

  @override
  String get syncStoragePressRefresh =>
      'Press Refresh to read the current usage.';

  @override
  String get syncStorageEmpty => 'Nothing stored on the server yet.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size in $count packets',
      one: '$size in 1 packet',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Counters $first–$last';
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
      other: 'Counters $first–$last, $snapshots snapshot(s)',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Plus $count attachments ($size), stored once and shared by every packet that references them.',
      one:
          'Plus 1 attachment ($size), stored once and shared by every packet that references them.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This device holds $count of them locally ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Compact data on server';

  @override
  String get syncResetIdentity => 'Reset device identity';

  @override
  String get syncNotConfiguredOnDevice =>
      'Sync is not configured on this device.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Could not read server storage: $error';
  }

  @override
  String get syncResetConfirm =>
      'This device will start syncing under a new identity, and its next sync will publish a full copy of the current database. Your other devices merge that normally — nothing is lost.\n\nDo this when syncing reports that this device’s history has diverged, which usually means this database was restored from a backup after it had already synced.\n\nThe old identity keeps appearing in the server’s storage list until you compact.';

  @override
  String get syncReset => 'Reset';

  @override
  String syncResetFailed(String error) {
    return 'Could not reset the device identity: $error';
  }

  @override
  String get syncCompactConfirm =>
      'This device will sync, then upload one snapshot of the whole database. The server then deletes every stored change the snapshot already contains, and so does every device as it picks the snapshot up.\n\nYour notes, times and attachments are unaffected — what is discarded is the record of individual past edits below the snapshot.\n\nUpdate Noo on your other devices first: an older version cannot read a stream whose beginning has been removed.';

  @override
  String get syncCompact => 'Compact';

  @override
  String get syncCompactFailed => 'Compaction failed.';

  @override
  String get syncCompactNothing => 'Nothing to compact yet.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Freed $size on the server ($count packets)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Snapshot uploaded, but this server does not support compaction yet, so it kept its copies';

  @override
  String get syncCompactRelayNothing =>
      'Snapshot uploaded; the server had nothing left to drop';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'This device freed $size ($count packets)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. The snapshot itself is $size.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. The snapshot itself is $size.';
  }

  @override
  String get syncTestSuccess => 'Success: Server is reachable';

  @override
  String get syncTestUnreachable => 'Error: Server not reachable';

  @override
  String syncErrorWith(String error) {
    return 'Error: $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Error: Username and password required';

  @override
  String syncRegisterSuccess(String user) {
    return 'Success: Account \"$user\" created. Settings saved.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Success: Account \"$user\" created with unlimited server storage. Settings saved.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Success: Account \"$user\" created with $size of server storage. Settings saved.';
  }

  @override
  String get syncStagePreparing => 'Preparing';

  @override
  String get syncStageAuthenticating => 'Validating credentials';

  @override
  String get syncStagePushing => 'Pushing changes';

  @override
  String get syncStageApplying => 'Applying changes';

  @override
  String get syncStatePending => 'Pending';

  @override
  String get syncStateActive => 'Working…';

  @override
  String get syncStateDone => 'Done';

  @override
  String get syncStateSkipped => 'Skipped';

  @override
  String get syncStateFailed => 'Failed';

  @override
  String get syncCancelling => 'Cancelling…';

  @override
  String get syncSynchronizing => 'Synchronizing…';

  @override
  String get syncCancelled => 'Sync cancelled';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncShowFullLogTooltip => 'Show full log';

  @override
  String get syncShowFullLog => 'Show Full Log';

  @override
  String get syncMoreSeeFullLog => 'see Show Full Log';

  @override
  String get syncGroupProgress => 'Progress';

  @override
  String get syncNoRunYet =>
      'No sync has run yet. Use “Sync Now” to synchronize; the details of the last sync will appear here.';

  @override
  String get syncCancelledNote =>
      'Stopped at your request. Everything synchronized up to that point is kept; the next sync continues from there.';

  @override
  String get syncGroupSummary => 'Summary';

  @override
  String get syncChangesPushed => 'Changes pushed';

  @override
  String get syncChangesApplied => 'Changes applied';

  @override
  String get syncGroupApplied => 'Applied — from other devices';

  @override
  String get syncGroupPushed => 'Pushed — from this device';

  @override
  String get syncGroupLwwSkipped =>
      'Not applied — this device already had a newer value';

  @override
  String get syncGroupUnreadable => 'Could not be read';

  @override
  String get syncLwwTieNote =>
      'Timestamps that match exactly are kept as they are on both devices, so the two stay different. Edit the item again on the device whose version you want to keep.';

  @override
  String get syncLwwOlderNote =>
      'The incoming value was older than this device\'s, so it was not written. If it should have won, check that the clocks on both devices agree.';

  @override
  String get syncSkewSame => 'same timestamp';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'local $seconds s ahead',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'local $minutes min $seconds s ahead';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'local $hours h $minutes min ahead';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'local $days days ahead',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'incoming $incoming · local $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage failed  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'These packets could not be decrypted, which means this database\'s password differs from the one on the device that wrote them. Sync does not retry them: make the passwords match, then re-save the affected items on the other device so they are sent again.';

  @override
  String get syncSkippedUnreadableNote =>
      'These packets could not be read and sync has moved past them — their changes will not arrive on their own. Re-save the affected items on the other device to send them again.';

  @override
  String get syncP2pNotConfigured =>
      'Sync is not configured. Set a user name in Preferences → Sync first.';

  @override
  String syncP2pStartFailed(String error) {
    return 'Could not start peer-to-peer sync: $error';
  }

  @override
  String get syncP2pStarting => 'Starting...';

  @override
  String get syncP2pLooking => 'Looking for devices on this network...';

  @override
  String get syncP2pIntro =>
      'Open Sync P2P... on the other device too. Devices sync as soon as they find each other; they stop being visible when this window is closed.';

  @override
  String get syncP2pTitle => 'Sync P2P';

  @override
  String get syncP2pSyncAgain => 'Sync Again';

  @override
  String get syncP2pFound => 'Found — waiting to sync';

  @override
  String get syncP2pSyncing => 'Syncing...';

  @override
  String get syncP2pUpToDate => 'Synced — already up to date';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced — $count changes received',
      one: 'Synced — 1 change received',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Failed — $error';
  }

  @override
  String get syncP2pUnknownError => 'unknown error';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return 'Received from $device ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return 'Sent to $device ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$used of $quota used ($percent%)';
  }

  @override
  String get syncQuotaSemantics => 'Server storage used';

  @override
  String get syncQuotaFull =>
      'Full: the server refuses new changes until you compact or remove attachments.';

  @override
  String get syncQuotaNearlyFull =>
      'Nearly full. Compacting usually frees most of it.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'Sync is not configured. Open Sync Settings first.';

  @override
  String get syncNoServerConfigured =>
      'No sync server is configured. Use \"Sync P2P...\" for local sync, or add a server in Preferences → Sync.';

  @override
  String get syncAlreadyInProgress => 'Sync already in progress';

  @override
  String get syncAlreadyInProgressSentence => 'A sync is already in progress.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done of $totalText changes',
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
      other: '$countText changes · packet $current of $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText changes',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · about $seconds s left';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · about $minutes min left';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Device stream fork detected: a remote node holds packet counter $remote for this device, but this device is at $local, and it cannot confirm the two agree on what came before (database restored from a backup?). Use \"Reset device identity\" in Preferences → Sync to resume syncing.';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Device stream diverged at packet counter $counter: this device and $source hold different content under the same identity ($localHash here vs $remoteHash there). This database was most likely restored from a backup and has re-used packet numbers it had already published. Use \"Reset device identity\" in Preferences → Sync to resume syncing; it republishes this database under a fresh identity and nothing is lost.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'The server is missing part of this device\'s history: it expects packet #$expected next, but the earliest packet this device still holds is #$local, and the ones in between are no longer here (the server was most likely restored from an older backup after this device compacted). Use \"Reset device identity\" in Preferences → Sync to resume syncing; it republishes this database under a fresh identity and nothing is lost.';
  }

  @override
  String get syncIdentityReset =>
      'This device now syncs under a new identity. Its next sync publishes a full copy of the current database, which every other device merges normally.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This device now syncs under a new identity. Its next sync publishes a full copy of the current database, which every other device merges normally. $count unusable packet(s) were discarded.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Deriving encryption key';

  @override
  String get syncDetailSignedIn => 'Already signed in';

  @override
  String get syncDetailPackaging => 'Packaging local changes';

  @override
  String get syncDetailRecovering => 'Recovering this device\'s own history';

  @override
  String get syncDetailUploading => 'Uploading to server';

  @override
  String get syncDetailNoLocalChanges => 'No local changes';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes pushed',
      one: '1 change pushed',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => 'Downloading remote changes';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments downloaded',
      one: '1 attachment downloaded',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments still to download',
      one: '1 attachment still to download',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Already up to date';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes applied',
      one: '1 change applied',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'Cancelled';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return 'The attachment \"$name\" has not downloaded to this device yet, and a change this device made refers to it, so this device\'s changes cannot reach the server until it arrives — sync again once it has, or sync with a nearby device that holds it.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'The server refused the attachment \"$name\" ($size) as too large. Everything else syncs; the attachment itself reaches other devices only through Sync P2P.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'The server refused the attachment \"$name\" ($size) as too large (its limit is $limit). Everything else syncs; the attachment itself reaches other devices only through Sync P2P.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return 'The attachment \"$name\" ($size) does not fit in your server storage. Everything else syncs; compact data on the server or remove large attachments to make room, and until then the attachment reaches other devices only through Sync P2P.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return 'The attachment \"$name\" ($size) does not fit in your server storage ($used of $quota used). Everything else syncs; compact data on the server or remove large attachments to make room, and until then the attachment reaches other devices only through Sync P2P.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bytes',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'No sync server is configured. Compaction publishes a snapshot to the relay; with nearby-device sync alone there is no relay storage to reclaim.';

  @override
  String get syncCompactStageSyncing => 'Syncing before compaction';

  @override
  String get syncCompactStageChecking => 'Checking this device is up to date';

  @override
  String get syncCompactStagePackaging =>
      'Packaging a snapshot of the whole database';

  @override
  String get syncCompactStageAttachments =>
      'Uploading attachments the snapshot references';

  @override
  String get syncCompactStageUploading => 'Uploading the snapshot';

  @override
  String get syncCompactStageReclaiming => 'Reclaiming space on this device';

  @override
  String get syncCompactStageReadingUsage => 'Reading relay storage';

  @override
  String syncCompactNeedsSync(String error) {
    return 'Compaction needs a completed sync first: $error';
  }

  @override
  String get syncCompactDidNotFinish => 'Compaction did not finish.';

  @override
  String get syncCompactRaced =>
      'Another sync packaged first. Try compacting again.';

  @override
  String get syncCompactSnapshotMissing =>
      'The snapshot was packaged but is not in the local store.';

  @override
  String get syncCompactMissingAttachments =>
      'This device is still missing some attachments. Sync until every attachment has downloaded, then compact.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Relay refused the snapshot: $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Compaction failed: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This device could not read $count packet(s) ($packets), so its state is not the merge of everything in the log. Compacting would discard packets this device never applied.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'This device still has unsynced edits. Sync first, then compact.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This device is still missing some attachments ($count to download), so its snapshot could not supply them and the server would drop them. Sync until every attachment has downloaded, then compact.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This device has not applied everything it holds for $count device(s). Sync again, then compact.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'Nearby-device sync alone cannot guarantee another device still holds a deleted attachment, so none were released.';

  @override
  String get syncCollectUnsynced =>
      'This device has changes the server has not stored yet. Sync first, then compact.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Snapshot of $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fields — the whole database',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Node \"$name\"';
  }

  @override
  String syncSummaryFile(String name) {
    return 'File \"$name\"';
  }

  @override
  String get syncSummaryFileFallback => 'file';

  @override
  String get syncSummaryTimeChunk => 'Time chunk';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'renamed to \"$title\"';
  }

  @override
  String get syncSummaryContentEdited => 'content edited';

  @override
  String get syncSummaryMoved => 'moved';

  @override
  String get syncSummaryReordered => 'reordered';

  @override
  String get syncSummaryFlagsChanged => 'flags changed';

  @override
  String get syncSummaryRenamed => 'renamed';

  @override
  String get syncSummaryContentUpdated => 'content updated';

  @override
  String syncSummaryFrom(String time) {
    return 'from $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'until $time';
  }

  @override
  String get syncValueTopLevel => 'top level';

  @override
  String get syncStorageFull =>
      'Server storage is full. Compact data on the server (Preferences → Sync → Server storage) or remove large attachments; what has not been uploaded stays on this device.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'Server storage is full ($used of $quota used). Compact data on the server (Preferences → Sync → Server storage) or remove large attachments; what has not been uploaded stays on this device.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'The server refuses another device stream for this account: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'The server is out of disk space. Nothing was lost; sync again later.';

  @override
  String syncStorageRefused(String detail) {
    return 'The server refused to store more: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'This server is not accepting new accounts: it has reached its account limit.';

  @override
  String get syncRegClosed =>
      'This server does not accept sign-ups. Ask its operator for an account.';

  @override
  String get syncRegTaken => 'That user name is already taken.';

  @override
  String get syncRegInvalid =>
      'The user name must be 3–50 characters and the server password 8–128.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Too many accounts have been registered from this network today.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Too many accounts have been registered from this network today. Try again in $wait.';
  }

  @override
  String get syncRegTooManyAttempts => 'Too many attempts.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Too many attempts. Try again in $wait.';
  }

  @override
  String get syncRegBusy => 'The server is busy. Try again in a moment.';

  @override
  String syncRegFailed(int status) {
    return 'Registration failed (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Registration failed (HTTP $status): $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return 'No response from $host within ${seconds}s';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'Response from $host stalled for ${seconds}s';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…and $count more — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'see the Sync Log';

  @override
  String get traceAtTopLevel => 'at top level';

  @override
  String traceInPath(String path) {
    return 'in $path';
  }

  @override
  String get traceRowNew => '(new)';

  @override
  String get traceRowRemoved => '(removed)';

  @override
  String get traceShowHowTooltip => 'Show how this change happened';

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
  String get traceDecisionApplied => 'applied';

  @override
  String get traceDecisionCreated => 'created here';

  @override
  String get traceDecisionConflictCopy =>
      'applied — the value it replaced was kept as a conflict copy';

  @override
  String get traceDecisionMerged =>
      'merged with the edit made here — both changes kept';

  @override
  String get traceDecisionCycleToRoot =>
      'moved to the top level — its parent would have made a loop';

  @override
  String get traceDecisionParentMissing =>
      'placed at the top level until its parent arrives';

  @override
  String get traceDecisionBlobPending =>
      'applied — the attachment bytes follow separately';

  @override
  String get traceDecisionSent => 'sent';

  @override
  String get traceDecisionForwarded => 'forwarded';

  @override
  String get traceRouteRelay => 'Downloaded from the relay.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Downloaded from the relay, which stored it $time.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Forwarded by $peer over the local network — $author wrote it.';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Directly from $peer over the local network.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Already on this device from an earlier exchange; applied in this one.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Already on this device — received $time; applied in this one.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Already on this device — received $time from $source; applied in this one.';
  }

  @override
  String get traceRoutePackagedUploaded =>
      'Packaged here and uploaded to the relay.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Packaged here; the relay already had it from another path.';

  @override
  String get traceRoutePackagedBlocked =>
      'Packaged here; not uploaded yet — an attachment it needs could not go up.';

  @override
  String get traceRoutePackagedWaiting =>
      'Packaged here; waiting for the relay or a peer to take it.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Pulled by $peer over the local network — forwarded on $author\'s behalf.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Pulled by $peer over the local network.';
  }

  @override
  String get traceBlobDownloaded => 'downloaded now';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'downloaded now ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'downloaded now from $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'downloaded now from $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'not downloaded yet — it follows on a later sync, or when opened';

  @override
  String get traceBlobHeld => 'already on this device';

  @override
  String get traceBlobUploaded => 'uploaded to the relay';

  @override
  String traceBlobUploadedSized(String size) {
    return 'uploaded to the relay ($size)';
  }

  @override
  String get traceBlobOnRelay => 'the relay already had them';

  @override
  String get traceBlobOffered => 'on this device for others to fetch';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'A compaction snapshot: the whole database of $device, in one packet.';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Part of a full-state snapshot from $device. A snapshot carries the author\'s whole database; this item is listed because it differed here.';
  }

  @override
  String get traceFieldsHeading => 'Fields';

  @override
  String traceTimeEdited(String time) {
    return 'edited $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'theirs $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'this device $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Packet $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Packet $device #$counter (snapshot)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'written $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes',
      one: '1 change',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Author device $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'from device $id';
  }

  @override
  String get traceCopyHashTooltip => 'Copy the packet hash';

  @override
  String get traceAttachmentBytesHeading => 'Attachment bytes';

  @override
  String get traceShowInSyncLog => 'Show in Sync Log';

  @override
  String get traceTriggerRelay => 'Server sync';

  @override
  String get traceTriggerCheck => 'Check for incoming changes';

  @override
  String get traceTriggerLan => 'Nearby devices';

  @override
  String get traceTriggerLanReturn => 'Nearby device (requested)';

  @override
  String get traceTriggerLanServe => 'Served to nearby device';

  @override
  String get traceTriggerPackage => 'Packaged local changes';

  @override
  String get traceTriggerCompaction => 'Compaction';

  @override
  String get traceTriggerIdentityReset => 'Device identity reset';

  @override
  String get traceTriggerAttachment => 'Attachment download';

  @override
  String get traceTriggerBlobCollect => 'Attachment clean-up';

  @override
  String get traceOutcomeRunning => 'running';

  @override
  String get traceOutcomeFailed => 'failed';

  @override
  String get traceOutcomeDeclined => 'declined';

  @override
  String get traceOutcomeBusy => 'busy';

  @override
  String get traceOutcomeInterrupted => 'interrupted';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copied $count event(s) as JSON',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Clear sync log?';

  @override
  String get traceClearBody =>
      'Every recorded run and event on this device is deleted. Synced data is not affected.';

  @override
  String get traceTitle => 'Sync Log';

  @override
  String get traceCopyAsJson => 'Copy as JSON';

  @override
  String get traceClearLogTooltip => 'Clear log';

  @override
  String get traceClearLogButton => 'Clear Log';

  @override
  String traceSummaryApplied(int count) {
    return '$count applied';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errors',
      one: '1 error',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Nothing exchanged';

  @override
  String get traceNoRuns =>
      'No sync has been recorded yet. Runs appear here as this device syncs with the server or with nearby devices.';

  @override
  String get traceAllRuns => 'All runs';

  @override
  String traceRunsRecorded(int count) {
    return '$count recorded';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'All runs ($count)';
  }

  @override
  String get traceRunLabel => 'Run';

  @override
  String get traceSearchHint => 'Search: node name, id, hash, device, kind…';

  @override
  String get traceLevelAll => 'All';

  @override
  String get traceLevelWarnings => 'Warnings';

  @override
  String get traceLevelErrors => 'Errors';

  @override
  String get traceDirectionAll => 'In and out';

  @override
  String get traceDirectionIncoming => 'Incoming';

  @override
  String get traceDirectionOutgoing => 'Outgoing';

  @override
  String get traceDirectionLocal => 'Local';

  @override
  String get traceNoEvents => 'No events match.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Showing the first $count events. Narrow the search or pick a run to see the rest.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Run #$id';
  }

  @override
  String get traceEmptyValue => '(empty)';

  @override
  String traceSubHash(String hash) {
    return 'hash $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'value $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'remote $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'local $time';
  }

  @override
  String get traceDetailAt => 'At';

  @override
  String get traceDetailDirection => 'Direction';

  @override
  String get traceDetailOriginDevice => 'Origin device';

  @override
  String get traceDetailCounter => 'Counter';

  @override
  String get traceDetailHash => 'Packet / blob hash';

  @override
  String get traceDetailEntity => 'Entity';

  @override
  String get traceDetailWorldId => 'World id';

  @override
  String get traceDetailName => 'Name';

  @override
  String get traceDetailField => 'Field';

  @override
  String get traceDetailRemoteTs => 'Remote timestamp';

  @override
  String get traceDetailLocalTs => 'Local timestamp';

  @override
  String get traceDetailValueHash => 'Value hash';

  @override
  String get traceDetailValuePreview => 'Value preview';

  @override
  String get traceDetailMessage => 'Message';

  @override
  String get traceDetailDetail => 'Detail';
}
