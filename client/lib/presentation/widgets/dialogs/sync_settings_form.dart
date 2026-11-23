import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/byte_format.dart';
import '../../../data/services/sync_api_client.dart';
import '../../../data/services/sync_service.dart';
import '../../../l10n/l10n.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import 'classic_form.dart';
import 'relay_quota_meter.dart';

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

  final _serverUrlFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _serverPasswordFocus = FocusNode();
  final _deviceNameFocus = FocusNode();

  bool _syncEnabled = false;
  bool _syncOnExit = true;
  bool _syncOnStart = true;
  bool _syncCheckOnStart = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;
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
    _syncCheckOnStart = settings.syncCheckOnStart;
    _serverUrlController.text = settings.syncServerUrl ?? '';
    _usernameController.text = settings.syncUsername ?? '';
    _serverPasswordController.text = settings.syncPassword ?? '';
    _deviceNameController.text = settings.syncDeviceName ?? Platform.localHostname;

    // Commit each field's value as soon as it loses focus, matching the
    // live-apply behavior of the other preferences tabs.
    for (final node in [
      _serverUrlFocus,
      _usernameFocus,
      _serverPasswordFocus,
      _deviceNameFocus,
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
    _serverUrlFocus.dispose();
    _usernameFocus.dispose();
    _serverPasswordFocus.dispose();
    _deviceNameFocus.dispose();
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
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: l10n.syncGroupSynchronization,
          child: ClassicCheckbox(
            label: l10n.syncEnable,
            hint: l10n.syncEnableHint,
            value: _syncEnabled,
            onChanged: _setSyncEnabled,
          ),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.syncGroupIdentity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (needsUserName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.syncNeedsUserName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ClassicField(
                label: l10n.syncUserName,
                hint: l10n.syncUserNameHint,
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
                label: l10n.syncDeviceName,
                hint: l10n.syncDeviceNameHint,
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
          title: l10n.syncGroupServer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.syncServerIntro,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              ClassicField(
                label: l10n.syncServerUrl,
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
                label: l10n.syncServerPassword,
                hint: l10n.syncServerPasswordHint,
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
                          : Text(l10n.syncTestConnection),
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
                          : Text(l10n.syncRegister),
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
                      color: _testOk
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
          title: l10n.syncGroupSchedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!relayConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.syncScheduleNeedsServer,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ClassicCheckbox(
                label: l10n.syncAutosyncOnStart,
                hint: l10n.syncAutosyncOnStartHint,
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
                label: l10n.syncCheckOnStart,
                hint: l10n.syncCheckOnStartHint,
                value: _syncCheckOnStart,
                onChanged: scheduleEnabled && !_syncOnStart
                    ? (value) {
                        setState(() => _syncCheckOnStart = value);
                        ref
                            .read(settingsProvider.notifier)
                            .setSyncCheckOnStart(value);
                      }
                    : null,
              ),
              kClassicRowGap,
              ClassicCheckbox(
                label: l10n.syncAskOnExit,
                hint: l10n.syncAskOnExitHint,
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
          title: l10n.syncGroupServerStorage,
          child: _buildRelayStorage(theme, relayConfigured),
        ),

        kClassicGroupGap,

        ClassicGroupBox(
          title: l10n.syncGroupPeerToPeer,
          child: Text(
            l10n.syncPeerToPeerIntro,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
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
    final l10n = context.l10n;

    if (!relayConfigured) {
      return Text(
        l10n.syncStorageNoServer,
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
            l10n.syncStorageIntro,
            style: hint,
          ),
        ),
        if (_loadingUsage)
          Text(l10n.syncStorageReading, style: theme.textTheme.bodyMedium)
        else if (_usageError != null)
          Text(
            _usageError!,
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (usage == null)
          Text(l10n.syncStoragePressRefresh, style: hint)
        else ...[
          if (usage.hasQuota) ...[
            RelayQuotaMeter(usage: usage),
            const SizedBox(height: 6),
          ],
          Text(
            usage.packets == 0
                ? l10n.syncStorageEmpty
                : l10n.syncStorageTotal(usage.packets, formatBytes(usage.bytes)),
            style: usage.hasQuota
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyMedium
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
                      message: '${device.snapshots > 0 ? l10n.syncStorageDeviceCountersSnapshots(device.snapshots, device.firstCounter, device.lastCounter) : l10n.syncStorageDeviceCounters(device.firstCounter, device.lastCounter)}'
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
                l10n.syncStorageBlobs(
                    usage.blobs, formatBytes(usage.blobBytes)),
                style: hint,
              ),
            ),
          if (_localUsage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.syncStorageLocal(
                    _localUsage!.packets, formatBytes(_localUsage!.bytes)),
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
              child: Text(l10n.commonRefresh),
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
                  : Text(l10n.syncCompactOnServer),
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
                  : Text(l10n.syncResetIdentity),
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
      setState(() => _usageError = context.l10n.syncNotConfiguredOnDevice);
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
      setState(() => _usageError = context.l10n.syncStorageReadFailed('$e'));
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
        _resetResult = context.l10n.syncNotConfiguredOnDevice;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.syncResetIdentity),
        content: Text(context.l10n.syncResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.syncReset),
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
        _resetResult = context.l10n.syncResetFailed('$e');
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
        _compactResult = context.l10n.syncNotConfiguredOnDevice;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.syncCompactOnServer),
        content: Text(context.l10n.syncCompactConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.syncCompact),
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
    final l10n = context.l10n;
    if (!result.success) return result.error ?? l10n.syncCompactFailed;
    if (result.snapshotCounter == 0) {
      return l10n.syncCompactNothing;
    }
    final String relay;
    if (result.relayPackets > 0) {
      relay = l10n.syncCompactRelayFreed(
          result.relayPackets, formatBytes(result.relayBytes));
    } else if (!result.relaySupported) {
      relay = l10n.syncCompactRelayUnsupported;
    } else {
      relay = l10n.syncCompactRelayNothing;
    }
    final snapshot = formatBytes(result.snapshotBytes);
    if (result.localPackets > 0) {
      return l10n.syncCompactSummary(
          relay,
          l10n.syncCompactLocalFreed(
              result.localPackets, formatBytes(result.localBytes)),
          snapshot);
    }
    return l10n.syncCompactSummaryNoLocal(relay, snapshot);
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
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final client = SyncApiClient(config: SyncConfig(serverUrl: _serverUrlController.text.trim(), deviceId: 'test'));
      final ok = await client.testConnection();
      if (!mounted) return;
      setState(() {
        _testOk = ok;
        _testResult = ok
            ? context.l10n.syncTestSuccess
            : context.l10n.syncTestUnreachable;
      });
      client.dispose();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testResult = context.l10n.syncErrorWith('$e');
      });
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _registerAccount() async {
    final username = _usernameController.text.trim();
    // Trimmed, as [_commit] stores it: registering with a trailing space the
    // login then drops would create an account this device cannot log into.
    final password = _serverPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _testOk = false;
        _testResult = context.l10n.syncRegisterNeedsCredentials;
      });
      return;
    }

    setState(() {
      _registering = true;
      _testResult = null;
    });

    final config = SyncConfig(
        enabled: true,
        serverUrl: _serverUrlController.text.trim(),
        username: username,
        password: password);
    final client = SyncApiClient(config: config);
    try {
      final quota = await client.register();
      // The fields are what the account was created with: keep them, so the
      // next sync logs in with exactly these rather than whatever focus-loss
      // has or has not committed yet.
      await _commit();
      if (!mounted) return;
      final l10n = context.l10n;
      setState(() {
        _testOk = true;
        _testResult = quota == null
            ? l10n.syncRegisterSuccess(username)
            : quota == 0
                ? l10n.syncRegisterSuccessUnlimited(username)
                : l10n.syncRegisterSuccessQuota(username, formatBytes(quota));
      });
      // Reading the usage logs in with the new account, so it confirms the
      // whole path works and shows the quota straight away.
      unawaited(_refreshUsage());
    } on RelayRegistrationException catch (e) {
      if (mounted) {
        setState(() {
          _testOk = false;
          _testResult = context.l10n.syncErrorWith(e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testOk = false;
          _testResult = context.l10n.syncErrorWith('$e');
        });
      }
    } finally {
      client.dispose();
      if (mounted) setState(() => _registering = false);
    }
  }
}
