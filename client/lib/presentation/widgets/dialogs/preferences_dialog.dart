import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/editor_toolbar.dart';
import '../../../core/constants/fonts.dart';
import '../../../core/constants/table_separator.dart';
import '../../../core/utils/platform_info.dart';
import '../../../l10n/l10n.dart';
import '../../../platform/biometric_gate.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import 'classic_form.dart';
import 'mcp_settings_form.dart';
import 'sync_settings_form.dart';
import 'voice_memo_settings_form.dart';
import '../../../core/theme/noo_chrome.dart';
import '../../../core/theme/ui_style.dart';
import '../time_tracking/mini_tracker.dart';
import '../window_title_bar.dart';

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
  late final TextEditingController _treeCustomFamilyController;
  late final TextEditingController _treeSizeController;
  late final FocusNode _sizeFocusNode;
  late final FocusNode _treeSizeFocusNode;
  late final FocusNode _customFamilyFocusNode;
  late final FocusNode _treeCustomFamilyFocusNode;
  late final FocusNode _chromeCustomFamilyFocusNode;
  bool _showCustomFamilyField = false;
  bool _showChromeCustomFamilyField = false;
  bool _showTreeCustomFamilyField = false;

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

    final treeFamily = settings.treeFontFamily;
    _showTreeCustomFamilyField =
        treeFamily != null && !kCuratedFonts.contains(treeFamily);
    _treeCustomFamilyController = TextEditingController(
      text: _showTreeCustomFamilyField ? treeFamily : '',
    );
    _treeSizeController = TextEditingController(
      text: settings.treeFontSize.toStringAsFixed(0),
    );
    _treeSizeFocusNode = FocusNode();

    final chromeFamily = settings.chromeFontFamily;
    _showChromeCustomFamilyField =
        chromeFamily != null && !kCuratedFonts.contains(chromeFamily);
    _chromeCustomFamilyController = TextEditingController(
      text: _showChromeCustomFamilyField ? chromeFamily : '',
    );

    // Typed values commit when the field loses focus, not only on Enter: a
    // user who types a size and clicks OK — or clicks the next field — has
    // committed it as far as they are concerned. The same commits run once
    // more from [_accept], for a field that still has focus when OK is hit.
    _onBlur(_sizeFocusNode, () => _commitSize(_sizeController.text));
    _onBlur(_treeSizeFocusNode, () => _commitTreeSize(_treeSizeController.text));
    _customFamilyFocusNode = FocusNode();
    _onBlur(_customFamilyFocusNode, _commitCustomFamily);
    _treeCustomFamilyFocusNode = FocusNode();
    _onBlur(_treeCustomFamilyFocusNode, _commitTreeCustomFamily);
    _chromeCustomFamilyFocusNode = FocusNode();
    _onBlur(_chromeCustomFamilyFocusNode, _commitChromeCustomFamily);
  }

  static void _onBlur(FocusNode node, VoidCallback commit) {
    node.addListener(() {
      if (!node.hasFocus) commit();
    });
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
    _treeCustomFamilyController.dispose();
    _treeSizeController.dispose();
    _sizeFocusNode.dispose();
    _treeSizeFocusNode.dispose();
    _customFamilyFocusNode.dispose();
    _treeCustomFamilyFocusNode.dispose();
    _chromeCustomFamilyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (!_sizeFocusNode.hasFocus) {
        final t = next.fontSize.toStringAsFixed(0);
        if (_sizeController.text != t) _sizeController.text = t;
      }
      if (!_treeSizeFocusNode.hasFocus) {
        final t = next.treeFontSize.toStringAsFixed(0);
        if (_treeSizeController.text != t) _treeSizeController.text = t;
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
    final l10n = context.l10n;
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
            tabs: [
              Tab(height: 36, text: l10n.prefsTabAppearance),
              Tab(height: 36, text: l10n.prefsTabBehavior),
              Tab(height: 36, text: l10n.prefsTabVoiceMemos),
              Tab(height: 36, text: l10n.prefsTabSync),
              Tab(height: 36, text: l10n.prefsTabMcp),
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
            title: Text(l10n.prefsTitle),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.commonCancel,
              onPressed: _cancel,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: l10n.commonOk,
                onPressed: _accept,
              ),
            ],
          ),
          body: SafeArea(child: tabs),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.prefsTitle),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: NooChrome.of(context).dialogShape,
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
          child: Text(l10n.commonOk),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: _cancel,
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  /// Keep the live-applied edits and carry out the changes that were held back
  /// until the user accepted.
  Future<void> _accept() async {
    final navigator = Navigator.of(context);

    // A field that still has focus has not committed yet — OK is the commit.
    _commitTypedValues();

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
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: l10n.prefsGroupLanguage,
          child: ClassicField(
            label: l10n.prefsInterfaceLanguage,
            hint: l10n.prefsLanguageHint,
            child: ClassicDropdown<String>(
              value: kAppLanguages.containsKey(settings.appLanguage)
                  ? settings.appLanguage
                  : '',
              width: 220,
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text(l10n.languageSystem),
                ),
                // Each language in its own name, untranslated: it is what
                // a user who cannot read the current one looks for.
                for (final entry in kAppLanguages.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
              ],
              onChanged: (code) {
                if (code != null) notifier.setAppLanguage(code);
              },
            ),
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupTheme,
          child: ClassicField(
            label: l10n.prefsThemeMode,
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) notifier.setThemeMode(mode);
              },
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  ClassicRadio<ThemeMode>(
                    label: l10n.prefsThemeSystem,
                    value: ThemeMode.system,
                  ),
                  ClassicRadio<ThemeMode>(
                    label: l10n.prefsThemeLight,
                    value: ThemeMode.light,
                  ),
                  ClassicRadio<ThemeMode>(
                    label: l10n.prefsThemeDark,
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          // The look is a desktop choice — Classic imitates desktop window
          // chrome, which a phone does not have — so only the accent colour
          // is offered elsewhere.
          title: _offersUiStyle ? l10n.prefsGroupStyle : l10n.prefsGroupColour,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_offersUiStyle) ...[
                ClassicField(
                  label: l10n.prefsLook,
                  hint: l10n.prefsLookHint,
                  child: RadioGroup<UiStyle>(
                    groupValue: settings.uiStyle,
                    onChanged: (style) {
                      if (style != null) notifier.setUiStyle(style);
                    },
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        for (final style in UiStyle.values)
                          ClassicRadio<UiStyle>(
                            label: style.label,
                            value: style,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              ClassicField(
                label: l10n.prefsAccentColour,
                child: _AccentSwatches(
                  selected: settings.accentColor,
                  onSelected: notifier.setAccentColor,
                ),
              ),
            ],
          ),
        ),

        if (offersSystemTitleBarChoice) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: l10n.prefsGroupWindow,
            child: ClassicCheckbox(
              label: l10n.prefsSystemTitleBar,
              hint: l10n.prefsSystemTitleBarHint,
              value: settings.useSystemTitleBar,
              onChanged: notifier.setUseSystemTitleBar,
            ),
          ),
        ],

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupEditorFont,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsFontFamily,
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
                  label: l10n.prefsCustomName,
                  expand: true,
                  child: ClassicTextField(
                    controller: _customFamilyController,
                    focusNode: _customFamilyFocusNode,
                    hintText: l10n.prefsCustomFamilyExample('Consolas'),
                    onEditingComplete: _commitCustomFamily,
                  ),
                ),
              ],
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsFontSize,
                child: ClassicSpinBox(
                  controller: _sizeController,
                  focusNode: _sizeFocusNode,
                  suffix: l10n.prefsUnitPt,
                  width: 96,
                  onCommit: () => _commitSize(_sizeController.text),
                  onIncrement: () => _stepSize(1),
                  onDecrement: () => _stepSize(-1),
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsFontStyle,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  children: [
                    ClassicCheckbox(
                      label: l10n.prefsBold,
                      value: settings.fontBold,
                      onChanged: notifier.setFontBold,
                    ),
                    ClassicCheckbox(
                      label: l10n.prefsItalic,
                      value: settings.fontItalic,
                      onChanged: notifier.setFontItalic,
                    ),
                  ],
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsPreview,
                expand: true,
                child: _buildFontPreview(
                  fontSettingsToStyle(
                    settings,
                    base: Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupTreeFont,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsFontFamily,
                child: _buildFamilyDropdown(
                  value: _showTreeCustomFamilyField
                      ? '__custom__'
                      : settings.treeFontFamily,
                  onChanged: (value) {
                    if (value == '__custom__') {
                      setState(() => _showTreeCustomFamilyField = true);
                    } else {
                      setState(() {
                        _showTreeCustomFamilyField = false;
                        _treeCustomFamilyController.text = '';
                      });
                      notifier.setTreeFontFamily(value);
                    }
                  },
                ),
              ),
              if (_showTreeCustomFamilyField) ...[
                kClassicRowGap,
                ClassicField(
                  label: l10n.prefsCustomName,
                  expand: true,
                  child: ClassicTextField(
                    controller: _treeCustomFamilyController,
                    focusNode: _treeCustomFamilyFocusNode,
                    hintText: l10n.prefsCustomFamilyExample('Consolas'),
                    onEditingComplete: _commitTreeCustomFamily,
                  ),
                ),
              ],
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsFontSize,
                child: ClassicSpinBox(
                  controller: _treeSizeController,
                  focusNode: _treeSizeFocusNode,
                  suffix: l10n.prefsUnitPt,
                  width: 96,
                  onCommit: () => _commitTreeSize(_treeSizeController.text),
                  onIncrement: () => _stepTreeSize(1),
                  onDecrement: () => _stepTreeSize(-1),
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsFontStyle,
                child: Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  children: [
                    ClassicCheckbox(
                      label: l10n.prefsBold,
                      value: settings.treeFontBold,
                      onChanged: notifier.setTreeFontBold,
                    ),
                    ClassicCheckbox(
                      label: l10n.prefsItalic,
                      value: settings.treeFontItalic,
                      onChanged: notifier.setTreeFontItalic,
                    ),
                  ],
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsPreview,
                expand: true,
                child: _buildFontPreview(
                  treeFontSettingsToStyle(
                    settings,
                    base: Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle(),
                  ),
                ),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupInterfaceFont,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsFontFamily,
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
                  label: l10n.prefsCustomName,
                  expand: true,
                  child: ClassicTextField(
                    controller: _chromeCustomFamilyController,
                    focusNode: _chromeCustomFamilyFocusNode,
                    hintText: l10n.prefsCustomFamilyExample('Segoe UI'),
                    onEditingComplete: _commitChromeCustomFamily,
                  ),
                ),
              ],
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsScale,
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
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: l10n.prefsGroupTimeTracking,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicCheckbox(
                label: l10n.prefsEnableTimeTracking,
                hint: l10n.prefsEnableTimeTrackingHint,
                value: settings.timeTrackingEnabled,
                onChanged: notifier.setTimeTrackingEnabled,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsShowSeconds,
                hint: l10n.prefsShowSecondsHint,
                value: settings.showSeconds,
                onChanged: settings.timeTrackingEnabled
                    ? notifier.setShowSeconds
                    : null,
              ),
              if (offersMiniTracker) ...[
                kClassicRowGap,
                ClassicCheckbox(
                  label: l10n.prefsMiniTracker,
                  hint: l10n.prefsMiniTrackerHint,
                  value: settings.miniTrackerOnMinimize,
                  onChanged: settings.timeTrackingEnabled
                      ? notifier.setMiniTrackerOnMinimize
                      : null,
                ),
              ],
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupSaving,
          child: ClassicField(
            label: l10n.prefsAutoSaveEvery,
            child: ClassicSpinBox(
              text: '${settings.autoSaveIntervalSeconds}',
              suffix: l10n.prefsUnitSec,
              width: 104,
              onIncrement: () => _stepAutoSave(5),
              onDecrement: () => _stepAutoSave(-5),
            ),
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupEditor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsTabWidth,
                child: ClassicSpinBox(
                  text: '${settings.editorTabWidth}',
                  suffix: l10n.prefsUnitSpaces,
                  width: 118,
                  onIncrement: () => _stepTabWidth(1),
                  onDecrement: () => _stepTabWidth(-1),
                ),
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsTabAsSpaces,
                hint: l10n.prefsTabAsSpacesHint,
                value: settings.editorTabAsSpaces,
                onChanged: notifier.setEditorTabAsSpaces,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsWordWrap,
                hint: l10n.prefsWordWrapHint,
                value: settings.editorWordWrap,
                onChanged: notifier.setEditorWordWrap,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsMonospaceOnly,
                hint: l10n.prefsMonospaceOnlyHint,
                value: settings.monospaceFontsOnly,
                onChanged: notifier.setMonospaceFontsOnly,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsFloatingButtons,
                hint: l10n.prefsFloatingButtonsHint,
                value: settings.editorFloatingActions,
                onChanged: notifier.setEditorFloatingActions,
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsPaste,
                hint: l10n.prefsPasteHint,
                child: ClassicDropdown<PasteFormatting>(
                  value: settings.pasteFormatting,
                  width: 232,
                  items: [
                    DropdownMenuItem(
                      value: PasteFormatting.keep,
                      child: Text(l10n.prefsPasteKeep),
                    ),
                    DropdownMenuItem(
                      value: PasteFormatting.stripStyling,
                      child: Text(l10n.prefsPasteStrip),
                    ),
                    DropdownMenuItem(
                      value: PasteFormatting.plainText,
                      child: Text(l10n.prefsPastePlain),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setPasteFormatting(value);
                  },
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsTableColumns,
                hint: l10n.prefsTableColumnsHint,
                child: ClassicDropdown<TableSeparator>(
                  value: settings.tableSeparator,
                  width: 232,
                  items: [
                    for (final separator in TableSeparator.values)
                      DropdownMenuItem(
                        value: separator,
                        child: Text(_tableSeparatorName(l10n, separator)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setTableSeparator(value);
                  },
                ),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupToolbarButtons,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.prefsToolbarButtonsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              kClassicRowGap,
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final button in EditorToolbarButton.values)
                    SizedBox(
                      width: 176,
                      child: ClassicCheckbox(
                        label: button.label,
                        value:
                            !settings.editorToolbarHidden.contains(button),
                        onChanged: (shown) => notifier
                            .setEditorToolbarButtonShown(button, shown),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.prefsGroupSecurity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicCheckbox(
                label: l10n.prefsRememberPassword,
                hint: l10n.prefsRememberPasswordHint,
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
                  label: l10n.prefsBiometricUnlock,
                  // Say *why* it is unavailable — a greyed-out checkbox with
                  // the generic hint reads as a bug, and the fix (enrol a
                  // fingerprint, set a screen lock) is not guessable.
                  hint: _biometricAvailable == false
                      ? l10n.prefsBiometricUnavailableHint
                      : l10n.prefsBiometricHint,
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
                  label: l10n.prefsBlockScreenshots,
                  hint: l10n.prefsBlockScreenshotsHint,
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
            title: l10n.prefsGroupStartup,
            child: ClassicCheckbox(
              label: l10n.prefsSingleInstance,
              hint: l10n.prefsSingleInstanceHint,
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
            child: Text(fontFamilyLabel(family)),
          ),
        DropdownMenuItem<String?>(
          value: '__custom__',
          child: Text(context.l10n.prefsFontCustom),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildFontPreview(TextStyle style) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: NooChrome.of(context).smallRadius,
      ),
      child: Text(
        context.l10n.prefsPreviewText,
        style: style,
      ),
    );
  }

  // ---------- Typed values ----------

  /// Commit every free-text field as it stands. Run from OK, so a value typed
  /// into a field that still has focus is not lost with the dialog; each
  /// commit is idempotent, so a field that already committed on blur or
  /// Enter is simply written again with the same value.
  void _commitTypedValues() {
    _commitSize(_sizeController.text);
    _commitTreeSize(_treeSizeController.text);
    if (_showCustomFamilyField) _commitCustomFamily();
    if (_showTreeCustomFamilyField) _commitTreeCustomFamily();
    if (_showChromeCustomFamilyField) _commitChromeCustomFamily();
  }

  void _commitCustomFamily() {
    final trimmed = _customFamilyController.text.trim();
    ref
        .read(settingsProvider.notifier)
        .setFontFamily(trimmed.isEmpty ? null : trimmed);
  }

  void _commitTreeCustomFamily() {
    final trimmed = _treeCustomFamilyController.text.trim();
    ref
        .read(settingsProvider.notifier)
        .setTreeFontFamily(trimmed.isEmpty ? null : trimmed);
  }

  void _commitChromeCustomFamily() {
    final trimmed = _chromeCustomFamilyController.text.trim();
    ref
        .read(settingsProvider.notifier)
        .setChromeFontFamily(trimmed.isEmpty ? null : trimmed);
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

  void _stepTreeSize(double delta) {
    final settings = ref.read(settingsProvider);
    final newSize = (settings.treeFontSize + delta).clamp(8.0, 48.0);
    ref.read(settingsProvider.notifier).setTreeFontSize(newSize);
    _treeSizeController.text = newSize.toStringAsFixed(0);
  }

  void _commitTreeSize(String raw) {
    final parsed = double.tryParse(raw);
    final settings = ref.read(settingsProvider);
    if (parsed == null || parsed < 8 || parsed > 48) {
      _treeSizeController.text = settings.treeFontSize.toStringAsFixed(0);
      return;
    }
    ref.read(settingsProvider.notifier).setTreeFontSize(parsed);
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

/// Whether Preferences offers the Modern/Classic choice: desktops only.
bool get _offersUiStyle =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

/// A row of colour swatches, one per [AccentColor]; the chosen one is ringed.
class _AccentSwatches extends StatelessWidget {
  const _AccentSwatches({required this.selected, required this.onSelected});

  final AccentColor selected;
  final ValueChanged<AccentColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = NooChrome.of(context).smallRadius;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final accent in AccentColor.values)
          Tooltip(
            message: accent.label,
            child: Semantics(
              button: true,
              selected: accent == selected,
              label: accent.label,
              child: InkWell(
                key: ValueKey('accent-${accent.name}'),
                borderRadius: radius,
                onTap: () => onSelected(accent),
                child: Container(
                  width: 26,
                  height: 26,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: accent == selected
                          ? theme.colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.seed,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// How Preferences names a [TableSeparator].
String _tableSeparatorName(AppLocalizations l10n, TableSeparator separator) =>
    switch (separator) {
      TableSeparator.colon => l10n.prefsSeparatorColon,
      TableSeparator.equals => l10n.prefsSeparatorEquals,
      TableSeparator.pipe => l10n.prefsSeparatorPipe,
      TableSeparator.semicolon => l10n.prefsSeparatorSemicolon,
      TableSeparator.comma => l10n.prefsSeparatorComma,
      TableSeparator.tab => l10n.prefsSeparatorTab,
    };
