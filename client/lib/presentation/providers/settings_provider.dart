import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/audio/whisper_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../../platform/secure_window.dart';

/// Keys for settings storage
class SettingsKeys {
  SettingsKeys._();

  static const String themeMode = 'theme_mode';
  static const String lastDatabasePath = 'last_database_path';
  static const String showSeconds = 'show_seconds';
  static const String autoSaveInterval = 'auto_save_interval';
  static const String rememberPassword = 'remember_password';
  static const String singleInstance = 'single_instance';
  static const String syncEnabled = 'sync_enabled';
  static const String syncServerUrl = 'sync_server_url';
  static const String syncUsername = 'sync_username';

  /// Legacy SharedPreferences key for the sync server password. The password
  /// now lives in the platform keychain ([SecureStorageService]); this key is
  /// only read once, to migrate and purge the plaintext copy.
  static const String legacySyncPassword = 'sync_password';
  static const String syncDeviceId = 'sync_device_id';
  static const String syncDeviceName = 'sync_device_name';
  static const String syncAutoInterval = 'sync_auto_interval';
  static const String syncOnExit = 'sync_on_exit';
  static const String syncOnStart = 'sync_on_start';
  static const String fontFamily = 'font_family';
  static const String fontSize = 'font_size';
  static const String fontBold = 'font_bold';
  static const String fontItalic = 'font_italic';
  static const String monospaceFontsOnly = 'monospace_fonts_only';
  static const String treeFontFamily = 'tree_font_family';
  static const String treeFontSize = 'tree_font_size';
  static const String treeFontBold = 'tree_font_bold';
  static const String treeFontItalic = 'tree_font_italic';
  static const String chromeFontFamily = 'chrome_font_family';
  static const String chromeFontScale = 'chrome_font_scale';
  static const String editorTabWidth = 'editor_tab_width';
  static const String editorTabAsSpaces = 'editor_tab_as_spaces';
  static const String editorPasteFormatting = 'editor_paste_formatting';
  static const String voiceMemoModel = 'voice_memo_model';
  static const String voiceMemoTranscribe = 'voice_memo_transcribe';
  static const String voiceMemoLanguage = 'voice_memo_language';
  static const String voiceMemoInputDevice = 'voice_memo_input_device';
  static const String voiceMemoOutputDevice = 'voice_memo_output_device';
  static const String biometricUnlock = 'biometric_unlock';
  static const String blockScreenshots = 'block_screenshots';

  static const String mcpEnabled = 'mcp_enabled';
  static const String mcpPort = 'mcp_port';
  static const String mcpReadOnly = 'mcp_read_only';

  // No key for the MCP token: it is a bearer credential and lives only in the
  // platform keychain ([SecureStorageService]), for the same reason
  // [legacySyncPassword] is purged from here on sight.
}

/// What happens to the formatting carried by text pasted from the clipboard.
///
/// Rich text copied out of a browser or an office suite brings its own colors,
/// fonts and sizes with it, which rarely match the note it lands in — and a
/// colour picked for a white page can be unreadable against the dark theme.
enum PasteFormatting {
  /// Paste exactly what the clipboard offers (flutter_quill's own behaviour).
  keep,

  /// Drop the appearance attributes — colour, background, font family and font
  /// size — while keeping bold/italic/links/lists and the rest of the
  /// structure.
  stripStyling,

  /// Paste the clipboard's plain text, which then picks up the styling of the
  /// text it is inserted into.
  plainText;

  /// The value stored under [SettingsKeys.editorPasteFormatting], falling back
  /// to [keep] for anything unrecognised (an older or newer build's name).
  static PasteFormatting fromName(String? name) {
    return PasteFormatting.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => PasteFormatting.keep,
    );
  }
}

/// Settings state
class AppSettings {
  static const double kDefaultContentFontSize = 14.0;
  static const double kDefaultChromeFontScale = 1.0;
  static const int kDefaultTabWidth = 4;

  /// Default loopback port for the MCP server.
  ///
  /// Fixed rather than ephemeral because the URL is pasted into agent config
  /// files and has to survive a restart. Unregistered with IANA, but not
  /// reserved either — a collision surfaces in the preferences tab.
  static const int kDefaultMcpPort = 8737;
  static const int kMinMcpPort = 1024;
  static const int kMaxMcpPort = 65535;

  final ThemeMode themeMode;
  final String? lastDatabasePath;
  final bool showSeconds;
  final int autoSaveIntervalSeconds;
  final bool rememberPassword;
  final bool singleInstance;
  final bool syncEnabled;
  final String? syncServerUrl;
  final String? syncUsername;
  final String? syncPassword;
  final String? syncDeviceId;
  final String? syncDeviceName;
  final int syncAutoInterval;
  final bool syncOnExit;
  final bool syncOnStart;
  final String? fontFamily;
  final double fontSize;
  final bool fontBold;
  final bool fontItalic;

  /// Offer only the fixed-width family in the editor toolbar's Font menu, so
  /// that text whose columns are meant to line up — a table made by the
  /// editor's Format as table — cannot be set in a font that will not line
  /// them up. It narrows what that one menu offers; text already in another
  /// family keeps it, and the content font in Preferences is untouched
  /// because it dresses the tree as well as the editor.
  final bool monospaceFontsOnly;
  /// The tree's own font. Separate from the editor's: the outline is chrome
  /// as much as content, and a font chosen to line up columns in a note — the
  /// fixed-width one, above all — is rarely the one to read a tree of titles
  /// in. Seeded from the editor's font the first time the app runs with these
  /// keys, so splitting the two changed nothing that was already on screen.
  final String? treeFontFamily;
  final double treeFontSize;
  final bool treeFontBold;
  final bool treeFontItalic;

  final String? chromeFontFamily;
  final double chromeFontScale;
  final int editorTabWidth;
  final bool editorTabAsSpaces;

  /// How much of the clipboard's own formatting survives a paste.
  final PasteFormatting pasteFormatting;

  /// Android: gate the remembered-password auto-unlock behind a biometric
  /// prompt. Meaningless while [rememberPassword] is off.
  final bool biometricUnlock;

  /// Android: FLAG_SECURE — blank the app in screenshots and recents.
  final bool blockScreenshots;

  /// Whisper model used to transcribe voice memos. [VoiceMemoModel.none]
  /// means memos are recorded and stored as audio only.
  ///
  /// Selecting a model does not fetch it — see
  /// `WhisperService.downloadModel`, which only ever runs from the button in
  /// Preferences.
  final VoiceMemoModel voiceMemoModel;

  /// Transcribe a new memo once it has been stored. Off stores the audio and
  /// nothing else; the attachment menu can still ask for a transcript later.
  final bool voiceMemoTranscribe;

  /// Language code passed to whisper; `auto` lets it detect.
  final String voiceMemoLanguage;

  /// Name of the microphone memos are recorded from. Empty means whatever the
  /// platform calls the default.
  ///
  /// The *name*, not the index: `voice_audio` says plainly that a device's
  /// index is its only identifier and that an index outlives nothing — plug in
  /// a headset and index 3 is a different device. So the name is stored and
  /// resolved against a fresh enumeration each time, which also gives the
  /// honest answer when the device is simply gone: fall back to the default
  /// rather than record from something the user never chose.
  final String voiceMemoInputDevice;

  /// Name of the speaker memos play back through, on the same terms as
  /// [voiceMemoInputDevice].
  ///
  /// Applies to voice memos, which play through `voice_audio`. Other audio
  /// attachments go through `audioplayers` and the loopback media server,
  /// which has no device selection to offer.
  final String voiceMemoOutputDevice;

  /// Serve the outline to local coding agents over loopback HTTP.
  final bool mcpEnabled;

  /// Port the MCP server binds on loopback.
  final int mcpPort;

  /// Withhold the MCP write tools, so agents can read but not modify.
  final bool mcpReadOnly;

  /// Bearer token agents present to the MCP server.
  ///
  /// Keychain-only, like [syncPassword] — never written to SharedPreferences,
  /// which is a world-readable JSON file on desktop.
  final String? mcpToken;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.lastDatabasePath,
    this.showSeconds = false,
    this.autoSaveIntervalSeconds = 10,
    this.rememberPassword = false,
    this.singleInstance = false,
    this.syncEnabled = false,
    this.syncServerUrl,
    this.syncUsername,
    this.syncPassword,
    this.syncDeviceId,
    this.syncDeviceName,
    this.syncAutoInterval = 0,
    this.syncOnExit = true,
    this.syncOnStart = true,
    this.fontFamily,
    this.fontSize = kDefaultContentFontSize,
    this.fontBold = false,
    this.fontItalic = false,
    this.monospaceFontsOnly = false,
    this.treeFontFamily,
    this.treeFontSize = kDefaultContentFontSize,
    this.treeFontBold = false,
    this.treeFontItalic = false,
    this.chromeFontFamily,
    this.chromeFontScale = kDefaultChromeFontScale,
    this.editorTabWidth = kDefaultTabWidth,
    this.editorTabAsSpaces = true,
    this.pasteFormatting = PasteFormatting.keep,
    this.biometricUnlock = false,
    this.blockScreenshots = false,
    this.voiceMemoModel = VoiceMemoModel.none,
    this.voiceMemoTranscribe = true,
    this.voiceMemoLanguage = 'en',
    this.voiceMemoInputDevice = '',
    this.voiceMemoOutputDevice = '',
    this.mcpEnabled = false,
    this.mcpPort = kDefaultMcpPort,
    this.mcpReadOnly = false,
    this.mcpToken,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? lastDatabasePath,
    bool? showSeconds,
    int? autoSaveIntervalSeconds,
    bool? rememberPassword,
    bool? singleInstance,
    bool? syncEnabled,
    String? syncServerUrl,
    String? syncUsername,
    String? syncPassword,
    String? syncDeviceId,
    String? syncDeviceName,
    int? syncAutoInterval,
    bool? syncOnExit,
    bool? syncOnStart,
    Object? fontFamily = _unset,
    double? fontSize,
    bool? fontBold,
    bool? fontItalic,
    bool? monospaceFontsOnly,
    Object? treeFontFamily = _unset,
    double? treeFontSize,
    bool? treeFontBold,
    bool? treeFontItalic,
    Object? chromeFontFamily = _unset,
    double? chromeFontScale,
    int? editorTabWidth,
    bool? editorTabAsSpaces,
    PasteFormatting? pasteFormatting,
    bool? biometricUnlock,
    bool? blockScreenshots,
    VoiceMemoModel? voiceMemoModel,
    bool? voiceMemoTranscribe,
    String? voiceMemoLanguage,
    String? voiceMemoInputDevice,
    String? voiceMemoOutputDevice,
    bool? mcpEnabled,
    int? mcpPort,
    bool? mcpReadOnly,
    Object? mcpToken = _unset,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      lastDatabasePath: lastDatabasePath ?? this.lastDatabasePath,
      showSeconds: showSeconds ?? this.showSeconds,
      autoSaveIntervalSeconds: autoSaveIntervalSeconds ?? this.autoSaveIntervalSeconds,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      singleInstance: singleInstance ?? this.singleInstance,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      syncServerUrl: syncServerUrl ?? this.syncServerUrl,
      syncUsername: syncUsername ?? this.syncUsername,
      syncPassword: syncPassword ?? this.syncPassword,
      syncDeviceId: syncDeviceId ?? this.syncDeviceId,
      syncDeviceName: syncDeviceName ?? this.syncDeviceName,
      syncAutoInterval: syncAutoInterval ?? this.syncAutoInterval,
      syncOnExit: syncOnExit ?? this.syncOnExit,
      syncOnStart: syncOnStart ?? this.syncOnStart,
      fontFamily: identical(fontFamily, _unset) ? this.fontFamily : fontFamily as String?,
      fontSize: fontSize ?? this.fontSize,
      fontBold: fontBold ?? this.fontBold,
      fontItalic: fontItalic ?? this.fontItalic,
      monospaceFontsOnly: monospaceFontsOnly ?? this.monospaceFontsOnly,
      treeFontFamily: identical(treeFontFamily, _unset)
          ? this.treeFontFamily
          : treeFontFamily as String?,
      treeFontSize: treeFontSize ?? this.treeFontSize,
      treeFontBold: treeFontBold ?? this.treeFontBold,
      treeFontItalic: treeFontItalic ?? this.treeFontItalic,
      chromeFontFamily: identical(chromeFontFamily, _unset) ? this.chromeFontFamily : chromeFontFamily as String?,
      chromeFontScale: chromeFontScale ?? this.chromeFontScale,
      editorTabWidth: editorTabWidth ?? this.editorTabWidth,
      editorTabAsSpaces: editorTabAsSpaces ?? this.editorTabAsSpaces,
      pasteFormatting: pasteFormatting ?? this.pasteFormatting,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      voiceMemoModel: voiceMemoModel ?? this.voiceMemoModel,
      voiceMemoTranscribe: voiceMemoTranscribe ?? this.voiceMemoTranscribe,
      voiceMemoLanguage: voiceMemoLanguage ?? this.voiceMemoLanguage,
      voiceMemoInputDevice: voiceMemoInputDevice ?? this.voiceMemoInputDevice,
      voiceMemoOutputDevice:
          voiceMemoOutputDevice ?? this.voiceMemoOutputDevice,
      mcpEnabled: mcpEnabled ?? this.mcpEnabled,
      mcpPort: mcpPort ?? this.mcpPort,
      mcpReadOnly: mcpReadOnly ?? this.mcpReadOnly,
      // Nullable-with-sentinel like [fontFamily]: revoking the token has to be
      // expressible, and `null` alone would read as "leave it alone".
      mcpToken: identical(mcpToken, _unset) ? this.mcpToken : mcpToken as String?,
    );
  }
}

/// Settings notifier that persists to SharedPreferences
class SettingsNotifier extends Notifier<AppSettings> {
  /// Keychain-backed store for the sync server password. Constructed directly
  /// rather than read from `secureStorageServiceProvider`: that provider lives
  /// in `providers.dart`, which re-exports `sync_provider.dart`, which imports
  /// this file. The service is stateless, so a second instance is equivalent.
  SecureStorageService _secureStorage = SecureStorageService();

  @visibleForTesting
  set secureStorage(SecureStorageService storage) => _secureStorage = storage;

  @override
  AppSettings build() {
    _loadSettings();
    return const AppSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final syncPassword = await _loadSyncPassword(prefs);
    final mcpToken = await _secureStorage.getMcpToken();

    // Three awaits stand between build() and this write, and the provider can
    // be gone by now — at shutdown, or in any test whose container outlives
    // the load by less than a disk read. Writing state through a disposed ref
    // throws, and there is nothing left to publish to anyway.
    if (!ref.mounted) return;

    final themeModeIndex = prefs.getInt(SettingsKeys.themeMode) ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];

    state = AppSettings(
      themeMode: themeMode,
      lastDatabasePath: prefs.getString(SettingsKeys.lastDatabasePath),
      showSeconds: prefs.getBool(SettingsKeys.showSeconds) ?? false,
      autoSaveIntervalSeconds: prefs.getInt(SettingsKeys.autoSaveInterval) ?? 10,
      rememberPassword: prefs.getBool(SettingsKeys.rememberPassword) ?? false,
      singleInstance: prefs.getBool(SettingsKeys.singleInstance) ?? false,
      syncEnabled: prefs.getBool(SettingsKeys.syncEnabled) ?? false,
      syncServerUrl: prefs.getString(SettingsKeys.syncServerUrl),
      syncUsername: prefs.getString(SettingsKeys.syncUsername),
      syncPassword: syncPassword,
      syncDeviceId: prefs.getString(SettingsKeys.syncDeviceId),
      syncDeviceName: prefs.getString(SettingsKeys.syncDeviceName),
      syncAutoInterval: prefs.getInt(SettingsKeys.syncAutoInterval) ?? 0,
      syncOnExit: prefs.getBool(SettingsKeys.syncOnExit) ?? true,
      syncOnStart: prefs.getBool(SettingsKeys.syncOnStart) ?? true,
      fontFamily: prefs.getString(SettingsKeys.fontFamily),
      fontSize: (prefs.getDouble(SettingsKeys.fontSize) ?? AppSettings.kDefaultContentFontSize).clamp(8.0, 48.0),
      fontBold: prefs.getBool(SettingsKeys.fontBold) ?? false,
      fontItalic: prefs.getBool(SettingsKeys.fontItalic) ?? false,
      monospaceFontsOnly:
          prefs.getBool(SettingsKeys.monospaceFontsOnly) ?? false,
      // Falling back to the editor's font is the migration: before the two
      // were separate settings, one font dressed both. An *empty* value is
      // not the same as a missing one — it is "System default", chosen for
      // the tree on purpose, and it has to outlive a restart rather than
      // being read as "never set" and following the editor again.
      treeFontFamily: switch (prefs.getString(SettingsKeys.treeFontFamily)) {
        null => prefs.getString(SettingsKeys.fontFamily),
        '' => null,
        final family => family,
      },
      treeFontSize: (prefs.getDouble(SettingsKeys.treeFontSize) ??
              prefs.getDouble(SettingsKeys.fontSize) ??
              AppSettings.kDefaultContentFontSize)
          .clamp(8.0, 48.0),
      treeFontBold: prefs.getBool(SettingsKeys.treeFontBold) ??
          prefs.getBool(SettingsKeys.fontBold) ??
          false,
      treeFontItalic: prefs.getBool(SettingsKeys.treeFontItalic) ??
          prefs.getBool(SettingsKeys.fontItalic) ??
          false,
      chromeFontFamily: prefs.getString(SettingsKeys.chromeFontFamily),
      chromeFontScale: (prefs.getDouble(SettingsKeys.chromeFontScale) ?? AppSettings.kDefaultChromeFontScale).clamp(0.8, 1.5),
      editorTabWidth: (prefs.getInt(SettingsKeys.editorTabWidth) ?? AppSettings.kDefaultTabWidth).clamp(1, 8),
      editorTabAsSpaces: prefs.getBool(SettingsKeys.editorTabAsSpaces) ?? true,
      pasteFormatting: PasteFormatting.fromName(
          prefs.getString(SettingsKeys.editorPasteFormatting)),
      biometricUnlock: prefs.getBool(SettingsKeys.biometricUnlock) ?? false,
      blockScreenshots: prefs.getBool(SettingsKeys.blockScreenshots) ?? false,
      voiceMemoModel: VoiceMemoModel.fromName(
          prefs.getString(SettingsKeys.voiceMemoModel)),
      voiceMemoTranscribe:
          prefs.getBool(SettingsKeys.voiceMemoTranscribe) ?? true,
      voiceMemoLanguage:
          prefs.getString(SettingsKeys.voiceMemoLanguage) ?? 'en',
      voiceMemoInputDevice:
          prefs.getString(SettingsKeys.voiceMemoInputDevice) ?? '',
      voiceMemoOutputDevice:
          prefs.getString(SettingsKeys.voiceMemoOutputDevice) ?? '',
      mcpEnabled: prefs.getBool(SettingsKeys.mcpEnabled) ?? false,
      mcpPort: (prefs.getInt(SettingsKeys.mcpPort) ?? AppSettings.kDefaultMcpPort)
          .clamp(AppSettings.kMinMcpPort, AppSettings.kMaxMcpPort),
      mcpReadOnly: prefs.getBool(SettingsKeys.mcpReadOnly) ?? false,
      mcpToken: mcpToken,
    );

    // The window flag lives on the Android activity, not in Flutter state, so
    // re-assert it whenever the persisted settings come in.
    await SecureWindow.apply(state.blockScreenshots);
  }

  /// Read the sync server password from the keychain, migrating any plaintext
  /// copy left in SharedPreferences by an older build.
  ///
  /// The legacy key is removed unconditionally — it is a bearer credential
  /// sitting in a world-readable JSON file on desktop, so it must not survive
  /// even when the keychain already holds the password or is unavailable. The
  /// keychain wins on a mismatch; it is the only copy anything writes now.
  Future<String?> _loadSyncPassword(SharedPreferences prefs) async {
    final legacy = prefs.getString(SettingsKeys.legacySyncPassword);
    final stored = await _secureStorage.getServerPassword();

    if (stored == null && legacy != null && legacy.isNotEmpty) {
      await _secureStorage.saveServerPassword(legacy);
    }
    if (legacy != null) {
      await prefs.remove(SettingsKeys.legacySyncPassword);
    }

    return stored ?? legacy;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.themeMode, mode.index);
  }

  Future<void> setLastDatabasePath(String path) async {
    state = state.copyWith(lastDatabasePath: path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.lastDatabasePath, path);
  }

  Future<void> setShowSeconds(bool value) async {
    state = state.copyWith(showSeconds: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.showSeconds, value);
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    state = state.copyWith(autoSaveIntervalSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.autoSaveInterval, seconds);
  }

  Future<void> setRememberPassword(bool value) async {
    state = state.copyWith(rememberPassword: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.rememberPassword, value);
  }

  Future<void> setSingleInstance(bool value) async {
    state = state.copyWith(singleInstance: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.singleInstance, value);
  }

  Future<void> setSyncEnabled(bool value) async {
    state = state.copyWith(syncEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.syncEnabled, value);
  }

  Future<void> setSyncServerUrl(String value) async {
    state = state.copyWith(syncServerUrl: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.syncServerUrl, value);
  }

  Future<void> setSyncUsername(String value) async {
    state = state.copyWith(syncUsername: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.syncUsername, value);
  }

  /// Persist the sync server password to the platform keychain. Never written
  /// to SharedPreferences — see [_loadSyncPassword].
  Future<void> setSyncPasswod(String value) async {
    state = state.copyWith(syncPassword: value);
    if (value.isEmpty) {
      await _secureStorage.deleteServerPassword();
    } else {
      await _secureStorage.saveServerPassword(value);
    }
  }

  Future<void> setSyncDeviceId(String value) async {
    state = state.copyWith(syncDeviceId: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.syncDeviceId, value);
  }

  Future<void> setSyncDeviceName(String value) async {
    state = state.copyWith(syncDeviceName: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.syncDeviceName, value);
  }

  Future<void> setSyncAutoInterval(int minutes) async {
    state = state.copyWith(syncAutoInterval: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.syncAutoInterval, minutes);
  }

  Future<void> setSyncOnExit(bool value) async {
    state = state.copyWith(syncOnExit: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.syncOnExit, value);
  }

  Future<void> setSyncOnStart(bool value) async {
    state = state.copyWith(syncOnStart: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.syncOnStart, value);
  }

  Future<void> setFontFamily(String? value) async {
    state = state.copyWith(fontFamily: value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(SettingsKeys.fontFamily);
    } else {
      await prefs.setString(SettingsKeys.fontFamily, value);
    }
  }

  Future<void> setFontSize(double value) async {
    final clamped = value.clamp(8.0, 48.0);
    state = state.copyWith(fontSize: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SettingsKeys.fontSize, clamped);
  }

  Future<void> setFontBold(bool value) async {
    state = state.copyWith(fontBold: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.fontBold, value);
  }

  Future<void> setFontItalic(bool value) async {
    state = state.copyWith(fontItalic: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.fontItalic, value);
  }

  Future<void> setTreeFontFamily(String? value) async {
    state = state.copyWith(treeFontFamily: value);
    final prefs = await SharedPreferences.getInstance();
    // Written as empty rather than removed: a missing key means the tree font
    // has never been set and follows the editor's, which is not what picking
    // System default for the tree asks for.
    await prefs.setString(SettingsKeys.treeFontFamily, value ?? '');
  }

  Future<void> setTreeFontSize(double value) async {
    final clamped = value.clamp(8.0, 48.0);
    state = state.copyWith(treeFontSize: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SettingsKeys.treeFontSize, clamped);
  }

  Future<void> setTreeFontBold(bool value) async {
    state = state.copyWith(treeFontBold: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.treeFontBold, value);
  }

  Future<void> setTreeFontItalic(bool value) async {
    state = state.copyWith(treeFontItalic: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.treeFontItalic, value);
  }

  Future<void> setMonospaceFontsOnly(bool value) async {
    state = state.copyWith(monospaceFontsOnly: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.monospaceFontsOnly, value);
  }

  Future<void> setChromeFontFamily(String? value) async {
    state = state.copyWith(chromeFontFamily: value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(SettingsKeys.chromeFontFamily);
    } else {
      await prefs.setString(SettingsKeys.chromeFontFamily, value);
    }
  }

  Future<void> setChromeFontScale(double value) async {
    final clamped = value.clamp(0.8, 1.5);
    state = state.copyWith(chromeFontScale: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SettingsKeys.chromeFontScale, clamped);
  }

  Future<void> setEditorTabWidth(int value) async {
    final clamped = value.clamp(1, 8);
    state = state.copyWith(editorTabWidth: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.editorTabWidth, clamped);
  }

  Future<void> setEditorTabAsSpaces(bool value) async {
    state = state.copyWith(editorTabAsSpaces: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.editorTabAsSpaces, value);
  }

  Future<void> setPasteFormatting(PasteFormatting value) async {
    state = state.copyWith(pasteFormatting: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.editorPasteFormatting, value.name);
  }

  Future<void> setBiometricUnlock(bool value) async {
    state = state.copyWith(biometricUnlock: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.biometricUnlock, value);
  }

  Future<void> setBlockScreenshots(bool value) async {
    state = state.copyWith(blockScreenshots: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.blockScreenshots, value);
    await SecureWindow.apply(value);
  }

  Future<void> setVoiceMemoModel(VoiceMemoModel value) async {
    state = state.copyWith(voiceMemoModel: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.voiceMemoModel, value.name);
  }

  Future<void> setVoiceMemoTranscribe(bool value) async {
    state = state.copyWith(voiceMemoTranscribe: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.voiceMemoTranscribe, value);
  }

  Future<void> setVoiceMemoLanguage(String value) async {
    state = state.copyWith(voiceMemoLanguage: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.voiceMemoLanguage, value);
  }

  /// Choose the microphone, by name. Empty for the platform default.
  Future<void> setVoiceMemoInputDevice(String value) async {
    state = state.copyWith(voiceMemoInputDevice: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.voiceMemoInputDevice, value);
  }

  /// Choose the speaker memos play through, by name. Empty for the default.
  Future<void> setVoiceMemoOutputDevice(String value) async {
    state = state.copyWith(voiceMemoOutputDevice: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.voiceMemoOutputDevice, value);
  }

  Future<void> setMcpEnabled(bool value) async {
    state = state.copyWith(mcpEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.mcpEnabled, value);
  }

  Future<void> setMcpPort(int value) async {
    final clamped = value.clamp(AppSettings.kMinMcpPort, AppSettings.kMaxMcpPort);
    state = state.copyWith(mcpPort: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.mcpPort, clamped);
  }

  Future<void> setMcpReadOnly(bool value) async {
    state = state.copyWith(mcpReadOnly: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.mcpReadOnly, value);
  }

  /// Persist the MCP token to the platform keychain, or revoke it with null.
  ///
  /// Returns false when the keychain refused the write. [SecureStorageService]
  /// swallows that failure, so the only way to tell a missing token from an
  /// unavailable keyring is to read the value back — and the caller needs to
  /// know, because the difference is "press the button again" versus "your
  /// keyring is locked".
  Future<bool> setMcpToken(String? value) async {
    state = state.copyWith(mcpToken: value);
    if (value == null || value.isEmpty) {
      await _secureStorage.deleteMcpToken();
      return await _secureStorage.getMcpToken() == null;
    }
    await _secureStorage.saveMcpToken(value);
    return await _secureStorage.getMcpToken() == value;
  }

  /// Restore every preference back to [snapshot], in memory and on disk.
  ///
  /// Backs the Preferences dialog's Cancel button: that dialog applies edits
  /// live, so cancelling has to put the whole settings object back the way it
  /// was when the dialog opened. [AppSettings.lastDatabasePath] is not a
  /// user-facing preference and is left untouched.
  Future<void> restorePreferences(AppSettings snapshot) async {
    state = snapshot.copyWith(lastDatabasePath: state.lastDatabasePath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.themeMode, snapshot.themeMode.index);
    await prefs.setBool(SettingsKeys.showSeconds, snapshot.showSeconds);
    await prefs.setInt(
        SettingsKeys.autoSaveInterval, snapshot.autoSaveIntervalSeconds);
    await prefs.setBool(
        SettingsKeys.rememberPassword, snapshot.rememberPassword);
    await prefs.setBool(SettingsKeys.singleInstance, snapshot.singleInstance);

    await prefs.setBool(SettingsKeys.syncEnabled, snapshot.syncEnabled);
    await _setOrRemove(prefs, SettingsKeys.syncServerUrl, snapshot.syncServerUrl);
    await _setOrRemove(prefs, SettingsKeys.syncUsername, snapshot.syncUsername);
    // The sync password is keychain-only, so it rolls back there rather than
    // through prefs. Written directly rather than via [setSyncPasswod] so a
    // snapshot whose password was unset restores as null, not ''.
    final syncPassword = snapshot.syncPassword;
    if (syncPassword == null || syncPassword.isEmpty) {
      await _secureStorage.deleteServerPassword();
    } else {
      await _secureStorage.saveServerPassword(syncPassword);
    }
    await _setOrRemove(prefs, SettingsKeys.syncDeviceId, snapshot.syncDeviceId);
    await _setOrRemove(
        prefs, SettingsKeys.syncDeviceName, snapshot.syncDeviceName);
    await prefs.setInt(
        SettingsKeys.syncAutoInterval, snapshot.syncAutoInterval);
    await prefs.setBool(SettingsKeys.syncOnExit, snapshot.syncOnExit);
    await prefs.setBool(SettingsKeys.syncOnStart, snapshot.syncOnStart);

    await _setOrRemove(prefs, SettingsKeys.fontFamily, snapshot.fontFamily);
    await prefs.setDouble(SettingsKeys.fontSize, snapshot.fontSize);
    await prefs.setBool(SettingsKeys.fontBold, snapshot.fontBold);
    await prefs.setBool(SettingsKeys.fontItalic, snapshot.fontItalic);
    await prefs.setBool(
        SettingsKeys.monospaceFontsOnly, snapshot.monospaceFontsOnly);
    await prefs.setString(
        SettingsKeys.treeFontFamily, snapshot.treeFontFamily ?? '');
    await prefs.setDouble(SettingsKeys.treeFontSize, snapshot.treeFontSize);
    await prefs.setBool(SettingsKeys.treeFontBold, snapshot.treeFontBold);
    await prefs.setBool(SettingsKeys.treeFontItalic, snapshot.treeFontItalic);
    await _setOrRemove(
        prefs, SettingsKeys.chromeFontFamily, snapshot.chromeFontFamily);
    await prefs.setDouble(
        SettingsKeys.chromeFontScale, snapshot.chromeFontScale);

    await prefs.setInt(SettingsKeys.editorTabWidth, snapshot.editorTabWidth);
    await prefs.setBool(
        SettingsKeys.editorTabAsSpaces, snapshot.editorTabAsSpaces);
    await prefs.setString(
        SettingsKeys.editorPasteFormatting, snapshot.pasteFormatting.name);

    await prefs.setBool(
        SettingsKeys.biometricUnlock, snapshot.biometricUnlock);
    await prefs.setBool(
        SettingsKeys.blockScreenshots, snapshot.blockScreenshots);
    await SecureWindow.apply(snapshot.blockScreenshots);

    await prefs.setString(
        SettingsKeys.voiceMemoModel, snapshot.voiceMemoModel.name);
    await prefs.setBool(
        SettingsKeys.voiceMemoTranscribe, snapshot.voiceMemoTranscribe);
    await prefs.setString(
        SettingsKeys.voiceMemoLanguage, snapshot.voiceMemoLanguage);
    await prefs.setString(
        SettingsKeys.voiceMemoInputDevice, snapshot.voiceMemoInputDevice);
    await prefs.setString(
        SettingsKeys.voiceMemoOutputDevice, snapshot.voiceMemoOutputDevice);

    await prefs.setBool(SettingsKeys.mcpEnabled, snapshot.mcpEnabled);
    await prefs.setInt(SettingsKeys.mcpPort, snapshot.mcpPort);
    await prefs.setBool(SettingsKeys.mcpReadOnly, snapshot.mcpReadOnly);
    // Keychain-only, like the sync password above, and written directly so a
    // snapshot taken before any token existed restores as absent rather than
    // ''. Regenerate-then-Cancel has to put the agents' old token back.
    final mcpToken = snapshot.mcpToken;
    if (mcpToken == null || mcpToken.isEmpty) {
      await _secureStorage.deleteMcpToken();
    } else {
      await _secureStorage.saveMcpToken(mcpToken);
    }
  }

  /// Write [value] under [key], or drop the key entirely when it is null, so a
  /// restored "unset" preference reads back as unset.
  Future<void> _setOrRemove(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }

  /// Cycle through theme modes: System -> Light -> Dark -> System
  Future<void> cycleThemeMode() async {
    final nextMode = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(nextMode);
  }
}

/// Provider for app settings
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Provider for just the theme mode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

const Object _unset = Object();
