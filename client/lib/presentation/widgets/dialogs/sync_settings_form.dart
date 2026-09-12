import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/byte_format.dart';
import '../../../data/services/sync_api_client.dart';
import '../../../data/services/sync_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import 'classic_form.dart';

/// Sync configuration form, embedded as the "Sync" tab of the preferences
/// dialog. Like the other preferences tabs it applies changes live: text
/// fields commit when they lose focus and toggles commit immediately, so there
/// is no separate save step.
class SyncSettingsForm extends ConsumerStatefulWidget {
  const SyncSettingsForm({super.key});

  @override
  ConsumerState<SyncSettingsForm> createState() => _SyncSettingsFormState();
}

class _SyncSettingsFormState extends ConsumerState<SyncSettingsForm> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _serverPasswordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _autoSyncController = TextEditingController();

  final _serverUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _serverPasswordFocus = FocusNode();
  final _deviceNameFocus = FocusNode();
  final _autoSyncFocus = FocusNode();

  bool _syncEnabled = false;
  bool _syncOnExit = true;
  bool _syncOnStart = true;
  bool _testing = false;
  String? _testResult;
  bool _registering = false;

  /// Relay storage, once asked for. Null until the first refresh: reading it
  /// costs a login, so the tab does not fetch it just by being opened.
  RelayUsage? _usage;
  ({int packets, int bytes})? _localUsage;
  bool _loadingUsage = false;
  String? _usageError;

  /// Compaction is a long, server-visible action: the button reports its
  /// stage while it runs and its outcome afterwards.
  bool _compacting = false;
  String? _compactStage;
  String? _compactResult;
  bool _compactFailed = false;

  /// Fork recovery (docs/P2P_SYNC.md §3.3): rare, and the one action here that
  /// changes what this device *is* to the rest of the fleet, so its outcome is
  /// reported in place rather than in a snack bar that scrolls away.
  bool _resetting = false;
  String? _resetResult;
  bool _resetFailed = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _syncEnabled = settings.syncEnabled;
    _syncOnExit = settings.syncOnExit;
    _syncOnStart = settings.syncOnStart;
    _serverUrlController.text = settings.syncServerUrl ?? '';
    _usernameController.text = settings.syncUsername ?? '';
    _serverPasswordController.text = settings.syncPassword ?? '';
    _deviceNameController.text = settings.syncDeviceName ?? Platform.localHostname;
    _autoSyncController.text = settings.syncAutoInterval.toString();

    // Commit each field's value as soon as it loses focus, matching the
    // live-apply behavior of the other preferences tabs.
    for (final node in [
      _serverUrlFocus,
      _usernameFocus,
      _serverPasswordFocus,
      _deviceNameFocus,
      _autoSyncFocus,
    ]) {
      node.addListener(() {
        if (!node.hasFocus) _commit();
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _serverPasswordController.dispose();
    _deviceNameController.dispose();
    _autoSyncController.dispose();
    _serverUrlFocus.dispose();
    _usernameFocus.dispose();
    _serverPasswordFocus.dispose();
    _deviceNameFocus.dispose();
    _autoSyncFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scheduled sync is a server feature: the LAN path never runs unattended.
    // Reads the committed config rather than the live controllers, so it
    // settles when a field loses focus.
    final config = ref.watch(syncConfigProvider);
    final relayConfigured = config.isRelayConfigured;
    final scheduleEnabled = _syncEnabled && relayConfigured;
    // A user name is now the only thing between the user and working LAN
    // sync, so say so rather than leaving sync silently inert.
    final needsUserName = _syncEnabled && !config.isIdentityConfigured;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: 'Synchronization',
          child: ClassicCheckbox(
            label: 'Enable sync',
            hint: 'Keep this database in sync with a server',
            value: _syncEnabled,
            onChanged: _setSyncEnabled,
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Identity',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsUserName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Enter a user name to start syncing. Nothing syncs '
                    'without one \u2014 with or without a server.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ClassicField(
                label: 'User name',
                hint: 'The same on every device of yours. Together with the '
                    'database password it derives the encryption keys, so '
                    'devices only sync when both match.',
                expand: true,
                child: ClassicTextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  enabled: _syncEnabled,
                  onEditingComplete: _commit,
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: 'Device name',
                hint: 'How this device introduces itself to nearby devices',
                expand: true,
                child: ClassicTextField(
                  controller: _deviceNameController,
                  focusNode: _deviceNameFocus,
                  enabled: _syncEnabled,
                  onEditingComplete: _commit,
                ),
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Sync server (optional)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Leave empty to sync only with nearby devices on the same '
                  'network. A server additionally lets devices sync when they '
                  'are apart; it stores encrypted data it cannot read.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              ClassicField(
                label: 'Server URL',
                expand: true,
                child: ClassicTextField(
                  controller: _serverUrlController,
                  focusNode: _serverUrlFocus,
                  hintText: 'https://sync.example.com',
                  enabled: _syncEnabled,
                  onEditingComplete: _commit,
                ),
              ),
              kClassicRowGap,
              ClassicField(
                label: 'Password',
                hint: 'Your account password on the server. Not the database '
                    'password, and never used as an encryption key.',
                expand: true,
                child: ClassicTextField(
                  controller: _serverPasswordController,
                  focusNode: _serverPasswordFocus,
                  obscureText: true,
                  enabled: _syncEnabled,
                  onEditingComplete: _commit,
                ),
              ),
              kClassicRowGap,
              ClassicFieldIndent(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      style: classicButtonStyle(context),
                      onPressed:
                          _syncEnabled && !_testing ? _testConnection : null,
                      child: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test Connection'),
                    ),
                    OutlinedButton(
                      style: classicButtonStyle(context),
                      onPressed: _syncEnabled && !_registering
                          ? _registerAccount
                          : null,
                      child: _registering
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Register'),
                    ),
                  ],
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 8),
                ClassicFieldIndent(
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.startsWith('Success')
                          ? Colors.green
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Schedule',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!relayConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Scheduled sync needs a server. Nearby devices sync when '
                    'you ask them to, from File \u2192 Sync with Nearby '
                    'Devices.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ClassicField(
                label: 'Auto-sync every',
                hint: '0 = manual sync only',
                child: ClassicSpinBox(
                  controller: _autoSyncController,
                  focusNode: _autoSyncFocus,
                  suffix: 'min',
                  width: 104,
                  enabled: scheduleEnabled,
                  onCommit: _commit,
                  onIncrement: () => _stepAutoSync(5),
                  onDecrement: () => _stepAutoSync(-5),
                ),
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: 'Autosync on start',
                hint: 'Sync when the app opens the database',
                value: _syncOnStart,
                onChanged: scheduleEnabled
                    ? (value) {
                        setState(() => _syncOnStart = value);
                        ref
                            .read(settingsProvider.notifier)
                            .setSyncOnStart(value);
                      }
                    : null,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: 'Ask to sync on exit',
                hint: 'Prompt to sync pending changes before the app closes',
                value: _syncOnExit,
                onChanged: scheduleEnabled
                    ? (value) {
                        setState(() => _syncOnExit = value);
                        ref
                            .read(settingsProvider.notifier)
                            .setSyncOnExit(value);
                      }
                    : null,
              ),
            ],
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Server storage',
          child: _buildRelayStorage(theme, relayConfigured),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: 'Nearby devices',
          child: _buildTrustedPeers(theme),
        ),
      ],
    );
  }

  /// What this account occupies on the server, and the command that shrinks
  /// it.
  ///
  /// The packet log is append-only, so it grows even when the outline does
  /// not — most of the cost is old edits and superseded full-state packets,
  /// not current data. Compaction publishes one snapshot of the whole
  /// database and lets the server discard everything that snapshot already
  /// contains.
  Widget _buildRelayStorage(ThemeData theme, bool relayConfigured) {
    final hint = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.outline);

    if (!relayConfigured) {
      return Text(
        'Nothing is stored on a server in this setup. Nearby-device sync '
        'keeps every packet on the devices themselves.',
        style: hint,
      );
    }

    final usage = _usage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'The server keeps every encrypted change ever made, so its size '
            'grows with edits rather than with the size of your outline.',
            style: hint,
          ),
        ),
        if (_loadingUsage)
          Text('Reading\u2026', style: theme.textTheme.bodyMedium)
        else if (_usageError != null)
          Text(
            _usageError!,
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (usage == null)
          Text('Press Refresh to read the current usage.', style: hint)
        else ...[
          Text(
            usage.packets == 0
                ? 'Nothing stored on the server yet.'
                : '${formatBytes(usage.bytes)} in ${usage.packets} '
                    'packet${usage.packets == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final device in usage.devices)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.devices,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'Counters ${device.firstCounter}'
                          '\u2013${device.lastCounter}'
                          '${device.snapshots > 0 ? ', ${device.snapshots} snapshot(s)' : ''}'
                          '\n${device.deviceId}',
                      child: Text(
                        device.deviceName.isEmpty
                            ? device.deviceId
                            : device.deviceName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Text(
                    '${device.packets} \u00b7 ${formatBytes(device.bytes)}',
                    style: hint,
                  ),
                ],
              ),
            ),
          if (usage.blobs > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Plus ${usage.blobs} attachment${usage.blobs == 1 ? '' : 's'} '
                '(${formatBytes(usage.blobBytes)}), stored once and shared by '
                'every packet that references them.',
                style: hint,
              ),
            ),
          if (_localUsage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'This device holds ${_localUsage!.packets} of them locally '
                '(${formatBytes(_localUsage!.bytes)}).',
                style: hint,
              ),
            ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              style: classicButtonStyle(context),
              onPressed:
                  _syncEnabled && !_loadingUsage && !_compacting ? _refreshUsage : null,
              child: const Text('Refresh'),
            ),
            OutlinedButton(
              style: classicButtonStyle(context),
              onPressed: _syncEnabled && !_compacting ? _compactRelay : null,
              child: _compacting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Compact data on server'),
            ),
            OutlinedButton(
              style: classicButtonStyle(context),
              onPressed: _syncEnabled && !_compacting && !_resetting
                  ? _resetDeviceIdentity
                  : null,
              child: _resetting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reset device identity'),
            ),
          ],
        ),
        if (_resetResult != null && !_resetting)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _resetResult!,
              style: TextStyle(
                color: _resetFailed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        if (_compactStage != null && _compacting)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${_compactStage!}\u2026', style: hint),
          ),
        if (_compactResult != null && !_compacting)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _compactResult!,
              style: TextStyle(
                color: _compactFailed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _refreshUsage() async {
    final service = ref.read(syncServiceProvider);
    if (service == null || !service.hasRelay) {
      setState(() => _usageError = 'Sync is not configured on this device.');
      return;
    }

    setState(() {
      _loadingUsage = true;
      _usageError = null;
    });
    try {
      final usage = await service.fetchRelayUsage();
      final local = await service.localPacketStorage();
      if (!mounted) return;
      setState(() {
        _usage = usage;
        _localUsage = local;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _usageError = 'Could not read server storage: $e');
    } finally {
      if (mounted) setState(() => _loadingUsage = false);
    }
  }

  /// Give this device a fresh sync identity and republish its whole database
  /// under it (docs/P2P_SYNC.md §3.3).
  ///
  /// The way out of a fork: this database has published packet numbers that
  /// already belong to different content elsewhere, and no message can take
  /// those back. A new identity makes the argument moot — the old stream stops
  /// growing, and the full copy published under the new one merges everywhere
  /// by the ordinary rules.
  ///
  /// Offered as a button rather than done automatically because it is visible
  /// to the whole fleet: a new device appears in the server's storage list, and
  /// the old one's packets linger until someone compacts. The error that sends
  /// people here names this action, so it has to exist.
  Future<void> _resetDeviceIdentity() async {
    final service = ref.read(syncServiceProvider);
    if (service == null) {
      setState(() {
        _resetFailed = true;
        _resetResult = 'Sync is not configured on this device.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset device identity'),
        content: const Text(
          'This device will start syncing under a new identity, and its next '
          'sync will publish a full copy of the current database. Your other '
          'devices merge that normally \u2014 nothing is lost.\n\n'
          'Do this when syncing reports that this device\u2019s history has '
          'diverged, which usually means this database was restored from a '
          'backup after it had already synced.\n\n'
          'The old identity keeps appearing in the server\u2019s storage list '
          'until you compact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _resetting = true;
      _resetResult = null;
      _resetFailed = false;
    });
    try {
      final notifier = ref.read(settingsProvider.notifier);
      final recovery = await service.recoverFromFork(
        divergedAtCounter: service.lastDivergenceCounter,
        persistIdentity: notifier.setSyncDeviceId,
      );
      if (!mounted) return;
      setState(() => _resetResult = recovery.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resetFailed = true;
        _resetResult = 'Could not reset the device identity: $e';
      });
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  /// Publish a snapshot and let the server (and this device) drop everything
  /// it covers. Confirmed first: it discards edit history everywhere, and a
  /// device still running an older version of Noo cannot read a stream whose
  /// beginning has been pruned.
  Future<void> _compactRelay() async {
    final service = ref.read(syncServiceProvider);
    if (service == null || !service.hasRelay) {
      setState(() {
        _compactFailed = true;
        _compactResult = 'Sync is not configured on this device.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compact data on server'),
        content: const Text(
          'This device will sync, then upload one snapshot of the whole '
          'database. The server then deletes every stored change the '
          'snapshot already contains, and so does every device as it picks '
          'the snapshot up.\n\n'
          'Your notes, times and attachments are unaffected \u2014 what is '
          'discarded is the record of individual past edits below the '
          'snapshot.\n\n'
          'Update Noo on your other devices first: an older version cannot '
          'read a stream whose beginning has been removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Compact'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _compacting = true;
      _compactStage = null;
      _compactResult = null;
      _compactFailed = false;
    });

    final result = await service.compactRelay(
      onProgress: (stage) {
        if (mounted) setState(() => _compactStage = stage);
      },
    );
    if (!mounted) return;

    setState(() {
      _compacting = false;
      _compactStage = null;
      _compactFailed = !result.success;
      _compactResult = _describeCompaction(result);
      if (result.usage != null) _usage = result.usage;
    });
    if (result.success) {
      final service = ref.read(syncServiceProvider);
      final local = await service?.localPacketStorage();
      if (mounted && local != null) setState(() => _localUsage = local);
    }
  }

  String _describeCompaction(CompactionResult result) {
    if (!result.success) return result.error ?? 'Compaction failed.';
    if (result.snapshotCounter == 0) {
      return 'Nothing to compact yet.';
    }
    final buffer = StringBuffer();
    if (result.relayPackets > 0) {
      buffer.write('Freed ${formatBytes(result.relayBytes)} on the server '
          '(${result.relayPackets} packets)');
    } else if (!result.relaySupported) {
      buffer.write('Snapshot uploaded, but this server does not support '
          'compaction yet, so it kept its copies');
    } else {
      buffer.write('Snapshot uploaded; the server had nothing left to drop');
    }
    if (result.localPackets > 0) {
      buffer.write('. This device freed ${formatBytes(result.localBytes)} '
          '(${result.localPackets} packets)');
    }
    buffer.write('. The snapshot itself is '
        '${formatBytes(result.snapshotBytes)}.');
    return buffer.toString();
  }

  /// Devices allowed to sync without asking, each revocable.
  ///
  /// "Always allow" is answered on a prompt that appears on whichever device
  /// happens to be nearby, so this is the only place it can be taken back —
  /// without it, ticking the box would be a one-way door.
  Widget _buildTrustedPeers(ThemeData theme) {
    final trusted = ref.watch(trustedPeerListProvider).value ?? const {};

    if (trusted.isEmpty) {
      return Text(
        'Devices on this network that share your user name and database '
        'password sync directly with each other \u2014 no server needed. '
        'No devices are allowed to sync without asking yet; nearby devices '
        'are confirmed each time they request a sync.',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.outline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'These devices sync without asking. They still only sync when '
          'someone presses sync.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        for (final entry in trusted.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.devices, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: entry.key,
                    child: Text(
                      entry.value.isEmpty ? entry.key : entry.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _revokePeer(entry.key),
                  child: const Text('Revoke'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _revokePeer(String deviceId) async {
    await ref.read(trustedPeersProvider)?.revoke(deviceId);
    if (!mounted) return;
    ref.invalidate(trustedPeerListProvider);
  }

  /// Nudge the auto-sync interval by [delta] minutes, keeping it non-negative.
  void _stepAutoSync(int delta) {
    final current = int.tryParse(_autoSyncController.text) ?? 0;
    final next = (current + delta).clamp(0, 1440);
    _autoSyncController.text = next.toString();
    _commit();
  }

  Future<void> _setSyncEnabled(bool value) async {
    setState(() => _syncEnabled = value);
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.setSyncEnabled(value);
    // Ensure a device ID exists once sync is turned on.
    if (value) {
      final settings = ref.read(settingsProvider);
      if (settings.syncDeviceId == null || settings.syncDeviceId!.isEmpty) {
        await notifier.setSyncDeviceId(const Uuid().v4());
      }
    }
  }

  /// Persist the current field values to settings. Called on focus loss /
  /// editing complete for each field. The server password lands in the
  /// platform keychain — [SettingsNotifier.setSyncPasswod] routes it there,
  /// including deleting the entry when the field is cleared.
  Future<void> _commit() async {
    final notifier = ref.read(settingsProvider.notifier);

    await notifier.setSyncServerUrl(_serverUrlController.text.trim());
    await notifier.setSyncUsername(_usernameController.text.trim());
    await notifier.setSyncPasswod(_serverPasswordController.text.trim());
    await notifier.setSyncDeviceName(_deviceNameController.text.trim());
    await notifier.setSyncAutoInterval(
      int.tryParse(_autoSyncController.text) ?? 0,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final client = SyncApiClient(config: SyncConfig(serverUrl: _serverUrlController.text.trim(), deviceId: 'test'));
      final ok = await client.testConnection();
      setState(() {
        _testResult = ok ? 'Success: Server is reachable' : 'Error: Server not reachable';
      });
      client.dispose();
    } catch (e) {
      setState(() {
        _testResult = 'Error: $e';
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _registerAccount() async {
    final username = _usernameController.text.trim();
    final password = _serverPasswordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _testResult = 'Error: Username and password required');
      return;
    }

    setState(() {
      _registering = true;
      _testResult = null;
    });

    try {
      final config = SyncConfig(enabled: true, serverUrl: _serverUrlController.text.trim(), username: username, password: password);
      final client = SyncApiClient(config: config);
      await client.register();
      setState(() => _testResult = 'Success: Account registered');
      client.dispose();
    } catch (e) {
      setState(() => _testResult = 'Error: $e');
    } finally {
      setState(() => _registering = false);
    }
  }
}
