import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/fonts.dart';
import '../../../core/utils/platform_info.dart';
import '../../../platform/biometric_gate.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import 'classic_form.dart';
import 'mcp_settings_form.dart';
import 'sync_settings_form.dart';
import 'voice_memo_settings_form.dart';

/// Preferences dialog for application settings.
///
/// Laid out as a classic desktop property sheet: plain text tabs across the
/// top, settings framed by titled group boxes with an aligned label column,
/// and OK / Cancel buttons.
///
/// Edits apply live (so the theme and fonts preview themselves as you change
/// them); OK simply keeps them, while Cancel — including Esc and a click
/// outside — restores the settings snapshot taken when the dialog opened.
/// Server-side actions on the Sync tab (Test Connection, Register, Compact
/// data on server) are not part of that snapshot and cannot be undone.
///
/// [initialTab] selects which tab opens first (0=Appearance, 1=Behavior,
/// 2=Voice memos, 3=Sync, 4=MCP).
class PreferencesDialog extends ConsumerStatefulWidget {
  final int initialTab;

  const PreferencesDialog({super.key, this.initialTab = 0});

  @override
  ConsumerState<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends ConsumerState<PreferencesDialog> {
  late final TextEditingController _customFamilyController;
  late final TextEditingController _sizeController;
  late final TextEditingController _chromeCustomFamilyController;
  late final FocusNode _sizeFocusNode;
  bool _showCustomFamilyField = false;
  bool _showChromeCustomFamilyField = false;

  /// Settings as they were when the dialog opened; Cancel restores this.
  late final AppSettings _snapshot;

  /// Set while "Remember password" is switched off. The keychain entry is only
  /// dropped once the user accepts, so Cancel can put the setting back without
  /// having thrown the password away.
  bool _clearSavedPassword = false;

  /// Whether this device has an enrolled biometric or a secure screen lock, so
  /// the "Biometric unlock" preference can do anything at all. Null while the
  /// asynchronous probe is still in flight; the checkbox stays disabled until
  /// it answers, which is a frame or two.
  bool? _biometricAvailable;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _probeBiometricAvailability();
    final settings = ref.read(settingsProvider);
    _snapshot = settings;
    final family = settings.fontFamily;
    _showCustomFamilyField =
        family != null && !kCuratedFonts.contains(family);
    _customFamilyController = TextEditingController(
      text: _showCustomFamilyField ? family : '',
    );
    _sizeController = TextEditingController(
      text: settings.fontSize.toStringAsFixed(0),
    );
    _sizeFocusNode = FocusNode();

    final chromeFamily = settings.chromeFontFamily;
    _showChromeCustomFamilyField =
        chromeFamily != null && !kCuratedFonts.contains(chromeFamily);
    _chromeCustomFamilyController = TextEditingController(
      text: _showChromeCustomFamilyField ? chromeFamily : '',
    );
  }

  Future<void> _probeBiometricAvailability() async {
    final available = await BiometricGate.isAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _customFamilyController.dispose();
    _sizeController.dispose();
    _chromeCustomFamilyController.dispose();
    _sizeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (!_sizeFocusNode.hasFocus) {
        final t = next.fontSize.toStringAsFixed(0);
        if (_sizeController.text != t) _sizeController.text = t;
      }
    });

    final theme = Theme.of(context);
    // Grow the sheet with the UI font so the label column and its controls
    // still fit at the larger scales; the SizedBox is clamped by the dialog's
    // own constraints on small screens.
    final scale = classicUiScale(context);

    // Esc and clicking outside the dialog must go through Cancel, otherwise
    // they would silently keep the live-applied edits.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: _buildDialog(theme, scale),
    );
  }

  Widget _buildDialog(ThemeData theme, double scale) {
    final tabs = DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab.clamp(0, 4),
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium,
            tabs: const [
              Tab(height: 36, text: 'Appearance'),
              Tab(height: 36, text: 'Behavior'),
              Tab(height: 36, text: 'Voice memos'),
              Tab(height: 36, text: 'Sync'),
              Tab(height: 36, text: 'MCP'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTabBody(_buildAppearanceTab()),
                _buildTabBody(_buildBehaviorTab()),
                _buildTabBody(const VoiceMemoSettingsForm()),
                _buildTabBody(const SyncSettingsForm()),
                _buildTabBody(const McpSettingsForm()),
              ],
            ),
          ),
        ],
      ),
    );

    // Phones: the 520px property sheet doesn't fit, so present the same
    // content full-screen. Close (and system back, via the PopScope in
    // [build]) cancels; the check mark accepts.
    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Preferences'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _cancel,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'OK',
                onPressed: _accept,
              ),
            ],
          ),
          body: SafeArea(child: tabs),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Preferences'),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 520 * scale,
        height: 520 * scale,
        child: tabs,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      actions: [
        FilledButton(
          style: classicButtonStyle(context),
          onPressed: _accept,
          child: const Text('OK'),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Keep the live-applied edits and carry out the changes that were held back
  /// until the user accepted.
  Future<void> _accept() async {
    final navigator = Navigator.of(context);

    if (_clearSavedPassword) {
      final dbPath = ref.read(databaseManagerProvider).currentPath;
      await ref
          .read(secureStorageServiceProvider)
          .deletePassword(dbPath: dbPath);
    }

    navigator.pop();
  }

  /// Put every setting back the way it was when the dialog opened, then close.
  Future<void> _cancel() async {
    final navigator = Navigator.of(context);

    // restorePreferences also rolls the sync server password back in the
    // keychain, which is now its only home.
    await ref.read(settingsProvider.notifier).restorePreferences(_snapshot);

    navigator.pop();
  }

  /// Wraps each tab's content in consistent padding + scrolling.
  Widget _buildTabBody(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: child,
    );
  }

  // ---------- Tabs ----------

  Widget _buildAppearanceTab() {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: 'Theme',
          child: ClassicField(
            label: 'Mode',
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) notifier.setThemeMode(mode);
              },
              child: const Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  ClassicRadio<ThemeMode>(
                    label: 'System',
                    value: ThemeMode.system,
                  ),
                  ClassicRadio<ThemeMode>(
                    label: 'Light',
                    value: ThemeMode.light,
                  ),
                  ClassicRadio<ThemeMode>(
                    label: 'Dark',
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Content font (tree & editor)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: 'Family',
                child: _buildFamilyDropdown(
                  value: _showCustomFamilyField
                      ? '__custom__'
                      : settings.fontFamily,
                  onChanged: (value) {
                    if (value == '__custom__') {
                      setState(() => _showCustomFamilyField = true);
                    } else {
                      setState(() {
                        _showCustomFamilyField = false;
                        _customFamilyController.text = '';
                      });
                      notifier.setFontFamily(value);
                    }
                  },
                ),
              ),
              if (_showCustomFamilyField) ...[
                kClassicRowGap,
                ClassicField(
                  label: 'Custom name',
                  expand: true,
                  child: ClassicTextField(
                    controller: _customFamilyController,
                    hintText: 'e.g. Consolas',
                    onEditingComplete: () {
                      final trimmed = _customFamilyController.text.trim();
                      notifier.setFontFamily(trimmed.isEmpty ? null : trimmed);
                    },
                  ),
                ),
              ],
              kClassicRowGap,
              ClassicField(
                label: 'Size',
                child: ClassicSpinBox(
                  controller: _sizeController,
                  focusNode: _sizeFocusNode,
                  suffix: 'pt',
                  width: 96,
                  onCommit: () => _commitSize(_sizeController.text),
                  onIncrement: () => _stepSize(1),
                  onDecrement: () => _stepSize(-1),
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: 'Style',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  children: [
                    ClassicCheckbox(
                      label: 'Bold',
                      value: settings.fontBold,
                      onChanged: notifier.setFontBold,
                    ),
                    ClassicCheckbox(
                      label: 'Italic',
                      value: settings.fontItalic,
                      onChanged: notifier.setFontItalic,
                    ),
                  ],
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: 'Preview',
                expand: true,
                child: _buildFontPreview(settings),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Interface font (menus & dialogs)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: 'Family',
                child: _buildFamilyDropdown(
                  value: _showChromeCustomFamilyField
                      ? '__custom__'
                      : settings.chromeFontFamily,
                  onChanged: (value) {
                    if (value == '__custom__') {
                      setState(() => _showChromeCustomFamilyField = true);
                    } else {
                      setState(() {
                        _showChromeCustomFamilyField = false;
                        _chromeCustomFamilyController.text = '';
                      });
                      notifier.setChromeFontFamily(value);
                    }
                  },
                ),
              ),
              if (_showChromeCustomFamilyField) ...[
                kClassicRowGap,
                ClassicField(
                  label: 'Custom name',
                  expand: true,
                  child: ClassicTextField(
                    controller: _chromeCustomFamilyController,
                    hintText: 'e.g. Segoe UI',
                    onEditingComplete: () {
                      final trimmed = _chromeCustomFamilyController.text.trim();
                      notifier
                          .setChromeFontFamily(trimmed.isEmpty ? null : trimmed);
                    },
                  ),
                ),
              ],
              kClassicRowGap,
              ClassicField(
                label: 'Scale',
                child: ClassicSpinBox(
                  text: '${(settings.chromeFontScale * 100).round()}',
                  suffix: '%',
                  width: 96,
                  onIncrement: () => _stepChromeScale(0.05),
                  onDecrement: () => _stepChromeScale(-0.05),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBehaviorTab() {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: 'Time display',
          child: ClassicCheckbox(
            label: 'Show seconds',
            hint: 'Display seconds in time durations',
            value: settings.showSeconds,
            onChanged: notifier.setShowSeconds,
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Saving',
          child: ClassicField(
            label: 'Auto-save every',
            child: ClassicSpinBox(
              text: '${settings.autoSaveIntervalSeconds}',
              suffix: 'sec',
              width: 104,
              onIncrement: () => _stepAutoSave(5),
              onDecrement: () => _stepAutoSave(-5),
            ),
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Editor',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: 'Tab width',
                child: ClassicSpinBox(
                  text: '${settings.editorTabWidth}',
                  suffix: 'spaces',
                  width: 118,
                  onIncrement: () => _stepTabWidth(1),
                  onDecrement: () => _stepTabWidth(-1),
                ),
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: 'Insert tabs as spaces',
                hint: 'Pressing Tab inserts spaces instead of a tab',
                value: settings.editorTabAsSpaces,
                onChanged: notifier.setEditorTabAsSpaces,
              ),
              kClassicRowGap,
              ClassicField(
                label: 'Paste',
                hint: 'Ctrl+Shift+V always pastes plain text',
                child: ClassicDropdown<PasteFormatting>(
                  value: settings.pasteFormatting,
                  width: 232,
                  items: const [
                    DropdownMenuItem(
                      value: PasteFormatting.keep,
                      child: Text('Keep formatting'),
                    ),
                    DropdownMenuItem(
                      value: PasteFormatting.stripStyling,
                      child: Text('Remove colours and fonts'),
                    ),
                    DropdownMenuItem(
                      value: PasteFormatting.plainText,
                      child: Text('Plain text only'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setPasteFormatting(value);
                  },
                ),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Security',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicCheckbox(
                label: 'Remember password',
                hint: 'Store database password in system keychain',
                value: settings.rememberPassword,
                onChanged: (value) async {
                  await notifier.setRememberPassword(value);
                  // Switching this off clears the saved password for the open
                  // database, but only once the user accepts — see
                  // [_clearSavedPassword].
                  if (mounted) setState(() => _clearSavedPassword = !value);
                },
              ),
              if (Platform.isAndroid) ...[
                kClassicRowGap,
                ClassicCheckbox(
                  label: 'Biometric unlock',
                  // Say *why* it is unavailable — a greyed-out checkbox with
                  // the generic hint reads as a bug, and the fix (enrol a
                  // fingerprint, set a screen lock) is not guessable.
                  hint: _biometricAvailable == false
                      ? 'Unavailable — set up a fingerprint or screen lock in '
                          'Android settings first'
                      : 'Confirm fingerprint, face, or screen lock before '
                          'the remembered password is used',
                  value: settings.biometricUnlock,
                  // Two ways to have nothing to gate: no remembered password
                  // for the prompt to release, or no enrolled biometric and no
                  // screen lock, in which case the prompt could only ever fail
                  // closed and send the user to the password dialog anyway.
                  onChanged:
                      settings.rememberPassword && _biometricAvailable == true
                          ? notifier.setBiometricUnlock
                          : null,
                ),
                kClassicRowGap,
                ClassicCheckbox(
                  label: 'Block screenshots',
                  hint: 'Hide app content in screenshots, screen recording, '
                      'and the recent-apps switcher',
                  value: settings.blockScreenshots,
                  onChanged: notifier.setBlockScreenshots,
                ),
              ],
            ],
          ),
        ),

        // Single instance is a desktop-only concern — mobile OSes already keep
        // one process — so hide the control elsewhere.
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: 'Startup',
            child: ClassicCheckbox(
              label: 'Single instance',
              hint: 'Allow only one running window; a new launch focuses the '
                  'existing one. Takes effect on next launch.',
              value: settings.singleInstance,
              onChanged: notifier.setSingleInstance,
            ),
          ),
        ],
      ],
    );
  }

  // ---------- Shared controls ----------

  /// Font family combo box: the curated list plus a "Custom…" entry.
  Widget _buildFamilyDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return ClassicDropdown<String?>(
      value: value,
      width: 220,
      items: [
        for (final family in kCuratedFonts)
          DropdownMenuItem<String?>(
            value: family,
            child: Text(family ?? 'System default'),
          ),
        const DropdownMenuItem<String?>(
          value: '__custom__',
          child: Text('Custom…'),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildFontPreview(AppSettings settings) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium ?? const TextStyle();
    final style = fontSettingsToStyle(settings, base: base);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'The quick brown fox jumps over the lazy dog.',
        style: style,
      ),
    );
  }

  // ---------- Value stepping ----------

  void _stepSize(double delta) {
    final settings = ref.read(settingsProvider);
    final newSize = (settings.fontSize + delta).clamp(8.0, 48.0);
    ref.read(settingsProvider.notifier).setFontSize(newSize);
    _sizeController.text = newSize.toStringAsFixed(0);
  }

  void _commitSize(String raw) {
    final parsed = double.tryParse(raw);
    final settings = ref.read(settingsProvider);
    if (parsed == null || parsed < 8 || parsed > 48) {
      _sizeController.text = settings.fontSize.toStringAsFixed(0);
      return;
    }
    ref.read(settingsProvider.notifier).setFontSize(parsed);
  }

  void _stepChromeScale(double delta) {
    final settings = ref.read(settingsProvider);
    // Round to the nearest 5% step so repeated clicks stay on whole percents.
    final percent =
        (((settings.chromeFontScale + delta) * 100).round() / 5).round() * 5;
    ref
        .read(settingsProvider.notifier)
        .setChromeFontScale((percent / 100).clamp(0.8, 1.5));
  }

  void _stepAutoSave(int delta) {
    final settings = ref.read(settingsProvider);
    final value = (settings.autoSaveIntervalSeconds + delta).clamp(5, 60);
    ref.read(settingsProvider.notifier).setAutoSaveInterval(value);
  }

  void _stepTabWidth(int delta) {
    final settings = ref.read(settingsProvider);
    final value = (settings.editorTabWidth + delta).clamp(1, 8);
    ref.read(settingsProvider.notifier).setEditorTabWidth(value);
  }
}
