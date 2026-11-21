# Voice Memos with On-Device Transcription

Plan for recording voice memos into a task and appending their transcript to the
task's content. Audio is stored as an Opus attachment; the text lands in the
rich-text body where the rest of the note lives.

Status: **implemented — all five phases**, then rebuilt on `voice_audio`.
Every claim marked "verified" below was measured on Linux x64 with Flutter
3.44.2 against the exact package versions named; the numbers are reproducible
with the probe described in
[Appendix A](#appendix-a--how-the-numbers-were-produced).

> **What changed, and why.** Capture, the Opus codec and the Ogg container were
> three packages and about 1700 lines of our own Dart. They are now one FFI
> plugin, `voice_audio`, which does all of it natively and builds libopus and
> libogg from source. Two things forced it. `opus_codec_linux` ships **zero-byte
> blobs** — §12.1 — so on Linux the feature quietly depended on a system
> `libopus.so.0` and reported itself unavailable without one; and every release
> carried 4.3 MB of Windows binaries it could never use (§12.2). Both are gone.
>
> The one behavioural change is **transcription now runs after the memo is
> stored**, not alongside the microphone. That removed the live PCM tee, and
> with it the partial transcript in the recording bar. What it buys: a memo is
> safe on disk before whisper is asked for anything, so a model that fails to
> load, takes too long, or falls over costs the text and never the audio — and a
> transcript can be asked for again later from the attachment row, which is
> something the live path could never offer.
>
> The stored format did not change. It is the same RFC 7845 Ogg Opus at the same
> settings, so memos recorded by earlier versions — including ones already synced
> to other devices — play and transcribe unchanged.

---

## 1. Decisions

| Question | Decision |
|---|---|
| Capture | `voice_audio` (FFI plugin), 16 kHz mono, encoded natively — no PCM in Dart |
| Storage format | **Ogg Opus**, 24 kbit/s VBR, voice-tuned |
| Opus codec | libopus **built from source** and linked statically by `voice_audio` |
| Ogg container | `voice_audio`, via libogg |
| Transcription | `whisper_ggml` 2.6.0, via `startWhisperLiveSession` (**not** `transcribe`) |
| When transcription runs | **after** the memo is stored, from the stored bytes |
| Transcript destination | inserted into the task's Quill document at the caret |
| Temp files | **none** — the whole pipeline is in memory |
| External binaries | **none** — no ffmpeg, no opus-tools, no SDL2 |
| Microphone permission | `permission_handler`, Android only |

The two rejected shapes, and why, are in [§8](#8-rejected-alternatives).

---

## 2. Why the pipeline looks like this

Three project constraints drive the entire design:

1. **Nothing decrypted touches disk.** `AGENTS.md` and
   `data/services/attachment_media_server.dart` both state that a temp file
   would be the one place the app writes decrypted content outside an explicit
   export. That rules out every "record to file, then read it back" flow.
2. **No hidden external binary.** A dependency the user must install separately
   fails silently on their machine, not ours.
3. **Attachments sync as base64 inside change packets**
   (`sync_change_packager.dart:140`). Audio size is bandwidth, not just disk.

Opus at 16 kHz mono is also exactly what whisper wants as input, so nothing in
the chain ever resamples.

### The ffmpeg trap (verified)

`whisper_ggml`'s file API converts non-WAV input through **system** ffmpeg on
Windows and Linux. With a failing `ffmpeg` stub on `PATH`:

| Input | ffmpeg present | ffmpeg missing |
|---|---|---|
| 16 kHz mono WAV | ✅ transcribed | ✅ transcribed |
| 44.1 kHz stereo WAV | ✅ transcribed | ❌ **returns `null`** |
| Ogg Opus / m4a | ✅ transcribed | ❌ **returns `null`** |

It returns `null` — no exception, no message. Shipping that as a hidden
requirement would produce unreproducible "transcription does nothing" reports.

`transcribe(audioPath:)` also writes its converted copy next to the input as
`<name>.wav`, i.e. a second decrypted file we did not ask for.

Both problems vanish by never using the file API: `startWhisperLiveSession`
takes a model path and raw PCM fed through `session.feed(Uint8List)`, so we
control the audio end to end and no decoder but ours is involved.

---

## 3. Data flow

### Recording

```
microphone ──► voice_audio ──► Ogg Opus bytes ──► createAttachment(".opus")
               (native: capture, 20 ms frames,
                encode, Ogg paging)                        │
                                                           ▼
                                            whisper_ggml, from the stored bytes
                                            (optional; off ⇒ stored untranscribed)
```

**PCM never reaches Dart while recording.** One blob crosses the FFI boundary
per recording, which is why there is no audio deadline on the UI isolate to
miss: the recording is safe in native memory whether or not Dart is keeping up.
What Dart polls on a timer is the elapsed time and the level, and neither is on
a deadline.

Transcription starts only once `createAttachment` has returned. The memo is a
row in the database before whisper is asked for anything, so anything that goes
wrong from there costs the text and never the audio.

Nothing is written to disk at any point. The transcript is inserted into the
open Quill document; the attachment lands in the `file` table like any other.

### Playback and re-transcription

```
file table BLOB ──► voice_audio ──► speaker            (VoiceMemo.play)
                              └───► PCM16 ──► whisper  (VoiceMemo.decodeToPcm)
```

Playback reads the stored bytes directly. It does **not** go through
`AttachmentMediaServer` — that still serves mp3, m4a, wav and video, but a memo
never touches it, which is what retired the Opus→WAV transcode described in §7.

Re-transcribing a memo recorded on another device needs no microphone, no temp
file and no ffmpeg — it decodes the stored packets natively.

---

## 4. Verified measurements

Source clip: 6.34 s of speech, 16 kHz mono.

| Step | Result |
|---|---|
| WAV (what a PCM-tee design would store) | 202,874 B |
| **Ogg Opus, 24 kbit/s target, VBR, `OPUS_SIGNAL_VOICE`** | **17,318 B** |
| Compression | **11.7×** |
| Measured rate | 21.94 kbit/s, container overhead 2.68% |
| Encode (316 frames) | 75 ms |
| Decode back to PCM | 7 ms |
| Transcription, `tiny`, one-shot | 463 ms |
| Transcription, `tiny`, live session incl. model load | 1.59 s, 4 partials |
| Round-trip transcript | byte-identical to the WAV transcript |

Container validated by third parties: `opusinfo` reports a clean stream
(pre-skip 312, original sample rate 16000 Hz, 20 ms packets, no page or CRC
warnings), `ffprobe` reads it as `Audio: opus, 48000 Hz, mono`, and GStreamer —
the backend `audioplayers` uses on Linux — decodes it through `decodebin`
without complaint.

### Storage and sync cost

| | per minute | 5-minute memo |
|---|---|---|
| Stored in `file` table | ~165 KB | ~825 KB |
| On the wire (base64 in a sync packet) | ~220 KB | ~1.1 MB |

For comparison, the WAV that a no-encoder design would store is 1.92 MB/min,
2.56 MB/min after base64 — a 5-minute memo would be a 13 MB sync change.

### Model download (verified sizes)

| Model | Size | Notes |
|---|---|---|
| `tiny` | 77,691,713 B | transcribed the test clip perfectly, but it was clean synthetic speech |
| `base` | 147,951,465 B | recommended default for real dictation |
| `small` | 487,601,967 B | best quality that still fits a desktop app |

Fetched from HuggingFace into the app-support dir (`~/.local/share/<app-id>` on
Linux) on first use. It is the only network access this feature needs, and it
must be **explicitly user-initiated in Preferences** — an app that is otherwise
offline and zero-knowledge should not quietly pull 148 MB.

---

## 5. Components to build

```
client/lib/
├── data/services/audio/
│   ├── voice_memo_recorder.dart         # VoiceMemoEngine + the clock, meter, cap, filename
│   └── whisper_service.dart             # model dir, download, session, releaseModel
├── presentation/providers/
│   ├── voice_memo_provider.dart         # idle / recording / saving / transcribing
│   └── attachment_playback_provider.dart # dispatches .opus to voice_audio, the rest to audioplayers
└── presentation/widgets/task_editor/
    ├── voice_memo_ops.dart              # mirrors attachment_image_ops.dart
    └── voice_memo_bar.dart              # elapsed time, level meter, stop / cancel
```

`core/utils/ogg_opus.dart`, `opus_runtime.dart`, `opus_encoder.dart` and
`opus_decoder.dart` are gone — about 1700 lines, plus 1300 lines of their tests.
Everything they did is in `voice_audio`, covered there by C++ suites that put a
real 440 Hz signal through the codec and check pitch, level, seek accuracy and
the waveform. The sections below describing them are kept as a record of what
the problems were, because every one of them still exists — it is just solved on
the other side of the FFI boundary now, and the notes explain what to look for
if it resurfaces.

### The seam that keeps ng's tests honest

`VoiceMemoEngine` (in `voice_memo_recorder.dart`) is what `VoiceMemoAudioSource`
used to be, one level up: the unit is a whole recording rather than a stream of
chunks, because that is now the smallest thing that crosses the boundary. Tests
inject a fake that returns `test/fixtures/memo-1s.opus` — a real Ogg Opus file,
so the bytes that reach the attachment row are bytes a decoder would accept — and
drive the elapsed clock by hand.

The suite no longer needs a system libopus, and no longer skips itself when
there is none. What it cannot cover is whether the audio *sounds* right; that is
what `tool/voice_memo_capture_probe.dart` is for, and it should be run against a
real microphone after any change to `voice_audio`.

### `ogg_opus.dart` — the only non-obvious piece

A prototype of this file is written and validated (Appendix A). What an
implementation must get right:

- **Page header** — `OggS`, version 0, header type (2 = BOS, 4 = EOS),
  granule position (int64 LE), serial (u32 LE), page sequence (u32 LE),
  CRC32 (u32 LE), segment count, lacing table. CRC is Ogg's own variant:
  polynomial `0x04c11db7`, **not** reflected, init 0, no final XOR, computed
  over the whole page with the CRC field zeroed.
- **Lacing** — each packet becomes ⌊len/255⌋ values of 255 followed by
  `len % 255`; a packet whose length is a multiple of 255 still needs the
  trailing 0. At most 255 lacing values per page.
- **Header packets** — page 0 carries `OpusHead` (version 1, channel count,
  pre-skip 312, *original* sample rate 16000, gain 0, mapping family 0) with
  the BOS flag; page 1 carries `OpusTags`.
- **Granule positions are always in 48 kHz units**, whatever the input rate.
  A 20 ms frame at 16 kHz advances the granule by 960, not 320.
- **The granule counts decoder output from zero and is *not* offset by the
  pre-skip** — an earlier draft of this plan said it was, and the
  implementation that followed it clipped 6.5 ms off the end of every memo.
  Playable length is `finalGranule - preSkip`: the lookahead is subtracted at
  playback, not added at write time. Offsetting the pages instead makes
  `libopusfile` read a non-zero stream start and then discard the pre-skip
  twice. `opusenc` on a 3.17 s clip writes 48000 / 96000 / 144000 / 152472,
  never 48312.
- **The final granule is also how end trimming is expressed.** Opus encodes
  whole frames, so capture that stops mid-frame is padded out; setting the
  last page's granule to `preSkip + capturedSamples` tells the decoder to drop
  the padding. Skipping this leaves every memo up to 20 ms long.
- **The last page must carry the EOS flag**, or decoders report a truncated
  stream.

It is pure computation over `Uint8List` with no Flutter or FFI dependency, so
it unit-tests directly under `client/test/core/ogg_opus_test.dart`.

### The libopus bindings — why they are ours

`opus_codec` ships the libopus **binary** per platform. Its companion binding
package, `opus_codec_dart`, is not used, for two reasons found while wiring it
up:

- `opus_encoder_ctl` is a C **variadic** function. The package declares it as
  `Int Function(Pointer, Int, Int)`. That makes the CTL *get*-requests
  inexpressible — they take a pointer to write through — so
  `OPUS_GET_LOOKAHEAD` is unreachable, and the lookahead is precisely the value
  the Ogg pre-skip must equal.
- Calling a variadic function through a non-variadic signature is also wrong on
  Apple arm64, where variadic arguments go on the stack rather than in
  registers. It happens to work on x86-64 and on Linux arm64.

`dart:ffi`'s `VarArgs` states the convention correctly on every ABI, so
`opus_runtime.dart` binds the nine symbols we need directly — about thirty
lines, smaller and more correct than the dependency it replaces. **The pre-skip
is now read from the encoder rather than assumed**: `OPUS_GET_LOOKAHEAD`
returns 104 samples at 16 kHz, which is the 312 this document quotes.

### `opus_encoder.dart` — the two paddings

The encoder owns the frame buffering, rather than the recorder as sketched
below: `record` delivers arbitrary chunk sizes — including splits that land
mid-sample — and the frame size belongs next to the encoder that defines it.
Feed it bytes with `addPcm`, take out whole packets.

Stopping a recording needs two kinds of padding, and getting either wrong
truncates the memo:

- A tail shorter than one frame is zero-padded, because Opus has no partial
  frames.
- **libopus holds `lookaheadSamples` of audio internally.** Stopping at the last
  real sample leaves 6.5 ms of the recording stranded inside the encoder, so
  `flush()` keeps feeding silence until the encoded length covers the input
  plus the lookahead. This is what `opusenc` does, and it is why a 3.17 s clip
  comes out as 159 frames (50 880 samples) rather than 158.

Both paddings are real encoded audio. `playbackSamples` reports the unpadded
length, and `OggOpusWriter.finish(playbackSamples:)` trims it back off, so a
decoder returns exactly the samples that were captured — verified against
`opusdec`, not just our own decoder.

### `voice_memo_recorder.dart`

Owns one `AudioRecorder`, subscribes to `startStream`, and fans each chunk out
to the encoder and (when enabled) the live session. The frame buffering lives
in the encoder rather than here — see above — so this stays plumbing. On stop
it returns the Ogg bytes, the captured length and a filename; on cancel it
discards everything and destroys the encoder.

Two things this had to get right that are not obvious:

- **Elapsed time comes from the samples, not the wall clock.** They drift, and
  the samples are what gets stored. A 4 s real-microphone run captures 3.900 s,
  the difference being how long the device takes to open.
- **The length cap must be noticed before the last progress tick goes out**,
  not after. A single chunk long enough to cross the cap would otherwise detach
  the recorder from the microphone with nobody left to tell — the caller learns
  to stop from a tick. The cap notice then survives the automatic save, so the
  bar can explain why a recording ended on its own instead of just vanishing.

Recording state belongs in a provider, not the widget: a memo must survive the
attachments panel collapsing, and only one recording may run at a time
(`whisper_ggml` allows one live session per process anyway).

> Widget tests that record have two traps, both documented in
> `voice_memo_bar_test.dart`. Tearing a recording down cancels a stream
> subscription, and that future only completes when the microtask queue is
> pumped — awaiting it from the test body blocks the code that would pump, and
> the deadlock has no timeout to break it because the timeout is a fake timer
> nobody advances either; drive it through `tester.runAsync`. And the recording
> dot blinks on a repeating animation, so `pumpAndSettle` never returns while
> the bar is on screen.

### `whisper_service.dart`

Wraps model lifecycle: resolve path, report whether the selected model is
present, download with progress, hand out `startWhisperLiveSession`, and call
`releaseModel` when the provider is disposed. `keepModelLoaded: true` between
memos in a sitting so the second memo skips the multi-second load.

**The download is ours, not the package's.** `WhisperController.downloadModel`
buffers the whole file in memory — 148 MB for `base` — reports no progress, and
writes straight to the final path, so an interrupted fetch leaves a truncated
file that `isPresent` happily calls a model and whisper then fails to load with
no hint why. This one streams to `<model>.part` and renames on completion,
reports bytes as they arrive, verifies the length against `Content-Length`, and
can be cancelled.

### UI entry point

`QuillEditorWrapper` already has a `customButtons` list holding the "Insert
image" button, with `_controller` and `taskId` in scope
(`quill_editor_wrapper.dart:437-445`). A microphone button belongs beside it,
following the `attachment_image_ops.dart` pattern exactly: the op function takes
`(WidgetRef ref, QuillController controller, int taskId)`, stores the
attachment, and inserts into the document.

---

## 6. Transcript → task content

Insert at the caret through the live `QuillController`, exactly as image embeds
are inserted today. No schema change, no sync-protocol change, and the text is
immediately searchable by the existing full-text search and exportable to
Obsidian.

**Resolved:** no prefix, no link — the transcript goes in as a plain
paragraph, as the paragraph below argued it should. A `🎤 memo <date> —` prefix
would be noise in every note that has one, it reads as a machine annotation
rather than as the user's own words, and it would have to be stripped by hand
before the text was useful. The memo is already listed in the attachments panel
with its timestamp in the filename, which is where a reader looks for the
audio.

Rules:

- Insert **after** the attachment row is created, so a failed store never
  leaves an orphan line.
- If transcription is off, unavailable, or returns empty, insert nothing — the
  memo is still attached, and "Transcribe" stays available from the row menu.
- Empty transcripts are common with the energy gate on silence; treat them as
  success, not error.
- Insertion goes through the controller only when the editor still shows the
  same task; if the user has navigated away, skip the insert rather than
  writing into the wrong note.

Re-running "Transcribe" later inserts at the caret of the then-open task by the
same path.

---

## 7. Playback: the Windows question

`Attachment.isAudio` already accepts `opus`/`ogg`, and `AttachmentMediaServer`
already streams attachment bytes over loopback with range support — so on paper
playback needs no work.

**But** `audioplayers` on Windows is Media Foundation
(`audioplayers_windows/windows/MediaEngineWrapper.cpp`), and Ogg Opus is not a
built-in Media Foundation format: it depends on Microsoft's *Web Media
Extensions*, which is preinstalled on most consumer Windows 10/11 images but
absent from N editions and Server, and removable. Linux is fine (verified:
GStreamer decodes our file), macOS and Android are fine.

The original mitigation was to **have `AttachmentMediaServer` decode `.opus` to
WAV in memory** and serve that, reusing the decoder re-transcription already
needed. It worked, and it is gone.

**Memos no longer go near a platform codec at all.** `voice_audio` plays them
from their bytes with its own decoder, so the question this section asks does
not arise: there is nothing for Media Foundation to fail to open. The transcode,
its one-entry cache, its two size caps and its 321-line test have all been
removed, and `attachment_playback_provider.dart` simply routes `.opus` to
`voice_audio` and everything else to `audioplayers` as before.

The section is kept because the reasoning still applies to every *other* audio
format the app accepts. mp3, m4a and wav are still the platform's business, and
a format the host cannot decode still fails the same quiet way.

### The Linux packaging half of the same question

Decoding to WAV settles the *codec*; the AppImage still has to be able to
*fetch* the bytes. `audioplayers_linux` hands the URL to a GStreamer `playbin`,
and the AppImage points GStreamer at its own bundled plugin directory only, so
whatever is not bundled does not exist. The first release with memos bundled
every decoder but no HTTP source, and playback failed at the very first step:

```
PlatformException(LinuxAudioError, ...,
  No URI handler implemented for "http". (gst-core-error-quark, Code: 12))
```

Fixed by bundling `libgstsoup.so` (`scripts/build_linux.py`, `GST_PLUGINS`).
The catch worth remembering: since 1.20 that plugin **`dlopen`s** its libsoup
(3.0 first, 2.4 as fallback) instead of linking it, so `ldd` does not name it
and the dependency walk cannot find it — `GST_PLUGIN_DLOPEN_LIBS` bundles it
explicitly. Without libsoup the plugin loads and registers nothing, which looks
exactly like not bundling it at all.

The Dart side was equally at fault: a platform failure arrives as an *error on
the player's event stream*, not as an exception out of `play()`, so the
`try`/`catch` around `play()` never saw it and it escaped as an unhandled async
exception. Every listener in `AudioPlaybackNotifier` now carries an `onError`
that puts the player back into a failed-but-idle state.

### ...and the desktop proxy behind it

With souphttpsrc in place the request is made — and then, on a machine with a
proxy configured, sent to the proxy. `souphttpsrc` resolves the proxy for its
URL through GIO, and GIO on Ubuntu resolves through **libproxy**, which returns
the configured proxy *even for `127.0.0.1`*, whatever the desktop's "ignore
hosts" list says. Measured on the dev machine (GNOME proxy `127.0.0.1:2080`,
ignore-hosts `['localhost', '127.0.0.0/8', '::1']`):

```
GLibproxyResolver  lookup('http://127.0.0.1:8933/tone.wav') -> ['http://127.0.0.1:2080']
```

The proxy has no idea what to do with a port on the user's own machine, so
playback fails a second time, now with `Bad Gateway`. This one is not specific
to the AppImage — a `flutter run` build on the same machine fails identically.

`bypassProxyForLocalPlayback()` (`lib/platform/playback_proxy.dart`, called
first thing in `main`) sets `GIO_USE_PROXY_RESOLVER=dummy` through an FFI
`setenv`, selecting GLib's no-op resolver, which answers `direct://`. Nothing in
this app reaches the network through GIO — the model download is a Dart
`HttpClient`, which keeps its own cached copy of the environment and never
consults GIO — so the only request this redirects is the loopback one that must
not be proxied anyway. An explicit `GIO_USE_PROXY_RESOLVER` in the environment
is left alone.

Verified against the bundled plugin set with a `playbin` over loopback HTTP:
default resolver → `ERROR ... Bad Gateway`; `GIO_USE_PROXY_RESOLVER=dummy` →
`Got EOS from element "playbin0"`.

---

## 8. Rejected alternatives

**Record straight to an Opus file with `record`, then transcribe that file.**
Needs a temp file (breaks the disk invariant), and transcription then needs
system ffmpeg on Windows and Linux to decode Opus for whisper — the silent-null
trap above. Also loses the ability to transcribe while recording.

**Store WAV, compress to Opus afterwards with ffmpeg.** Same hidden binary, plus
`record`'s Linux *file* path already shells out to ffmpeg (its *stream* path
needs only `parecord`, which is why the streaming design is also the one with
fewer external processes).

**`ogg_opus_player` for record + play.** Bundles a recorder and player for all
five platforms, but requires user-installed SDL2 and libopus-dev on Linux, and
gives no access to PCM for transcription.

**Whisper's `transcribe(audioPath:)` anywhere in the flow.** Rejected for the
temp file, the ffmpeg dependency, and the stray `<name>.wav` sibling it writes.

---

## 9. Platform work

| Platform | Needed |
|---|---|
| Linux | **done and verified.** A C++ toolchain is needed at build time (the plugin builds libopus, libogg, PortAudio and the WebRTC audio processing module from source). **No runtime dependency at all**: `libvoice_audio.so` is 2.3 MB stripped and needs only ALSA and the C/C++ runtime, all of which `HOST_LIB_PREFIXES` already takes from the host — so `scripts/build_linux.py` has nothing new to bundle. `parecord` is no longer involved: capture goes through PortAudio, which enumerates 21 devices here including `pulse` and `default` |
| Windows | **built, no automated coverage.** `voice_audio` 0.3.1 is confirmed built from these sources on a Windows host, but nothing there runs its tests. whisper.cpp builds still require **AVX2** |
| Android | `RECORD_AUDIO` is in `AndroidManifest.xml` and `permission_handler` asks for it at runtime; a refusal is reported in the bar. **minSdk is now 28**, up from 24, because the AAudio backend needs API 28 — see `android/app/build.gradle.kts`. `voice_audio` is 1.8 MB stripped per ABI with both codecs static; the APK also carries whisper and `ffmpeg_kit_flutter_new_min` per ABI, which `whisper_ggml` pulls in transitively even though we never use it. Built and linked for arm64, **not run on a device** |
| macOS | `com.apple.security.device.audio-input` is in both entitlements files and `NSMicrophoneUsageDescription` is in `Info.plist`, and macOS prompts by itself on first use, so `permission_handler` is not needed there. **`voice_audio` does not declare macOS** as of 0.3.1 — the backend sources are still in its tree (`src/audio/ios/`, `macos/`) but have never been through an Apple toolchain, so the plugin is absent from a macOS build and voice memos cannot work there |

Dependency resolution was re-checked after the swap: **win32 stays at 5.15.0**,
and none of the pins documented in `pubspec.yaml` (file_picker 11 / win32 5.9,
riverpod, analyzer) are disturbed. The Linux debug build was built and run, and
`tool/voice_memo_capture_probe.dart` records, plays, seeks and exports a memo
that `opusinfo`, `opusdec` and `ffprobe` all accept.

---

## 10. Preferences

The "Voice memos" tab, in three group boxes.

**Devices.**

- **Microphone** / **Speaker** — the system default, or a named device.
  Stored **by name**, not by index. `voice_audio` says plainly that a device's
  index is its only identifier and that an index outlives nothing: plug in a
  headset and index 3 is a different device. So the name is resolved against a
  fresh enumeration at the moment of use (`selectedMicrophone`,
  `selectedSpeaker`), and a name that no longer matches resolves to null —
  which is the package's own word for the platform default. A stored device
  that is not currently present keeps its own entry in the combo box, marked
  *(not connected)*: quietly showing "System default" while the preference on
  disk said otherwise would be worse than saying so.
- The speaker reaches **voice memos only**. Those play through `voice_audio`,
  which takes a device; every other audio attachment goes through
  `audioplayers` and the loopback media server, which does not. The hint under
  the control says this, because the difference is otherwise inexplicable.
- **Refresh** re-scans. Hot-plug is reported on Windows and nowhere else
  (`VoiceAudio.deviceListChanges`), so this is the only way a headset plugged
  in after the dialog opened shows up.

**Transcription.**

- **Model** — none / tiny / base / small, with size and a Download button that
  shows progress. Nothing downloads implicitly.
- **Transcribe after recording** — on by default once a model exists. It used to
  say "while recording"; transcription now runs once the memo is stored.
- **Language** — default `en`, plus ten languages and **Detect automatically**
  (`auto`). The string goes straight into `whisper_full_params.language`, and
  whisper.cpp treats `auto` as "detect" (`whisper.cpp:6833`). Note the live
  path re-decodes a sliding window, so detection is re-run per window rather
  than fixed once for the memo; naming the language is still faster and more
  accurate when it is known.
- **Bitrate** — probably not worth a control; 24 kbit/s voice is already the
  right answer. Revisit only if music-quality memos are ever wanted.

**Check.** One **Test** button that runs the whole chain — record (capped at
15 s, with the level meter and a Stop button), play back through the chosen
speaker, transcribe with the chosen model and language — and shows the text.

The chain is the point. A muted microphone, a silent speaker, a model that was
never downloaded and a language set wrong all present identically from the
editor: a memo with no text under it. Running the three in order and naming the
stage that stopped is the only way to tell them apart, and it takes about
fifteen seconds instead of recording a real note and guessing. So:

- Everything **after capture reports rather than fails**. "No model is
  selected", "Base has not been downloaded" and "whisper found no speech" are
  all outcomes of a run whose recording and playback *worked*, and saying so is
  more useful than a red line.
- The **peak level** is kept, because a device that opened but captured nothing
  reports zero — and on the platforms that answer a refused microphone
  permission with silence rather than an error, that is the only signal there
  is. A silent clip with no transcript blames the microphone; an audible one
  blames whisper.
- It **refuses while a memo is being recorded** (`voiceMemoProvider.isBusy`).
  One microphone; a test that stole it would cost the user their note.
- Nothing is saved. The clip is held in memory, played, and dropped — it never
  becomes an attachment and never reaches the database.

> Per `AGENTS.md`: every user-facing preference must also be written back in
> `SettingsNotifier.restorePreferences` (`settings_provider.dart:504`), or
> Cancel rolls it back in memory while leaving it written on disk.

---

## 11. Phases

**Phase 1 — container** — **done.** `client/lib/core/utils/ogg_opus.dart` plus
`client/test/core/ogg_opus_test.dart` (46 tests) and
`client/tool/ogg_roundtrip_probe.dart`, a dev-time harness that round-trips a
real encoder's file through the reader and writer. Pure Dart, no plugins, no
new dependencies. Tests cover the CRC vector, TOC packet-duration arithmetic,
lacing edge cases (1, 254, 255, 256, 510, 511, 65024 bytes and a packet too
large for one page), granule arithmetic including end trimming, mux→demux
round trip, malformed-input rejection, and a golden byte comparison — the
fixture being a file muxed by libavformat, read back with the exact fields
`opusinfo` reports for it.

Verified out of band on Linux against `opusenc`, `ffmpeg`, `opusinfo`,
`ffprobe`, `gst-launch-1.0` and `opusdec`: demuxing and re-muxing 16 kHz mono,
48 kHz stereo, 60 ms-framesize and 3-packet files all yield streams whose
`opusdec` PCM output is **byte-identical** to the original's, with container
overhead down from 7.84% to 2.7% (the plan predicted 2.68%).

**Phase 2 — codec** — **done.** `opus_runtime.dart` (library loading and the
native bindings), `opus_encoder.dart`, `opus_decoder.dart`, plus
`client/test/data/audio/opus_codec_test.dart` (29 tests) and
`client/tool/voice_memo_probe.dart` / `client/tool/opus_load_probe.dart`.

The tests run under plain `flutter test` — no integration-test harness needed.
They load the *system* libopus directly and skip with a clear reason where
there is none. `opus_load_probe.dart` covers the one path they cannot reach —
`OpusRuntime.ensureLoaded` with its real default loader, which needs the plugin
registrant and the asset bundle — by building it as an alternative entrypoint
and running it headless under `xvfb-run`. It reports `ensureLoaded=true`,
`libopus 1.4`, pre-skip 312, and a half-second buffer that survives the round
trip sample-for-sample. (`flutter run` is not usable for this: it does not exit
when the app does, so build the entrypoint and run the binary.)

Measured on the 3.17 s / 16 kHz mono clip: 9134 bytes, 23.05 kbit/s (22.14
excluding container overhead, against the 21.94 predicted above), encode 34 ms,
decode 7 ms. `opusinfo` reports the stream clean with pre-skip 312 and a
playback length of 3.169 s — the same figures `opusenc` produces from the same
source — and `opusdec` decodes it back to **exactly** the 50720 input samples.

**Phase 3 — capture + attachment** — **done.**
`data/services/audio/voice_memo_recorder.dart`,
`presentation/providers/voice_memo_provider.dart`,
`presentation/widgets/task_editor/voice_memo_ops.dart` and `voice_memo_bar.dart`,
a mic button in the editor toolbar, plus `RECORD_AUDIO` on Android and the
microphone entitlement and usage string on macOS. Tests:
`test/data/audio/voice_memo_recorder_test.dart` (14),
`voice_memo_provider_test.dart` (11) and `test/widgets/voice_memo_bar_test.dart`
(7).

The microphone sits behind a `VoiceMemoAudioSource` interface, so framing,
encoding, the elapsed clock, the level meter, cancel, the length cap and every
failure path are testable by pushing bytes in, with no audio hardware. What
that cannot reach — the `record` plugin itself — is covered by
`client/tool/voice_memo_capture_probe.dart`, which records from the real
microphone in a built app.

Verified against a real microphone on Linux: a 4 s run captured 3.900 s (the
balance is device startup), 196 packets, 8615 bytes at 17.67 kbit/s, 39
progress ticks at the configured 100 ms interval. `opusinfo` reports the file
clean with pre-skip 312 and a 3.899 s playback length, `opusdec` returns
exactly the 62400 samples the recorder claimed, and GStreamer — the backend
`audioplayers` uses on Linux — decodes it, so playback needs nothing new.

**Phase 4 — transcription** — **done.**
`data/services/audio/whisper_service.dart`, a "Voice memos" tab in Preferences
(`widgets/dialogs/voice_memo_settings_form.dart`), the live feed during
recording, "Transcribe" in the attachment row menu, and insertion into the
Quill document. Three new preferences — model, transcribe-while-recording and
language — all written back in `SettingsNotifier.restorePreferences`, so Cancel
rolls them back on disk as well as in memory. Tests:
`test/data/audio/whisper_service_test.dart` (17) and
`test/widgets/voice_memo_transcript_test.dart` (14), plus a Voice-memos case in
`test/preferences_dialog_test.dart`.

The transcriber reaches the recorder through a `VoiceMemoTranscriber`
interface, so the tee, the hand-off and every failure path are testable without
a model on disk; `client/tool/transcribe_probe.dart` covers the rest by
downloading a model and transcribing for real.

Verified end to end on Linux with `tiny`: the download is 77,691,713 bytes —
exactly the figure quoted above — and took 5m07s; a 6.96 s clip encoded to
18,440 bytes and transcribed in **2.16 s**, about 3x faster than real time.
See the accuracy note in §12, which is less encouraging.

**Phase 5 — playback hardening** — **done.** `AttachmentMediaServer` decodes
Ogg Opus to WAV in memory and serves that, with both caps and a one-entry
cache; `PcmAudio.toWav()` does the framing. Tests:
`client/test/data/attachment_media_server_opus_test.dart` (15), alongside the
existing media-server tests, which still pass unchanged.

Beyond swapping the bytes, three things this needed that §7 did not mention:

- **A cache.** A player issues a burst of range requests while the user drags
  the seek bar, and decoding a five-minute memo on each of them would make
  seeking unusable. One entry — playback is one attachment at a time — keyed on
  worldId *and* stored size, so replacing an attachment's content invalidates
  it. Cleared on `stop()`, since a stopped server should not sit on a copy of
  decoded media.
- **Decoding in batches.** It is synchronous CPU work on the UI isolate, so it
  yields to the event loop every 500 packets rather than freezing the app while
  a player waits for its first byte.
- **Falling back, not failing.** Anything that is not a small Ogg Opus file is
  served exactly as before, and so is anything that fails to decode — a `.ogg`
  holding Vorbis, a truncated blob, a machine where libopus will not load.
  Passing the bytes through is what used to happen anyway, so a failure here
  costs nothing that was not already the case.

Verified with third parties: the WAV the server produces is read by `ffprobe`
as `pcm_s16le, 16000 Hz, mono, 16-bit` with a duration of **6.964313 s against
the source WAV's 6.964313 s** — identical to the microsecond — and both
`ffmpeg` and GStreamer decode it. On that clip (real speech rather than a
tone) the memo is 12.1x smaller than the WAV at 21.18 kbit/s, against the
11.7x / 21.94 kbit/s predicted above.

**Phase 6 — device selection and the self-test** — **done.**
`data/services/audio/audio_devices.dart` (enumeration behind a seam, plus
`resolveAudioDevice`), `data/services/audio/memo_player.dart` (playing a clip
and *waiting* for it, which `audioPlaybackProvider` never had to do),
`presentation/providers/audio_device_provider.dart`,
`presentation/providers/audio_check_provider.dart`, and two new group boxes in
`voice_memo_settings_form.dart`. Two new preferences —
`voiceMemoInputDevice` and `voiceMemoOutputDevice`, both written back in
`restorePreferences`. Tests: `test/data/audio/audio_devices_test.dart` (5),
`audio_check_provider_test.dart` (19), `test/widgets/voice_memo_devices_test.dart`
(9), plus the shared fakes in `test/data/audio/audio_fakes.dart` and extra
cases in `voice_memo_provider_test.dart` and `preferences_dialog_test.dart`.

Two things worth knowing before touching it:

- **The device is resolved late, every time.** Nothing holds an
  `AudioDevice`; the preference is a name and the lookup happens at
  `recorder.start` and at `player.play`. Holding one would be a recording from
  the wrong microphone the first time someone unplugged a headset.
- **Cancel does not interrupt anything native.** Nothing can stop a decode
  once it has started, so the run is stamped and `cancel` moves the stamp on;
  a continuation that comes back to a stale stamp writes nothing. Without it,
  cancelling mid-playback clears the panel and then a transcript appears in it
  a second later.
- **A subscription cancel does not finish inside `pumpAndSettle`.** The check
  tears down the recorder's progress subscription on its way out of each
  stage, and in a widget test the state change lands *after* the test has
  looked. `test/widgets/voice_memo_devices_test.dart` has a `settle` helper
  that runs the real event loop first; this is the same `runAsync` quirk
  `AGENTS.md` documents for the clipboard and database tests.

Phases 1-2 are self-contained and testable without a microphone; phase 3 is the
first that needs one, and phase 6's self-test is the thing to reach for when
one is present but not behaving.

---

## 12a. Feed block size, and why transcription reports a percentage

Transcription of a stored memo is split into **25-second blocks**, one live
session each, awaited in turn (`WhisperService.kTranscribeBlockSeconds`,
`transcribeBlock`). This started as a question about progress and turned into a
performance fix; both come out of the same property of the native side.

**Why it was slow.** `stream_feed` appends samples and, once ~1.5 s of
untranscribed audio has arrived, re-runs `whisper_full` over its *whole*
accumulated window — not over the new audio. The window is only erased at the
25 s commit boundary. So feeding a stored memo one second at a time decodes the
same audio again and again: the window is decoded at 2 s, 4 s, 6 s … 26 s, then
committed and restarted. That is ~182 seconds of decoding per 26 seconds of
audio, about **eleven times** the work of decoding it once. It is bounded by the
commit window, so it is a constant multiplier rather than a blow-up with
length — but it is a large one.

Measured with `tool/transcribe_chunk_probe.dart`, which feeds the same PCM at
different chunk sizes and reports wall time and partial count:

| memo | model | 1 s chunks | 25 s chunks | speed-up |
|---|---|---|---|---|
| 1:06 | tiny | 16.7 s | 1.48 s | 11.3x |
| 1:06 | base | 35.8 s | 3.16 s | 11.3x |
| 4:57 | tiny | 85.1 s | 7.97 s | 10.7x |

The transcript is **identical** between the two — the intermediate decodes were
being thrown away, which is exactly why removing them costs nothing.

**Why one session per block rather than one long one.** They cost the same:
1456 ms of per-block sessions against 1454 ms for a single session over the
same 1:06 memo, and 8.2 s against 8.0 s over 4:57 — because `keepModelLoaded`
parks the model in native memory and the next session borrows it, so a block is
a decode and nothing else. What per-block buys is a **real** percentage: a
finished block is a decode that has actually happened. There is nothing to
count on the single-session path — `stream_feed` returns only `{@type, text}`
with no sample counts, and the worker isolate forwards a partial only when the
text *changed*, so a quiet stretch reports nothing at all.

The decoder carries no state across the boundary either way: the native side
sets `no_context = true` and the commit already erases the window at 25 s, so
splitting at 25 s is the same cut it was making anyway.

**Whisper's own progress callback is not an option here.** `whisper_ggml` does
expose one (`progress_callback` in the request body), but only on the *file*
API — the one this app deliberately never calls, because it converts non-WAV
input through system ffmpeg and writes a decrypted copy next to the input. See
§5. The live path has no such hook.

End to end through the shipped path, a 4:57 memo with `base` transcribes in
**15.7 s** (`tool/transcribe_probe.dart`), decode included.

**Cancelling** rides on the same block boundary. `transcribePcm` takes an
`isCancelled` callback, polls it before each block and throws
`TranscriptionCancelled`; a native decode has no interrupt, so the block
already running finishes first. Measured end to end with `base` on the 4:57
memo (`NOO_PROBE_CANCEL_MS` in `tool/transcribe_probe.dart`, which asks from a
timer the way a button press does): **151 ms, 702 ms and 2550 ms** for presses
landing at different points, the worst case being one block.

It is a callback rather than a token object because every caller already holds
the state that decides, and a second piece of cancellation state would only be
one more thing to keep in step:

| surface | what cancels it |
|---|---|
| recording bar | `VoiceMemoNotifier.cancelTranscription` moves the status off `transcribing`, which the run polls |
| Preferences self-test | `cancel` already bumps the run number that keeps stale results out; the same stamp stops the work |
| attachment menu | a `bool` the snack bar's `SnackBarAction` sets |

Throwing rather than returning null is deliberate: null already means "whisper
found no speech in this", and a caller that conflated the two would report an
empty memo to someone who simply changed their mind.

Cancelling drops the blocks decoded so far. In the recording bar that is worth
saying out loud — the button there is **Cancel**, not the Discard/Stop pair a
recording gets, because by then the memo is stored and only the text is at
stake. It can be asked for again from the attachment menu, with a different
model or language.

`TranscriptionProgress` carries `block`, `total` and the text so far, so a
caller can draw a bar, a percentage, or the transcript building up. It also
carries `isGranular`, which is false for a recording shorter than one block:
that decodes in a single step, so its "progress" would read 0% and then done,
which tells the user less than the plain word does — the self-test's own clips
are capped at 15 s and always land here. Three callers use it:
the recording bar ("Saved. Transcribing… 25%"), the Preferences self-test (a
bar and a percentage), and the attachment menu's Transcribe, whose snack bar
holds a `ValueNotifier` because a snack bar cannot be edited once shown and
re-showing one per block would make it flicker.

---

## 12. Open risks

**Resolved by the move to `voice_audio`.** The first three risks below were the
reason for it. They are kept, struck through, because they are what the decision
was made against.

- ~~**`opus_codec_linux` 3.0.5 bundles nothing.**~~ Both of its asset blobs were
  zero bytes, upstream and in our build output, so on Linux the package's
  documented "bundled binary, system fallback" was really "system binary only",
  and the feature was not self-contained. libopus is now built from source and
  linked statically on every platform.
- ~~**Those Windows DLLs ship in every bundle.**~~ 4.3 MB of
  `opus_codec_windows` and 344 KB of `opus_codec_web` travelled in every Linux
  release. Both packages are gone.
- ~~**`opus_codec` 3.0.5 is a young fork**~~ of the dormant `opus_flutter`, with
  only its Linux path ever exercised. No longer a dependency.

**New, and the reason to be careful.**

- **`voice_audio` has never been *run* on Windows, Android or macOS.** Linux is
  built and verified; Windows is built (0.3.1 was compiled from these sources on
  a Windows host) but never exercised; Android builds and links for arm64 but has
  not run on a device; macOS is not a declared platform of the plugin at all, so
  voice memos cannot work there until an Apple toolchain has built it.
  (The arm64 PortAudio problem is gone — it is built from source now.)
- **Capture has only ever been exercised against silence here.** The codec is
  covered against a real 440 Hz signal in `voice_audio`'s own tests, and the
  container round-trips byte-for-byte, but no one has recorded speech through
  the whole chain on this machine. Run
  `tool/voice_memo_capture_probe.dart` and *listen to the result* before
  trusting the audio quality — particularly the WebRTC gain control and noise
  suppression, which `record` did not apply on Linux at all and which now do.
- **The 30-minute cap is enforced from a polled clock**, not from the encoder.
  The recorder reads the elapsed time every 100 ms and stops when it crosses the
  limit, so a stalled UI isolate could overshoot by however long it stalled. The
  memo is in native memory either way; the risk is size, not loss.
- **`transcribeLive`'s energy gate** is tuned for microphone input. Replaying a
  stored memo through it produced the correct transcript at both the default
  `gateRmsMin` (0.0015) and 0.0, but a very quiet recording could still be
  gated. Expose the gate as a constant we can tune rather than hardcoding it at
  the call site.
- **Whisper accuracy is the weak point, and `tiny` is not good enough.**
  Measured on one 6.96 s clip of `espeak-ng` speech, both models against the
  same audio:

  | | transcript | time |
  |---|---|---|
  | spoken | *The quick brown fox jumps over the lazy dog. This is a voice memo test for the outliner application.* | |
  | `tiny` | But wig brown fox jump, silver merrily nug. This is my moist memo test for the outside of application. | 2.16 s |
  | `base` | The quick brown fox dumb, so verna lazy dog. This is a voice memo test for the outside replication. | 3.89 s |

  `base` gets two of the four clauses exactly right where `tiny` gets none, for
  1.7 s more on a 7 s clip — still faster than real time. Both downloads were
  byte-for-byte the sizes quoted in §4 (77,691,713 and 147,951,465), taking
  5m07s and 10m33s here.

  Two caveats on reading this. The input is robotic TTS, which is unusually
  hard for whisper and says nothing about a real voice; and it is one clip. But
  it does contradict Appendix A's claim that `tiny` transcribed its test clip
  *perfectly* — that claim should not be relied on. Nothing here has been
  measured against real dictation, which remains the open question.
- **Windows AVX2 requirement** excludes pre-2013 CPUs; the app should detect the
  load failure and disable transcription rather than crash.
- **Long memos.** Nothing in this design streams to storage — a memo is held as
  PCM-derived Opus in memory until stop. At ~165 KB/min that is fine for tens of
  minutes, but the UI should cap recording length (30 min suggested) rather than
  discover the limit the hard way.

---

## Appendix A — how the numbers were produced

A throwaway Flutter Linux app with `whisper_ggml 2.6.0`, `record 7.1.1`,
`opus_codec 3.0.5` and `opus_codec_dart 3.0.5`, plus a prototype
`ogg_opus.dart` implementing the muxer and demuxer described in §5. It was run
headless under `xvfb-run` and performed, in one process:

1. read a 16 kHz mono WAV;
2. encode it to Ogg Opus (24 kbit/s VBR, voice signal, 20 ms frames);
3. write the `.opus` file and validate it with `opusinfo`, `ffprobe` and
   `gst-launch-1.0 ... ! decodebin ! fakesink`;
4. demux and decode it back to PCM;
5. transcribe the decoded audio both via `transcribe()` and by feeding PCM to
   `startWhisperLiveSession`, comparing the two transcripts;
6. repeat step 5 with `gateRmsMin` at 0.0015 and 0.0.

Microphone capture was verified separately with `parecord --format=s16le
--rate=16000 --channels=1 --raw`, the exact invocation `record_linux` uses
(`record_linux-2.1.1/lib/record_linux.dart:135`), confirming the OS resamples
48 kHz hardware down to the 16 kHz mono PCM16 whisper expects.

The prototype lives outside the repository (session scratchpad) and can be
landed as the starting point for phases 1-2 on request.
