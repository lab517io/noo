# Noo

A tiny outliner with time tracking. Hierarchical notes and tasks in an encrypted
local database, with rich text, attachments, voice memos that transcribe
themselves on device, and end-to-end encrypted sync across your devices.

Everything lives in one SQLCipher file that only you can open. Sync is
end-to-end encrypted: keys derive from your database password, and the relay
server stores opaque blobs it cannot read. Two devices on the same network sync
directly and need no server at all. Transcription runs locally through
whisper.cpp — no audio leaves the machine, and there is no API key to buy.

## Download

Builds are attached to each release —
**[latest release](https://github.com/lab517io/noo/releases/latest)**:

- `noo-<version>-x86_64.AppImage` — Linux; `chmod +x` it and run, nothing else needed
- `noo-<version>-android.apk` — Android; signed, sideloadable

`SHA256SUMS` is attached beside them:

```bash
sha256sum -c SHA256SUMS
```

## Features

- **Outline** — tree of tasks with unlimited nesting, full-text search, and a
  rich-text editor (formatting, inline images, paste control)
- **Time tracking** — start/stop per task, with tree, per-day, flat and CSV reports
- **Encrypted storage** — SQLCipher database, optional password remembering via the
  platform keychain (Secret Service, Keychain, Credential Manager)
- **Sync** — multi-device via a zero-knowledge relay (AES-256-GCM, HKDF-SHA256),
  or directly between devices on a LAN with no account at all
- **Attachments** — files stored by content hash and synced once, with image
  thumbnails and audio playback in place
- **Voice memos** — recorded from the editor toolbar, encoded to Ogg Opus in
  memory, stored as ordinary attachments
- **On-device transcription** — whisper.cpp turns a memo into text in the note,
  offline, with the model chosen in Preferences
- **MCP server** — exposes the outline to local AI agents over loopback, off by
  default, token-gated, with per-branch exclusions
- **Obsidian export/import** — round-trips the tree to a Markdown vault

Linux, Windows, macOS and Android are supported; iOS and web are not started.

## Build from source

Requires Flutter 3.44+ (Dart 3.12+), Python 3.10+ for the build scripts, and on
Linux the GStreamer development packages:

```bash
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

Two dependencies compile native code from source — `voice_audio` (libopus,
libogg) and `whisper_ggml` (whisper.cpp) — so the first build is slow and
Android needs the NDK. Nothing has to be installed system-wide for either.

```bash
cd client
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d linux
```

Packaged builds:

```bash
python scripts/build_linux.py         # AppImage
python scripts/build_windows.py       # ZIP
python scripts/build_android.py --apk # AAB + universal APK
```

## Documentation

- [AGENTS.md](AGENTS.md) — architecture, domain model, data layer and development guide
- [docs/P2P_SYNC.md](docs/P2P_SYNC.md) — sync protocol v2: packet streams, version vectors, attachment blobs
- [docs/RELAY_PROTOCOL.md](docs/RELAY_PROTOCOL.md) — what the relay server speaks, and what it cannot see
- [AUDIO_MEMO.md](AUDIO_MEMO.md) — voice memo capture, encoding, playback and transcription
- [EXPORT_FORMAT.md](EXPORT_FORMAT.md) — the Obsidian vault format

The sync relay is a separate Go server and is not in this repository.

## License

MIT — see [LICENSE](LICENSE).
