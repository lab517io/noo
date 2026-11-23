import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/mcp/mcp_protocol.dart';
import '../../../data/services/mcp/mcp_server.dart';
import '../../providers/mcp_provider.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import 'classic_form.dart';
import 'mcp_excluded_branches_dialog.dart';
import 'mcp_setup_hints.dart';
import '../../../core/theme/noo_chrome.dart';
import '../../../l10n/l10n.dart';

/// MCP configuration, embedded as the "MCP" tab of the preferences dialog.
///
/// Like the other preferences tabs it applies changes live: the port commits
/// when the field loses focus and the toggles commit immediately, so there is
/// no separate save step.
class McpSettingsForm extends ConsumerStatefulWidget {
  const McpSettingsForm({super.key});

  @override
  ConsumerState<McpSettingsForm> createState() => _McpSettingsFormState();
}

class _McpSettingsFormState extends ConsumerState<McpSettingsForm> {
  final _portController = TextEditingController();
  final _portFocus = FocusNode();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();

  McpClientHint _client = McpClientHint.claudeCode;
  bool _tokenVisible = false;

  /// Which control was last copied, cleared by [_copiedTimer].
  ///
  /// An inline label rather than a SnackBar: on desktop this form lives inside
  /// an AlertDialog, and a SnackBar posts to the root ScaffoldMessenger, which
  /// puts it behind the dialog the user is looking at.
  String? _copied;
  Timer? _copiedTimer;

  String? _tokenError;

  @override
  void initState() {
    super.initState();
    _portController.text = ref.read(settingsProvider).mcpPort.toString();
    _portFocus.addListener(() {
      if (!_portFocus.hasFocus) _commitPort();
    });
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _portController.dispose();
    _portFocus.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _commitPort() {
    final parsed = int.tryParse(_portController.text.trim());
    final settings = ref.read(settingsProvider);
    if (parsed == null) {
      _portController.text = settings.mcpPort.toString();
      return;
    }
    final clamped =
        parsed.clamp(AppSettings.kMinMcpPort, AppSettings.kMaxMcpPort);
    _portController.text = clamped.toString();
    if (clamped != settings.mcpPort) {
      ref.read(settingsProvider.notifier).setMcpPort(clamped);
    }
  }

  void _stepPort(int delta) {
    final settings = ref.read(settingsProvider);
    final next = (settings.mcpPort + delta)
        .clamp(AppSettings.kMinMcpPort, AppSettings.kMaxMcpPort);
    _portController.text = next.toString();
    ref.read(settingsProvider.notifier).setMcpPort(next);
  }

  /// Turning the server on mints a token if there is not one already, so the
  /// common path is a single click rather than a toggle plus a button.
  Future<void> _setEnabled(bool value) async {
    final notifier = ref.read(settingsProvider.notifier);
    if (value && (ref.read(settingsProvider).mcpToken ?? '').isEmpty) {
      // Deliberately not conditional on the write succeeding: a token that
      // reached memory but not the keychain still works until the app closes,
      // which is more use than refusing to start at all. The warning below
      // says what will be lost.
      await _writeToken(McpProtocol.randomToken());
    }
    await notifier.setMcpEnabled(value);
  }

  /// Write a token and check it survived the trip to the keychain.
  ///
  /// [SecureStorageService] swallows a keychain failure by design, so reading
  /// the value back is the only way to tell a missing token from a locked
  /// keyring — and the difference matters, because one is fixed by pressing a
  /// button and the other is not.
  Future<void> _writeToken(String? token) async {
    final stored = await ref.read(settingsProvider.notifier).setMcpToken(token);
    if (!mounted) return;
    setState(() {
      _tokenError = stored ? null : context.l10n.prefsMcpTokenSessionOnly;
    });
  }

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.prefsMcpRegenerateTitle),
        content: Text(context.l10n.prefsMcpRegenerateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.prefsMcpRegenerate),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _writeToken(McpProtocol.randomToken());
  }

  Future<void> _copy(String what, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = what);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final server = ref.watch(mcpServerProvider);
    final l10n = context.l10n;

    final token = settings.mcpToken ?? '';
    // The live port while bound, the setting otherwise — a snippet must never
    // name a port nothing is listening on.
    final port = server.isRunning ? server.port : settings.mcpPort;

    _urlController.text = mcpEndpointUrl(port);
    _tokenController.text = token;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: l10n.prefsMcpGroupAccess,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicCheckbox(
                label: l10n.prefsMcpEnable,
                hint: l10n.prefsMcpEnableHint,
                value: settings.mcpEnabled,
                onChanged: (value) => unawaited(_setEnabled(value)),
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.prefsMcpReadOnly,
                hint: l10n.prefsMcpReadOnlyHint,
                value: settings.mcpReadOnly,
                onChanged:
                    settings.mcpEnabled ? notifier.setMcpReadOnly : null,
              ),
              kClassicRowGap,
              _buildStatus(theme, settings, server),
            ],
          ),
        ),
        kClassicGroupGap,
        ClassicGroupBox(
          title: l10n.prefsMcpGroupEndpoint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsMcpPort,
                child: ClassicSpinBox(
                  controller: _portController,
                  focusNode: _portFocus,
                  width: 104,
                  onCommit: _commitPort,
                  onIncrement: () => _stepPort(1),
                  onDecrement: () => _stepPort(-1),
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsMcpUrl,
                expand: true,
                child: ClassicTextField(
                  controller: _urlController,
                  readOnly: true,
                  suffix: _iconButton(
                    icon: Icons.copy,
                    tooltip: l10n.prefsMcpCopyUrl,
                    onPressed: () => _copy('url', _urlController.text),
                  ),
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: l10n.prefsMcpToken,
                expand: true,
                hint: l10n.prefsMcpTokenHint,
                child: ClassicTextField(
                  controller: _tokenController,
                  readOnly: true,
                  obscureText: !_tokenVisible && token.isNotEmpty,
                  hintText: l10n.prefsMcpNoTokenYet,
                  suffix: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconButton(
                        icon: _tokenVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        tooltip: _tokenVisible
                            ? l10n.prefsMcpHideToken
                            : l10n.prefsMcpShowToken,
                        onPressed: token.isEmpty
                            ? null
                            : () =>
                                setState(() => _tokenVisible = !_tokenVisible),
                      ),
                      _iconButton(
                        icon: Icons.copy,
                        tooltip: l10n.prefsMcpCopyToken,
                        onPressed:
                            token.isEmpty ? null : () => _copy('token', token),
                      ),
                    ],
                  ),
                ),
              ),
              if (_tokenError != null) ...[
                kClassicRowGap,
                Text(
                  _tokenError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              kClassicRowGap,
              Row(
                children: [
                  TextButton(
                    // Available with no token too, so the "keychain lost it"
                    // state above has a way out.
                    onPressed: token.isEmpty && !settings.mcpEnabled
                        ? null
                        : _regenerate,
                    child: Text(l10n.prefsMcpRegenerate),
                  ),
                  const SizedBox(width: 12),
                  if (_copied == 'token' || _copied == 'url')
                    Text(
                      l10n.prefsMcpCopied,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
        kClassicGroupGap,
        _buildExcludedSection(theme),
        kClassicGroupGap,
        _buildSetupSection(theme, port, token),
      ],
    );
  }

  /// What is currently withheld from agents, and the way to change it.
  ///
  /// The picking happens in a subdialog rather than in the outline's context
  /// menu: hiding a branch is a rare, deliberate act done while thinking about
  /// what agents may read, which is here — and a per-task command would sit in
  /// the menu the user opens twenty times a day to rename something.
  ///
  /// What stays here is the answer to "what have I hidden", because a branch
  /// hidden months ago is otherwise findable only by scrolling the outline
  /// looking for the badge.
  Widget _buildExcludedSection(ThemeData theme) {
    final branches = ref.watch(mcpExcludedBranchesProvider);
    final databaseOpen = ref.watch(databaseProvider) != null;
    final l10n = context.l10n;

    return ClassicGroupBox(
      title: l10n.prefsMcpGroupExcluded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.prefsMcpExcludedIntro,
            style: theme.textTheme.bodySmall,
          ),
          kClassicRowGap,
          branches.when(
            // Neither a spinner nor an error box: this is a detail of a
            // settings tab, and a failed read here must not look like the
            // server is broken.
            loading: () =>
                Text(l10n.prefsMcpLoading, style: theme.textTheme.bodySmall),
            error: (_, _) => Text(
              l10n.prefsMcpOutlineReadError,
              style: theme.textTheme.bodySmall,
            ),
            data: (list) => _buildExcludedSummary(theme, list),
          ),
          kClassicRowGap,
          Row(
            children: [
              OutlinedButton(
                style: classicButtonStyle(context),
                // Nothing to pick from until a database is open; the tab is
                // reachable before one is, to set the port and token up front.
                onPressed: databaseOpen ? _chooseBranches : null,
                child: Text(l10n.prefsMcpChoose),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Names the hidden branches, or says plainly that there are none.
  ///
  /// Capped at [_maxNamedBranches]: past that the list stops being a summary
  /// and starts pushing the button it belongs to off the tab.
  Widget _buildExcludedSummary(
    ThemeData theme,
    List<McpExcludedBranch> branches,
  ) {
    if (branches.isEmpty) {
      return Text(
        context.l10n.prefsMcpNothingExcluded,
        style: theme.textTheme.bodySmall,
      );
    }

    final shown = branches.take(_maxNamedBranches).toList();
    final rest = branches.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final branch in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    // The title alone would not distinguish one "Notes" from
                    // another.
                    [...branch.path, branch.title].join(' › '),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (rest > 0)
          Text(
            context.l10n.prefsMcpMoreBranches(rest),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
      ],
    );
  }

  static const int _maxNamedBranches = 4;

  Future<void> _chooseBranches() async {
    final changed = await showMcpExcludedBranchesDialog(context);
    if (changed && mounted) ref.invalidate(mcpExcludedBranchesProvider);
  }

  Widget _buildStatus(ThemeData theme, AppSettings settings, McpServer server) {
    final small = theme.textTheme.bodySmall;
    final databaseOpen = ref.watch(databaseProvider) != null;
    final l10n = context.l10n;

    final String message;
    Color? colour;
    if (server.isRunning) {
      message = l10n.prefsMcpListening(mcpEndpointUrl(server.port));
    } else if (server.lastBindError != null) {
      // The likeliest real failure: single-instance mode is off by default, so
      // a second Noo window cannot bind, and its agent would otherwise talk to
      // the first window's database without either of them saying so.
      message = l10n.prefsMcpPortUnavailable('${settings.mcpPort}');
      colour = theme.colorScheme.error;
    } else if (settings.mcpEnabled && (settings.mcpToken ?? '').isEmpty) {
      // Reachable after a restart when the keychain could not keep the token:
      // the setting says enabled, but there is nothing to authenticate with.
      message = l10n.prefsMcpNoAccessToken;
      colour = theme.colorScheme.error;
    } else if (settings.mcpEnabled && !databaseOpen) {
      message = l10n.prefsMcpWaitingDatabase;
    } else {
      message = l10n.prefsMcpNotRunning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: small?.copyWith(color: colour)),
        if (server.isRunning)
          Text(
            [
              if (server.lastRequestAt != null)
                l10n.prefsMcpLastRequest(_clock(server.lastRequestAt!))
              else
                l10n.prefsMcpNoRequests,
              if (server.rejectedRequests > 0)
                l10n.prefsMcpRejected(server.rejectedRequests),
            ].join(' · '),
            style: small,
          ),
      ],
    );
  }

  Widget _buildSetupSection(ThemeData theme, int port, String token) {
    final l10n = context.l10n;
    final display = token.isEmpty ? l10n.prefsMcpEnableFirst : token;
    final snippet = mcpSetupSnippet(_client, port: port, token: display);
    final note = mcpSetupNote(_client);

    return ClassicGroupBox(
      title: l10n.prefsMcpGroupSetup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClassicField(
            label: l10n.prefsMcpClient,
            child: ClassicDropdown<McpClientHint>(
              value: _client,
              items: [
                for (final client in McpClientHint.values)
                  DropdownMenuItem(
                    value: client,
                    child: Text(mcpClientLabel(client)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _client = value);
              },
            ),
          ),
          kClassicRowGap,
          Text(mcpSetupTarget(_client), style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          _buildSnippet(theme, snippet),
          kClassicRowGap,
          Row(
            children: [
              TextButton(
                onPressed:
                    token.isEmpty ? null : () => _copy('snippet', snippet),
                child: Text(l10n.commonCopy),
              ),
              const SizedBox(width: 12),
              if (_copied == 'snippet')
                Text(l10n.prefsMcpCopied, style: theme.textTheme.bodySmall),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note, style: theme.textTheme.bodySmall),
          ],
          kClassicRowGap,
          Text(
            l10n.prefsMcpStdioBridge,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          _buildSnippet(
            theme,
            mcpStdioBridgeSnippet(port: port, token: display),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippet(ThemeData theme, String snippet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: NooChrome.of(context).smallRadius,
      ),
      // Scrolls rather than wrapping: a wrapped shell command reads as several
      // lines the user might paste one at a time.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          snippet,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Consolas', 'Menlo', 'DejaVu Sans Mono'],
          ),
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
    );
  }

  static String _clock(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}:'
      '${at.second.toString().padLeft(2, '0')}';
}
