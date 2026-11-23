import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// Top-level menu
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get appMenuFile;

  /// Top-level menu (macOS)
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get appMenuEdit;

  /// Top-level menu
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get appMenuView;

  /// Top-level menu
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get appMenuTools;

  /// Top-level menu shown only in debug builds
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get appMenuDebug;

  /// Top-level menu
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get appMenuHelp;

  /// Top-level menu (macOS)
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get appMenuWindow;

  /// Desktop menu bar item (Windows/Linux); keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Open...'**
  String get appMenuOpen;

  /// Phone overflow menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Open Database...'**
  String get appMenuOpenDatabase;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'New Database...'**
  String get appMenuNewDatabase;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Export to Obsidian...'**
  String get appMenuExportObsidian;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Import from Obsidian...'**
  String get appMenuImportObsidian;

  /// Desktop menu bar item (Windows/Linux)
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get appMenuExit;

  /// Desktop menu bar item (Windows/Linux); keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Find...'**
  String get appMenuFind;

  /// View menu submenu, and title of the phone theme picker
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appMenuTheme;

  /// Phone overflow menu item opening the theme picker; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Theme...'**
  String get appMenuThemeEllipsis;

  /// Theme choice: follow the operating system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appThemeSystem;

  /// Theme choice
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appThemeLight;

  /// Theme choice
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appThemeDark;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Timeline...'**
  String get appMenuTimeline;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Time Report...'**
  String get appMenuTimeReport;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Compact Database...'**
  String get appMenuCompactDatabase;

  /// Tools menu item: sync with the server
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get appMenuSyncNow;

  /// Menu item: sync with devices on the local network; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Sync P2P...'**
  String get appMenuSyncP2p;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Preferences...'**
  String get appMenuPreferences;

  /// Debug menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'View Change History...'**
  String get appMenuViewChangeHistory;

  /// Debug menu item, and title of its confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Generate Test Data'**
  String get appMenuGenerateTestData;

  /// Debug menu item, and title of its confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Generate Large Dataset'**
  String get appMenuGenerateLargeDataset;

  /// Debug menu item, and title of its confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get appMenuClearAllData;

  /// Help menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Check for Update...'**
  String get appMenuCheckForUpdate;

  /// Help menu submenu
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get appMenuLogs;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Sync Log...'**
  String get appMenuSyncLog;

  /// Menu item; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'App Log...'**
  String get appMenuAppLog;

  /// Help menu item and About dialog title; appName is the product name
  ///
  /// In en, this message translates to:
  /// **'About {appName}'**
  String appMenuAbout(String appName);

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Check for Update…'**
  String get appMacMenuCheckForUpdate;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis). The macOS name for Preferences
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get appMacMenuSettings;

  /// macOS application menu item
  ///
  /// In en, this message translates to:
  /// **'Quit {appName}'**
  String appMacMenuQuit(String appName);

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Open…'**
  String get appMacMenuOpen;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'New Database…'**
  String get appMacMenuNewDatabase;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Export to Obsidian…'**
  String get appMacMenuExportObsidian;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Import from Obsidian…'**
  String get appMacMenuImportObsidian;

  /// macOS Edit menu item
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get appMacMenuUndo;

  /// macOS Edit menu item
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get appMacMenuRedo;

  /// macOS Edit menu item
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get appMacMenuCut;

  /// macOS Edit menu item
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get appMacMenuPaste;

  /// macOS Edit menu item
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get appMacMenuSelectAll;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Find…'**
  String get appMacMenuFind;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Timeline…'**
  String get appMacMenuTimeline;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Time Report…'**
  String get appMacMenuTimeReport;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Compact Database…'**
  String get appMacMenuCompactDatabase;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Sync P2P…'**
  String get appMacMenuSyncP2p;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis) (debug builds only)
  ///
  /// In en, this message translates to:
  /// **'View Change History…'**
  String get appMacMenuViewChangeHistory;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'Sync Log…'**
  String get appMacMenuSyncLog;

  /// macOS system menu bar item; keep the trailing … (Unicode ellipsis)
  ///
  /// In en, this message translates to:
  /// **'App Log…'**
  String get appMacMenuAppLog;

  /// macOS menu item marked as the active choice (platform menus have no check mark)
  ///
  /// In en, this message translates to:
  /// **'✓ {label}'**
  String appMacMenuChecked(String label);

  /// Title of the file picker for opening a database
  ///
  /// In en, this message translates to:
  /// **'Open Database'**
  String get appOpenDatabaseDialogTitle;

  /// Title of the save dialog for a new database
  ///
  /// In en, this message translates to:
  /// **'Create New Database'**
  String get appCreateDatabaseDialogTitle;

  /// No description provided for @appIncorrectPasswordRetry.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get appIncorrectPasswordRetry;

  /// Snack bar after opening a database
  ///
  /// In en, this message translates to:
  /// **'Opened: {fileName}'**
  String appDatabaseOpened(String fileName);

  /// No description provided for @appOpenDatabaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open database: {error}'**
  String appOpenDatabaseFailed(String error);

  /// Snack bar after creating a database
  ///
  /// In en, this message translates to:
  /// **'Created: {fileName}'**
  String appDatabaseCreated(String fileName);

  /// No description provided for @appCreateDatabaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create database: {error}'**
  String appCreateDatabaseFailed(String error);

  /// No description provided for @appOpenDatabaseFirst.
  ///
  /// In en, this message translates to:
  /// **'Open a database first'**
  String get appOpenDatabaseFirst;

  /// No description provided for @appNoDatabaseOpen.
  ///
  /// In en, this message translates to:
  /// **'No database open'**
  String get appNoDatabaseOpen;

  /// No description provided for @appCannotReadDatabaseFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot read database file: {error}'**
  String appCannotReadDatabaseFile(String error);

  /// No description provided for @appWrongPasswordOrCorrupt.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password or corrupted database'**
  String get appWrongPasswordOrCorrupt;

  /// Directory picker title
  ///
  /// In en, this message translates to:
  /// **'Export to Obsidian Directory'**
  String get appExportObsidianDialogTitle;

  /// Directory picker title
  ///
  /// In en, this message translates to:
  /// **'Import from Obsidian Directory'**
  String get appImportObsidianDialogTitle;

  /// File picker title (phones)
  ///
  /// In en, this message translates to:
  /// **'Import Obsidian .zip'**
  String get appImportObsidianZipDialogTitle;

  /// Progress dialog
  ///
  /// In en, this message translates to:
  /// **'Exporting to Obsidian format...'**
  String get appExportingObsidian;

  /// Progress dialog
  ///
  /// In en, this message translates to:
  /// **'Importing from Obsidian format...'**
  String get appImportingObsidian;

  /// Used inside appExportResult / appImportResult. English deliberately always says "tasks"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} tasks}}'**
  String appCountTasks(int count);

  /// Used inside appExportResult
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} timeline files}}'**
  String appCountTimelineFiles(int count);

  /// Used inside appExportResult
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} images}}'**
  String appCountImages(int count);

  /// Used inside appImportResult
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} time records}}'**
  String appCountTimeRecords(int count);

  /// Snack bar after an Obsidian export; each placeholder is a counted phrase (appCountTasks, appCountTimelineFiles, appCountImages)
  ///
  /// In en, this message translates to:
  /// **'Exported {tasks}, {timelineFiles}, {images}'**
  String appExportResult(String tasks, String timelineFiles, String images);

  /// Snack bar after an Obsidian import; placeholders are counted phrases (appCountTasks, appCountTimeRecords)
  ///
  /// In en, this message translates to:
  /// **'Imported {tasks}, {timeRecords}'**
  String appImportResult(String tasks, String timeRecords);

  /// No description provided for @appExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String appExportFailed(String error);

  /// No description provided for @appImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String appImportFailed(String error);

  /// Title of the share sheet for the exported vault archive (phones)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Obsidian export ({count} tasks)}}'**
  String appObsidianExportShareTitle(int count);

  /// No description provided for @appDirectoryDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Directory does not exist: {path}'**
  String appDirectoryDoesNotExist(String path);

  /// No description provided for @appSyncNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync not configured. Open Sync Settings first.'**
  String get appSyncNotConfigured;

  /// Keep "Sync P2P..." and "(Shift+F5)" as the menu item and shortcut are named
  ///
  /// In en, this message translates to:
  /// **'No sync server configured. Use Sync P2P... (Shift+F5), or add a server in Preferences.'**
  String get appNoSyncServer;

  /// Dialog title on exit
  ///
  /// In en, this message translates to:
  /// **'Unsynced changes'**
  String get appUnsyncedChangesTitle;

  /// No description provided for @appUnsyncedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'There are unsynced changes; do you want to sync them?'**
  String get appUnsyncedChangesBody;

  /// Button: close without syncing
  ///
  /// In en, this message translates to:
  /// **'Don\'t sync'**
  String get appDontSync;

  /// Button: sync before closing
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get appSync;

  /// No description provided for @appSelectTaskFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a task first'**
  String get appSelectTaskFirst;

  /// No description provided for @appGenerateTestDataBody.
  ///
  /// In en, this message translates to:
  /// **'This will create sample tasks with hierarchy and time records.\n\nContinue?'**
  String get appGenerateTestDataBody;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get appGenerate;

  /// No description provided for @appTestDataGenerated.
  ///
  /// In en, this message translates to:
  /// **'Test data generated successfully'**
  String get appTestDataGenerated;

  /// No description provided for @appGenerateLargeDatasetBody.
  ///
  /// In en, this message translates to:
  /// **'This will create a large dataset with:\n- 20 top-level tasks\n- Up to 5 levels deep\n- Up to 6 children per task\n- Time records for many tasks\n\nThis may take a moment. Continue?'**
  String get appGenerateLargeDatasetBody;

  /// No description provided for @appGeneratingData.
  ///
  /// In en, this message translates to:
  /// **'Generating data...'**
  String get appGeneratingData;

  /// No description provided for @appLargeDatasetGenerated.
  ///
  /// In en, this message translates to:
  /// **'Large dataset generated successfully'**
  String get appLargeDatasetGenerated;

  /// No description provided for @appClearAllDataBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all tasks, time records, and attachments.\n\nThis action cannot be undone. Are you sure?'**
  String get appClearAllDataBody;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get appDeleteAll;

  /// No description provided for @appAllDataCleared.
  ///
  /// In en, this message translates to:
  /// **'All data cleared'**
  String get appAllDataCleared;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Compact Database'**
  String get appCompactDatabaseTitle;

  /// No description provided for @appCompactDatabaseBody.
  ///
  /// In en, this message translates to:
  /// **'Rewrites the database file so the space held by deleted tasks, attachments and old change history is returned to the disk.\n\nThe contents of deleted attachments are released too, and are downloaded again from the server if you ever restore one.\n\nNothing you can still see is removed. On a large database this takes a while, and the app cannot be used until it finishes.'**
  String get appCompactDatabaseBody;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get appCompact;

  /// Progress dialog
  ///
  /// In en, this message translates to:
  /// **'Compacting database...'**
  String get appCompactingDatabase;

  /// No description provided for @appCompactingFailed.
  ///
  /// In en, this message translates to:
  /// **'Compacting failed: {error}'**
  String appCompactingFailed(String error);

  /// No description provided for @appDatabaseCompacted.
  ///
  /// In en, this message translates to:
  /// **'Database compacted'**
  String get appDatabaseCompacted;

  /// freed and size are byte sizes such as "12.3 MB"
  ///
  /// In en, this message translates to:
  /// **'Database compacted — {freed} freed (now {size})'**
  String appDatabaseCompactedFreed(String freed, String size);

  /// size is a byte size such as "12.3 MB"
  ///
  /// In en, this message translates to:
  /// **'Database compacted — already compact ({size})'**
  String appDatabaseCompactedAlready(String size);

  /// Compaction result followed by why deleted attachments were kept
  ///
  /// In en, this message translates to:
  /// **'{result}. {note}'**
  String appDatabaseCompactedWithNote(String result, String note);

  /// Tooltip of the search button (phone app bar)
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get appFindTooltip;

  /// Tooltip of the sync button (phone app bar)
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get appSyncNowTooltip;

  /// No description provided for @appBiometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric check failed. Please enter password.'**
  String get appBiometricFailed;

  /// No description provided for @appSavedPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Saved password is incorrect. Please enter password.'**
  String get appSavedPasswordIncorrect;

  /// No description provided for @appLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get appLoading;

  /// Heading on the startup screen
  ///
  /// In en, this message translates to:
  /// **'Failed to Open Database'**
  String get appFailedToOpenDatabaseTitle;

  /// Button on the startup screen
  ///
  /// In en, this message translates to:
  /// **'Open another database…'**
  String get appOpenAnotherDatabase;

  /// Shown by the operating system in the fingerprint/face prompt (Android)
  ///
  /// In en, this message translates to:
  /// **'Unlock your Noo database'**
  String get appBiometricReason;

  /// No description provided for @appWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}'**
  String appWelcomeTitle(String appName);

  /// No description provided for @appWelcomeIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose where to store your encrypted database. You can change this later from the File menu.'**
  String get appWelcomeIntro;

  /// No description provided for @appUseDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Use default location'**
  String get appUseDefaultLocation;

  /// Shown while the default database location is being determined
  ///
  /// In en, this message translates to:
  /// **'Resolving…'**
  String get appResolving;

  /// Option on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Create new database…'**
  String get appCreateNewDatabaseOption;

  /// No description provided for @appCreateNewDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a custom location for a new encrypted database.'**
  String get appCreateNewDatabaseSubtitle;

  /// Option on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Open existing database…'**
  String get appOpenExistingDatabaseOption;

  /// No description provided for @appOpenExistingDatabaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use an existing .noo file from another location.'**
  String get appOpenExistingDatabaseSubtitle;

  /// Button on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get appQuit;

  /// No description provided for @appWelcomeSyncHint.
  ///
  /// In en, this message translates to:
  /// **'Already have a database on another device? Create a new one here with the same password, then set up sync in Preferences → Sync with the same user name — your notes will arrive with the first sync.'**
  String get appWelcomeSyncHint;

  /// Phone task screen title when the task has no title
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get appTaskFallbackTitle;

  /// Tab on the phone task screen
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get appTabNotes;

  /// Tab on the phone task screen
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get appTabTime;

  /// Tab on the phone task screen
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get appTabFiles;

  /// Tab on the phone task screen with the number of attachments
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String appTabFilesCount(int count);

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get appStartTracking;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get appStopTracking;

  /// No description provided for @appNoTaskSelected.
  ///
  /// In en, this message translates to:
  /// **'No task selected.'**
  String get appNoTaskSelected;

  /// Heading of the attachments tab
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get appAttachmentsHeading;

  /// Status bar: the note has unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get appModified;

  /// No description provided for @appWordWrapOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Word wrap is on — click to turn it off'**
  String get appWordWrapOnTooltip;

  /// No description provided for @appWordWrapOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Word wrap is off — click to turn it on'**
  String get appWordWrapOffTooltip;

  /// Status bar tooltip (phone)
  ///
  /// In en, this message translates to:
  /// **'Time tracked today — tap to open'**
  String get appTimeTodayTap;

  /// Status bar tooltip
  ///
  /// In en, this message translates to:
  /// **'Hide time tracking'**
  String get appHideTimeTracking;

  /// Status bar tooltip (desktop)
  ///
  /// In en, this message translates to:
  /// **'Time tracked today — click for details'**
  String get appTimeTodayClick;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'View timeline'**
  String get appViewTimeline;

  /// Status bar tooltip (phone)
  ///
  /// In en, this message translates to:
  /// **'Attachments — tap to open'**
  String get appAttachmentsTap;

  /// Status bar tooltip
  ///
  /// In en, this message translates to:
  /// **'Hide attachments'**
  String get appHideAttachments;

  /// Status bar tooltip (desktop)
  ///
  /// In en, this message translates to:
  /// **'Attachments — click to show'**
  String get appAttachmentsClick;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get appAddAttachment;

  /// An untitled task in the status bar path
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get appUntitledInPath;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Sync disabled — click to sync'**
  String get appSyncStatusDisabled;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Not synced yet — click to sync'**
  String get appSyncStatusUnknown;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Synced — click to sync'**
  String get appSyncStatusIdle;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get appSyncStatusSyncing;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Sync error — click to retry'**
  String get appSyncStatusError;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Pending changes — click to sync'**
  String get appSyncStatusPending;

  /// Sync icon tooltip
  ///
  /// In en, this message translates to:
  /// **'Other devices have sent changes — click to sync'**
  String get appSyncStatusIncoming;

  /// Status bar chip for the task whose clock is running
  ///
  /// In en, this message translates to:
  /// **'Tracking time on \"{title}\" — click to go to it'**
  String appTrackingChipTooltip(String title);

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Stop tracking \"{title}\"'**
  String appStopTrackingTask(String title);

  /// Minutes of the running clock at the start of the window title, e.g. "42m"; keep it very short
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String appTrackingMinutes(int minutes);

  /// More items not listed in the pending-sync preview
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String appPendingMore(int count);

  /// Changed fields, then how long ago (e.g. "title, content · 5 min ago")
  ///
  /// In en, this message translates to:
  /// **'{fields} · {ago}'**
  String appPendingItemDetail(String fields, String ago);

  /// Used inside appPendingSummary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String appCountItems(int count);

  /// Used inside appPendingSummary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String appCountChanges(int count);

  /// Placeholders are counted phrases (appCountItems, appCountChanges)
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync: {items}, {changes}'**
  String appPendingSummary(String items, String changes);

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'title'**
  String get appPendingFieldTitle;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'content'**
  String get appPendingFieldContent;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'moved'**
  String get appPendingFieldMoved;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'reordered'**
  String get appPendingFieldReordered;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'flags'**
  String get appPendingFieldFlags;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'deleted'**
  String get appPendingFieldDeleted;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get appPendingFieldName;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'start time'**
  String get appPendingFieldStartTime;

  /// Lower-case name of a changed field in the pending-sync preview, joined into a list
  ///
  /// In en, this message translates to:
  /// **'end time'**
  String get appPendingFieldEndTime;

  /// Pending-sync preview: changed less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get appJustNow;

  /// Short form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} min ago}}'**
  String appMinutesAgo(int count);

  /// Short form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} h ago}}'**
  String appHoursAgo(int count);

  /// Short form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} d ago}}'**
  String appDaysAgo(int count);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get appEnterPasswordTitle;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Database Password'**
  String get appSetDatabasePasswordTitle;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get appPasswordLabel;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get appConfirmPasswordLabel;

  /// No description provided for @appPleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get appPleaseEnterPassword;

  /// No description provided for @appPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 4 characters'**
  String get appPasswordTooShort;

  /// No description provided for @appPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get appPasswordsDoNotMatch;

  /// No description provided for @appPasswordWarning.
  ///
  /// In en, this message translates to:
  /// **'The password will be used to encrypt your database. If you forget it, the data cannot be recovered.'**
  String get appPasswordWarning;

  /// Button: create the database
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get appCreate;

  /// Password strength
  ///
  /// In en, this message translates to:
  /// **'Very weak'**
  String get appStrengthVeryWeak;

  /// Password strength
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get appStrengthWeak;

  /// Password strength
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get appStrengthFair;

  /// Password strength
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get appStrengthGood;

  /// Password strength
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get appStrengthStrong;

  /// Subtitle in the About dialog
  ///
  /// In en, this message translates to:
  /// **'Tiny outliner with time tracking'**
  String get appTagline;

  /// No description provided for @appAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A cross-platform desktop outliner application for organizing your thoughts, tasks, and projects with built-in time tracking.'**
  String get appAboutDescription;

  /// No description provided for @appBuiltWithFlutter.
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter'**
  String get appBuiltWithFlutter;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Check for Update'**
  String get appCheckForUpdateTitle;

  /// No description provided for @appCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String appCouldNotOpen(String url);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Open Release Page'**
  String get appOpenReleasePage;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get appDownloadApk;

  /// Button (macOS .dmg)
  ///
  /// In en, this message translates to:
  /// **'Download Disk Image'**
  String get appDownloadDiskImage;

  /// No description provided for @appCheckingForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking for a new version...'**
  String get appCheckingForUpdate;

  /// No description provided for @appUpdateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get appUpdateCheckFailed;

  /// No description provided for @appUpToDate.
  ///
  /// In en, this message translates to:
  /// **'{appName} {version} is the latest version.'**
  String appUpToDate(String appName, String version);

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'{appName} {version} is available (you have {installed}).'**
  String appUpdateAvailable(String appName, String version, String installed);

  /// No description provided for @appDownloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading {appName} {version}...'**
  String appDownloadingUpdate(String appName, String version);

  /// Byte sizes, e.g. "3.2 MB of 20.1 MB"
  ///
  /// In en, this message translates to:
  /// **'{received} of {total}'**
  String appDownloadProgress(String received, String total);

  /// No description provided for @appUpdateReadyToInstall.
  ///
  /// In en, this message translates to:
  /// **'{appName} {version} is downloaded and verified. Installing it closes {appName}, replaces the program files and starts it again. Your databases are not touched.'**
  String appUpdateReadyToInstall(String appName, String version);

  /// No description provided for @appUpdateInstalled.
  ///
  /// In en, this message translates to:
  /// **'{appName} {version} is installed. Restart to start using it.'**
  String appUpdateInstalled(String appName, String version);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appLater;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get appInstall;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Install and Restart'**
  String get appInstallAndRestart;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Restart Now'**
  String get appRestartNow;

  /// No description provided for @appUpdGithubTimeout.
  ///
  /// In en, this message translates to:
  /// **'GitHub did not answer in time'**
  String get appUpdGithubTimeout;

  /// No description provided for @appUpdCannotReachGithub.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach GitHub: {error}'**
  String appUpdCannotReachGithub(String error);

  /// status is an HTTP status code
  ///
  /// In en, this message translates to:
  /// **'GitHub answered {status} for the latest release'**
  String appUpdGithubStatus(int status);

  /// No description provided for @appUpdUnexpectedDataDetail.
  ///
  /// In en, this message translates to:
  /// **'Unexpected release data: {error}'**
  String appUpdUnexpectedDataDetail(String error);

  /// No description provided for @appUpdUnexpectedData.
  ///
  /// In en, this message translates to:
  /// **'Unexpected release data'**
  String get appUpdUnexpectedData;

  /// No description provided for @appUpdNoInPlace.
  ///
  /// In en, this message translates to:
  /// **'No in-place update on this platform'**
  String get appUpdNoInPlace;

  /// No description provided for @appUpdNoWindowsInstaller.
  ///
  /// In en, this message translates to:
  /// **'Release {version} has no Windows installer'**
  String appUpdNoWindowsInstaller(String version);

  /// No description provided for @appUpdNoWindowsZip.
  ///
  /// In en, this message translates to:
  /// **'Release {version} has no Windows ZIP'**
  String appUpdNoWindowsZip(String version);

  /// No description provided for @appUpdCannotWrite.
  ///
  /// In en, this message translates to:
  /// **'Cannot write to {path}; download the new version manually'**
  String appUpdCannotWrite(String path);

  /// fileName is the downloaded ZIP, path the program inside it
  ///
  /// In en, this message translates to:
  /// **'{fileName} does not contain {path}'**
  String appUpdZipMissingExe(String fileName, String path);

  /// No description provided for @appUpdInvalidZip.
  ///
  /// In en, this message translates to:
  /// **'The download is not a valid ZIP: {error}'**
  String appUpdInvalidZip(String error);

  /// No description provided for @appUpdUnsafeZipPath.
  ///
  /// In en, this message translates to:
  /// **'The ZIP holds an unsafe path: {path}'**
  String appUpdUnsafeZipPath(String path);

  /// No description provided for @appUpdCannotUnpack.
  ///
  /// In en, this message translates to:
  /// **'Cannot unpack the download: {error}'**
  String appUpdCannotUnpack(String error);

  /// No description provided for @appUpdNotAppImage.
  ///
  /// In en, this message translates to:
  /// **'Not running from an AppImage'**
  String get appUpdNotAppImage;

  /// No description provided for @appUpdNoAppImage.
  ///
  /// In en, this message translates to:
  /// **'Release {version} has no Linux AppImage'**
  String appUpdNoAppImage(String version);

  /// No description provided for @appUpdCannotChmod.
  ///
  /// In en, this message translates to:
  /// **'Cannot make the new AppImage executable: {error}'**
  String appUpdCannotChmod(String error);

  /// No description provided for @appUpdCannotReplace.
  ///
  /// In en, this message translates to:
  /// **'Cannot replace {path}: {error}'**
  String appUpdCannotReplace(String path, String error);

  /// No description provided for @appUpdDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String appUpdDownloadFailed(String error);

  /// status is an HTTP status code
  ///
  /// In en, this message translates to:
  /// **'Download failed: server answered {status}'**
  String appUpdDownloadStatus(int status);

  /// No description provided for @appUpdCannotSave.
  ///
  /// In en, this message translates to:
  /// **'Cannot save the download: {error}'**
  String appUpdCannotSave(String error);

  /// No description provided for @appUpdInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Download interrupted: {error}'**
  String appUpdInterrupted(String error);

  /// No description provided for @appUpdChecksumMismatch.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file does not match its published checksum'**
  String get appUpdChecksumMismatch;

  /// No description provided for @appUpdNoChecksums.
  ///
  /// In en, this message translates to:
  /// **'Release {version} publishes no checksums; download it manually'**
  String appUpdNoChecksums(String version);

  /// No description provided for @appUpdChecksumTimeout.
  ///
  /// In en, this message translates to:
  /// **'Checksum download timed out'**
  String get appUpdChecksumTimeout;

  /// No description provided for @appUpdChecksumFailed.
  ///
  /// In en, this message translates to:
  /// **'Checksum download failed: {error}'**
  String appUpdChecksumFailed(String error);

  /// status is an HTTP status code
  ///
  /// In en, this message translates to:
  /// **'Checksum download failed: server answered {status}'**
  String appUpdChecksumStatus(int status);

  /// No description provided for @appUpdNotListed.
  ///
  /// In en, this message translates to:
  /// **'{fileName} is not listed in {checksumsFile}'**
  String appUpdNotListed(String fileName, String checksumsFile);

  /// No description provided for @appLogCopied.
  ///
  /// In en, this message translates to:
  /// **'App log copied to clipboard'**
  String get appLogCopied;

  /// Dialog title; also the share sheet title
  ///
  /// In en, this message translates to:
  /// **'App Log'**
  String get appLogTitle;

  /// Save dialog title
  ///
  /// In en, this message translates to:
  /// **'Save App Log'**
  String get appLogSaveDialogTitle;

  /// No description provided for @appSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String appSavedTo(String path);

  /// No description provided for @appSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String appSaveFailed(String error);

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get appShare;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get appClearLogTooltip;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Clear Log'**
  String get appClearLogButton;

  /// Button opening a save dialog; keep the trailing ...
  ///
  /// In en, this message translates to:
  /// **'Save...'**
  String get appSaveEllipsis;

  /// Hint text of a filter field
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get appSearchHint;

  /// Log level filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get appLogLevelAll;

  /// Log level filter
  ///
  /// In en, this message translates to:
  /// **'Warnings and errors'**
  String get appLogLevelWarnings;

  /// Log level filter
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get appLogLevelErrors;

  /// No description provided for @appLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been logged yet.'**
  String get appLogEmpty;

  /// No description provided for @appLogNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No lines match.'**
  String get appLogNoMatch;

  /// Debug dialog title
  ///
  /// In en, this message translates to:
  /// **'Change History'**
  String get appHistoryTitle;

  /// Label before filter chips; keep the trailing space
  ///
  /// In en, this message translates to:
  /// **'Filter: '**
  String get appHistoryFilter;

  /// Filter chip
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String appHistoryAll(int count);

  /// Filter chip
  ///
  /// In en, this message translates to:
  /// **'Tasks ({count})'**
  String appHistoryTasks(int count);

  /// Filter chip
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String appHistoryFiles(int count);

  /// Filter chip
  ///
  /// In en, this message translates to:
  /// **'Timeline ({count})'**
  String appHistoryTimeline(int count);

  /// No description provided for @appHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String appHistoryError(String error);

  /// No description provided for @appHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history entries found'**
  String get appHistoryEmpty;

  /// No description provided for @appHistoryFieldsChanged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 field changed} =1{1 field changed} other{{count} fields changed}}'**
  String appHistoryFieldsChanged(int count);

  /// No description provided for @appHistoryShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} grouped entries ({changes} total field changes)'**
  String appHistoryShowing(int shown, int total, int changes);

  /// Label before the old value
  ///
  /// In en, this message translates to:
  /// **'Old:'**
  String get appHistoryOld;

  /// Label before the new value
  ///
  /// In en, this message translates to:
  /// **'New:'**
  String get appHistoryNew;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save as...'**
  String get commonSaveAs;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse...'**
  String get commonBrowse;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get commonShow;

  /// No description provided for @commonHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get commonHide;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get commonTest;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get commonSystemDefault;

  /// No description provided for @commonUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get commonUntitled;

  /// Preferences > Appearance > Language: follow the operating system's language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Placeholder drawn in a note where an embedded image cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get editorImageNotAvailable;

  /// Menu item on an image embedded in a note; opens the resize dialog
  ///
  /// In en, this message translates to:
  /// **'Resize...'**
  String get editorImageResize;

  /// Menu item on an image embedded in a note; opens a file picker
  ///
  /// In en, this message translates to:
  /// **'Replace image...'**
  String get editorImageReplace;

  /// Menu item on an image embedded in a note; opens a save dialog
  ///
  /// In en, this message translates to:
  /// **'Save image as...'**
  String get editorImageSaveAs;

  /// Menu item on an image embedded in a note: removes the image from the note only
  ///
  /// In en, this message translates to:
  /// **'Remove from text'**
  String get editorImageRemoveFromText;

  /// Subtitle under 'Remove from text'
  ///
  /// In en, this message translates to:
  /// **'Keeps the file in Attachments'**
  String get editorImageRemoveFromTextHint;

  /// Menu item on an image embedded in a note: removes it and deletes the attachment
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get editorImageDelete;

  /// Subtitle under 'Delete image'
  ///
  /// In en, this message translates to:
  /// **'Also deletes the attachment'**
  String get editorImageDeleteHint;

  /// Snack bar after 'Delete image' on an image whose file belongs to a different task
  ///
  /// In en, this message translates to:
  /// **'Image removed from the text. The file belongs to another task and was kept there.'**
  String get editorImageKeptInOtherTask;

  /// Title of the image resize dialog
  ///
  /// In en, this message translates to:
  /// **'Resize image'**
  String get editorResizeImageTitle;

  /// Label of the width field (in pixels) in the image resize dialog
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get editorResizeWidth;

  /// Resize dialog: the chosen width as a percentage of the image's natural width in pixels
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {natural} px'**
  String editorResizePercentOf(int percent, int natural);

  /// Button in the image resize dialog: reset to the image's own size
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get editorResizeOriginalSize;

  /// Toolbar button tooltip and file picker title for inserting an image into a note
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get editorInsertImage;

  /// Title of the file picker that replaces an embedded image
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get editorReplaceImageDialogTitle;

  /// Title of the save dialog for an embedded image
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get editorSaveImageDialogTitle;

  /// Snack bar after saving an image to disk
  ///
  /// In en, this message translates to:
  /// **'Saved: {name}'**
  String editorSavedFile(String name);

  /// Tooltip of the floating attach button on a phone; keep the line break
  ///
  /// In en, this message translates to:
  /// **'Attach file\n(long-press to show attachments)'**
  String get editorAttachFileTooltipCompact;

  /// Tooltip of the floating attach button on a desktop; keep the line break
  ///
  /// In en, this message translates to:
  /// **'Attach file\n(long-press to show or hide attachments)'**
  String get editorAttachFileTooltip;

  /// Tooltip of the voice memo button while recording
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get editorStopRecording;

  /// Tooltip of the editor toolbar's microphone button
  ///
  /// In en, this message translates to:
  /// **'Record voice memo'**
  String get editorRecordVoiceMemo;

  /// Tooltip of the floating microphone button over the note; keep the line break
  ///
  /// In en, this message translates to:
  /// **'Record voice memo\n(long-press to record without transcribing)'**
  String get editorRecordVoiceMemoTooltip;

  /// Snack bar after attaching one file
  ///
  /// In en, this message translates to:
  /// **'Attached {name}'**
  String editorAttachedOne(String name);

  /// Snack bar after attaching several files (count is always 2 or more)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Attached 1 file} other{Attached {count} files}}'**
  String editorAttachedMany(int count);

  /// Tooltip of the editor toolbar's font menu
  ///
  /// In en, this message translates to:
  /// **'Font family'**
  String get editorFontFamily;

  /// Tooltip of the editor toolbar's size menu
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get editorFontSize;

  /// Short label on the toolbar's size menu when no size is known
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get editorSizeLabel;

  /// Named text size (short toolbar label)
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get editorSizeSmall;

  /// Named text size (short toolbar label)
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get editorSizeLarge;

  /// Named text size (short toolbar label)
  ///
  /// In en, this message translates to:
  /// **'Huge'**
  String get editorSizeHuge;

  /// Placeholder shown in an empty note
  ///
  /// In en, this message translates to:
  /// **'Start typing...'**
  String get editorStartTyping;

  /// Snack bar when a link to another task is opened but that task was deleted
  ///
  /// In en, this message translates to:
  /// **'The linked task no longer exists.'**
  String get editorLinkedTaskGone;

  /// Editor context menu item
  ///
  /// In en, this message translates to:
  /// **'Remove formatting'**
  String get editorRemoveFormatting;

  /// Editor context menu item: line up the selected lines in columns split on the separator
  ///
  /// In en, this message translates to:
  /// **'Format as table ({separator})'**
  String editorFormatAsTable(String separator);

  /// Editor context menu item
  ///
  /// In en, this message translates to:
  /// **'Turn word wrap off'**
  String get editorWordWrapOff;

  /// Editor context menu item
  ///
  /// In en, this message translates to:
  /// **'Turn word wrap on'**
  String get editorWordWrapOn;

  /// Shown in the editor panel when the task failed to load
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String editorErrorMessage(String error);

  /// No description provided for @editorTaskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get editorTaskNotFound;

  /// Shown in the editor panel when no task is selected
  ///
  /// In en, this message translates to:
  /// **'Select a task to edit'**
  String get editorSelectTask;

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save task: {error}'**
  String editorSaveFailed(String error);

  /// Snack bar: a sync or an AI agent changed the note while it was being edited
  ///
  /// In en, this message translates to:
  /// **'This note was changed elsewhere while you were editing it. Both changes were merged.'**
  String get editorChangesMerged;

  /// Snack bar: the other version of the note was kept as a new task with this title
  ///
  /// In en, this message translates to:
  /// **'This note was changed elsewhere while you were editing it. Your text was saved; the other version is kept as \"{copyTitle}\".'**
  String editorConflictCopyKept(String copyTitle);

  /// Tooltip of the tree toolbar's add button, with its shortcut
  ///
  /// In en, this message translates to:
  /// **'New task (Ctrl+N)'**
  String get treeNewTask;

  /// Tooltip of the tree toolbar's add-child button, with its shortcut
  ///
  /// In en, this message translates to:
  /// **'New child task (Ctrl+Shift+N)'**
  String get treeNewChildTask;

  /// Tooltip of the tree toolbar's delete button
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get treeDeleteTask;

  /// No description provided for @treeExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get treeExpandAll;

  /// No description provided for @treeCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get treeCollapseAll;

  /// Shown in an empty outline
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get treeNoTasks;

  /// Button in an empty outline
  ///
  /// In en, this message translates to:
  /// **'Create your first task'**
  String get treeCreateFirstTask;

  /// Tooltip of the timer icon on the tracked task's row
  ///
  /// In en, this message translates to:
  /// **'Time is being tracked on this task'**
  String get treeTrackedHere;

  /// Tooltip of the timer badge on a collapsed row that hides the tracked task
  ///
  /// In en, this message translates to:
  /// **'Time is being tracked on a task inside'**
  String get treeTrackedInside;

  /// Tooltip of the badge on a branch excluded from the MCP server
  ///
  /// In en, this message translates to:
  /// **'Hidden from AI agents, including everything under it'**
  String get treeHiddenFromAgents;

  /// Tree context menu item
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get treeMoveUp;

  /// Tree context menu item
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get treeMoveDown;

  /// Tree context menu item: outdent the task
  ///
  /// In en, this message translates to:
  /// **'Move to parent level'**
  String get treeMoveToParentLevel;

  /// Tree context menu item: indent the task under the sibling above
  ///
  /// In en, this message translates to:
  /// **'Move under previous'**
  String get treeMoveUnderPrevious;

  /// Tree context menu item
  ///
  /// In en, this message translates to:
  /// **'Add child task'**
  String get treeAddChildTask;

  /// Tree context menu item: start time tracking on this task
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get treeStartTracking;

  /// Tree context menu item: stop time tracking
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get treeStopTracking;

  /// Tree context menu item; opens the task's time records
  ///
  /// In en, this message translates to:
  /// **'Timeline...'**
  String get treeTimeline;

  /// Placeholder of the search field
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchHint;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String searchResultCount(int count);

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoMatches;

  /// Shown in search results for a task with an empty title
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get searchUntitled;

  /// Shown in place of an attachment image preview that cannot be decoded
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get attachImageNotAvailable;

  /// Tooltip of the retry button after audio playback of an attachment failed
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get attachTryAgain;

  /// Tooltip: start audio playback of an attachment
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get attachPlay;

  /// Tooltip: pause audio playback of an attachment
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get attachPause;

  /// The attachment list of a task could not be read; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Failed to load attachments: {error}'**
  String attachLoadFailed(String error);

  /// Empty state of a task's attachment list
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get attachNone;

  /// Button in the empty attachment list
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get attachAddFile;

  /// Snack bar: the attachment's bytes have not arrived from another device yet
  ///
  /// In en, this message translates to:
  /// **'This attachment has not been downloaded yet — sync to fetch it'**
  String get attachNotDownloaded;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Failed to load attachment content'**
  String get attachContentLoadFailed;

  /// Progress dialog while one attachment is fetched from another device
  ///
  /// In en, this message translates to:
  /// **'Downloading attachment…'**
  String get attachDownloading;

  /// Title of the save-file dialog when exporting an attachment
  ///
  /// In en, this message translates to:
  /// **'Export attachment'**
  String get attachExportDialogTitle;

  /// Snack bar after an attachment was saved; name is the file name
  ///
  /// In en, this message translates to:
  /// **'Exported: {name}'**
  String attachExported(String name);

  /// Phone: no installed app handles this file type; name is the file name
  ///
  /// In en, this message translates to:
  /// **'No app can open {name}'**
  String attachNoAppCanOpen(String name);

  /// Dialog title: an attachment cannot be deleted because the note shows it as an image
  ///
  /// In en, this message translates to:
  /// **'Image is in the note'**
  String get attachImageInNoteTitle;

  /// Dialog body. "Delete image" and "Remove from text" are the names of items in the image's own menu in the editor; use the same translations as those menu items. name is the file name
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" is shown in this task\'s note, so it cannot be deleted from here.\n\nClick the image in the note and choose \"Delete image\" to remove both the picture and the file, or \"Remove from text\" to keep the file and delete it here afterwards.'**
  String attachImageInNoteBody(String name);

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete attachment?'**
  String get attachDeleteTitle;

  /// Confirmation dialog body; name is the attachment's file name
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String attachDeleteConfirm(String name);

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename attachment'**
  String get attachRenameTitle;

  /// Label of the text field in the Rename attachment dialog
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get attachFileName;

  /// Tooltip: expand an image attachment's preview
  ///
  /// In en, this message translates to:
  /// **'Show preview'**
  String get attachShowPreview;

  /// Tooltip: collapse an image attachment's preview
  ///
  /// In en, this message translates to:
  /// **'Hide preview'**
  String get attachHidePreview;

  /// Attachment row menu item (phones): hand the file to another app
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get attachShare;

  /// Attachment row menu item (desktop): save the file to disk
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get attachExport;

  /// Attachment row menu item: turn a voice memo into text in the note
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get attachTranscribe;

  /// Error shown under an audio attachment whose playback failed
  ///
  /// In en, this message translates to:
  /// **'Cannot play this file'**
  String get attachCannotPlay;

  /// Error shown under an audio attachment when the player cannot be reached
  ///
  /// In en, this message translates to:
  /// **'Playback is unavailable'**
  String get attachPlaybackUnavailable;

  /// Notice in the recording bar after a voice memo hit the maximum length
  ///
  /// In en, this message translates to:
  /// **'Recording stopped at the {minutes, plural, other{{minutes} minute}} limit. The memo was saved.'**
  String voiceStoppedAtLimit(int minutes);

  /// Tooltip on the recording bar's icon once the memo reached its maximum length
  ///
  /// In en, this message translates to:
  /// **'Reached the {minutes, plural, other{{minutes} minute}} limit'**
  String voiceReachedLimit(int minutes);

  /// Tooltip: close the voice memo notice
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get voiceDismiss;

  /// Recording bar while the microphone starts
  ///
  /// In en, this message translates to:
  /// **'Opening the microphone…'**
  String get voiceOpeningMic;

  /// Recording bar while the memo is being stored
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get voiceSaving;

  /// Recording bar: the memo is stored and is now being turned into text
  ///
  /// In en, this message translates to:
  /// **'Saved. Transcribing…'**
  String get voiceSavedTranscribing;

  /// Like voiceSavedTranscribing, with progress; percent is 0-100
  ///
  /// In en, this message translates to:
  /// **'Saved. Transcribing… {percent}%'**
  String voiceSavedTranscribingPercent(int percent);

  /// Tooltip: throw away the recording in progress
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get voiceDiscard;

  /// Button: stop recording and save the memo
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get voiceStop;

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Choose a transcription model in Preferences first'**
  String get voiceChooseModelFirst;

  /// Snack bar; model is the name of a speech recognition model
  ///
  /// In en, this message translates to:
  /// **'The {model} model has not been downloaded yet — see Preferences'**
  String voiceModelNotDownloaded(String model);

  /// Snack bar while a stored memo is turned into text
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get voiceTranscribing;

  /// Like voiceTranscribing, with progress; percent is 0-100
  ///
  /// In en, this message translates to:
  /// **'Transcribing… {percent}%'**
  String voiceTranscribingPercent(int percent);

  /// Snack bar; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Could not transcribe: {error}'**
  String voiceTranscribeFailed(String error);

  /// Snack bar after transcription found no words
  ///
  /// In en, this message translates to:
  /// **'No speech found in this memo'**
  String get voiceNoSpeech;

  /// Snack bar: the text could not be inserted because the user moved to another task
  ///
  /// In en, this message translates to:
  /// **'Transcribed, but the note it belongs to is not open'**
  String get voiceTranscribedNoteNotOpen;

  /// Recording bar notice
  ///
  /// In en, this message translates to:
  /// **'The recording was discarded because another database was opened.'**
  String get voiceDiscardedDatabaseSwitched;

  /// Recording error
  ///
  /// In en, this message translates to:
  /// **'Microphone permission was refused'**
  String get voiceMicPermissionRefused;

  /// Recording error; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Could not start recording: {error}'**
  String voiceStartFailed(String error);

  /// Recording error; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Recording failed: {error}'**
  String voiceRecordingFailed(String error);

  /// Recording error; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Could not finish the recording: {error}'**
  String voiceFinishFailed(String error);

  /// Recording error
  ///
  /// In en, this message translates to:
  /// **'No database is open, so the memo could not be saved'**
  String get voiceNoDatabase;

  /// Recording error; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Could not save the memo: {error}'**
  String voiceSaveFailed(String error);

  /// Title of the dialog listing a task's time records
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeTimelineTitle;

  /// Label in the time statistics panel, followed by a duration
  ///
  /// In en, this message translates to:
  /// **'Today:'**
  String get timeStatsToday;

  /// Label in the time statistics panel, followed by a duration
  ///
  /// In en, this message translates to:
  /// **'This month:'**
  String get timeStatsThisMonth;

  /// Time tracking is running; time is a clock time like 14:05
  ///
  /// In en, this message translates to:
  /// **'Recording since {time}'**
  String timeRecordingSince(String time);

  /// Validation error in the time interval dialog
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get timeEndBeforeStart;

  /// Validation error in the time interval dialog
  ///
  /// In en, this message translates to:
  /// **'Overlaps with an existing interval'**
  String get timeOverlaps;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Add Time Interval'**
  String get timeAddIntervalTitle;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Time Interval'**
  String get timeEditIntervalTitle;

  /// Label in the time interval dialog, followed by date and time buttons; column is about 90px wide
  ///
  /// In en, this message translates to:
  /// **'Start time:'**
  String get timeStartTime;

  /// Label in the time interval dialog, followed by date and time buttons; column is about 90px wide
  ///
  /// In en, this message translates to:
  /// **'Finish time:'**
  String get timeFinishTime;

  /// Label in the time interval dialog; column is about 90px wide
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get timeDurationLabel;

  /// Length of a time interval of at least one hour and one minute
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, other{{hours} hours}} {minutes, plural, other{{minutes} minutes}}'**
  String timeDurationHoursMinutes(int hours, int minutes);

  /// Length of a time interval in whole hours
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, other{{hours} hours}}'**
  String timeDurationHours(int hours);

  /// Length of a time interval under an hour, or in whole minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, other{{minutes} minutes}}'**
  String timeDurationMinutes(int minutes);

  /// Compact duration with abbreviated units, as in a list of time intervals or a report total ("2h 30m"). Use the usual short unit forms of the language.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String timeShortHoursMinutes(int hours, int minutes);

  /// Compact duration with abbreviated units, as in a list of time intervals or a report total ("2h 30m"). Use the usual short unit forms of the language.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String timeShortHours(int hours);

  /// Compact duration with abbreviated units, as in a list of time intervals or a report total ("2h 30m"). Use the usual short unit forms of the language.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String timeShortMinutes(int minutes);

  /// Compact duration with abbreviated units, as in a list of time intervals or a report total ("2h 30m"). Use the usual short unit forms of the language.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String timeShortSeconds(int seconds);

  /// Button in the Timeline dialog that opens the Add Time Interval dialog
  ///
  /// In en, this message translates to:
  /// **'Add...'**
  String get timeAddEllipsis;

  /// Empty state of the Timeline dialog
  ///
  /// In en, this message translates to:
  /// **'No time records'**
  String get timeNoRecords;

  /// Day node in the timeline tree, e.g. '23 (Mon)'; weekday is the abbreviated weekday name
  ///
  /// In en, this message translates to:
  /// **'{day} ({weekday})'**
  String timeDayWithWeekday(int day, String weekday);

  /// End of a time interval that is still running, as in '14:05 - now'
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeNow;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove interval?'**
  String get timeRemoveIntervalTitle;

  /// Confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this time interval?'**
  String get timeRemoveIntervalConfirm;

  /// Mini tracker window, when no task is tracked and none is selected
  ///
  /// In en, this message translates to:
  /// **'Not tracking'**
  String get timeNotTracking;

  /// Accessibility label of the mini tracker's stop button
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get timeStopTracking;

  /// Accessibility label of the mini tracker's start button
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get timeStartTracking;

  /// Accessibility label of the mini tracker's restore button
  ///
  /// In en, this message translates to:
  /// **'Back to the full window'**
  String get timeBackToFullWindow;

  /// Title of the Time Report dialog
  ///
  /// In en, this message translates to:
  /// **'Time Report'**
  String get timeReportTitle;

  /// Title of the save-file dialog
  ///
  /// In en, this message translates to:
  /// **'Save Time Report'**
  String get timeReportSaveTitle;

  /// Snack bar; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Failed to generate report: {error}'**
  String timeReportGenerateFailed(String error);

  /// Snack bar
  ///
  /// In en, this message translates to:
  /// **'Report copied to clipboard'**
  String get timeReportCopied;

  /// Snack bar; path is a file path
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String timeReportSavedTo(String path);

  /// Snack bar; error is a technical message
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String timeReportSaveFailed(String error);

  /// Section title in the Time Report dialog
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get timeReportTasks;

  /// Time Report dialog, empty task list
  ///
  /// In en, this message translates to:
  /// **'No tasks available.'**
  String get timeReportNoTasks;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get timeReportClearSelection;

  /// Number of tasks ticked in the Time Report dialog
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String timeReportSelectedCount(int count);

  /// Checkbox title
  ///
  /// In en, this message translates to:
  /// **'Include descendants'**
  String get timeReportIncludeDescendants;

  /// Checkbox subtitle under 'Include descendants'
  ///
  /// In en, this message translates to:
  /// **'Also report time from child tasks of each selected node.'**
  String get timeReportIncludeDescendantsHint;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get timeReportDateRange;

  /// Button showing the start of the report period; date is like 2026-11-23
  ///
  /// In en, this message translates to:
  /// **'From: {date}'**
  String timeReportFrom(String date);

  /// Button showing the end of the report period; date is like 2026-11-23
  ///
  /// In en, this message translates to:
  /// **'To: {date}'**
  String timeReportTo(String date);

  /// Section title: output format of the report
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get timeReportFormat;

  /// Report format option
  ///
  /// In en, this message translates to:
  /// **'Tree (totals only)'**
  String get timeReportFormatTree;

  /// Report format option
  ///
  /// In en, this message translates to:
  /// **'Tree with per-day breakdown'**
  String get timeReportFormatTreeWithDays;

  /// Report format option
  ///
  /// In en, this message translates to:
  /// **'Flat interval list'**
  String get timeReportFormatFlat;

  /// Checkbox: include tasks with no recorded time
  ///
  /// In en, this message translates to:
  /// **'Show empty tasks'**
  String get timeReportShowEmpty;

  /// Task list entry for a task with an empty title
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get timeReportUntitled;

  /// Placeholder where the report preview goes
  ///
  /// In en, this message translates to:
  /// **'Select one or more tasks to generate a report.'**
  String get timeReportSelectTasks;

  /// Placeholder where the report preview goes
  ///
  /// In en, this message translates to:
  /// **'No time records in the selected period.'**
  String get timeReportNoRecordsInPeriod;

  /// Label in the generated time report text (Markdown, shown bold), followed by the date range. Include the colon as your language writes it.
  ///
  /// In en, this message translates to:
  /// **'Period:'**
  String get timeReportTextPeriod;

  /// Label in the generated time report text, followed by the total duration.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get timeReportTextTotal;

  /// Label in the generated time report text, followed by the date and time the report was made.
  ///
  /// In en, this message translates to:
  /// **'Generated:'**
  String get timeReportTextGenerated;

  /// Note in the generated time report text: time records that start before or end after the chosen period count only the part inside it.
  ///
  /// In en, this message translates to:
  /// **'Records that straddle the period boundaries are clipped to the range.'**
  String get timeReportTextClipped;

  /// In the tree report, after a task's total (which includes its subtasks): the time recorded on the task itself.
  ///
  /// In en, this message translates to:
  /// **'self: {duration}'**
  String timeReportTextSelf(String duration);

  /// In the flat report, after an interval whose clock is still running.
  ///
  /// In en, this message translates to:
  /// **'ongoing'**
  String get timeReportTextOngoing;

  /// Footer of the Time Report dialog; duration is like '2h 30m'. Keep the spacing around the bullet
  ///
  /// In en, this message translates to:
  /// **'Total: {duration}   •   {count, plural, =1{1 record} other{{count} records}}'**
  String timeReportTotal(String duration, int count);

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get timeReportRegenerate;

  /// Button (phones): share the report
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get timeReportShare;

  /// Button (desktop): save the report to a file
  ///
  /// In en, this message translates to:
  /// **'Save…'**
  String get timeReportSave;

  /// Date range preset chip
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timeReportPresetToday;

  /// Date range preset chip
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get timeReportPresetThisWeek;

  /// Date range preset chip
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get timeReportPresetThisMonth;

  /// Date range preset chip
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get timeReportPresetLastMonth;

  /// Date range preset chip
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get timeReportPresetThisYear;

  /// Title of the Preferences dialog
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get prefsTitle;

  /// Preferences tab
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get prefsTabAppearance;

  /// Preferences tab
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get prefsTabBehavior;

  /// Preferences tab
  ///
  /// In en, this message translates to:
  /// **'Voice memos'**
  String get prefsTabVoiceMemos;

  /// Preferences tab
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get prefsTabSync;

  /// Preferences tab (MCP = Model Context Protocol, a product name)
  ///
  /// In en, this message translates to:
  /// **'MCP'**
  String get prefsTabMcp;

  /// A field caption in a property-sheet form, followed by its control
  ///
  /// In en, this message translates to:
  /// **'{label}:'**
  String prefsFieldLabel(String label);

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get prefsGroupLanguage;

  /// Preferences > Appearance > Language: caption of the interface language dropdown (short)
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get prefsInterfaceLanguage;

  /// Hint under the interface language dropdown
  ///
  /// In en, this message translates to:
  /// **'Translations other than English are machine-made; corrections are welcome.'**
  String get prefsLanguageHint;

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get prefsGroupTheme;

  /// Preferences > Appearance > Theme: light/dark mode caption
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get prefsThemeMode;

  /// Theme mode: follow the operating system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get prefsThemeSystem;

  /// Theme mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get prefsThemeLight;

  /// Theme mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get prefsThemeDark;

  /// Preferences > Appearance: group box title (look of the app)
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get prefsGroupStyle;

  /// Preferences > Appearance: group box title on phones, where only the accent colour is offered
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get prefsGroupColour;

  /// Preferences > Appearance > Style: caption of the Modern/Classic choice
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get prefsLook;

  /// No description provided for @prefsLookHint.
  ///
  /// In en, this message translates to:
  /// **'Classic: square corners, flat bordered buttons, no ripples, scrollbars always shown, and a title bar in the accent colour with the menu beneath it.'**
  String get prefsLookHint;

  /// UI style name
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get prefsUiStyleModern;

  /// UI style name
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get prefsUiStyleClassic;

  /// Preferences > Appearance: caption of the accent colour swatches
  ///
  /// In en, this message translates to:
  /// **'Accent colour'**
  String get prefsAccentColour;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get prefsAccentTeal;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get prefsAccentBlue;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get prefsAccentIndigo;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get prefsAccentPurple;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get prefsAccentPink;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get prefsAccentRed;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get prefsAccentOrange;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get prefsAccentAmber;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get prefsAccentGreen;

  /// Accent colour name (tooltip of a colour swatch)
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get prefsAccentGraphite;

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get prefsGroupWindow;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Use the system title bar'**
  String get prefsSystemTitleBar;

  /// No description provided for @prefsSystemTitleBarHint.
  ///
  /// In en, this message translates to:
  /// **'The window frame, title and buttons as the desktop draws them, with the menu bar beneath.'**
  String get prefsSystemTitleBarHint;

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Editor font (the text of a note)'**
  String get prefsGroupEditorFont;

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Tree font (the outline)'**
  String get prefsGroupTreeFont;

  /// Preferences > Appearance: group box title
  ///
  /// In en, this message translates to:
  /// **'Interface font (menus & dialogs)'**
  String get prefsGroupInterfaceFont;

  /// Font family caption
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get prefsFontFamily;

  /// Font family dropdown entry that lets the user type a family name
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get prefsFontCustom;

  /// Caption of the field where a custom font family name is typed
  ///
  /// In en, this message translates to:
  /// **'Custom name'**
  String get prefsCustomName;

  /// Placeholder text of the custom font family field
  ///
  /// In en, this message translates to:
  /// **'e.g. {font}'**
  String prefsCustomFamilyExample(String font);

  /// Font size caption
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get prefsFontSize;

  /// Unit after a font size (points); very short
  ///
  /// In en, this message translates to:
  /// **'pt'**
  String get prefsUnitPt;

  /// Font style caption (bold/italic checkboxes follow)
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get prefsFontStyle;

  /// Font style checkbox
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get prefsBold;

  /// Font style checkbox
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get prefsItalic;

  /// Caption of the font preview box
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get prefsPreview;

  /// Sample text in the font preview; use a pangram or a typical sentence of the language
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog.'**
  String get prefsPreviewText;

  /// Interface font size scale caption (value in percent)
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get prefsScale;

  /// Generic font family name
  ///
  /// In en, this message translates to:
  /// **'Sans Serif'**
  String get prefsFontSansSerif;

  /// Generic font family name
  ///
  /// In en, this message translates to:
  /// **'Serif'**
  String get prefsFontSerif;

  /// Generic font family name
  ///
  /// In en, this message translates to:
  /// **'Monospace'**
  String get prefsFontMonospace;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Time tracking'**
  String get prefsGroupTimeTracking;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Enable time tracking'**
  String get prefsEnableTimeTracking;

  /// No description provided for @prefsEnableTimeTrackingHint.
  ///
  /// In en, this message translates to:
  /// **'Start/stop tracking, timelines and time reports. Turning it off hides them; recorded time is kept'**
  String get prefsEnableTimeTrackingHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Show seconds'**
  String get prefsShowSeconds;

  /// No description provided for @prefsShowSecondsHint.
  ///
  /// In en, this message translates to:
  /// **'Display seconds in time durations'**
  String get prefsShowSecondsHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Show mini window while tracking'**
  String get prefsMiniTracker;

  /// No description provided for @prefsMiniTrackerHint.
  ///
  /// In en, this message translates to:
  /// **'While a clock runs, minimizing the window shrinks it to a small always-on-top clock instead'**
  String get prefsMiniTrackerHint;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get prefsGroupSaving;

  /// Caption before a number of seconds
  ///
  /// In en, this message translates to:
  /// **'Auto-save every'**
  String get prefsAutoSaveEvery;

  /// Unit after a number of seconds; very short
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get prefsUnitSec;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get prefsGroupEditor;

  /// Caption: width of a tab character
  ///
  /// In en, this message translates to:
  /// **'Tab width'**
  String get prefsTabWidth;

  /// Unit after the tab width number; short
  ///
  /// In en, this message translates to:
  /// **'spaces'**
  String get prefsUnitSpaces;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Insert tabs as spaces'**
  String get prefsTabAsSpaces;

  /// No description provided for @prefsTabAsSpacesHint.
  ///
  /// In en, this message translates to:
  /// **'Pressing Tab inserts spaces instead of a tab'**
  String get prefsTabAsSpacesHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get prefsWordWrap;

  /// No description provided for @prefsWordWrapHint.
  ///
  /// In en, this message translates to:
  /// **'Off: long lines run on and the note scrolls sideways (Shift + wheel). Also in the editor\'s context menu and the status bar'**
  String get prefsWordWrapHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Monospace fonts only'**
  String get prefsMonospaceOnly;

  /// No description provided for @prefsMonospaceOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'The toolbar\'s Font menu offers only the fixed-width family, so text meant to line up stays lined up'**
  String get prefsMonospaceOnlyHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Floating buttons'**
  String get prefsFloatingButtons;

  /// No description provided for @prefsFloatingButtonsHint.
  ///
  /// In en, this message translates to:
  /// **'Attach file and Record voice memo over the note; the toolbar keeps its own buttons either way'**
  String get prefsFloatingButtonsHint;

  /// Caption of the paste formatting dropdown
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get prefsPaste;

  /// Keep the shortcut as is
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Shift+V always pastes plain text'**
  String get prefsPasteHint;

  /// Paste formatting option
  ///
  /// In en, this message translates to:
  /// **'Keep formatting'**
  String get prefsPasteKeep;

  /// Paste formatting option
  ///
  /// In en, this message translates to:
  /// **'Remove colours and fonts'**
  String get prefsPasteStrip;

  /// Paste formatting option
  ///
  /// In en, this message translates to:
  /// **'Plain text only'**
  String get prefsPastePlain;

  /// Caption of the table separator dropdown
  ///
  /// In en, this message translates to:
  /// **'Table columns'**
  String get prefsTableColumns;

  /// "Format as table" is the name of an editor context menu command
  ///
  /// In en, this message translates to:
  /// **'What Format as table (editor context menu) splits columns on. Not inside URLs or quoted text'**
  String get prefsTableColumnsHint;

  /// Table separator option; keep the character in brackets
  ///
  /// In en, this message translates to:
  /// **'Colon  ( : )'**
  String get prefsSeparatorColon;

  /// Table separator option; keep the character in brackets
  ///
  /// In en, this message translates to:
  /// **'Equals sign  ( = )'**
  String get prefsSeparatorEquals;

  /// Table separator option; keep the character in brackets
  ///
  /// In en, this message translates to:
  /// **'Vertical bar  ( | )'**
  String get prefsSeparatorPipe;

  /// Table separator option; keep the character in brackets
  ///
  /// In en, this message translates to:
  /// **'Semicolon  ( ; )'**
  String get prefsSeparatorSemicolon;

  /// Table separator option; keep the character in brackets
  ///
  /// In en, this message translates to:
  /// **'Comma  ( , )'**
  String get prefsSeparatorComma;

  /// The Tab character as a table separator; also shown in the editor menu entry "Format as table (Tab)"
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get prefsSeparatorTab;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Toolbar buttons'**
  String get prefsGroupToolbarButtons;

  /// No description provided for @prefsToolbarButtonsHint.
  ///
  /// In en, this message translates to:
  /// **'Untick a button to take it off the editor toolbar.'**
  String get prefsToolbarButtonsHint;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Undo / Redo'**
  String get prefsToolbarUndoRedo;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get prefsToolbarFont;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get prefsToolbarSize;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get prefsToolbarBold;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get prefsToolbarItalic;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get prefsToolbarUnderline;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get prefsToolbarStrikeThrough;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get prefsToolbarInlineCode;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Text colour'**
  String get prefsToolbarTextColor;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Highlight colour'**
  String get prefsToolbarHighlightColor;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Clear formatting'**
  String get prefsToolbarClearFormat;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Headings'**
  String get prefsToolbarHeadings;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get prefsToolbarNumberedList;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Bulleted list'**
  String get prefsToolbarBulletedList;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get prefsToolbarChecklist;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Code block'**
  String get prefsToolbarCodeBlock;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get prefsToolbarQuote;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get prefsToolbarIndent;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get prefsToolbarLink;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get prefsToolbarInsertImage;

  /// Name of an editor toolbar button, in the Preferences list of toolbar buttons (checkbox, short)
  ///
  /// In en, this message translates to:
  /// **'Voice memo'**
  String get prefsToolbarVoiceMemo;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get prefsGroupSecurity;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Remember password'**
  String get prefsRememberPassword;

  /// No description provided for @prefsRememberPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Store database password in system keychain'**
  String get prefsRememberPasswordHint;

  /// Checkbox (Android)
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get prefsBiometricUnlock;

  /// No description provided for @prefsBiometricUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Unavailable — set up a fingerprint or screen lock in Android settings first'**
  String get prefsBiometricUnavailableHint;

  /// No description provided for @prefsBiometricHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm fingerprint, face, or screen lock before the remembered password is used'**
  String get prefsBiometricHint;

  /// Checkbox (Android)
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get prefsBlockScreenshots;

  /// No description provided for @prefsBlockScreenshotsHint.
  ///
  /// In en, this message translates to:
  /// **'Hide app content in screenshots, screen recording, and the recent-apps switcher'**
  String get prefsBlockScreenshotsHint;

  /// Preferences > Behavior: group box title
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get prefsGroupStartup;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Single instance'**
  String get prefsSingleInstance;

  /// No description provided for @prefsSingleInstanceHint.
  ///
  /// In en, this message translates to:
  /// **'Allow only one running window; a new launch focuses the existing one. Takes effect on next launch.'**
  String get prefsSingleInstanceHint;

  /// Preferences > Voice memos: group box title (audio devices)
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get prefsVoiceGroupDevices;

  /// Caption of the microphone dropdown
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get prefsVoiceMicrophone;

  /// No description provided for @prefsVoiceMicrophoneHint.
  ///
  /// In en, this message translates to:
  /// **'Used for voice memos and for the check below.'**
  String get prefsVoiceMicrophoneHint;

  /// Caption of the speaker (audio output) dropdown
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get prefsVoiceSpeaker;

  /// No description provided for @prefsVoiceSpeakerHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to voice memos. Other audio attachments play through the system default.'**
  String get prefsVoiceSpeakerHint;

  /// Shown while audio devices are being listed
  ///
  /// In en, this message translates to:
  /// **'Looking…'**
  String get prefsVoiceDevicesLooking;

  /// No description provided for @prefsVoiceDevicesError.
  ///
  /// In en, this message translates to:
  /// **'No audio devices could be listed: {error}'**
  String prefsVoiceDevicesError(String error);

  /// Shown instead of a device dropdown when no devices could be listed
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get prefsVoiceDevicesUnavailable;

  /// An audio device the system uses by default
  ///
  /// In en, this message translates to:
  /// **'{name} (default)'**
  String prefsVoiceDeviceDefault(String name);

  /// A selected audio device that is not present
  ///
  /// In en, this message translates to:
  /// **'{name} (not connected)'**
  String prefsVoiceDeviceMissing(String name);

  /// Preferences > Voice memos: group box title
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get prefsVoiceGroupTranscription;

  /// Caption of the speech recognition model dropdown
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get prefsVoiceModel;

  /// No description provided for @prefsVoiceModelHintNone.
  ///
  /// In en, this message translates to:
  /// **'Memos are recorded and stored as audio only.'**
  String get prefsVoiceModelHintNone;

  /// No description provided for @prefsVoiceModelHintLocal.
  ///
  /// In en, this message translates to:
  /// **'Runs on this device. Nothing is sent anywhere.'**
  String get prefsVoiceModelHintLocal;

  /// Model dropdown entry: no transcription
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get prefsVoiceModelOff;

  /// Model dropdown entry
  ///
  /// In en, this message translates to:
  /// **'{model} · {size}'**
  String prefsVoiceModelItem(String model, String size);

  /// Model dropdown entry for the recommended model
  ///
  /// In en, this message translates to:
  /// **'{model} · {size} · recommended'**
  String prefsVoiceModelItemRecommended(String model, String size);

  /// A size in megabytes
  ///
  /// In en, this message translates to:
  /// **'{count} MB'**
  String prefsMegabytes(String count);

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Transcribe after recording'**
  String get prefsVoiceTranscribeAfter;

  /// "Transcribe" is the name of an attachment menu item
  ///
  /// In en, this message translates to:
  /// **'A memo is stored first and transcribed from the stored audio. Off stores it untranscribed; \"Transcribe\" in the attachment menu still works later.'**
  String get prefsVoiceTranscribeAfterHint;

  /// Caption of the transcription language dropdown
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get prefsVoiceLanguage;

  /// Transcription language option: let the recogniser detect it
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get prefsVoiceLanguageAuto;

  /// No description provided for @prefsVoiceFooter.
  ///
  /// In en, this message translates to:
  /// **'Recording works without a model — memos are always stored as audio, and play back like any other attachment. A model only adds the text.'**
  String get prefsVoiceFooter;

  /// Preferences > Voice memos: group box title of the audio self-test
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get prefsVoiceGroupCheck;

  /// No description provided for @prefsVoiceCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'Records a few seconds, plays them back and transcribes them, using the devices and model above. Nothing is saved.'**
  String get prefsVoiceCheckIntro;

  /// Button: stop recording
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get prefsVoiceStop;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Test again'**
  String get prefsVoiceTestAgain;

  /// "Stop" is the button label
  ///
  /// In en, this message translates to:
  /// **'Recording — say a sentence, then press Stop.'**
  String get prefsVoiceCheckRecording;

  /// No description provided for @prefsVoiceCheckPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing it back…'**
  String get prefsVoiceCheckPlaying;

  /// No description provided for @prefsVoiceCheckTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get prefsVoiceCheckTranscribing;

  /// No description provided for @prefsVoiceCheckTranscribingPercent.
  ///
  /// In en, this message translates to:
  /// **'Transcribing… {percent}%'**
  String prefsVoiceCheckTranscribingPercent(int percent);

  /// After the self-test
  ///
  /// In en, this message translates to:
  /// **'Recorded {duration}.'**
  String prefsVoiceCheckDone(String duration);

  /// No description provided for @prefsVoiceCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The check did not finish.'**
  String get prefsVoiceCheckFailed;

  /// No description provided for @prefsVoiceDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get prefsVoiceDownloading;

  /// Model download progress
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {size}'**
  String prefsVoiceDownloadProgress(int percent, String size);

  /// No description provided for @prefsVoiceModelReady.
  ///
  /// In en, this message translates to:
  /// **'{model} is downloaded and ready.'**
  String prefsVoiceModelReady(String model);

  /// No description provided for @prefsVoiceModelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded — {size} from HuggingFace.'**
  String prefsVoiceModelNotDownloaded(String size);

  /// No description provided for @prefsCheckBusy.
  ///
  /// In en, this message translates to:
  /// **'A voice memo is being recorded. Finish it first.'**
  String get prefsCheckBusy;

  /// No description provided for @prefsCheckPermissionRefused.
  ///
  /// In en, this message translates to:
  /// **'The microphone permission was refused.'**
  String get prefsCheckPermissionRefused;

  /// No description provided for @prefsCheckMicWouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'The microphone would not open: {error}'**
  String prefsCheckMicWouldNotOpen(String error);

  /// No description provided for @prefsCheckRecordingFailed.
  ///
  /// In en, this message translates to:
  /// **'Recording failed: {error}'**
  String prefsCheckRecordingFailed(String error);

  /// No description provided for @prefsCheckNotFinished.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be finished: {error}'**
  String prefsCheckNotFinished(String error);

  /// No description provided for @prefsCheckNothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recorded. Hold the test a moment longer, or pick another microphone.'**
  String get prefsCheckNothingRecorded;

  /// No description provided for @prefsCheckMalformed.
  ///
  /// In en, this message translates to:
  /// **'The recording came back malformed and would not play.'**
  String get prefsCheckMalformed;

  /// No description provided for @prefsCheckPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed: {error}'**
  String prefsCheckPlaybackFailed(String error);

  /// No description provided for @prefsCheckNoModel.
  ///
  /// In en, this message translates to:
  /// **'Recording and playback worked. No model is selected, so there is nothing to transcribe.'**
  String get prefsCheckNoModel;

  /// No description provided for @prefsCheckModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Recording and playback worked. {model} has not been downloaded yet, so nothing was transcribed.'**
  String prefsCheckModelMissing(String model);

  /// No description provided for @prefsCheckTranscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed: {error}'**
  String prefsCheckTranscriptionFailed(String error);

  /// No description provided for @prefsCheckSilence.
  ///
  /// In en, this message translates to:
  /// **'The microphone produced silence — the level meter never moved. Check that the right device is selected and that the app may use it.'**
  String get prefsCheckSilence;

  /// "whisper" is the speech recogniser's name
  ///
  /// In en, this message translates to:
  /// **'Recording and playback worked, but whisper found no speech. Try speaking closer to the microphone, or another language.'**
  String get prefsCheckNoSpeech;

  /// No description provided for @prefsCheckQuiet.
  ///
  /// In en, this message translates to:
  /// **'The level meter never moved, so the input is very quiet.'**
  String get prefsCheckQuiet;

  /// No description provided for @prefsDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled.'**
  String get prefsDownloadCancelled;

  /// No description provided for @prefsDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String prefsDownloadFailed(String error);

  /// Stands for a task with an empty title in a list of tasks
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get prefsUntitled;

  /// "Regenerate" is a button label
  ///
  /// In en, this message translates to:
  /// **'Saved for this session only: the system keychain refused it. If your keyring is locked, unlock it and press Regenerate.'**
  String get prefsMcpTokenSessionOnly;

  /// Confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Regenerate token?'**
  String get prefsMcpRegenerateTitle;

  /// No description provided for @prefsMcpRegenerateBody.
  ///
  /// In en, this message translates to:
  /// **'Agents configured with the current token will stop working until you paste the new one into their settings.'**
  String get prefsMcpRegenerateBody;

  /// Button: create a new access token
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get prefsMcpRegenerate;

  /// Preferences > MCP: group box title (AI agents)
  ///
  /// In en, this message translates to:
  /// **'Agent access'**
  String get prefsMcpGroupAccess;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Enable MCP server'**
  String get prefsMcpEnable;

  /// No description provided for @prefsMcpEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Let local AI coding agents read this outline over 127.0.0.1. Off by default.'**
  String get prefsMcpEnableHint;

  /// Checkbox
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get prefsMcpReadOnly;

  /// No description provided for @prefsMcpReadOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Agents can search and read tasks but cannot create, change, move or delete them.'**
  String get prefsMcpReadOnlyHint;

  /// Preferences > MCP: group box title (network address of the server)
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get prefsMcpGroupEndpoint;

  /// Network port caption
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get prefsMcpPort;

  /// Caption
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get prefsMcpUrl;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get prefsMcpCopyUrl;

  /// Caption of the access token field
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get prefsMcpToken;

  /// No description provided for @prefsMcpTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Anyone who can run programs as you can use this token. Treat it like a password.'**
  String get prefsMcpTokenHint;

  /// Placeholder of the empty token field
  ///
  /// In en, this message translates to:
  /// **'No token yet — enable the server to create one'**
  String get prefsMcpNoTokenYet;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get prefsMcpShowToken;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get prefsMcpHideToken;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Copy token'**
  String get prefsMcpCopyToken;

  /// Shown briefly after something was copied to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get prefsMcpCopied;

  /// Preferences > MCP: group box title, and title of the dialog choosing them (parts of the outline hidden from AI agents)
  ///
  /// In en, this message translates to:
  /// **'Excluded branches'**
  String get prefsMcpGroupExcluded;

  /// No description provided for @prefsMcpExcludedIntro.
  ///
  /// In en, this message translates to:
  /// **'Tasks hidden from the MCP server, together with everything under them.'**
  String get prefsMcpExcludedIntro;

  /// No description provided for @prefsMcpLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get prefsMcpLoading;

  /// No description provided for @prefsMcpOutlineReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the outline.'**
  String get prefsMcpOutlineReadError;

  /// Button opening the excluded branches dialog
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get prefsMcpChoose;

  /// No description provided for @prefsMcpNothingExcluded.
  ///
  /// In en, this message translates to:
  /// **'Nothing is excluded — agents can see the whole outline.'**
  String get prefsMcpNothingExcluded;

  /// After a short list of excluded branches: how many more there are
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{and {count} more}}'**
  String prefsMcpMoreBranches(int count);

  /// MCP server status
  ///
  /// In en, this message translates to:
  /// **'Listening on {url}'**
  String prefsMcpListening(String url);

  /// No description provided for @prefsMcpPortUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Port {port} is not available. Choose another port.'**
  String prefsMcpPortUnavailable(String port);

  /// "Regenerate" is a button label
  ///
  /// In en, this message translates to:
  /// **'No access token. Press Regenerate to create one.'**
  String get prefsMcpNoAccessToken;

  /// MCP server status
  ///
  /// In en, this message translates to:
  /// **'Waiting for a database to be opened.'**
  String get prefsMcpWaitingDatabase;

  /// MCP server status
  ///
  /// In en, this message translates to:
  /// **'Not running.'**
  String get prefsMcpNotRunning;

  /// MCP server status; time of day
  ///
  /// In en, this message translates to:
  /// **'Last request {time}'**
  String prefsMcpLastRequest(String time);

  /// MCP server status
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get prefsMcpNoRequests;

  /// Number of refused requests
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} rejected (wrong or missing token)}}'**
  String prefsMcpRejected(int count);

  /// Stands in for the token inside a configuration snippet when there is none yet; keep the angle brackets
  ///
  /// In en, this message translates to:
  /// **'<enable the server first>'**
  String get prefsMcpEnableFirst;

  /// Preferences > MCP: group box title
  ///
  /// In en, this message translates to:
  /// **'Set up your agent'**
  String get prefsMcpGroupSetup;

  /// Caption of the AI agent (client program) dropdown
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get prefsMcpClient;

  /// Followed by a shell command
  ///
  /// In en, this message translates to:
  /// **'An agent that only speaks stdio can bridge with:'**
  String get prefsMcpStdioBridge;

  /// Followed by a shell command
  ///
  /// In en, this message translates to:
  /// **'Run this in a terminal:'**
  String get prefsMcpTargetTerminal;

  /// Followed by configuration file contents
  ///
  /// In en, this message translates to:
  /// **'Add to {file}:'**
  String prefsMcpTargetFile(String file);

  /// No description provided for @prefsMcpNoteClaudeCode.
  ///
  /// In en, this message translates to:
  /// **'Scoped to your user, so the outline is available in every project.'**
  String get prefsMcpNoteClaudeCode;

  /// Keep http_headers, bearer_token_env_var and "NOO_MCP_TOKEN" verbatim
  ///
  /// In en, this message translates to:
  /// **'To keep the token out of the file, replace http_headers with bearer_token_env_var = \"NOO_MCP_TOKEN\" and set that variable in your shell.'**
  String get prefsMcpNoteCodex;

  /// Keep "oauth: false" verbatim
  ///
  /// In en, this message translates to:
  /// **'oauth: false matters — without it OpenCode reads this server\'s 401 as an invitation to start an OAuth registration it cannot finish.'**
  String get prefsMcpNoteOpenCode;

  /// No description provided for @prefsMcpExcludedDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'A ticked task is hidden from the MCP server together with everything under it — agents cannot read it, change it, or delete anything that contains it.'**
  String get prefsMcpExcludedDialogIntro;

  /// No description provided for @prefsMcpNoDatabase.
  ///
  /// In en, this message translates to:
  /// **'No database is open.'**
  String get prefsMcpNoDatabase;

  /// No description provided for @prefsMcpNoTasks.
  ///
  /// In en, this message translates to:
  /// **'This outline has no tasks yet.'**
  String get prefsMcpNoTasks;

  /// Tooltip of a tree row button
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get prefsMcpCollapse;

  /// Tooltip of a tree row button
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get prefsMcpExpand;

  /// Beside a task that is hidden because an ancestor is; short
  ///
  /// In en, this message translates to:
  /// **'hidden with parent'**
  String get prefsMcpHiddenWithParent;

  /// Group box title in Preferences → Sync
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get syncGroupSynchronization;

  /// No description provided for @syncEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable sync'**
  String get syncEnable;

  /// No description provided for @syncEnableHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this database in sync with a server'**
  String get syncEnableHint;

  /// Group box title in Preferences → Sync: the user name and device name
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get syncGroupIdentity;

  /// No description provided for @syncNeedsUserName.
  ///
  /// In en, this message translates to:
  /// **'Enter a user name to start syncing. Nothing syncs without one — with or without a server.'**
  String get syncNeedsUserName;

  /// No description provided for @syncUserName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get syncUserName;

  /// No description provided for @syncUserNameHint.
  ///
  /// In en, this message translates to:
  /// **'The same on every device of yours. Together with the database password it derives the encryption keys, so devices only sync when both match.'**
  String get syncUserNameHint;

  /// No description provided for @syncDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get syncDeviceName;

  /// No description provided for @syncDeviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'How this device introduces itself to nearby devices'**
  String get syncDeviceNameHint;

  /// No description provided for @syncGroupServer.
  ///
  /// In en, this message translates to:
  /// **'Sync server (optional)'**
  String get syncGroupServer;

  /// No description provided for @syncServerIntro.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to sync only with nearby devices on the same network. A server additionally lets devices sync when they are apart; it stores encrypted data it cannot read.'**
  String get syncServerIntro;

  /// No description provided for @syncServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get syncServerUrl;

  /// Field label: the account password on the sync server (not the database password)
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get syncServerPassword;

  /// No description provided for @syncServerPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Your account password on the server. Not the database password, and never used as an encryption key.'**
  String get syncServerPasswordHint;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get syncTestConnection;

  /// Button label: create an account on the sync server
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get syncRegister;

  /// No description provided for @syncGroupSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get syncGroupSchedule;

  /// No description provided for @syncScheduleNeedsServer.
  ///
  /// In en, this message translates to:
  /// **'Syncing on start and exit needs a server. Devices on the same network sync when you ask them to, from Tools → Sync P2P...'**
  String get syncScheduleNeedsServer;

  /// No description provided for @syncAutosyncOnStart.
  ///
  /// In en, this message translates to:
  /// **'Autosync on start'**
  String get syncAutosyncOnStart;

  /// No description provided for @syncAutosyncOnStartHint.
  ///
  /// In en, this message translates to:
  /// **'Sync when the app opens the database'**
  String get syncAutosyncOnStartHint;

  /// No description provided for @syncCheckOnStart.
  ///
  /// In en, this message translates to:
  /// **'Check for incoming changes on start'**
  String get syncCheckOnStart;

  /// No description provided for @syncCheckOnStartHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the server whether other devices have sent changes, without syncing, and show it on the sync icon. Not needed while Autosync on start is on'**
  String get syncCheckOnStartHint;

  /// No description provided for @syncAskOnExit.
  ///
  /// In en, this message translates to:
  /// **'Ask to sync on exit'**
  String get syncAskOnExit;

  /// No description provided for @syncAskOnExitHint.
  ///
  /// In en, this message translates to:
  /// **'Prompt to sync pending changes before the app closes'**
  String get syncAskOnExitHint;

  /// No description provided for @syncGroupServerStorage.
  ///
  /// In en, this message translates to:
  /// **'Server storage'**
  String get syncGroupServerStorage;

  /// No description provided for @syncGroupPeerToPeer.
  ///
  /// In en, this message translates to:
  /// **'Peer-to-peer'**
  String get syncGroupPeerToPeer;

  /// No description provided for @syncPeerToPeerIntro.
  ///
  /// In en, this message translates to:
  /// **'Devices on the same network that share your user name and database password can sync directly — no server needed. Open Tools → Sync P2P... on each of them: they find each other and sync while that window is open, and are not discoverable otherwise.'**
  String get syncPeerToPeerIntro;

  /// No description provided for @syncStorageNoServer.
  ///
  /// In en, this message translates to:
  /// **'Nothing is stored on a server in this setup. Peer-to-peer sync keeps every packet on the devices themselves.'**
  String get syncStorageNoServer;

  /// No description provided for @syncStorageIntro.
  ///
  /// In en, this message translates to:
  /// **'The server keeps every encrypted change ever made, so its size grows with edits rather than with the size of your outline.'**
  String get syncStorageIntro;

  /// No description provided for @syncStorageReading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get syncStorageReading;

  /// No description provided for @syncStoragePressRefresh.
  ///
  /// In en, this message translates to:
  /// **'Press Refresh to read the current usage.'**
  String get syncStoragePressRefresh;

  /// No description provided for @syncStorageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing stored on the server yet.'**
  String get syncStorageEmpty;

  /// Server storage total. size is a formatted byte size such as '2.4 MB'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{size} in 1 packet} other{{size} in {count} packets}}'**
  String syncStorageTotal(int count, String size);

  /// Tooltip on a device's row in Server storage: the range of packet counters stored for it
  ///
  /// In en, this message translates to:
  /// **'Counters {first}–{last}'**
  String syncStorageDeviceCounters(int first, int last);

  /// Tooltip on a device's row in Server storage: the range of packet counters and the number of full-state snapshots
  ///
  /// In en, this message translates to:
  /// **'{snapshots, plural, other{Counters {first}–{last}, {snapshots} snapshot(s)}}'**
  String syncStorageDeviceCountersSnapshots(int snapshots, int first, int last);

  /// No description provided for @syncStorageBlobs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Plus 1 attachment ({size}), stored once and shared by every packet that references them.} other{Plus {count} attachments ({size}), stored once and shared by every packet that references them.}}'**
  String syncStorageBlobs(int count, String size);

  /// Under the server storage total: how many of the server's packets this device also holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device holds {count} of them locally ({size}).}}'**
  String syncStorageLocal(int count, String size);

  /// Button label and confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Compact data on server'**
  String get syncCompactOnServer;

  /// Button label and confirmation dialog title. Also named in sync error messages (syncForkDetected etc.), keep them consistent
  ///
  /// In en, this message translates to:
  /// **'Reset device identity'**
  String get syncResetIdentity;

  /// No description provided for @syncNotConfiguredOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Sync is not configured on this device.'**
  String get syncNotConfiguredOnDevice;

  /// No description provided for @syncStorageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read server storage: {error}'**
  String syncStorageReadFailed(String error);

  /// No description provided for @syncResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'This device will start syncing under a new identity, and its next sync will publish a full copy of the current database. Your other devices merge that normally — nothing is lost.\n\nDo this when syncing reports that this device’s history has diverged, which usually means this database was restored from a backup after it had already synced.\n\nThe old identity keeps appearing in the server’s storage list until you compact.'**
  String get syncResetConfirm;

  /// Confirm button of the Reset device identity dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get syncReset;

  /// No description provided for @syncResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the device identity: {error}'**
  String syncResetFailed(String error);

  /// No description provided for @syncCompactConfirm.
  ///
  /// In en, this message translates to:
  /// **'This device will sync, then upload one snapshot of the whole database. The server then deletes every stored change the snapshot already contains, and so does every device as it picks the snapshot up.\n\nYour notes, times and attachments are unaffected — what is discarded is the record of individual past edits below the snapshot.\n\nUpdate Noo on your other devices first: an older version cannot read a stream whose beginning has been removed.'**
  String get syncCompactConfirm;

  /// Confirm button of the Compact data on server dialog
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get syncCompact;

  /// No description provided for @syncCompactFailed.
  ///
  /// In en, this message translates to:
  /// **'Compaction failed.'**
  String get syncCompactFailed;

  /// No description provided for @syncCompactNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to compact yet.'**
  String get syncCompactNothing;

  /// First part of the compaction summary, no final period (see syncCompactSummary)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Freed {size} on the server ({count} packets)}}'**
  String syncCompactRelayFreed(int count, String size);

  /// First part of the compaction summary, no final period (see syncCompactSummary)
  ///
  /// In en, this message translates to:
  /// **'Snapshot uploaded, but this server does not support compaction yet, so it kept its copies'**
  String get syncCompactRelayUnsupported;

  /// First part of the compaction summary, no final period (see syncCompactSummary)
  ///
  /// In en, this message translates to:
  /// **'Snapshot uploaded; the server had nothing left to drop'**
  String get syncCompactRelayNothing;

  /// Second part of the compaction summary, no final period (see syncCompactSummary)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device freed {size} ({count} packets)}}'**
  String syncCompactLocalFreed(int count, String size);

  /// Compaction result. relay is syncCompactRelayFreed/Unsupported/Nothing, local is syncCompactLocalFreed, size a byte size
  ///
  /// In en, this message translates to:
  /// **'{relay}. {local}. The snapshot itself is {size}.'**
  String syncCompactSummary(String relay, String local, String size);

  /// Compaction result when this device freed nothing. relay is syncCompactRelayFreed/Unsupported/Nothing
  ///
  /// In en, this message translates to:
  /// **'{relay}. The snapshot itself is {size}.'**
  String syncCompactSummaryNoLocal(String relay, String size);

  /// No description provided for @syncTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success: Server is reachable'**
  String get syncTestSuccess;

  /// No description provided for @syncTestUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Error: Server not reachable'**
  String get syncTestUnreachable;

  /// Result line under Test Connection / Register
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String syncErrorWith(String error);

  /// No description provided for @syncRegisterNeedsCredentials.
  ///
  /// In en, this message translates to:
  /// **'Error: Username and password required'**
  String get syncRegisterNeedsCredentials;

  /// No description provided for @syncRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success: Account \"{user}\" created. Settings saved.'**
  String syncRegisterSuccess(String user);

  /// No description provided for @syncRegisterSuccessUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Success: Account \"{user}\" created with unlimited server storage. Settings saved.'**
  String syncRegisterSuccessUnlimited(String user);

  /// No description provided for @syncRegisterSuccessQuota.
  ///
  /// In en, this message translates to:
  /// **'Success: Account \"{user}\" created with {size} of server storage. Settings saved.'**
  String syncRegisterSuccessQuota(String user, String size);

  /// Sync progress dialog: stage name in the label column
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get syncStagePreparing;

  /// Sync progress dialog: stage name in the label column, also shown as the stage's status
  ///
  /// In en, this message translates to:
  /// **'Validating credentials'**
  String get syncStageAuthenticating;

  /// No description provided for @syncStagePushing.
  ///
  /// In en, this message translates to:
  /// **'Pushing changes'**
  String get syncStagePushing;

  /// No description provided for @syncStageApplying.
  ///
  /// In en, this message translates to:
  /// **'Applying changes'**
  String get syncStageApplying;

  /// Status word of a sync stage
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get syncStatePending;

  /// No description provided for @syncStateActive.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get syncStateActive;

  /// No description provided for @syncStateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get syncStateDone;

  /// No description provided for @syncStateSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get syncStateSkipped;

  /// No description provided for @syncStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get syncStateFailed;

  /// Sync progress dialog title and its (disabled) Cancel button while the run winds down
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get syncCancelling;

  /// No description provided for @syncSynchronizing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get syncSynchronizing;

  /// No description provided for @syncCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sync cancelled'**
  String get syncCancelled;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// Title of the sync progress dialog before any sync has run
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncTitle;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// Button label
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncShowFullLogTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show full log'**
  String get syncShowFullLogTooltip;

  /// Button label; also referred to by syncMoreSeeFullLog
  ///
  /// In en, this message translates to:
  /// **'Show Full Log'**
  String get syncShowFullLog;

  /// Tail of a capped list: '…and 800 more — see Show Full Log'. Refers to the Show Full Log button
  ///
  /// In en, this message translates to:
  /// **'see Show Full Log'**
  String get syncMoreSeeFullLog;

  /// No description provided for @syncGroupProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get syncGroupProgress;

  /// No description provided for @syncNoRunYet.
  ///
  /// In en, this message translates to:
  /// **'No sync has run yet. Use “Sync Now” to synchronize; the details of the last sync will appear here.'**
  String get syncNoRunYet;

  /// No description provided for @syncCancelledNote.
  ///
  /// In en, this message translates to:
  /// **'Stopped at your request. Everything synchronized up to that point is kept; the next sync continues from there.'**
  String get syncCancelledNote;

  /// No description provided for @syncGroupSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get syncGroupSummary;

  /// No description provided for @syncChangesPushed.
  ///
  /// In en, this message translates to:
  /// **'Changes pushed'**
  String get syncChangesPushed;

  /// No description provided for @syncChangesApplied.
  ///
  /// In en, this message translates to:
  /// **'Changes applied'**
  String get syncChangesApplied;

  /// No description provided for @syncGroupApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied — from other devices'**
  String get syncGroupApplied;

  /// No description provided for @syncGroupPushed.
  ///
  /// In en, this message translates to:
  /// **'Pushed — from this device'**
  String get syncGroupPushed;

  /// No description provided for @syncGroupLwwSkipped.
  ///
  /// In en, this message translates to:
  /// **'Not applied — this device already had a newer value'**
  String get syncGroupLwwSkipped;

  /// No description provided for @syncGroupUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not be read'**
  String get syncGroupUnreadable;

  /// No description provided for @syncLwwTieNote.
  ///
  /// In en, this message translates to:
  /// **'Timestamps that match exactly are kept as they are on both devices, so the two stay different. Edit the item again on the device whose version you want to keep.'**
  String get syncLwwTieNote;

  /// No description provided for @syncLwwOlderNote.
  ///
  /// In en, this message translates to:
  /// **'The incoming value was older than this device\'s, so it was not written. If it should have won, check that the clocks on both devices agree.'**
  String get syncLwwOlderNote;

  /// No description provided for @syncSkewSame.
  ///
  /// In en, this message translates to:
  /// **'same timestamp'**
  String get syncSkewSame;

  /// How far this device's timestamp is ahead of the incoming one
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, other{local {seconds} s ahead}}'**
  String syncSkewSeconds(int seconds);

  /// No description provided for @syncSkewMinutes.
  ///
  /// In en, this message translates to:
  /// **'local {minutes} min {seconds} s ahead'**
  String syncSkewMinutes(int minutes, int seconds);

  /// No description provided for @syncSkewHours.
  ///
  /// In en, this message translates to:
  /// **'local {hours} h {minutes} min ahead'**
  String syncSkewHours(int hours, int minutes);

  /// No description provided for @syncSkewDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, other{local {days} days ahead}}'**
  String syncSkewDays(int days);

  /// incoming/local are timestamps, skew is syncSkew*
  ///
  /// In en, this message translates to:
  /// **'incoming {incoming} · local {local} ({skew})'**
  String syncLwwSkipTimes(String incoming, String local, String skew);

  /// A packet that could not be read. stage is a technical step name (decrypt, decode…), detail the error
  ///
  /// In en, this message translates to:
  /// **'{id}  ·  {stage} failed  ·  {detail}'**
  String syncSkippedPacketLine(String id, String stage, String detail);

  /// No description provided for @syncSkippedDecryptNote.
  ///
  /// In en, this message translates to:
  /// **'These packets could not be decrypted, which means this database\'s password differs from the one on the device that wrote them. Sync does not retry them: make the passwords match, then re-save the affected items on the other device so they are sent again.'**
  String get syncSkippedDecryptNote;

  /// No description provided for @syncSkippedUnreadableNote.
  ///
  /// In en, this message translates to:
  /// **'These packets could not be read and sync has moved past them — their changes will not arrive on their own. Re-save the affected items on the other device to send them again.'**
  String get syncSkippedUnreadableNote;

  /// No description provided for @syncP2pNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sync is not configured. Set a user name in Preferences → Sync first.'**
  String get syncP2pNotConfigured;

  /// No description provided for @syncP2pStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start peer-to-peer sync: {error}'**
  String syncP2pStartFailed(String error);

  /// No description provided for @syncP2pStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get syncP2pStarting;

  /// No description provided for @syncP2pLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking for devices on this network...'**
  String get syncP2pLooking;

  /// No description provided for @syncP2pIntro.
  ///
  /// In en, this message translates to:
  /// **'Open Sync P2P... on the other device too. Devices sync as soon as they find each other; they stop being visible when this window is closed.'**
  String get syncP2pIntro;

  /// Dialog title; same name as the menu item Sync P2P...
  ///
  /// In en, this message translates to:
  /// **'Sync P2P'**
  String get syncP2pTitle;

  /// No description provided for @syncP2pSyncAgain.
  ///
  /// In en, this message translates to:
  /// **'Sync Again'**
  String get syncP2pSyncAgain;

  /// No description provided for @syncP2pFound.
  ///
  /// In en, this message translates to:
  /// **'Found — waiting to sync'**
  String get syncP2pFound;

  /// No description provided for @syncP2pSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncP2pSyncing;

  /// No description provided for @syncP2pUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Synced — already up to date'**
  String get syncP2pUpToDate;

  /// No description provided for @syncP2pReceived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Synced — 1 change received} other{Synced — {count} changes received}}'**
  String syncP2pReceived(int count);

  /// No description provided for @syncP2pFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed — {error}'**
  String syncP2pFailed(String error);

  /// No description provided for @syncP2pUnknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get syncP2pUnknownError;

  /// Expandable list header; count is the number of changes
  ///
  /// In en, this message translates to:
  /// **'Received from {device} ({count})'**
  String syncP2pReceivedFrom(String device, int count);

  /// Expandable list header; count is the number of changes
  ///
  /// In en, this message translates to:
  /// **'Sent to {device} ({count})'**
  String syncP2pSentTo(String device, int count);

  /// Server storage quota headline; used/quota are byte sizes
  ///
  /// In en, this message translates to:
  /// **'{used} of {quota} used ({percent}%)'**
  String syncQuotaUsed(String used, String quota, int percent);

  /// Screen-reader label of the quota bar
  ///
  /// In en, this message translates to:
  /// **'Server storage used'**
  String get syncQuotaSemantics;

  /// No description provided for @syncQuotaFull.
  ///
  /// In en, this message translates to:
  /// **'Full: the server refuses new changes until you compact or remove attachments.'**
  String get syncQuotaFull;

  /// No description provided for @syncQuotaNearlyFull.
  ///
  /// In en, this message translates to:
  /// **'Nearly full. Compacting usually frees most of it.'**
  String get syncQuotaNearlyFull;

  /// No description provided for @syncNotConfiguredOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync is not configured. Open Sync Settings first.'**
  String get syncNotConfiguredOpenSettings;

  /// No description provided for @syncNoServerConfigured.
  ///
  /// In en, this message translates to:
  /// **'No sync server is configured. Use \"Sync P2P...\" for local sync, or add a server in Preferences → Sync.'**
  String get syncNoServerConfigured;

  /// No description provided for @syncAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync already in progress'**
  String get syncAlreadyInProgress;

  /// No description provided for @syncAlreadyInProgressSentence.
  ///
  /// In en, this message translates to:
  /// **'A sync is already in progress.'**
  String get syncAlreadyInProgressSentence;

  /// Apply progress inside one large packet. done/totalText are formatted numbers such as '4,200'
  ///
  /// In en, this message translates to:
  /// **'{total, plural, other{{done} of {totalText} changes}}'**
  String syncApplyOneOf(int total, String done, String totalText);

  /// Apply progress over several packets. countText is the formatted change count such as '4,200'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{countText} changes · packet {current} of {packets}}}'**
  String syncApplyPacketOf(
    int count,
    String countText,
    int current,
    int packets,
  );

  /// Apply progress. countText is the formatted change count such as '4,200'
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{countText} changes}}'**
  String syncApplyChanges(int count, String countText);

  /// progress is syncApply*
  ///
  /// In en, this message translates to:
  /// **'{progress} · about {seconds} s left'**
  String syncApplySecondsLeft(String progress, int seconds);

  /// progress is syncApply*
  ///
  /// In en, this message translates to:
  /// **'{progress} · about {minutes} min left'**
  String syncApplyMinutesLeft(String progress, int minutes);

  /// No description provided for @syncForkDetected.
  ///
  /// In en, this message translates to:
  /// **'Device stream fork detected: a remote node holds packet counter {remote} for this device, but this device is at {local}, and it cannot confirm the two agree on what came before (database restored from a backup?). Use \"Reset device identity\" in Preferences → Sync to resume syncing.'**
  String syncForkDetected(int remote, int local);

  /// source is a technical node name ('relay https://…', 'peer <id>@host:port'); the hashes are short hex
  ///
  /// In en, this message translates to:
  /// **'Device stream diverged at packet counter {counter}: this device and {source} hold different content under the same identity ({localHash} here vs {remoteHash} there). This database was most likely restored from a backup and has re-used packet numbers it had already published. Use \"Reset device identity\" in Preferences → Sync to resume syncing; it republishes this database under a fresh identity and nothing is lost.'**
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  );

  /// expected is a number or '?'
  ///
  /// In en, this message translates to:
  /// **'The server is missing part of this device\'s history: it expects packet #{expected} next, but the earliest packet this device still holds is #{local}, and the ones in between are no longer here (the server was most likely restored from an older backup after this device compacted). Use \"Reset device identity\" in Preferences → Sync to resume syncing; it republishes this database under a fresh identity and nothing is lost.'**
  String syncStreamGap(String expected, int local);

  /// No description provided for @syncIdentityReset.
  ///
  /// In en, this message translates to:
  /// **'This device now syncs under a new identity. Its next sync publishes a full copy of the current database, which every other device merges normally.'**
  String get syncIdentityReset;

  /// No description provided for @syncIdentityResetDiscarded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device now syncs under a new identity. Its next sync publishes a full copy of the current database, which every other device merges normally. {count} unusable packet(s) were discarded.}}'**
  String syncIdentityResetDiscarded(int count);

  /// Sync progress: what a stage is doing
  ///
  /// In en, this message translates to:
  /// **'Deriving encryption key'**
  String get syncDetailDerivingKey;

  /// No description provided for @syncDetailSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Already signed in'**
  String get syncDetailSignedIn;

  /// No description provided for @syncDetailPackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging local changes'**
  String get syncDetailPackaging;

  /// No description provided for @syncDetailRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering this device\'s own history'**
  String get syncDetailRecovering;

  /// No description provided for @syncDetailUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading to server'**
  String get syncDetailUploading;

  /// No description provided for @syncDetailNoLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'No local changes'**
  String get syncDetailNoLocalChanges;

  /// No description provided for @syncDetailPushed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change pushed} other{{count} changes pushed}}'**
  String syncDetailPushed(int count);

  /// No description provided for @syncDetailDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading remote changes'**
  String get syncDetailDownloading;

  /// No description provided for @syncDetailAttachmentsDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment downloaded} other{{count} attachments downloaded}}'**
  String syncDetailAttachmentsDownloaded(int count);

  /// No description provided for @syncDetailAttachmentsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 attachment still to download} other{{count} attachments still to download}}'**
  String syncDetailAttachmentsWaiting(int count);

  /// No description provided for @syncDetailUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get syncDetailUpToDate;

  /// No description provided for @syncDetailApplied.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change applied} other{{count} changes applied}}'**
  String syncDetailApplied(int count);

  /// No description provided for @syncDetailCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get syncDetailCancelled;

  /// No description provided for @syncAttachmentNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'The attachment \"{name}\" has not downloaded to this device yet, and a change this device made refers to it, so this device\'s changes cannot reach the server until it arrives — sync again once it has, or sync with a nearby device that holds it.'**
  String syncAttachmentNotDownloaded(String name);

  /// No description provided for @syncAttachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The server refused the attachment \"{name}\" ({size}) as too large. Everything else syncs; the attachment itself reaches other devices only through Sync P2P.'**
  String syncAttachmentTooLarge(String name, String size);

  /// No description provided for @syncAttachmentTooLargeLimit.
  ///
  /// In en, this message translates to:
  /// **'The server refused the attachment \"{name}\" ({size}) as too large (its limit is {limit}). Everything else syncs; the attachment itself reaches other devices only through Sync P2P.'**
  String syncAttachmentTooLargeLimit(String name, String size, String limit);

  /// No description provided for @syncAttachmentOverQuota.
  ///
  /// In en, this message translates to:
  /// **'The attachment \"{name}\" ({size}) does not fit in your server storage. Everything else syncs; compact data on the server or remove large attachments to make room, and until then the attachment reaches other devices only through Sync P2P.'**
  String syncAttachmentOverQuota(String name, String size);

  /// No description provided for @syncAttachmentOverQuotaUsage.
  ///
  /// In en, this message translates to:
  /// **'The attachment \"{name}\" ({size}) does not fit in your server storage ({used} of {quota} used). Everything else syncs; compact data on the server or remove large attachments to make room, and until then the attachment reaches other devices only through Sync P2P.'**
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  );

  /// A size below 1 KB
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} bytes}}'**
  String syncBytes(int count);

  /// No description provided for @syncCompactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No sync server is configured. Compaction publishes a snapshot to the relay; with nearby-device sync alone there is no relay storage to reclaim.'**
  String get syncCompactUnavailable;

  /// Compaction progress; shown followed by '…'
  ///
  /// In en, this message translates to:
  /// **'Syncing before compaction'**
  String get syncCompactStageSyncing;

  /// No description provided for @syncCompactStageChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking this device is up to date'**
  String get syncCompactStageChecking;

  /// No description provided for @syncCompactStagePackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging a snapshot of the whole database'**
  String get syncCompactStagePackaging;

  /// No description provided for @syncCompactStageAttachments.
  ///
  /// In en, this message translates to:
  /// **'Uploading attachments the snapshot references'**
  String get syncCompactStageAttachments;

  /// No description provided for @syncCompactStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading the snapshot'**
  String get syncCompactStageUploading;

  /// No description provided for @syncCompactStageReclaiming.
  ///
  /// In en, this message translates to:
  /// **'Reclaiming space on this device'**
  String get syncCompactStageReclaiming;

  /// No description provided for @syncCompactStageReadingUsage.
  ///
  /// In en, this message translates to:
  /// **'Reading relay storage'**
  String get syncCompactStageReadingUsage;

  /// No description provided for @syncCompactNeedsSync.
  ///
  /// In en, this message translates to:
  /// **'Compaction needs a completed sync first: {error}'**
  String syncCompactNeedsSync(String error);

  /// No description provided for @syncCompactDidNotFinish.
  ///
  /// In en, this message translates to:
  /// **'Compaction did not finish.'**
  String get syncCompactDidNotFinish;

  /// No description provided for @syncCompactRaced.
  ///
  /// In en, this message translates to:
  /// **'Another sync packaged first. Try compacting again.'**
  String get syncCompactRaced;

  /// No description provided for @syncCompactSnapshotMissing.
  ///
  /// In en, this message translates to:
  /// **'The snapshot was packaged but is not in the local store.'**
  String get syncCompactSnapshotMissing;

  /// No description provided for @syncCompactMissingAttachments.
  ///
  /// In en, this message translates to:
  /// **'This device is still missing some attachments. Sync until every attachment has downloaded, then compact.'**
  String get syncCompactMissingAttachments;

  /// No description provided for @syncCompactRelayRefused.
  ///
  /// In en, this message translates to:
  /// **'Relay refused the snapshot: {error}'**
  String syncCompactRelayRefused(String error);

  /// No description provided for @syncCompactError.
  ///
  /// In en, this message translates to:
  /// **'Compaction failed: {error}'**
  String syncCompactError(String error);

  /// packets lists up to three packet ids
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device could not read {count} packet(s) ({packets}), so its state is not the merge of everything in the log. Compacting would discard packets this device never applied.}}'**
  String syncCompactBlockedUnreadable(int count, String packets);

  /// No description provided for @syncCompactBlockedUnsynced.
  ///
  /// In en, this message translates to:
  /// **'This device still has unsynced edits. Sync first, then compact.'**
  String get syncCompactBlockedUnsynced;

  /// No description provided for @syncCompactBlockedAttachments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device is still missing some attachments ({count} to download), so its snapshot could not supply them and the server would drop them. Sync until every attachment has downloaded, then compact.}}'**
  String syncCompactBlockedAttachments(int count);

  /// No description provided for @syncCompactBlockedBehind.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{This device has not applied everything it holds for {count} device(s). Sync again, then compact.}}'**
  String syncCompactBlockedBehind(int count);

  /// Shown after Compact Database: why deleted attachments' bytes were kept
  ///
  /// In en, this message translates to:
  /// **'Nearby-device sync alone cannot guarantee another device still holds a deleted attachment, so none were released.'**
  String get syncCollectNoRelay;

  /// No description provided for @syncCollectUnsynced.
  ///
  /// In en, this message translates to:
  /// **'This device has changes the server has not stored yet. Sync first, then compact.'**
  String get syncCollectUnsynced;

  /// A row in the list of changes sent to a peer that stands for a whole full-state snapshot; device is a device name
  ///
  /// In en, this message translates to:
  /// **'Snapshot of {device}'**
  String syncSummarySnapshotOf(String device);

  /// No description provided for @syncSummarySnapshotFields.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} fields — the whole database}}'**
  String syncSummarySnapshotFields(int count);

  /// A task (outline node) in a list of synced changes
  ///
  /// In en, this message translates to:
  /// **'Node \"{name}\"'**
  String syncSummaryNode(String name);

  /// An attachment in a list of synced changes
  ///
  /// In en, this message translates to:
  /// **'File \"{name}\"'**
  String syncSummaryFile(String name);

  /// Name used for an attachment with no file name, inside syncSummaryFile
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get syncSummaryFileFallback;

  /// A time-tracking record in a list of synced changes
  ///
  /// In en, this message translates to:
  /// **'Time chunk'**
  String get syncSummaryTimeChunk;

  /// One item of a comma-separated list of what changed on a task
  ///
  /// In en, this message translates to:
  /// **'renamed to \"{title}\"'**
  String syncSummaryRenamedTo(String title);

  /// One item of a comma-separated list of what changed on a task
  ///
  /// In en, this message translates to:
  /// **'content edited'**
  String get syncSummaryContentEdited;

  /// One item of a comma-separated list of what changed on a task
  ///
  /// In en, this message translates to:
  /// **'moved'**
  String get syncSummaryMoved;

  /// One item of a comma-separated list of what changed on a task or file
  ///
  /// In en, this message translates to:
  /// **'reordered'**
  String get syncSummaryReordered;

  /// One item of a comma-separated list of what changed on a task
  ///
  /// In en, this message translates to:
  /// **'flags changed'**
  String get syncSummaryFlagsChanged;

  /// One item of a comma-separated list of what changed on a file
  ///
  /// In en, this message translates to:
  /// **'renamed'**
  String get syncSummaryRenamed;

  /// One item of a comma-separated list of what changed on a file
  ///
  /// In en, this message translates to:
  /// **'content updated'**
  String get syncSummaryContentUpdated;

  /// A time record with only a start time
  ///
  /// In en, this message translates to:
  /// **'from {time}'**
  String syncSummaryFrom(String time);

  /// A time record with only an end time
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String syncSummaryUntil(String time);

  /// The value of a task's parent when it sits at the top of the outline
  ///
  /// In en, this message translates to:
  /// **'top level'**
  String get syncValueTopLevel;

  /// No description provided for @syncStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Server storage is full. Compact data on the server (Preferences → Sync → Server storage) or remove large attachments; what has not been uploaded stays on this device.'**
  String get syncStorageFull;

  /// No description provided for @syncStorageFullUsage.
  ///
  /// In en, this message translates to:
  /// **'Server storage is full ({used} of {quota} used). Compact data on the server (Preferences → Sync → Server storage) or remove large attachments; what has not been uploaded stays on this device.'**
  String syncStorageFullUsage(String used, String quota);

  /// detail is the server's own (English) message
  ///
  /// In en, this message translates to:
  /// **'The server refuses another device stream for this account: {detail}'**
  String syncStorageStreams(String detail);

  /// No description provided for @syncStorageServerDisk.
  ///
  /// In en, this message translates to:
  /// **'The server is out of disk space. Nothing was lost; sync again later.'**
  String get syncStorageServerDisk;

  /// detail is the server's own (English) message
  ///
  /// In en, this message translates to:
  /// **'The server refused to store more: {detail}'**
  String syncStorageRefused(String detail);

  /// No description provided for @syncRegAccountLimit.
  ///
  /// In en, this message translates to:
  /// **'This server is not accepting new accounts: it has reached its account limit.'**
  String get syncRegAccountLimit;

  /// No description provided for @syncRegClosed.
  ///
  /// In en, this message translates to:
  /// **'This server does not accept sign-ups. Ask its operator for an account.'**
  String get syncRegClosed;

  /// No description provided for @syncRegTaken.
  ///
  /// In en, this message translates to:
  /// **'That user name is already taken.'**
  String get syncRegTaken;

  /// No description provided for @syncRegInvalid.
  ///
  /// In en, this message translates to:
  /// **'The user name must be 3–50 characters and the server password 8–128.'**
  String get syncRegInvalid;

  /// No description provided for @syncRegTooManyFromNetwork.
  ///
  /// In en, this message translates to:
  /// **'Too many accounts have been registered from this network today.'**
  String get syncRegTooManyFromNetwork;

  /// wait is syncWaitSeconds/Minutes/Hours
  ///
  /// In en, this message translates to:
  /// **'Too many accounts have been registered from this network today. Try again in {wait}.'**
  String syncRegTooManyFromNetworkWait(String wait);

  /// No description provided for @syncRegTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts.'**
  String get syncRegTooManyAttempts;

  /// wait is syncWaitSeconds/Minutes/Hours
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {wait}.'**
  String syncRegTooManyAttemptsWait(String wait);

  /// No description provided for @syncRegBusy.
  ///
  /// In en, this message translates to:
  /// **'The server is busy. Try again in a moment.'**
  String get syncRegBusy;

  /// No description provided for @syncRegFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed (HTTP {status})'**
  String syncRegFailed(int status);

  /// detail is the server's own (English) message
  ///
  /// In en, this message translates to:
  /// **'Registration failed (HTTP {status}): {detail}'**
  String syncRegFailedDetail(int status, String detail);

  /// No description provided for @syncWaitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} seconds}}'**
  String syncWaitSeconds(int count);

  /// No description provided for @syncWaitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} minutes}}'**
  String syncWaitMinutes(int count);

  /// No description provided for @syncWaitHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} hours}}'**
  String syncWaitHours(int count);

  /// No description provided for @syncTimeoutNoResponse.
  ///
  /// In en, this message translates to:
  /// **'No response from {host} within {seconds}s'**
  String syncTimeoutNoResponse(String host, int seconds);

  /// No description provided for @syncTimeoutStalled.
  ///
  /// In en, this message translates to:
  /// **'Response from {host} stalled for {seconds}s'**
  String syncTimeoutStalled(String host, int seconds);

  /// Last line of a capped list of sync changes. {where} says where the rest are, e.g. 'see the Sync Log'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{…and {count} more — {where}}}'**
  String traceMoreRows(int count, String where);

  /// Fills {where} in traceMoreRows: the rows left out are in the Sync Log dialog.
  ///
  /// In en, this message translates to:
  /// **'see the Sync Log'**
  String get traceMoreSeeSyncLog;

  /// Under a changed task in a sync report: it sits at the top level of the outline.
  ///
  /// In en, this message translates to:
  /// **'at top level'**
  String get traceAtTopLevel;

  /// Under a changed task in a sync report: where it is. {path} is its ancestors joined by ' › '.
  ///
  /// In en, this message translates to:
  /// **'in {path}'**
  String traceInPath(String path);

  /// Tag after an item a sync created.
  ///
  /// In en, this message translates to:
  /// **'(new)'**
  String get traceRowNew;

  /// Tag after an item a sync removed.
  ///
  /// In en, this message translates to:
  /// **'(removed)'**
  String get traceRowRemoved;

  /// Tooltip on a row of a sync report that opens its details.
  ///
  /// In en, this message translates to:
  /// **'Show how this change happened'**
  String get traceShowHowTooltip;

  /// A size in bytes.
  ///
  /// In en, this message translates to:
  /// **'{count} B'**
  String traceBytes(int count);

  /// A size in kilobytes; {size} is already formatted, e.g. 12.5.
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String traceKilobytes(String size);

  /// A size in megabytes; {size} is already formatted, e.g. 3.2.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String traceMegabytes(String size);

  /// What sync decided about a field: the incoming value was applied.
  ///
  /// In en, this message translates to:
  /// **'applied'**
  String get traceDecisionApplied;

  /// What sync decided about a field: the item was created on this device.
  ///
  /// In en, this message translates to:
  /// **'created here'**
  String get traceDecisionCreated;

  /// No description provided for @traceDecisionConflictCopy.
  ///
  /// In en, this message translates to:
  /// **'applied — the value it replaced was kept as a conflict copy'**
  String get traceDecisionConflictCopy;

  /// No description provided for @traceDecisionMerged.
  ///
  /// In en, this message translates to:
  /// **'merged with the edit made here — both changes kept'**
  String get traceDecisionMerged;

  /// No description provided for @traceDecisionCycleToRoot.
  ///
  /// In en, this message translates to:
  /// **'moved to the top level — its parent would have made a loop'**
  String get traceDecisionCycleToRoot;

  /// No description provided for @traceDecisionParentMissing.
  ///
  /// In en, this message translates to:
  /// **'placed at the top level until its parent arrives'**
  String get traceDecisionParentMissing;

  /// No description provided for @traceDecisionBlobPending.
  ///
  /// In en, this message translates to:
  /// **'applied — the attachment bytes follow separately'**
  String get traceDecisionBlobPending;

  /// What sync did with an outgoing field change.
  ///
  /// In en, this message translates to:
  /// **'sent'**
  String get traceDecisionSent;

  /// What sync did with a field change served to another device.
  ///
  /// In en, this message translates to:
  /// **'forwarded'**
  String get traceDecisionForwarded;

  /// How a sync packet arrived. 'Relay' is the sync server.
  ///
  /// In en, this message translates to:
  /// **'Downloaded from the relay.'**
  String get traceRouteRelay;

  /// How a sync packet arrived; {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'Downloaded from the relay, which stored it {time}.'**
  String traceRouteRelayStored(String time);

  /// {peer} and {author} are device names.
  ///
  /// In en, this message translates to:
  /// **'Forwarded by {peer} over the local network — {author} wrote it.'**
  String traceRoutePeerForwarded(String peer, String author);

  /// {peer} is a device name.
  ///
  /// In en, this message translates to:
  /// **'Directly from {peer} over the local network.'**
  String traceRoutePeerDirect(String peer);

  /// No description provided for @traceRouteStoredEarlier.
  ///
  /// In en, this message translates to:
  /// **'Already on this device from an earlier exchange; applied in this one.'**
  String get traceRouteStoredEarlier;

  /// {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'Already on this device — received {time}; applied in this one.'**
  String traceRouteStoredAt(String time);

  /// {time} is a date and time; {source} is as the sync log recorded it, e.g. 'relay https://…' or 'peer Laptop' (not translated).
  ///
  /// In en, this message translates to:
  /// **'Already on this device — received {time} from {source}; applied in this one.'**
  String traceRouteStoredAtFrom(String time, String source);

  /// No description provided for @traceRoutePackagedUploaded.
  ///
  /// In en, this message translates to:
  /// **'Packaged here and uploaded to the relay.'**
  String get traceRoutePackagedUploaded;

  /// No description provided for @traceRoutePackagedAlreadyHeld.
  ///
  /// In en, this message translates to:
  /// **'Packaged here; the relay already had it from another path.'**
  String get traceRoutePackagedAlreadyHeld;

  /// No description provided for @traceRoutePackagedBlocked.
  ///
  /// In en, this message translates to:
  /// **'Packaged here; not uploaded yet — an attachment it needs could not go up.'**
  String get traceRoutePackagedBlocked;

  /// No description provided for @traceRoutePackagedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Packaged here; waiting for the relay or a peer to take it.'**
  String get traceRoutePackagedWaiting;

  /// {peer} and {author} are device names.
  ///
  /// In en, this message translates to:
  /// **'Pulled by {peer} over the local network — forwarded on {author}\'s behalf.'**
  String traceRouteServedForwarded(String peer, String author);

  /// {peer} is a device name.
  ///
  /// In en, this message translates to:
  /// **'Pulled by {peer} over the local network.'**
  String traceRouteServedDirect(String peer);

  /// State of an attachment's bytes after a sync.
  ///
  /// In en, this message translates to:
  /// **'downloaded now'**
  String get traceBlobDownloaded;

  /// {size} is formatted, e.g. '12.5 KB'.
  ///
  /// In en, this message translates to:
  /// **'downloaded now ({size})'**
  String traceBlobDownloadedSized(String size);

  /// {source} is where the bytes came from, as the source names itself.
  ///
  /// In en, this message translates to:
  /// **'downloaded now from {source}'**
  String traceBlobDownloadedFrom(String source);

  /// No description provided for @traceBlobDownloadedFromSized.
  ///
  /// In en, this message translates to:
  /// **'downloaded now from {source} ({size})'**
  String traceBlobDownloadedFromSized(String source, String size);

  /// No description provided for @traceBlobWaiting.
  ///
  /// In en, this message translates to:
  /// **'not downloaded yet — it follows on a later sync, or when opened'**
  String get traceBlobWaiting;

  /// No description provided for @traceBlobHeld.
  ///
  /// In en, this message translates to:
  /// **'already on this device'**
  String get traceBlobHeld;

  /// No description provided for @traceBlobUploaded.
  ///
  /// In en, this message translates to:
  /// **'uploaded to the relay'**
  String get traceBlobUploaded;

  /// No description provided for @traceBlobUploadedSized.
  ///
  /// In en, this message translates to:
  /// **'uploaded to the relay ({size})'**
  String traceBlobUploadedSized(String size);

  /// 'them' = the attachment's bytes.
  ///
  /// In en, this message translates to:
  /// **'the relay already had them'**
  String get traceBlobOnRelay;

  /// No description provided for @traceBlobOffered.
  ///
  /// In en, this message translates to:
  /// **'on this device for others to fetch'**
  String get traceBlobOffered;

  /// One attachment under 'Attachment bytes': a short id, then its state (one of the traceBlob… messages).
  ///
  /// In en, this message translates to:
  /// **'{id} — {state}'**
  String traceBlobLine(String id, String state);

  /// No description provided for @traceSnapshotWhole.
  ///
  /// In en, this message translates to:
  /// **'A compaction snapshot: the whole database of {device}, in one packet.'**
  String traceSnapshotWhole(String device);

  /// No description provided for @traceSnapshotPart.
  ///
  /// In en, this message translates to:
  /// **'Part of a full-state snapshot from {device}. A snapshot carries the author\'s whole database; this item is listed because it differed here.'**
  String traceSnapshotPart(String device);

  /// Heading in a sync change's details: the fields that changed.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get traceFieldsHeading;

  /// When an outgoing field was edited; {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'edited {time}'**
  String traceTimeEdited(String time);

  /// The other device's timestamp for a field; {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'theirs {time}'**
  String traceTimeTheirs(String time);

  /// This device's timestamp for a field; {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'this device {time}'**
  String traceTimeThisDevice(String time);

  /// Heading for a sync packet: its author device and its number.
  ///
  /// In en, this message translates to:
  /// **'Packet {device} #{counter}'**
  String tracePacketHeading(String device, String counter);

  /// Heading for a sync packet that is a full-state snapshot.
  ///
  /// In en, this message translates to:
  /// **'Packet {device} #{counter} (snapshot)'**
  String tracePacketHeadingSnapshot(String device, String counter);

  /// When a sync packet was made; {time} is a date and time.
  ///
  /// In en, this message translates to:
  /// **'written {time}'**
  String tracePacketWritten(String time);

  /// How many field changes a sync packet carries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change} other{{count} changes}}'**
  String tracePacketChanges(int count);

  /// No description provided for @tracePacketAuthorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Author device {id}'**
  String tracePacketAuthorTooltip(String id);

  /// {id} is a shortened device id.
  ///
  /// In en, this message translates to:
  /// **'from device {id}'**
  String tracePacketFromDevice(String id);

  /// No description provided for @traceCopyHashTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy the packet hash'**
  String get traceCopyHashTooltip;

  /// Heading in a sync change's details: where the attachment's data stands.
  ///
  /// In en, this message translates to:
  /// **'Attachment bytes'**
  String get traceAttachmentBytesHeading;

  /// Button that opens the Sync Log dialog on this change.
  ///
  /// In en, this message translates to:
  /// **'Show in Sync Log'**
  String get traceShowInSyncLog;

  /// Sync Log: what started a run.
  ///
  /// In en, this message translates to:
  /// **'Server sync'**
  String get traceTriggerRelay;

  /// No description provided for @traceTriggerCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for incoming changes'**
  String get traceTriggerCheck;

  /// No description provided for @traceTriggerLan.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get traceTriggerLan;

  /// No description provided for @traceTriggerLanReturn.
  ///
  /// In en, this message translates to:
  /// **'Nearby device (requested)'**
  String get traceTriggerLanReturn;

  /// No description provided for @traceTriggerLanServe.
  ///
  /// In en, this message translates to:
  /// **'Served to nearby device'**
  String get traceTriggerLanServe;

  /// No description provided for @traceTriggerPackage.
  ///
  /// In en, this message translates to:
  /// **'Packaged local changes'**
  String get traceTriggerPackage;

  /// No description provided for @traceTriggerCompaction.
  ///
  /// In en, this message translates to:
  /// **'Compaction'**
  String get traceTriggerCompaction;

  /// No description provided for @traceTriggerIdentityReset.
  ///
  /// In en, this message translates to:
  /// **'Device identity reset'**
  String get traceTriggerIdentityReset;

  /// No description provided for @traceTriggerAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment download'**
  String get traceTriggerAttachment;

  /// No description provided for @traceTriggerBlobCollect.
  ///
  /// In en, this message translates to:
  /// **'Attachment clean-up'**
  String get traceTriggerBlobCollect;

  /// Sync Log: how a run ended (lowercase, shown in a list line).
  ///
  /// In en, this message translates to:
  /// **'running'**
  String get traceOutcomeRunning;

  /// No description provided for @traceOutcomeFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get traceOutcomeFailed;

  /// No description provided for @traceOutcomeDeclined.
  ///
  /// In en, this message translates to:
  /// **'declined'**
  String get traceOutcomeDeclined;

  /// Sync Log: the run did not start because another sync was in progress.
  ///
  /// In en, this message translates to:
  /// **'busy'**
  String get traceOutcomeBusy;

  /// No description provided for @traceOutcomeInterrupted.
  ///
  /// In en, this message translates to:
  /// **'interrupted'**
  String get traceOutcomeInterrupted;

  /// Snack bar after copying Sync Log events.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Copied {count} event(s) as JSON}}'**
  String traceCopiedJson(int count);

  /// No description provided for @traceClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear sync log?'**
  String get traceClearTitle;

  /// No description provided for @traceClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every recorded run and event on this device is deleted. Synced data is not affected.'**
  String get traceClearBody;

  /// Title of the Sync Log dialog.
  ///
  /// In en, this message translates to:
  /// **'Sync Log'**
  String get traceTitle;

  /// Button / tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get traceCopyAsJson;

  /// Tooltip on the phone layout's clear button.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get traceClearLogTooltip;

  /// Button label (title case).
  ///
  /// In en, this message translates to:
  /// **'Clear Log'**
  String get traceClearLogButton;

  /// Part of a Sync Log run summary: how many changes were applied.
  ///
  /// In en, this message translates to:
  /// **'{count} applied'**
  String traceSummaryApplied(int count);

  /// No description provided for @traceSummaryWarnings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warning} other{{count} warnings}}'**
  String traceSummaryWarnings(int count);

  /// No description provided for @traceSummaryErrors.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 error} other{{count} errors}}'**
  String traceSummaryErrors(int count);

  /// No description provided for @traceNothingExchanged.
  ///
  /// In en, this message translates to:
  /// **'Nothing exchanged'**
  String get traceNothingExchanged;

  /// No description provided for @traceNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No sync has been recorded yet. Runs appear here as this device syncs with the server or with nearby devices.'**
  String get traceNoRuns;

  /// No description provided for @traceAllRuns.
  ///
  /// In en, this message translates to:
  /// **'All runs'**
  String get traceAllRuns;

  /// Under 'All runs': how many runs are recorded.
  ///
  /// In en, this message translates to:
  /// **'{count} recorded'**
  String traceRunsRecorded(int count);

  /// No description provided for @traceAllRunsCount.
  ///
  /// In en, this message translates to:
  /// **'All runs ({count})'**
  String traceAllRunsCount(int count);

  /// Label of the run picker; also a row label in an event's details.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get traceRunLabel;

  /// No description provided for @traceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search: node name, id, hash, device, kind…'**
  String get traceSearchHint;

  /// Filter segment: events of every level.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get traceLevelAll;

  /// No description provided for @traceLevelWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get traceLevelWarnings;

  /// No description provided for @traceLevelErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get traceLevelErrors;

  /// No description provided for @traceDirectionAll.
  ///
  /// In en, this message translates to:
  /// **'In and out'**
  String get traceDirectionAll;

  /// No description provided for @traceDirectionIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get traceDirectionIncoming;

  /// No description provided for @traceDirectionOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get traceDirectionOutgoing;

  /// No description provided for @traceDirectionLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get traceDirectionLocal;

  /// No description provided for @traceNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No events match.'**
  String get traceNoEvents;

  /// No description provided for @traceEventsTruncated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Showing the first {count} events. Narrow the search or pick a run to see the rest.}}'**
  String traceEventsTruncated(int count);

  /// No description provided for @traceRunNumber.
  ///
  /// In en, this message translates to:
  /// **'Run #{id}'**
  String traceRunNumber(int id);

  /// Sync Log: a field whose new value is empty.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get traceEmptyValue;

  /// No description provided for @traceSubHash.
  ///
  /// In en, this message translates to:
  /// **'hash {hash}'**
  String traceSubHash(String hash);

  /// {hash} is a hash of the value.
  ///
  /// In en, this message translates to:
  /// **'value {hash}'**
  String traceSubValue(String hash);

  /// The incoming change's timestamp.
  ///
  /// In en, this message translates to:
  /// **'remote {time}'**
  String traceSubRemote(String time);

  /// This device's timestamp.
  ///
  /// In en, this message translates to:
  /// **'local {time}'**
  String traceSubLocal(String time);

  /// No description provided for @traceDetailAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get traceDetailAt;

  /// No description provided for @traceDetailDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get traceDetailDirection;

  /// No description provided for @traceDetailOriginDevice.
  ///
  /// In en, this message translates to:
  /// **'Origin device'**
  String get traceDetailOriginDevice;

  /// No description provided for @traceDetailCounter.
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get traceDetailCounter;

  /// No description provided for @traceDetailHash.
  ///
  /// In en, this message translates to:
  /// **'Packet / blob hash'**
  String get traceDetailHash;

  /// No description provided for @traceDetailEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get traceDetailEntity;

  /// No description provided for @traceDetailWorldId.
  ///
  /// In en, this message translates to:
  /// **'World id'**
  String get traceDetailWorldId;

  /// No description provided for @traceDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get traceDetailName;

  /// No description provided for @traceDetailField.
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get traceDetailField;

  /// No description provided for @traceDetailRemoteTs.
  ///
  /// In en, this message translates to:
  /// **'Remote timestamp'**
  String get traceDetailRemoteTs;

  /// No description provided for @traceDetailLocalTs.
  ///
  /// In en, this message translates to:
  /// **'Local timestamp'**
  String get traceDetailLocalTs;

  /// No description provided for @traceDetailValueHash.
  ///
  /// In en, this message translates to:
  /// **'Value hash'**
  String get traceDetailValueHash;

  /// No description provided for @traceDetailValuePreview.
  ///
  /// In en, this message translates to:
  /// **'Value preview'**
  String get traceDetailValuePreview;

  /// No description provided for @traceDetailMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get traceDetailMessage;

  /// No description provided for @traceDetailDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get traceDetailDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'it',
    'ja',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
