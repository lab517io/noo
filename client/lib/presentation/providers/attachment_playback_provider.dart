import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import '../../data/services/attachment_media_server.dart';
import '../../domain/entities/attachment.dart';
import 'audio_device_provider.dart';
import 'providers.dart';

/// Loopback HTTP server handing attachment bytes to the audio player.
///
/// Started on first use and torn down when the database is swapped or the app
/// shuts down, so no port stays open for a database that is no longer loaded.
final attachmentMediaServerProvider =
    FutureProvider<AttachmentMediaServer?>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;

  final server = AttachmentMediaServer(db);
  ref.onDispose(server.stop);
  await server.start();
  return server;
});

/// What the one shared audio player is doing.
class AudioPlayback {
  /// Attachment currently loaded into the player, null when idle.
  final int? attachmentId;
  final bool playing;
  final Duration position;
  final Duration duration;

  /// Set when the last attempt to play failed — a missing attachment, or a
  /// codec the platform cannot decode.
  final String? error;

  const AudioPlayback({
    this.attachmentId,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  bool isCurrent(Attachment attachment) =>
      attachmentId != null && attachmentId == attachment.id;

  AudioPlayback copyWith({
    int? attachmentId,
    bool? playing,
    Duration? position,
    Duration? duration,
    String? error,
    bool clearError = false,
  }) {
    return AudioPlayback(
      attachmentId: attachmentId ?? this.attachmentId,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives playback of audio attachments.
///
/// One player for the whole app: starting a second attachment replaces the
/// first rather than layering over it, which is both what a listener expects
/// and what keeps a single position/duration model honest.
///
/// Two backends behind that one model. Voice memos play through `voice_audio`,
/// straight from the stored bytes: it has the decoder already, which spares
/// this app the loopback server, the WAV transcode, and the fact that Opus is
/// not a format Media Foundation can open on Windows. Everything else — mp3,
/// m4a, wav, video — still goes through `audioplayers` and the media server,
/// because those are formats the platform does know and this package does not.
class AudioPlaybackNotifier extends Notifier<AudioPlayback> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Set while a memo is loaded, so pause, seek and stop reach the right
  /// player. Two backends, one piece of state, and this is what tells them
  /// apart.
  bool _memoLoaded = false;
  StreamSubscription<Duration>? _memoPosition;

  /// Where a drag landed on a memo that had already played out, and which
  /// attachment it belonged to.
  ///
  /// There is nothing loaded to seek in at that point, so the position is
  /// remembered here and applied to the next [play] instead. Keyed by
  /// attachment so that dragging one memo and then starting another does not
  /// silently start the second one part way through.
  int? _resumeAttachmentId;
  Duration? _resumeFrom;

  @override
  AudioPlayback build() {
    ref.onDispose(_disposePlayer);
    return const AudioPlayback();
  }

  /// Whether this is a recording `voice_audio` can play from its bytes.
  ///
  /// The extension is the only signal an attachment row carries; a `.opus` this
  /// package cannot parse falls back to the media server rather than failing,
  /// which is what a Vorbis-in-`.ogg` file needs.
  static bool _looksLikeMemo(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0) return false;
    final extension = filename.substring(dot + 1).toLowerCase();
    return extension == 'opus' || extension == 'ogg' || extension == 'oga';
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;

    final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    // Every one of these is a listener on the same broadcast event stream, and
    // a platform failure — a codec the host cannot decode, a GStreamer element
    // that failed to start — arrives as an error on it rather than as a thrown
    // exception from play(). A listener without an onError turns that into an
    // unhandled async exception, so all of them carry one.
    _subscriptions.addAll([
      player.onPositionChanged.listen((position) {
        if (state.attachmentId != null) {
          state = state.copyWith(position: position);
        }
      }, onError: _handlePlayerError),
      player.onDurationChanged.listen((duration) {
        if (state.attachmentId != null) {
          state = state.copyWith(duration: duration);
        }
      }, onError: _handlePlayerError),
      player.onPlayerStateChanged.listen((playerState) {
        if (state.attachmentId == null) return;
        state = state.copyWith(playing: playerState == PlayerState.playing);
      }, onError: _handlePlayerError),
      player.onPlayerComplete.listen((_) {
        state = state.copyWith(playing: false, position: Duration.zero);
      }, onError: _handlePlayerError),
    ]);

    _player = player;
    return player;
  }

  /// Report a playback failure raised after play() returned.
  void _handlePlayerError(Object error, StackTrace stackTrace) {
    debugPrint('Audio playback failed: $error');
    if (state.attachmentId == null) return;
    state = state.copyWith(playing: false, error: 'Cannot play this file');
  }

  void _disposePlayer() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _player?.dispose();
    _player = null;
    _memoPosition?.cancel();
    _memoPosition = null;
  }

  /// Play [attachment], pause it if it is already playing, resume it if it is
  /// loaded and paused.
  Future<void> toggle(Attachment attachment) async {
    final id = attachment.id;
    if (id == null) return;

    // Already loaded: this is a pause or a resume, on whichever backend has it.
    //
    // Except when a memo has played to the end. `voice_audio` is then idle, not
    // paused — there is nothing to resume, and a tap means "play it again". So
    // that case falls through to the start path below rather than being handled
    // here. `audioplayers` restarts by itself on resume-after-complete, which is
    // why the same question does not arise for the other formats.
    final memoFinished =
        _memoLoaded && va.VoiceAudio.instance.player.state == va.PlayerState.idle;

    if (state.attachmentId == id && !memoFinished) {
      if (_memoLoaded) {
        final memoPlayer = va.VoiceAudio.instance.player;
        if (state.playing) {
          await memoPlayer.pause();
        } else {
          await memoPlayer.resume();
        }
        // audioplayers reports its own state through a stream; this one does
        // not, so the flag is set here.
        state = state.copyWith(playing: !state.playing);
      } else {
        final player = _ensurePlayer();
        if (state.playing) {
          await player.pause();
        } else {
          await player.resume();
        }
      }
      return;
    }

    // Whichever backend was last used, it is not playing this.
    await _quiet();

    if (_looksLikeMemo(attachment.filename) && await _playMemo(attachment)) {
      return;
    }

    final server = await ref.read(attachmentMediaServerProvider.future);
    final url = server?.urlFor(attachment.worldId.value, attachment.filename);
    if (url == null) {
      state = state.copyWith(
        attachmentId: id,
        playing: false,
        error: 'Playback is unavailable',
      );
      return;
    }

    state = AudioPlayback(attachmentId: id, playing: true);

    try {
      await _ensurePlayer().play(UrlSource(url.toString()));
    } catch (e) {
      state = state.copyWith(playing: false, error: 'Cannot play this file');
    }
  }

  /// Play a stored recording through `voice_audio`.
  ///
  /// False when it is not one after all — a `.ogg` holding Vorbis, a truncated
  /// blob, a machine where the native library will not load — in which case the
  /// caller falls back to the media server, exactly as before.
  Future<bool> _playMemo(Attachment attachment) async {
    final id = attachment.id;
    final repo = ref.read(attachmentRepositoryProvider);
    if (id == null || repo == null) return false;

    try {
      final loaded = await repo.loadAttachmentContent(attachment);
      final bytes = loaded.content;
      if (bytes == null || bytes.isEmpty) return false;

      final memo = va.VoiceMemo.tryParseOgg(bytes);
      if (memo == null) return false;

      final audio = va.VoiceAudio.instance;
      await audio.initialize();
      // The speaker chosen in Preferences, resolved from its name against a
      // current enumeration; null when none is chosen or the device has gone,
      // which is the package's own word for the system default. It reaches
      // memos only — the other formats play through `audioplayers`, which has
      // no device selection to offer.
      await audio.player.play(memo, speaker: await selectedSpeaker(ref));

      // A drag on the finished memo, picked up here rather than at the time —
      // see [seek]. Discarded when it no longer points inside the recording.
      Duration start = Duration.zero;
      if (_resumeAttachmentId == id &&
          _resumeFrom != null &&
          _resumeFrom! > Duration.zero &&
          _resumeFrom! < memo.duration) {
        start = _resumeFrom!;
        await audio.player.seek(start);
      }
      _resumeAttachmentId = null;
      _resumeFrom = null;

      _memoLoaded = true;
      state = AudioPlayback(
        attachmentId: id,
        playing: true,
        position: start,
        duration: memo.duration,
      );

      // A timer over a cheap native read, not a callback out of the audio
      // thread. It closes by itself when playback stops.
      _memoPosition = audio.player.positionUpdates().listen(
        (position) {
          if (_memoLoaded && state.attachmentId == id) {
            state = state.copyWith(position: position);
          }
        },
        onDone: () {
          if (_memoLoaded && state.attachmentId == id) {
            state = state.copyWith(playing: false, position: Duration.zero);
          }
        },
        onError: _handlePlayerError,
      );

      return true;
    } on Object catch (error, stack) {
      debugPrint('Memo playback failed, falling back: $error\n$stack');
      _memoLoaded = false;
      return false;
    }
  }

  Future<void> seek(Duration position) async {
    final id = state.attachmentId;
    if (id == null) return;
    state = state.copyWith(position: position);

    if (!_memoLoaded) {
      await _player?.seek(position);
      return;
    }

    final player = va.VoiceAudio.instance.player;
    if (player.state == va.PlayerState.idle) {
      // The memo has played out, so there is nothing loaded to seek in. The
      // native player would take it anyway — a seek away from the end makes a
      // recording playable again — but it would start playing behind this
      // notifier's back: the position stream has closed, and `voice_audio`
      // refuses pause and resume on a recording it considers finished, so the
      // controls would be dead until it ran out a second time.
      //
      // So the drag is remembered and the next press starts there instead,
      // which is also what `audioplayers` does for the other formats.
      _resumeAttachmentId = id;
      _resumeFrom = position;
      return;
    }

    await player.seek(position);
  }

  /// Release the audio device and forget the current attachment — used when
  /// the attachment being played is deleted or the panel closes.
  Future<void> stop() async {
    await _quiet();
    _resumeAttachmentId = null;
    _resumeFrom = null;
    state = const AudioPlayback();
  }

  /// Silence whichever backend is loaded, without touching the state.
  Future<void> _quiet() async {
    if (_memoLoaded) {
      _memoLoaded = false;
      await _memoPosition?.cancel();
      _memoPosition = null;
      try {
        await va.VoiceAudio.instance.player.stop();
      } on Object {
        // Stopping something that already stopped is not a failure.
      }
    }
    await _player?.stop();
  }

  /// Stop only if [attachmentId] is the one loaded.
  Future<void> stopIfPlaying(int? attachmentId) async {
    if (attachmentId != null && state.attachmentId == attachmentId) {
      await stop();
    }
  }
}

final audioPlaybackProvider =
    NotifierProvider<AudioPlaybackNotifier, AudioPlayback>(
  AudioPlaybackNotifier.new,
);
