# Noo - Tiny Outliner with Time Tracking

## Project Overview

**Noo** is a lightweight, hierarchical outliner application with integrated time tracking capabilities. Built with Flutter, it provides a secure, encrypted workspace for organizing tasks, notes, and tracking time spent on activities.

### Key Features

- **Hierarchical Task Management**: Tree-based task organization with unlimited nesting
- **Time Tracking**: Built-in time recording for tasks with start/stop functionality
- **Rich Text Editing**: Full-featured text editor using Quill for task content — bold/italic/lists/headers plus font family, font size, text and highlight colour, and clear-formatting — including inline images (insert, paste, resize, replace). How much of the clipboard's own formatting survives a paste is a preference (keep it / drop colours and fonts / plain text only), and Ctrl+Shift+V always pastes plain text. The right-click menu adds two commands to Cut/Copy/Paste, both on the selection: **Remove formatting** (the toolbar's clear-format, without opening the toolbar) and **Format as table**, which lines up the colon-separated columns of the selected lines with spaces and sets them in Monospace — every colon starts a column, all the selected lines share their column widths, and lines that are not rows (blank ones, ones with no colon, a heading like `Addresses:` that ends in one, and any line holding an image) are left untouched. Re-running it re-fits the columns rather than adding to them, and one undo takes the whole table back. `presentation/widgets/task_editor/editor_commands.dart`
- **Voice Memos**: Record a memo from the editor toolbar; it is captured as a PCM stream, encoded to Ogg Opus in memory (never touching disk) and stored as an ordinary attachment, so it syncs and plays back through the paths that already exist. One recording at a time, capped at 30 minutes
- **On-Device Transcription**: Optional speech-to-text for voice memos via whisper. The same PCM feeds the encoder and the transcriber, so the text is ready when the memo ends, and it is inserted into the note as a plain paragraph — searchable and exportable like any other content. "Transcribe" in the attachment menu does the same for a memo recorded earlier or on another device, replaying the stored packets with no microphone and no temp file. Runs entirely locally; the model is the one thing ever downloaded, and only when the user presses Download in Preferences. Language may be fixed or left on "Detect automatically" (`auto`, passed straight through to whisper, which detects per decode window). A recording is decoded in **25-second blocks, one at a time**, so progress is reported as a real percentage rather than estimated, and it can be **cancelled** — from the recording bar, the Preferences self-test, or the Transcribe snack bar — landing at the next block boundary, since a native decode has no interrupt. Cancelling never touches the memo: the attachment was stored before transcription began, and the text can be asked for again at any time — and, because the native side re-decodes its whole accumulated window on every feed, blocks are also about **11x faster** than feeding the memo a second at a time for a byte-identical transcript (measured; see `AUDIO_MEMO.md` §12a)
- **Audio Devices and Self-Test**: Preferences → Voice memos chooses the microphone memos record from and the speaker they play back through, stored **by name** and resolved against a fresh enumeration each time — `voice_audio` device indices are not stable, and a device that has gone falls back to the platform default rather than to whatever now sits at the old index. The speaker applies to voice memos only; other audio attachments go through `audioplayers`, which takes no device. Beside them a **Test** button runs the whole chain — record, play back, transcribe — and names the stage that failed, which is the only way to tell a muted microphone from a missing model from a silent speaker. Nothing it records is saved
- **Attachment Blob Store**: Attachments sync by content, not by copy. A packet names an attachment by the SHA-256 of its bytes (`blob:<hex>`); the bytes travel once, separately, encrypted the same way, and every node stores each distinct attachment once — the `file` table read by hash *is* the node's blob store. The log therefore grows with edits, not with what is attached; a snapshot is the database minus attachments; re-attaching an existing file costs a reference. A packet is applied before its attachments have arrived, and the bytes are fetched after every exchange from whichever node has them (a row with a hash and no content is *not downloaded yet*). On the relay a packet declares its blobs on upload, is refused if they are missing, and a blob no stored packet declares is collected on the next compaction. See `docs/P2P_SYNC.md` §3.5
- **File Attachments**: Support for attaching files to tasks, with in-place previews — image thumbnails and expandable previews, audio playback with a seek bar. Voice memos are decoded to WAV in memory before being served, so they play identically everywhere rather than depending on the platform having an Opus decoder. Inline images are attachments too — the content stores a reference, the bytes stay in the `file` table and sync through the attachment path
- **Encrypted Storage**: SQLCipher-based encrypted database for data security
- **Secure Password Storage**: Optional password remembering using platform keychain (Secret Service, Keychain, Credential Manager)
- **End-to-End Encrypted Sync**: Multi-device synchronization via a zero-knowledge relay server. AES-256-GCM encryption with HKDF-SHA256 key derivation from the database password. Server never sees plaintext. Protocol v2 (`docs/P2P_SYNC.md`): per-device packet streams with version-vector exchange — every node stores and can forward encrypted packets, so any connectivity path converges.
- **Log Compaction**: The packet log is append-only, so server and device storage grow with edits, not with the size of the outline. Preferences → Sync → Server storage reports what the account occupies (per origin device, largest first) and offers **Compact data on server**: the device syncs, publishes one full-state snapshot, and declares in a header which packets it supersedes; the server deletes them, and every other device drops its own copies as it applies the snapshot. Current data is untouched — what is discarded is the record of individual past edits below the snapshot, and possibly a conflict copy that would have been raised. Per-device high-water marks on both sides mean a pruned stream continues at its old counter rather than restarting and forking. Design and what shipped: `docs/P2P_SYNC_COMPACTION.md`
- **LAN Peer Sync**: Devices on the same LAN sync directly with each other (UDP-broadcast discovery, mutual challenge-response auth, embedded HTTP peer server) — concurrent with the relay path, deduplicated by packet identity. Like the relay's manual sync, it runs **only on request**: Tools → Sync P2P... (Shift+F5) opens a dialog that starts the peer server and discovery, syncs with every device that also has Sync P2P open (no confirmation prompt — both users opening it is the consent), and stops both when closed. Outside that dialog the device is neither discoverable nor reachable. Works alongside the relay; either path alone eventually converges all devices. **A relay account is not required**: LAN sync needs only the workspace identity — a user name and a device id (`SyncConfig.isIdentityConfigured`) — because the sync and peer keys derive from the database password and the user name, never from server credentials. Leaving Server URL empty in Preferences → Sync gives a fully working P2P-only setup; what a server adds is syncing when devices are apart, plus scheduled/unattended sync (auto-sync interval, sync-on-start, sync-on-exit), which the LAN path deliberately never does on its own.
- **Backup-Restore Safety**: Restoring a database from a backup after it has synced is the one way a device can hand the fleet two different packets under one identity. Every node stores a content hash per packet and answers `{counter → hash}` for a device's stream, so each device verifies its *own* recent history against whatever it syncs with. A restore that merely lost history heals itself — that run publishes nothing and pulls the missing packets back. A genuine divergence names the exact counter where the streams parted and offers **Preferences → Sync → Reset device identity**: a fresh device id plus one full-state snapshot of the current database, which every other device merges normally. See `docs/P2P_SYNC.md` §3.3–§3.4
- **MCP Server**: Exposes the outline to local AI coding agents (Claude Code, Codex CLI, OpenCode) over a loopback HTTP endpoint speaking the Model Context Protocol — search, read, create, update, move and delete tasks. Off by default, bound to `127.0.0.1` only, gated on a bearer token the user issues from Preferences, and stopped whenever no database is open. Individual branches can be **excluded**: Preferences → MCP → Excluded branches → Choose… opens a tree of the outline with a checkbox per task, and a ticked task is hidden — along with everything under it — from every MCP tool. The exclusion is a `tasks.flags` bit, so it syncs — a branch hidden on one device is hidden from the agents on every other one
- **Change History**: Comprehensive audit trail with diff-based storage for efficient synchronization
- **Full-Text Search**: Inline search panel over task titles and rich-text content
- **Obsidian Export/Import**: Round-trip export of the task tree to an Obsidian-compatible vault (see `EXPORT_FORMAT.md`) and re-import
- **Time Reports**: Configurable time reporting (tree / tree-with-days / flat / CSV) exportable to clipboard or file
- **Cross-Platform**: Built with Flutter, targeting Linux and Windows desktop (macOS/mobile planned)
- **Session State**: The tree's expansion set and focused node are stored per database (in its `properties` table, keyed by world id), and the desktop window's position, size and maximized state are stored per machine. A focused node that sync has deleted falls back to its nearest surviving ancestor
- **Attachment staging names**: on mobile an attachment is opened or shared by writing its bytes under its own name in the temp directory. The name is free text — typed in Rename, or received from another device through sync — so it goes through `safeFilename` (`core/utils/safe_filename.dart`), which keeps only the last path segment: a name of `../../databases/noo.db` must not be able to write over the database
- **New Database asks for the password before the save dialog**: file_picker 12's save dialog writes an empty file at the chosen path as it closes, truncating whatever the user agreed to replace, so anything the user could still cancel on has to come first (`pickSavePath` documents the constraint; `AppMenuBar.newDatabase` and the welcome screen both follow it)
- **Check for Update**: Help → Check for Update... (the overflow menu on phones) asks GitHub for the latest release of `lab517io/noo` — only when chosen, never in the background — and compares it with the running version. A Linux AppImage updates itself: the new AppImage is downloaded beside the running one, verified against the release's `SHA256SUMS`, renamed over it, and Restart Now relaunches after the normal exit sequence. Android opens the APK in the browser (no REQUEST_INSTALL_PACKAGES — Play would refuse it); Windows, and a Linux build not running from an AppImage, open the release page, since there is no installer to update in place. `lib/data/services/update_service.dart`
- **Theme Support**: Light and dark mode support
- **Font Settings**: Three separately configurable fonts — the editor (the text of a note), the tree (the outline), and UI chrome (menus/dialogs/toolbars: family + size scale factor). Editor and tree each take family, size, bold and italic. They were one "content font" until the tree got its own, so a tree font that has never been set follows the editor's; once set it is stored — including an explicit "System default", written as an empty value so that choosing it is not read back as "never set". Preferences → Editor → **Monospace fonts only** narrows the editor toolbar's Font menu to the fixed-width family, so text whose columns are meant to line up cannot be set in a font that will not line them up. It governs that one menu: the content font is untouched, because it dresses the tree as well as the editor and the tree has no columns to line up, and text already in another family keeps it. **Five console fonts are bundled** (`assets/fonts/`, all OFL-1.1, Regular + Bold, ~2.7MB): JetBrains Mono, Cascadia Mono, Inconsolata, Source Code Pro and IBM Plex Mono. They are the only families the app treats as fixed-width — Consolas is not among them and cannot be, since it ships with Windows and Office and is not redistributable (Cascadia Mono is Microsoft's own successor to it, Inconsolata an open homage). Their licences are registered with the `LicenseRegistry` in `main.dart`, so they reach Help → About rather than only the source tree. Format as table sets the font the note is already in when that is one of the five, and JetBrains Mono otherwise. Why bundle at all: Flutter resolves the generic `monospace` to a *proportional* face on Linux, and an uninstalled family falls back to the default silently, so padded columns come out looking untouched either way. `tool/font_probe.dart` measures what the real engine makes of a family name — the one thing `flutter test` cannot tell you, since it lays every family out in a fixed-width stub font

---

## Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

```
client/lib/
├── core/               # Cross-cutting concerns
│   ├── constants/      # App-wide constants
│   ├── errors/         # Exception definitions
│   ├── theme/          # App theming
│   └── utils/          # Utility functions
├── domain/             # Business logic layer
│   ├── entities/       # Core business objects (Task, TimeRecord, SyncPacket, etc.)
│   ├── repositories/   # Repository interfaces
│   └── usecases/       # Use case placeholders
├── data/               # Data layer
│   ├── database/       # Drift database configuration
│   ├── models/         # Data models
│   ├── repositories/   # Repository implementations
│   └── services/       # Data services (including sync services)
├── presentation/       # UI layer
│   ├── blocs/          # BLoC/state management
│   ├── providers/      # Riverpod providers (including sync providers)
│   ├── screens/        # App screens
│   └── widgets/        # Reusable UI components
└── platform/           # Platform-specific code
    ├── app_registration.dart  # Register app in OS launcher (Linux .desktop / Windows shortcut)
    └── linux/          # Linux-specific implementations
```

The centralized sync relay is **not** in this repository — it lives in the separate
`noo-relay` repository (Go). See [Sync Server](#sync-server) below.

### Architectural Layers

1. **Domain Layer**: Pure Dart business logic
   - Entities: Task, TimeRecord, TimeLine, WorldId, Attachment, HistoryEntry, SyncPacket, SyncChange, SyncConfig
   - Repository interfaces
   - No dependencies on external frameworks

2. **Data Layer**: Data access and persistence
   - Drift-based SQLite database with SQLCipher encryption
   - Repository implementations
   - All CRUD operations directly on NooDatabase class (no separate DAOs)
   - Database manager for lifecycle control
   - Sync services: SyncService, SyncCrypto, SyncApiClient, SyncChangePackager
   - Test data generator for development

3. **Presentation Layer**: Flutter UI
   - Riverpod for state management
   - Screens and widgets
   - Providers for dependency injection (including sync providers)
   - Sync status indicator in toolbar
   - User interaction handling

4. **Relay** (separate `noo-relay` repository): Go zero-knowledge server
   - Stores only encrypted opaque blobs; no sync logic server-side
   - JWT authentication with bcrypt
   - Per-device packet streams keyed by client-assigned counters
   - Admin dashboard at `/admin/`

---

## Key Technologies

### Core Framework
- **Flutter** (^3.10.0): Cross-platform UI framework
- **Dart** (^3.10.0): Programming language

### State Management
- **flutter_riverpod** (^2.0.0): State management solution
- **riverpod_annotation** (^2.0.0): Code generation for providers

### Database & Persistence
- **drift** (^2.0.0): Type-safe, reactive SQL database wrapper
- **sqlite3** (^2.0.0): SQLite database engine
- **sqlcipher_flutter_libs** (^0.6.0): Encrypted SQLite support
- **path_provider** (^2.0.0): Platform-specific directory access
- **shared_preferences** (^2.0.0): Simple key-value storage for settings

### UI Components
- **flutter_fancy_tree_view** (^1.6.0): Tree view widget for task hierarchy
- **flutter_quill** (^11.0.0-dev): Rich text editor
- **dart_quill_delta** (^10.0.0): Quill delta format support
- **flutter_quill_delta_from_html** (^1.0.0): HTML conversion for Quill
- **audioplayers** (^6.8.0): In-place playback of audio attachments, sourced from the loopback media server rather than a file or byte buffer. Voice memos do **not** go through it — `voice_audio` plays those from their bytes
- **pasteboard** (^0.5.0): Clipboard images for Ctrl+V into task content, where flutter_quill's own image paste is unavailable on Windows/Linux
- **whisper_ggml** (^2.6.0): On-device speech-to-text. Only the *live session* API (`startWhisperLiveSession`) is used, never `transcribe(audioPath:)`: the file API converts non-WAV input through **system ffmpeg** on Windows and Linux and returns `null` — no exception, no message — when it is missing, and writes its converted copy next to the input as a second decrypted file. Feeding raw PCM avoids both. The PCM comes from decoding a memo that is already stored — transcription runs **after** the recording is saved, not alongside it, so nothing whisper does can cost the user a memo. **Feed a block at a time, not a second at a time**: `stream_feed` re-runs `whisper_full` over its whole accumulated window whenever ~1.5 s of new audio arrives, so small feeds decode the same audio repeatedly — 11x the work, for the same text. It is also why the file API's `progress_callback` is not available to us and progress is counted in blocks instead. Note it pulls `ffmpeg_kit_flutter_new_min` in transitively even though we never call it
- **voice_audio** (^0.3.1, published on pub.dev) + **ffi** (^2.2.0): Everything a voice memo needs below the UI — microphone capture, Opus, the Ogg container, playback, and decoding back to PCM16 for whisper. An FFI plugin: no method channel, but a C++ build, which is what sets `minSdk 28` (AAudio). It builds libopus and libogg from source and links them statically, so there is no runtime codec dependency on any platform. It replaced `record`, `opus_codec` and ~1700 lines of our own encoder, decoder and Ogg muxer; see `AUDIO_MEMO.md` §5. It requests **no** permissions itself, which is why `permission_handler` is here. 0.3.1 declares Android, Linux and Windows only: the iOS and macOS backends are written and still in its tree, but neither has been through an Apple toolchain, so on macOS the plugin is simply absent
- **permission_handler** (^12.0.0): The Android microphone permission, asked for before the first recording. Only Android needs it: macOS prompts by itself given the usage description and the audio-input entitlement, and Linux and Windows have no permission model

### Platform Integration
- **window_manager** (^0.3.0): Desktop window management
- **file_picker** (^8.0.0): File selection dialogs
- **flutter_secure_storage** (^10.0.0): Secure credential storage using platform keychain/keyring
- **share_plus** (^12.0.2): Android share sheet, used for attachment export where scoped storage rules out arbitrary save paths
- **open_filex** (^4.7.0): Opens an attachment in whichever app claims the file type — the mobile equivalent of desktop double-click-to-export
- **local_auth** (^3.0.2): Biometric unlock of the encrypted database on Android
- **url_launcher** (^6.3.2): Help → Check for Update opens the release page (Windows, non-AppImage Linux) or the APK (Android) in the browser

### Sync & Networking
- **cryptography** (^2.7.0): AES-256-GCM encryption and HKDF-SHA256 key derivation for sync
- **http** (^1.2.0): HTTP client for sync server API communication

### Utilities
- **uuid** (^3.0.0): UUID generation for WorldId and device IDs
- **intl**: Internationalization support
- **collection** (^1.18.0): Collection utilities
- **equatable** (^2.0.0): Value equality for entities
- **freezed_annotation** (^2.0.0): Immutable data classes
- **diff_match_patch** (^0.4.1): Text diff computation for efficient history storage
- **crypto** (^3.0.0): SHA256 hashing for password-based key derivation
- **path** (^1.8.0): Path manipulation utilities

### Development Tools
- **build_runner** (^2.4.0): Code generation
- **drift_dev** (^2.0.0): Drift code generation
- **riverpod_generator** (^2.0.0): Riverpod code generation
- **freezed** (^2.0.0): Code generation for immutable classes
- **flutter_lints** (^5.0.0): Linting rules

---

## Domain Model

### Core Entities

#### Task (`lib/domain/entities/task.dart`)
The central entity representing a hierarchical task/outline node.

```dart
class Task {
  final int? id;                    // Database ID
  final int? parentId;              // Parent task ID (null for root)
  final WorldId worldId;            // Global unique identifier
  final String title;               // Task title
  final String? content;            // Rich text content (Delta JSON)
  final int index;                  // Order within parent
  final int flags;                  // Task flags (noTimeTracking, mcpExcluded)
  final int attachmentCount;        // Number of attachments
  final List<Task> children;        // Child tasks
  final TimeLine timeLine;          // Time tracking data
  final bool contentLoaded;         // Whether content/timeline loaded
  // ... modification tracking fields
}
```

**Key Features**:
- Hierarchical structure with parent-child relationships
- Lazy loading of content (Delta JSON and timeline)
- Modification tracking for optimized updates
- Time tracking integration via TimeLine
- File attachment support

**Important Methods**:
- `Task.create()`: Factory for new tasks with generated WorldId
- `hasTimeTracking`: Check if time tracking is enabled
- `totalTimeWithChildren`: Recursive time calculation
- `findChildById()`: Recursive child search
- `allDescendantIds`: Get all descendant IDs
- `needsSave`: Check for unsaved modifications

#### TimeRecord (`lib/domain/entities/time_record.dart`)
Represents a single time tracking interval.

```dart
class TimeRecord {
  final int? id;                    // Database ID
  final int taskId;                 // Associated task
  final WorldId worldId;            // Global unique identifier
  final DateTime startTime;         // Start timestamp (UTC)
  final DateTime? endTime;          // End timestamp (null if active)
  final bool saved;                 // Persistence status
}
```

**Key Features**:
- UTC timestamp storage
- Active tracking (endTime == null)
- Duration calculation
- Overlap detection
- Point-in-time checking

#### TimeLine (`lib/domain/entities/time_line.dart`)
Collection of time records for a task.

```dart
class TimeLine {
  final List<TimeRecord> records;   // All time records
  final bool isLoaded;              // Whether loaded from DB
}
```

**Features**:
- Aggregate time calculations
- Active record management
- Day/week/month filtering
- Date range queries

#### WorldId (`lib/domain/entities/world_id.dart`)
Global unique identifier for entities, enabling synchronization across databases.

```dart
class WorldId {
  final String value;               // UUID string
}
```

**Purpose**:
- Unique identification independent of database IDs
- Future-proofing for multi-device sync
- Conflict-free replication support

#### Attachment (`lib/domain/entities/attachment.dart`)
File attachment with BLOB content storage.

```dart
class Attachment {
  final int? id;                    // Database ID
  final int taskId;                 // Parent task
  final WorldId worldId;            // Global unique identifier
  final String filename;            // Original file name
  final int index;                  // Sort order
  final Uint8List? content;         // Binary content (lazy loaded)
  final bool contentLoaded;         // Whether content has been loaded
}
```

**Key Features**:
- BLOB-based storage (files stored directly in database)
- Lazy loading of binary content
- File type detection via extension (isImage, isAudio, isDocument) — drives the panel's in-place previews
- Size computed from content bytes
- Doubles as the store for images embedded in task content, which reference an attachment by `worldId` (see *Inline images*)

#### HistoryEntry (`lib/domain/entities/history_entry.dart`)
Represents a single change record for audit trail and synchronization.

```dart
class HistoryEntry {
  final int id;                     // Database ID
  final int entityId;               // ID of changed entity
  final String entityType;          // 'task', 'file', or 'timeline'
  final String field;               // Field that was changed
  final String? oldValue;           // null for creation; for diff fields (title/content) '' — old values replay from the patch chain (full text kept only as the base of a chain with no creation row)
  final String? newValue;           // New value (null for deletion)
  final DateTime timestamp;         // When change occurred (UTC)
  final String? worldId;            // WorldId of entity (for sync matching)
}
```

**Key Features**:
- Tracks changes to tasks, files, and time records
- Supports creation, update, and deletion tracking
- Uses diff-based storage for large text fields (title, content): update rows store the dmp patch in `newValue` and `''` in `oldValue` (never the full previous text — that cost more than full-value storage). Actual values are rebuilt by `HistoryService.reconstructTaskFieldChain` replaying the chain from its base (creation row, or the one retained full `oldValue` when the task was created from remote). The v9 migration compacts pre-existing rows to this shape.
- ISO8601 UTC timestamps for reliable time-based queries
- WorldId stored alongside each entry for cross-device entity resolution

**Helper Methods**:
- `isCreation`: True when oldValue is null (new entity)
- `isDeletion`: True when newValue is null (deleted entity)
- `isUpdate`: True when both values present (modification)

#### SyncPacket (`lib/domain/entities/sync_packet.dart`)
A packet of changes to be transmitted during sync.

```dart
class SyncPacket {
  final int version;                // Packet format version (currently 1)
  final String deviceId;            // Originating device UUID
  final String timestamp;           // ISO8601 UTC creation time
  final List<SyncChange> changes;   // Field-level changes
}

class SyncChange {
  final String entityType;          // 'task', 'file', 'timeline'
  final String worldId;             // Entity WorldId
  final String field;               // Changed field name
  final String? value;              // Full current value (not diff)
  final String timestamp;           // ISO8601 UTC
  final bool isCreation;            // Whether this is a new entity
  final String? parentWorldId;      // Parent entity WorldId (for hierarchy)
}
```

**Key Design**: Sync packets carry **full current values**, not diffs. Diffs are a local storage optimization only and do not cross device boundaries.

#### SyncConfig (`lib/domain/entities/sync_config.dart`)
Configuration for sync operations (server URL, username, device ID, auto-sync interval).

---

## Data Layer

### Database Architecture

The application uses **Drift** for type-safe database access with **SQLCipher** encryption.

#### Database Tables (`lib/data/database/tables.dart`)

1. **Tasks Table** (`@DataClassName('TaskRow')`)
   - `id`: Auto-increment primary key
   - `parentId`: Foreign key to parent task (nullable)
   - `worldId`: Unique global identifier (TEXT)
   - `orderId`: Sort order within parent (INTEGER, default 0)
   - `title`: Task title (TEXT, default '')
   - `content`: Rich text content as Quill Delta JSON (TEXT, nullable; rows written before the Quill migration still hold HTML and are converted on load). Embedded images appear here only as `noo-attachment://<worldId>` references — never as bytes
   - `flags`: Bitfield for task properties (INTEGER, default 0). `1` = `noTimeTracking`; `2` = `mcpExcluded`, which withholds this task and its whole subtree from the MCP server (`TaskFlags` in `domain/entities/task.dart`)
   - `timestamp`: ISO8601 UTC modification timestamp (TEXT)
   - `removed`: Soft delete flag (INTEGER, default 0)

2. **Timeline Table** (`@DataClassName('TimelineEntry')`)
   - `id`: Auto-increment primary key
   - `taskId`: Foreign key to task
   - `worldId`: Unique global identifier (TEXT)
   - `startTime`: Recording start (TEXT, ISO8601)
   - `endTime`: Recording end (TEXT, nullable)
   - `timestamp`: ISO8601 UTC modification timestamp (TEXT)
   - `removed`: Soft delete flag (INTEGER, default 0)

3. **Files Table** (`@DataClassName('FileEntry')`, mapped to `file` table)
   - `id`: Auto-increment primary key — **device-local**; cross-device references use `worldId`
   - `taskId`: Foreign key to task
   - `worldId`: Unique global identifier (TEXT)
   - `filename`: Original filename (TEXT)
   - `content`: Binary file content (BLOB, nullable)
   - `orderId`: Sort order (INTEGER, default 0)
   - `timestamp`: ISO8601 UTC modification timestamp (TEXT)
   - `removed`: Soft delete flag (INTEGER, default 0)

   Holds ordinary attachments *and* the bytes of images embedded in task content. Two accessors exist for reading a BLOB without materialising it: `getAttachmentSize(worldId)` (`length(content)`) and `readAttachmentSlice(worldId, offset, length)` (SQL `substr`, 1-based over BLOBs). package:sqlite3 exposes no incremental BLOB API, so those are what make range-serving a large attachment possible without allocating it whole.

4. **Properties Table** (Key-value configuration)
   - `type`: Primary key (TEXT)
   - `value`: Property value (TEXT)

5. **HistoryTask Table** (Change tracking for tasks)
   - `id`: Auto-increment primary key
   - `taskId`: Foreign key to task
   - `worldId`: WorldId of the task (TEXT, for sync resolution)
   - `field`: Field name that changed (TEXT)
   - `oldValue`: TEXT, nullable — null for creation; `''` for title/content updates (see HistoryEntry); full previous value for other fields
   - `newValue`: New value (TEXT, nullable) — a dmp patch for title/content updates
   - `timestamp`: ISO8601 UTC timestamp

6. **HistoryFile Table** (Change tracking for attachments)
   - `id`: Auto-increment primary key
   - `fileId`: Foreign key to attachment
   - `worldId`: WorldId of the file (TEXT, for sync resolution)
   - `field`: Field name that changed (TEXT)
   - `oldValue`: Previous value (TEXT, nullable)
   - `newValue`: New value (TEXT, nullable)
   - `timestamp`: ISO8601 UTC timestamp

7. **HistoryTimeline Table** (Change tracking for time records)
   - `id`: Auto-increment primary key
   - `timelineId`: Foreign key to time record
   - `worldId`: WorldId of the time record (TEXT, for sync resolution)
   - `field`: Field name that changed (TEXT)
   - `oldValue`: Previous value (TEXT, nullable)
   - `newValue`: New value (TEXT, nullable)
   - `timestamp`: ISO8601 UTC timestamp

8. **Syncs Table** (Synchronization status tracking)
   - `id`: Auto-increment primary key
   - `timestamp`: ISO8601 UTC timestamp
   - `status`: Sync status (INTEGER)

9. **Sync Log Tables** (`sync_log_runs`, `sync_log_events` — schema v14; `SyncJournal` in `lib/data/services/sync_journal.dart`)
   - One run per relay sync, LAN exchange, peer session served, compaction, identity reset, attachment fetch; each records trigger, remote, device id, outcome (`running`/`ok`/`failed`/`declined`/`busy`/`interrupted`) and counts
   - Events carry the packet identity (origin device, counter), ciphertext hash, and per-change decisions (`applied`, `lww-lost`, `lww-tie`, `conflict-copy`, `orphaned`, …) with both timestamps and a value fingerprint
   - **Local diagnostics only**: never synced, never history-tracked, writing it never fails a sync; pruned to 30 days / 200 runs. Shown in Tools → Sync Log... (`SyncLogDialog`). See `docs/P2P_SYNC.md` §10.2

#### Database Manager (`lib/data/services/database_manager.dart`)

Manages database lifecycle:
- Database creation/opening
- Password-based encryption
- Database switching (open different files)
- Migration handling
- Close/dispose operations

**Key Features**:
- ChangeNotifier for state updates
- Password validation
- Loading state management
- Current database tracking

### Repositories

#### Task Repository Interface (`lib/domain/repositories/task_repository.dart`)
Defines operations for task management:
- CRUD operations
- Hierarchical queries
- Batch operations
- Search functionality

#### Attachment Repository (`lib/domain/repositories/attachment_repository.dart`)
File attachment management:
- Add/remove attachments
- Query by task, or by worldId (how inline images in task content are resolved)
- Replace an attachment's bytes in place, keeping its worldId so every reference follows
- File storage handling

Implementation: `lib/data/repositories/attachment_repository_impl.dart`

#### Settings Repository (`lib/domain/repositories/settings_repository.dart`)
Application settings persistence:
- Theme preferences
- Window state
- User preferences

#### Timeline Repository (`lib/domain/repositories/timeline_repository.dart`)
Time tracking operations:
- Start/stop tracking
- Query time records
- Time aggregation

### Services

#### History Service (`lib/data/services/history_service.dart`)
Manages change history recording and retrieval for synchronization support.

**Key Methods**:
- `recordTaskCreation()`: Record new task creation
- `recordTaskChange()`: Record task field modifications (with diff support)
- `recordTaskDeletion()`: Record task deletion
- `recordFileCreation()` / `recordFileChange()` / `recordFileDeletion()`: File history
- `recordTimelineCreation()` / `recordTimelineChange()` / `recordTimelineDeletion()`: Timeline history
- `getTaskHistorySince()`: Query task changes since timestamp
- `getFileHistorySince()`: Query file changes since timestamp
- `getTimelineHistorySince()`: Query timeline changes since timestamp
- `getAllHistorySince()`: Combined history query across all entity types

**Features**:
- Automatic diff computation for large text fields (title, content)
- Converts database records to domain HistoryEntry entities
- Timestamp-based filtering for incremental sync

#### Time Report Service (`lib/data/services/time_report_service.dart`)
Generates time tracking reports across the task tree.

**Formats** (`TimeReportFormat`):
- `tree`: Indented bullet list mirroring the hierarchy with per-task totals
- `treeWithDays`: Tree plus a per-day breakdown under each task
- `flat`: Chronological flat list of intervals as Markdown bullets
- `csv`: Comma-separated values (task path, date, start, end, duration seconds)

Driven from the **Tools > Time Report...** menu entry via `TimeReportDialog`, which supports date-range filtering and copy/save-to-file.

#### Obsidian Export Service (`lib/data/services/obsidian_export_service.dart`)
Exports the task tree to an Obsidian-compatible vault directory. Tasks with children become directories; leaf tasks become Markdown files. Time records are written to `timeline.txt` siblings. See `EXPORT_FORMAT.md` for the full specification.

Images embedded in content are written out too: each referenced attachment is copied once into a vault-level `_images/` folder and linked relatively from every note using it (`![](../_images/shot.png)`). Remote (`http`) images keep their URL; an image whose attachment has been deleted is skipped rather than emitting a broken link. The result reports `imagesExported` alongside the task and timeline counts.

#### Attachment Media Server (`lib/data/services/attachment_media_server.dart`)
Serves attachment bytes to media players over loopback HTTP, so audio can play in place without decrypted media ever reaching disk.

**Why it exists**: players accept a file path or a URL, and attachment bytes live in the encrypted database. A temp file would be the one place the app writes decrypted content outside an explicit export.

**Key points**:
- Binds `127.0.0.1` on an ephemeral port; started lazily on first playback via `attachmentMediaServerProvider` and stopped when the database is swapped
- Loopback is reachable by any process running as the same user, so every URL carries a per-run random token; requests without it get a 403 and a token does not survive a restart
- Supports `Range` (single range, including open-ended and suffix forms), served in 512 KB chunks through `readAttachmentSlice`, so seeking in a large attachment costs one chunk of memory rather than the whole file
- Content type is derived from the attachment's extension; deleted and unknown attachments are 404

#### MCP Server (`lib/data/services/mcp/`)
Serves the open outline to local AI coding agents over the Model Context Protocol, so an agent can search, read and edit tasks instead of the user pasting them into a chat.

**Why the protocol is hand-rolled**: the server side of MCP is small — `initialize`, `notifications/initialized`, `tools/list`, `tools/call`, `ping` — and `package:dart_mcp` (the Dart team's package) has no HTTP transport for servers: its published libraries are `client`/`server`/`stdio`, and its only server constructor takes a `StreamChannel`, so an HTTP deployment would mean writing and owning a session-keyed request-to-channel bridge anyway. That is most of the work the package would have saved, plus a dependency.

**Files**:
- `mcp_protocol.dart` — constants, JSON-RPC framing, protocol-version negotiation, token generation, constant-time comparison. No I/O, no database
- `mcp_tools.dart` — the seven tool descriptors as JSON Schema, the read/write split, and `validateToolArgs` (hand-written, since nothing else validates arguments here)
- `mcp_task_api.dart` — the only file touching `NooDatabase`; runs one tool call at a time
- `mcp_server.dart` — the socket, the `Origin` and bearer checks, and JSON-RPC dispatch

**Key points**:
- Binds `127.0.0.1` on a **fixed, user-configurable port** (default 8737) — unlike the attachment media server's ephemeral one, because the URL is pasted into agent config files and has to survive a restart. Internally the port is always a parameter, so tests bind on 0
- One JSON-RPC request per `POST /mcp`, answered with one `application/json` response. Nothing is ever sent that the client did not ask for, so there is no SSE stream to hold open and `GET` is a 405
- `Origin` is validated against exact hosts (`localhost`, `127.0.0.1`, `::1`) — the MCP spec requires it, because DNS rebinding reaches loopback from a web page. Absent is allowed; CLI clients send none
- Writes go through the ordinary `NooDatabase` methods, which record history rows in the same transaction as the row. Those history rows are what sync reads, so an agent's edit reaches the user's other devices by the same path as one typed into the app
- `beforeWrite` flushes the editor before any write tool runs, for the same reason `_runSync` does: an agent editing the task the user has open would otherwise be overwritten seconds later by a debounced save holding older text
- `onChanged` fires after writes, coalesced over 250 ms, so an agent renaming fifty tasks costs one tree reload
- Read-only mode omits the write tools from `tools/list` **and** refuses them in `tools/call` — a client caches the tool list from initialize time and this server sends no `listChanged`
- Branches the user has excluded are withheld from every tool, reads and writes alike (see **Excluded branches** below)
- Failed auth is counted and surfaced in the preferences tab, not rate-limited: the socket is reachable only by processes already running as this user, so a lockout would be a self-inflicted denial of service

**Content fidelity**: `tasks.content` is Quill Delta JSON, and MCP is a text protocol. Reads go through `extractPlaintext`; writes through `plaintextToDelta`, which appends the trailing newline `Document.fromJson` requires — without it an agent's write breaks the editor rather than merely losing formatting. Because `extractPlaintext` drops embeds, and inline images *are* embeds, `noo_update_task` refuses to overwrite content that `contentIsPlain` reports as formatted unless the caller passes `force`. Otherwise a read-modify-write round trip would silently delete the user's images.

**Excluded branches**: a task carrying `TaskFlags.mcpExcluded` (bit 2), and everything under it, is invisible here. The user picks them in Preferences → MCP → Excluded branches → **Choose…** (`mcp_excluded_branches_dialog.dart`).

- **Stored in `tasks.flags`, not in a local `properties` row**, because `flags` is a synced, history-tracked field: `setTaskMcpExcluded` goes through `updateTask`, so hiding a branch travels to the user's other devices by the ordinary sync path and the agents there cannot read it either. A local-only list would leave the same branch wide open on the laptop
- **The flag marks only the branch root.** `_isHidden` walks ancestors instead, so a task dragged into a hidden branch is hidden without any rewrite, and one dragged out is visible again. Storing it per descendant would need a subtree rewrite on every toggle and would drift out of step on the first move
- **Enforced in `mcp_task_api.dart` alone**, and almost entirely in `_resolve`: every tool turns an incoming worldId into a row through it, so one check covers read, update, move, delete, and naming a hidden task as a parent or a sibling. `_getTree`, `_visibleChildren` and the search loop add the bulk-listing side
- **A hidden id is reported as not found**, in the same words an id that never existed gets. A caller can only hold one out of band, so a distinct message would confirm the branch exists and buy nothing
- **A hidden node is not marked truncated** in `noo_get_tree`, and a hidden match is skipped before `total` is incremented in `noo_search_tasks` — a marker or a count would say exactly where the user's hidden branches sit
- **Delete refuses over a hidden descendant.** `noo_delete_task` on a *visible* task whose subtree contains an excluded branch is refused, because the delete cascades and would destroy the very content the flag protects. This is the one refusal that admits something is there — without saying what, where, or how much
- **Hidden siblings still hold their positions.** `_positionAfter` and `_renumberSiblings` run over the real sibling list, hidden rows included, so an insert lands where the caller asked; only `orderId` is ever written on a hidden row, and it is never read out. A hidden sibling simply cannot be *named* as `afterId`

**Not in the model**: there is no done/completed flag anywhere in `TaskFlags`, so no tool marks a task complete and the tool descriptions say so — an agent handed an "outliner" will otherwise assume a checkbox exists.

#### Obsidian Import Service (`lib/data/services/obsidian_import_service.dart`)
Reverse of the export: walks an Obsidian vault and reconstructs the task tree, preserving timelines from `timeline.txt` files.

#### Test Data Generator (`lib/data/services/test_data_generator.dart`)
Generates test datasets for development and debugging.

**Key Methods**:
- `generateTestData()`: Create hierarchical tasks with time records
- `clearAllData()`: Remove all data from the database

**Features**:
- Configurable depth, breadth, and time record generation
- Realistic task titles and HTML content
- Random time records spanning the last 30 days

#### Secure Storage Service (`lib/data/services/secure_storage_service.dart`)
Manages secure storage of sensitive data using platform-specific keychains.

**Key Methods**:
- `savePassword()` / `getPassword()` / `deletePassword()`: Database password
- `saveServerPassword()` / `getServerPassword()` / `deleteServerPassword()`: Sync server password
- `saveMcpToken()` / `getMcpToken()` / `deleteMcpToken()`: MCP bearer token. Scoped to the app rather than to a database file (unlike the database password), because it is pasted into agent config files by hand and per-database tokens would mean reconfiguring every agent on each database switch
- `hasPassword()`: Check if password is stored

**Platform Backends**:
- **Linux**: Secret Service API (GNOME Keyring / KWallet)
- **macOS**: Keychain Services
- **Windows**: DPAPI-encrypted JSON file (`flutter_secure_storage.dat`) in Roaming AppData, user-scoped (`CryptProtectData`). Legacy Windows Credential Manager entries are auto-migrated on first read. (Changed in flutter_secure_storage v9+/windows v4; older versions used Credential Manager directly.)
- **Android**: EncryptedSharedPreferences / Keystore
- **iOS**: Keychain Services

#### Sync Crypto (`lib/data/services/sync_crypto.dart`)
Handles encryption/decryption for sync payloads.

**Algorithm**: AES-256-GCM (authenticated encryption)

**Key Derivation**:
```
sync_key = HKDF-SHA256(
    ikm  = database_password (UTF-8),
    salt = username (UTF-8),
    info = "noo-sync-v1",
    len  = 32 bytes
)
```

**Per-blob Format**: `nonce (12 bytes) || ciphertext || GCM tag (16 bytes)`
- AAD (additional authenticated data) = device_id (prevents blob misattribution)

**Key Methods**:
- `deriveKey(password, username)`: Derive sync key from DB password
- `encrypt(plaintext, aad)`: Encrypt with random nonce
- `decrypt(data, aad)`: Decrypt and verify authenticity

#### Sync API Client (`lib/data/services/sync_api_client.dart`)
HTTP client for the sync relay server.

**Key Methods**:
- `register(username, password)`: Create server account
- `login(username, password, deviceName, platform)`: Authenticate and obtain JWT tokens
- `uploadChange(encryptedBlob)`: Push encrypted blob, returns server-assigned sequence
- `getChangesSince(seq, limit)`: Pull changes (auto-excludes own device)
- `testConnection()`: Health check
- Auto-refreshes access token on 401

#### Sync Change Packager (`lib/data/services/sync_change_packager.dart`)
Packages local history entries into sync packets.

**Key Methods**:
- `coalesce(entries)`: Deduplicate — keep only latest change per entity+field
- `packageChanges(entries, deviceId)`: Resolve full current values from DB and build SyncPacket
- `compress(json)` / `decompress(data)`: gzip compression

**Pipeline**: `coalesce → resolve full values → JSON → gzip → encrypt → upload`

#### Sync Service (`lib/data/services/sync_service.dart`)
Main sync orchestrator.

**Key Methods**:
- `performSync()`: Full push+pull cycle
- `pushLocalChanges()`: Package and upload local changes since last sync
- `pullAndApplyRemoteChanges()`: Fetch, decrypt, and apply remote changes
- `startAutoSync(intervalMinutes)` / `stopAutoSync()`: Timer-based auto-sync

**Conflict Resolution**: Last-Writer-Wins at field level (per entity+field). Special cases:
- **Tree structure**: Cycle detection before applying parent changes (falls back to root)
- **Deletions**: Deletion wins over modification
- **Conflict copies** (docs/P2P_SYNC.md §8.3): when a *concurrent* edit to a task's title/content (or a deletion racing such an edit) would silently discard user text under LWW, the losing value is preserved as a new sibling task titled `… (conflict <date time>)`. Concurrency is detected causally — each packet carries the sender's applied vector, resolved against the local `sync_push_log` table (own packet counter → max task-history row id packaged) — so an ordinary newer edit made on top of a synced value never produces a copy. Exactly one device creates each copy (the winning value's origin device for edit-vs-edit; the edit's origin device for delete-vs-edit), and it propagates as an ordinary task.

---

## Presentation Layer

### State Management with Riverpod

The app uses Riverpod providers for dependency injection and state management.

#### Key Providers (`lib/presentation/providers/providers.dart`)

**Database Providers**:
- `databaseManagerProvider`: Database lifecycle manager
- `databaseProvider`: Current database instance
- `isDatabaseReadyProvider`: Database readiness state
- `currentDatabasePathProvider`: Current DB file path
- `currentDatabaseFileNameProvider`: Current DB filename
- `initialDatabasePathProvider`: Initial DB path on startup

**Task Providers**:
- `taskTreeControllerProvider`: Manages task hierarchy
- `selectedTaskIdProvider`: Currently selected task
- `topLevelTasksProvider`: Root-level tasks
- `childTasksProvider`: Children of specific task
- `taskByIdProvider`: Single task lookup

**Time Tracking Providers**:
- `activeTrackingTaskIdProvider`: Currently tracked task
- `isTrackingProvider`: Whether tracking is active

**Attachment Providers**:
- `attachmentRepositoryProvider`: Attachment repository
- `taskAttachmentsProvider`: Attachments for task
- `attachmentCountProvider`: Attachment count
- `attachmentRefreshProvider`: Refresh trigger
- `attachmentMediaServerProvider`: Loopback HTTP server streaming attachment bytes to the audio player (started on first playback)
- `audioPlaybackProvider`: The single shared audio player — which attachment is loaded, playing state, position/duration

**Audio Device Providers** (`lib/presentation/providers/audio_device_provider.dart`):
- `audioDeviceSourceProvider`: How devices are enumerated. The real one brings the `voice_audio` engine up (everything there throws until `initialize` has run) but opens no stream; tests override it, which is what lets the Preferences device rows be exercised with no native library
- `microphoneDevicesProvider` / `speakerDevicesProvider`: What the platform currently reports. `FutureProvider`s because the answer expires — `refreshAudioDevices(ref)` re-scans and invalidates both. Hot-plug is only reported on Windows, so Refresh is the only way a headset plugged in after the dialog opened appears
- `selectedMicrophone(ref)` / `selectedSpeaker(ref)`: The stored *name* resolved to a device at the moment of use, never held. A name that no longer matches resolves to null, which is `voice_audio`'s own word for the system default

**Audio Check Providers** (`lib/presentation/providers/audio_check_provider.dart`):
- `memoPlayerProvider`: `MemoPlayer` — plays a clip from its bytes and completes when it has finished. A seam distinct from `audioPlaybackProvider` because the self-test has to *wait* for playback, and because a widget test must not open a speaker
- `audioCheckProvider`: The Preferences self-test. Carries `TranscriptionProgress` while transcribing, so the panel shows a bar and a percentage. Records (capped at 15 s), plays back, transcribes, and reports a stage. Refuses while `voiceMemoProvider.isBusy` — there is one microphone, and stealing it would cost the user the note they were dictating. Everything after capture *reports* rather than fails: no model selected, model not downloaded and whisper finding no speech are all outcomes of a run whose recording and playback worked

**History Providers**:
- `historyServiceProvider`: History service for change tracking and sync

**Secure Storage Providers**:
- `secureStorageServiceProvider`: Secure storage for sensitive data (passwords)

**Sync Providers** (`lib/presentation/providers/sync_provider.dart`):
- `syncConfigProvider`: Sync configuration derived from settings
- `syncCryptoProvider`: AES-256-GCM crypto service
- `syncApiClientProvider`: HTTP client for sync server (null if not configured)
- `syncServiceProvider`: Main sync orchestrator (null if not configured)
- `syncStatusProvider`: Current sync status (disabled/idle/syncing/error/pendingChanges)
- `lastSyncTimeProvider`: Last successful sync timestamp

**MCP Providers** (`lib/presentation/providers/mcp_provider.dart`):
- `mcpConfigProvider`: The MCP preferences the server reacts to, as one `Equatable` value. Equality matters: settings are rewritten on every preference edit, and a config without `==` would report a change each time the user nudged the font size — which for a *fixed* port means a rebind that intermittently fails on a socket still in TIME_WAIT. `SyncConfig` is `Equatable` for the same reason: `syncConfigProvider` derives it from the whole settings object, and without equality every preference edit closed the relay client, restarted the auto-sync timer and tore down an open P2P session.
- `mcpServerProvider`: The one long-lived `McpServer` for the process, bridged from `ChangeNotifier` the way `DatabaseManagerNotifier` is. Deliberately not rebuilt per database swap — `ref.onDispose` does not await the Future that closes the socket, so a replacement would race the old one for the port
- `mcpServerListenerProvider`: Pushes config into the server and refreshes tree/editor/timeline after an agent write, the same three refreshes `lanSyncListenerProvider` does. **Lazily initialized — `MainScreen` must `watch` it**, or the server never starts
- `mcpExcludedBranchesProvider`: The hidden branches of the open database, each with its ancestor path, for the summary the MCP tab shows above its Choose… button. `autoDispose` so re-opening preferences re-reads, and invalidated when the picker reports a change

**Settings Providers** (`lib/presentation/providers/settings_provider.dart`):
- `themeModeProvider`: Light/dark theme preference
- `settingsProvider`: Full application settings including:
  - `themeMode`: Light/dark/system theme
  - `lastDatabasePath`: Last opened database
  - `showSeconds`: Time display format
  - `autoSaveIntervalSeconds`: Auto-save interval
  - `rememberPassword`: Enable password storage in system keychain
  - `syncEnabled`: Whether sync is active
  - `syncServerUrl`: Relay server URL
  - `syncUsername`: Server account username
  - `syncDeviceId`: Auto-generated device UUID
  - `syncDeviceName`: Human-readable device name
  - `syncAutoInterval`: Auto-sync interval in minutes (0=manual)
  - `fontFamily`: Editor font family (null = system default)
  - `fontSize`: Editor font size in points, clamped [8, 48], default 14
  - `fontBold`: Whether editor text is rendered bold
  - `fontItalic`: Whether editor text is rendered italic
  - `treeFontFamily` / `treeFontSize` / `treeFontBold` / `treeFontItalic`: the tree's own font. A key that was never written falls back to the editor's value (the migration from the single content font); an empty `treeFontFamily` is an explicit "System default", not "unset"
  - `monospaceFontsOnly`: narrow the editor toolbar's Font menu to the bundled fixed-width families (default false)
  - `chromeFontFamily`: UI chrome font family (null = theme default)
  - `chromeFontScale`: UI chrome size scale factor, clamped [0.8, 1.5], default 1.0
  - `pasteFormatting`: what happens to the formatting on pasted text — `keep` (default), `stripStyling` (drop colour/background/font/size), `plainText`. Stored by enum name, and an unrecognised name reads back as `keep`
  - `voiceMemoModel` / `voiceMemoTranscribe` / `voiceMemoLanguage`: which whisper model, whether a new memo is transcribed once stored, and the language code (`auto` lets whisper detect)
  - `voiceMemoInputDevice` / `voiceMemoOutputDevice`: microphone and speaker, stored **by name** (empty = system default). Not by index: `voice_audio` indices are only meaningful within the enumeration they came from
  - `mcpEnabled`: Whether the MCP server serves local agents (default false)
  - `mcpPort`: Loopback port for the MCP server, clamped [1024, 65535], default 8737
  - `mcpReadOnly`: Withhold the MCP write tools (default false)
  - `mcpToken`: MCP bearer token. Keychain-only — it has no SharedPreferences key, like `syncPassword`, and `restorePreferences` rolls it back through the keychain so Regenerate-then-Cancel restores the agents' old token

> Every user-facing preference must also be written back in `SettingsNotifier.restorePreferences`. The dialog applies edits live, so Cancel replays the whole snapshot to memory *and* disk; a setting missing from that method rolls back in memory and stays written on disk, and nothing fails loudly when it does.

### Main Screens

#### Welcome Screen (`lib/presentation/screens/welcome_screen.dart`)
First-run screen that lets the user pick where their database lives before any password dialog appears. Calls back with an absolute path; the caller routes to create-new vs open-existing flows.

#### Startup Screen (`lib/presentation/screens/startup_screen.dart`)
- Database initialization
- Password entry for encrypted databases
- Auto-fill password from secure storage (when enabled)
- Database path selection (delegates to `WelcomeScreen` on first run)
- Loading states

#### Main Screen (`lib/presentation/screens/main_screen.dart`)
- Primary application interface
- Three-panel layout:
  - Task tree (left)
  - Task editor (center)
  - Attachments/info (right)
- Menu bar integration
- Time tracking controls
- Sync status indicator in toolbar (cloud icons: disabled/synced/syncing/error/pending)

### Key Widgets

#### Task Tree Panel (`lib/presentation/widgets/task_tree/`)
- `TaskTreePanel`: Container widget
- `TaskTreeController`: State and operations
- `TreeNode`: Individual task node rendering
- Features:
  - Drag-and-drop reordering
  - Step moves from the row's context menu and the keyboard (`TaskMove`, `TaskTreeController.move`): **Move up / Move down** swap with a sibling, **Move to parent level** puts the task right after its parent, **Move under previous** makes it the last child of the sibling above (and expands that sibling). Shortcuts are Alt+Shift+↑/↓/←/→ on Windows/Linux and ⌃⌘+arrows on macOS (`treeMoveActivator`), bound in `MainScreen` and routed to the panel through `taskMoveProvider` so the moved row is scrolled back into view. They act on the selected task and fire while the note editor has focus — Alt+Shift+arrows is why: every other modifier combination of the arrows is text navigation the editor needs, and on Windows/Linux this one only duplicates Shift/Ctrl+Shift+Home/End. Entries that would do nothing are disabled rather than hidden
  - Expansion survives moves: nodes are replaced whenever their task changes and the tree controller keys expansion by identity, so `_supersede` carries it to the new instance — otherwise moving an expanded node, or renumbering the siblings it displaced, collapsed them
  - Expand/collapse nodes
  - Add/delete tasks
  - Keyboard navigation
  - Selection management
  - A `visibility_off` badge on a branch hidden from AI agents. Read-only here — the picking is in Preferences → MCP, because a per-task command would sit in the menu the user opens twenty times a day to rename something. The badge marks the branch root only: its descendants are hidden by inheritance and carry no flag of their own

#### Task Editor Panel (`lib/presentation/widgets/task_editor/`)
- `TaskEditorPanel`: Container widget
- `QuillEditorWrapper`: Rich text editor integration
- Features:
  - Delta JSON content editing (legacy HTML rows converted on load)
  - Auto-save on changes. Switching tasks keeps the previous document on screen while the next one loads, but **frozen** (`QuillEditorWrapper.frozen`): keystrokes made in that window would land in the old document and be wiped, unsaved, when the new one arrived. In-flight saves are tracked in a map shared by every panel instance, so a panel torn down and rebuilt at once (layout threshold, task screen reopened) cannot read the database before the save its predecessor fired from `dispose` has landed
  - Title editing
  - Toolbar with formatting options
  - Undo/redo support
  - Inline images (insert, paste, resize, replace, remove)
  - On a phone (`isCompactLayout`) the toolbar sits *under* the text, so the keyboard inset puts it on top of the soft keyboard, and shows only while the editor has focus or a route a toolbar button opened is on top. It is hidden with `Visibility(maintainState: true)`, not removed: a dropdown awaits its menu and applies the pick afterwards, which a disposed State cannot do. `TaskEditorScreen` drops its tab bar while the keyboard is up on the Notes tab
  - Context menu (anchored at the pointer) adds **Remove formatting** and **Format as table** to quill's Cut/Copy/Paste (`editor_commands.dart`). Format as table pads the colon-separated columns of the selected lines with spaces and sets those lines in a bundled fixed-width font (`monospaceFontFor`); lines without a colon, headings ending in one, and lines holding an embed are left alone
  - `WordNavigationActions` (`word_navigation_actions.dart`) overrides quill's next-word intents (Ctrl+Right, Ctrl+Shift+Right, Ctrl+Delete) only when nothing but whitespace follows the caret: quill resolves that position against the first line and jumps the caret backwards (Ctrl+Delete threw a `RangeError`). Everything else is delegated back to quill via `callingAction`

##### Inline images
Images are **not** embedded in the content. The bytes go into the `file` table — the same store the attachments panel lists — and the Delta holds only a reference:

```json
{"insert": {"image": "noo-attachment://<attachment worldId>"}}
```

That keeps `tasks.content` small: it is diffed into history on every keystroke, searched with LIKE, and pushed whole in every sync packet. The bytes ride the attachment sync path instead, which transfers each image once, only when it changes. The reference is the attachment's **worldId**, not its row id, because row ids are device-local.

- `attachment_uri.dart` (`core/utils/`): the reference scheme, plus reference extraction from stored content.
- `AttachmentImageEmbedBuilder` (`attachment_image_embed.dart`): renders the embed and owns the click menu (resize / replace / save as / remove / delete) and the resize dialog. Also renders `data:`, `http(s)` and file-path sources so content imported from HTML is not blank.
- `AttachmentImage` (`widgets/attachments/attachment_image_provider.dart` — it lives with the attachments feature because the panel's thumbnails use it too): `ImageProvider` reading the BLOB, so the decoded frame is shared through Flutter's image cache. `attachmentImageFor(ref, worldId)` is the usual way to build one; call `AttachmentImage.evictWorldId` after replacing an attachment's bytes.
- `attachment_image_ops.dart`: insert / replace / remove / delete / save, and the display width helpers.

Display size is stored in the embed's `style` attribute (`width: 240px`). It cannot be a `width` attribute: `ResolveImageFormatRule` is the only rule flutter_quill has for formatting an embed, and it matches `style` alone.

Images arrive three ways: the toolbar button, the embed menu's *Replace*, and **Ctrl+V**. Paste is handled by the app rather than flutter_quill — its built-in image paste goes through `quill_native_bridge`, whose Windows implementation does not read clipboard images and which has no Linux implementation at all (the version that fixes this needs win32 ^6, ruled out by the `file_picker` pin). Instead `QuillClipboardConfig.onClipboardPaste` runs first and claims the paste only when an image is there:

- `clipboard_image.dart` reads the clipboard through `package:pasteboard` and normalises it. macOS and Linux hand over PNG; **Windows hands over an uncompressed BMP** (~8 MB for a 1080p screenshot), so anything that is not already a PNG is re-encoded through Skia — that would otherwise be the size stored, diffed into history and pushed through sync.
- Text on the clipboard wins: a copied selection carries both, and turning an ordinary text paste into an image would be worse than the reverse. Copying an image alone leaves no text, so screenshots still paste.
- Image *files* copied in a file manager paste as images too; other file types fall through to the normal paste.

Deleting an image from the text removes only the embed; "Delete image" also soft-deletes the attachment, but not while another embed in the same document still references it.

##### Pasted formatting

Rich text copied out of a browser or an office suite reaches the editor as HTML, which flutter_quill converts to a Delta carrying the source page's colours, fonts and sizes. Those rarely suit the note it lands in, and a colour picked for a white page can be unreadable against the dark theme — so `Preferences → Behavior → Editor → Paste` decides how much survives (`AppSettings.pasteFormatting`):

- **Keep formatting** — flutter_quill's own behaviour.
- **Remove colours and fonts** — `stripAppearanceAttributes` in `paste_formatting.dart` drops the `color`, `background`, `font` and `size` attributes through `QuillClipboardConfig.onRichTextPaste`, leaving emphasis, links, lists, headers and embeds (with their display width) alone.
- **Plain text only** — `onClipboardPaste` claims the paste and inserts `Clipboard.kTextPlain` itself, which then picks up the styling of the text it lands in (quill's `PreserveInlineStylesRule`).

**Ctrl+Shift+V** pastes plain text whatever the preference says, handled in `onKeyPressed` — nothing else binds that combination, and the paste is started rather than awaited because key handling is synchronous.

The preference is read (not watched) at paste time: the controller's clipboard config is built once in `initState`, so a preference changed since then would otherwise not take effect until the editor was rebuilt. Note that `onRichTextPaste` only fires for content coming from *another* app — an internal copy pastes its own Delta straight through — so a copy within the editor keeps its formatting in every mode but plain-text.

##### A failing clipboard probe must not eat the paste

`QuillController.clipboardPaste()` tries the richest thing on the clipboard first — HTML, an HTML file, a Markdown file, an image — and only if none of them answered does it fall back to `Clipboard.getData` and insert the plain text. **That chain has no error handling.** An exception from any probe escapes `clipboardPaste()`, past the fallback that never ran, and out through the editor's `pasteText` as an unhandled async error. What the user sees is a Paste entry that is enabled and a Ctrl+V that does nothing — *and only for plain text*, because rich content is answered before the failing probe is reached.

The probes reach the platform, which is where they fail. Every failure branch of `quill_native_bridge_windows`'s `getClipboardHtml` — the clipboard already open in another process, `RegisterClipboardFormat` reporting a stale `GetLastError`, `GlobalLock` refusing — is an `assert(false, …)`, so it **throws in a debug or profile build and returns null in release**. Under `flutter test` there is no implementation registered at all and `isSupported` throws `UnimplementedError`.

`ResilientClipboardService` (`task_editor/resilient_clipboard_service.dart`) wraps quill's own service and turns any throw into null, installed over `ClipboardServiceProvider` from `main()` before any editor exists. A clipboard that will not say what rich content it holds means there is none this app can use, which is what null already means to every caller. Nothing below it changes: an internal copy still restores its own formatting through the same plain-text branch, and external HTML still arrives rich. Each broken probe is logged once per run in debug builds — the log is the only thing that distinguishes a paste that lost its formatting from one that never happened.

Deliberately at the service, not at `onClipboardPaste`: quill calls the service for every paste however it was triggered — Ctrl+V, Shift+Insert, the context menu — so guarding there covers all of them at one point instead of re-implementing the paste behind each entry.

Toolbar-side, the same attributes are settable: font family (`kEditorFontFamilies`) and size (`kEditorFontSizes`, both in `core/constants/fonts.dart`), text and highlight colour, and clear-formatting for content pasted before the preference was set. **Neither dropdown may be given a `width`** — that switches its label to an `Expanded` inside a `Row`, and the single-row toolbar lays out unbounded, which asserts.

#### Search Panel (`lib/presentation/widgets/search/search_panel.dart`)
Inline search panel shown below the toolbar. Debounced text input searches across task titles and rich-text content, returning matches with context snippets (plaintext extracted via `extractPlaintext` in `core/utils/content_utils.dart`).

#### Attachments Panel (`lib/presentation/widgets/attachments/`)
- File list for the selected task; files are added from the status bar's add button (the panel has no header row) or the empty-state button
- Export / rename / delete from each row's menu; tapping a non-image row exports it
- File-type icons per extension
- In-place previews: image thumbnail + expandable preview (tapping an image row opens it), audio transport controls

##### In-place playback
Attachment bytes live in the encrypted database, but media players want a path or a URL. Rather than writing decrypted media to a temp file — the one thing the app otherwise never does outside an explicit export — audio is streamed from a loopback HTTP server:

- `AttachmentMediaServer` (`data/services/attachment_media_server.dart`): binds `127.0.0.1` on an ephemeral port, started lazily on first playback via `attachmentMediaServerProvider` and stopped when the database is swapped. Loopback is reachable by any local process, so every URL carries a per-run random token and requests without it get a 403.
- Range requests are served with `NooDatabase.readAttachmentSlice`, which reads through SQL `substr` — package:sqlite3 exposes no incremental BLOB API, and selecting the column would allocate the whole attachment. Playing a 300 MB file therefore costs one chunk of memory, not 300 MB.
- `AudioPlaybackNotifier` (`presentation/providers/attachment_playback_provider.dart`): one shared `AudioPlayer`, so starting a second attachment replaces the first instead of layering over it. Deleting the playing attachment stops it first.
- Images need none of this — `AttachmentThumbnail` and `AttachmentImagePreview` render straight from the BLOB through `AttachmentImage`.

Video is not played in place: `video_player` has no Windows/Linux implementation, and the only real option (`media_kit`) bundles libmpv. Video attachments keep the plain file row.

#### Time Tracking Widgets (`lib/presentation/widgets/time_tracking/`)
- Start/stop buttons
- Active timer display
- Time statistics
- Timeline visualization

#### Dialogs
- `PasswordDialog`: Database password entry
- `PreferencesDialog`: Application settings, styled as a classic property sheet (text tabs, titled group boxes, aligned label column, OK/Cancel) using the shared controls in `dialogs/classic_form.dart`. Edits apply live so the theme and fonts preview themselves; Cancel (also Esc or a click outside) restores the settings snapshot taken when the dialog opened, via `SettingsNotifier.restorePreferences`
- `SyncSettingsDialog`: Sync server configuration (URL, username, password, device name, auto-sync interval, test connection, register account)
- `AboutDialog`: Application information
- `HistoryViewerDialog`: Change history visualization for debugging
- `TimeReportDialog`: Time report generator with format selector, date range, and copy/save actions
- `SyncProgressDialog`: The running sync. **Hide** closes the dialog and leaves the sync running; **Cancel** calls `SyncService.requestCancel()`, which is checked between packets, pages and attachments (and inside a packet's apply, rolling that packet back), so the run stops at a safe point and the next one resumes from there. Applying yields to the event loop every ~12 ms, so the window stays responsive and a progress bar with an ETA is drawn under the applying stage. Result lists are capped at 200 rows, with a pointer to the full log
- `P2pSyncDialog`: Tools → Sync P2P... — the LAN sync session. It starts the peer server and discovery (`LanSyncCoordinator.startSession`), syncs with every device that also has it open, lists each one with its state, offers *Sync Again*, and stops both when closed. The lower device id leads each exchange; the other waits 4 s before starting its own
- `SyncLogDialog`: Tools → Sync Log... — the persistent sync log (see *Sync Log Tables*), across restarts and every kind of sync
- `UpdateDialog`: Help → Check for Update... (`UpdateService`); wraps and scrolls to fit phone-width screens

#### App Menu Bar (`lib/presentation/widgets/app_menu_bar.dart`)
Desktop menu bar with:
- File (Open..., New Database..., Export to Obsidian..., Import from Obsidian..., Exit)
- View (Find..., Theme)
- Tools (Timeline... [Ctrl+Shift+T], Time Report... [Ctrl+Shift+R], Compact Database... — runs `compactTaskHistoryOldValues` then `VACUUM` behind a modal barrier and reports the space returned to disk; Sync Now [F5], Sync P2P... [Shift+F5], Sync Log... (only with a database open); Preferences... [Ctrl+,])
- Debug (View Change History..., Generate Test Data, Generate Large Dataset, Clear All Data)
- Help (Check for Update..., About)

On phones the menu actions are reached from the app bar's overflow menu, which includes Sync P2P... and Compact Database...; the app bar shows the database name as a small muted line (full name on long-press).

Windows and Linux only. The commands themselves are `static` methods on
`AppMenuBar`, so both menus and the keyboard shortcuts call the same code.

#### macOS Menu Bar (`lib/presentation/widgets/macos_menu_bar.dart`)
macOS has one menu bar per app, at the top of the screen, so `AppMenuBar`
returns its child untouched there (`usesPlatformMenuBar`) and `MacosMenuBar`
hands the same commands to the OS as a real `NSMenu` via Flutter's
`PlatformMenuBar`. Differences from the in-window menu, all of them platform
convention:
- An application menu named after the app holds About, Settings..., the
  Services submenu, Hide/Hide Others/Show All and Quit — the items the other
  platforms keep in Tools and Help. (Check for Update... is not offered on
  macOS: no binary is published for it.) Quit is a custom item,
  not `PlatformProvidedMenuItemType.quit`, so it runs the same shutdown
  sequence (finalize tracking, sync on exit) as the window's close button.
- A standard **Edit** menu (Undo/Redo, Cut/Copy/Paste, Select All). Its items
  dispatch text-editing intents at the focused widget; the key equivalents are
  claimed by Flutter's own shortcuts before AppKit offers them to the menu, so
  the intents only run for a mouse selection.
- A **Window** menu (Minimize, Zoom, Bring All to Front) and Enter Full Screen
  under View, all platform-provided items.
- Items that need an open database are disabled while there is none, instead of
  answering with a snack bar after the fact.
- Theme marks the active mode with a `✓` in the label: a platform menu item
  carries no checked state.

It is mounted in `app.dart`'s `MaterialApp.builder`, not around the main
screen, because the system menu bar has to exist for the app's whole life —
including the startup and welcome screens and a window narrow enough to fall
back to the compact layout, none of which mount `AppMenuBar`. Being above the
navigator, its actions take their `BuildContext` from `rootNavigatorKey` when
selected.

Shortcuts follow the platform too (`lib/core/utils/menu_shortcuts.dart`):
`primaryActivator` is Ctrl on Windows/Linux and Cmd on macOS, and Find is
Cmd+F on macOS against Ctrl+Shift+F elsewhere. Neither menu invokes its own
accelerators — Flutter's `MenuBar` never does, and on macOS the framework
claims the key before the system menu sees it — so `MainScreen`'s
`CallbackShortcuts` remain the thing that actually runs them.

#### Window Title Bar (`lib/presentation/widgets/window_title_bar.dart`)
On Windows and Linux (`usesCustomTitleBar`) the app hides the native title bar
— `main.dart` calls `setTitleBarStyle(TitleBarStyle.hidden)` — and draws its
own 32px strip instead: the menu bar on the left, the window title in the
middle (also the drag handle, double-click to maximize), and minimize /
maximize / close on the right. This merges two bars into one; macOS keeps the
native bar, since its menu belongs in the system menu bar.

Consequences worth knowing:
- Windows keeps its native frame, so resize borders still work, but the
  Windows 11 Snap Layouts flyout on the maximize button is gone (it needs
  native `WM_NCHITTEST` handling in `windows/runner`).
- Linux loses its decorations entirely under desktops using server-side
  decorations, so `app.dart` wraps the app in `DragToResizeArea` to restore
  8px resize edges.
- The OS window title is still set (`app.dart`) because the taskbar and
  alt-tab switcher read it; `windowTitleText()` is the single source for both.

---

## Key Constants

### App Constants (`lib/core/constants/app_constants.dart`)
- Application name
- Version information
- Default values
- UI constants

### Database Constants (`lib/core/constants/database_constants.dart`)
- Default database name
- Table names
- Field names
- Migration versions

---

## Development Guide

### Prerequisites
- Flutter SDK ^3.10.0
- Dart SDK ^3.10.0
- SQLCipher libraries (for encrypted database support)
- Linux development headers (for Linux build), including GStreamer — see below
- Visual Studio with C++ desktop workload + vcpkg with OpenSSL (for Windows build)
- Android SDK + JDK 17 (for Android build; see `docs/ANDROID_PORT.md`)
- Python 3.10+ (for the `scripts/build_*.py` build scripts)

**Linux native dependencies.** `audioplayers_linux` links GStreamer, so the
Linux build fails at CMake configure time without its development packages:

```bash
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
```

`scripts/build_linux.py` probes for these with pkg-config before building and
prints the install line, rather than letting CMake fail inside the plugin.

### Setup

1. **Clone the repository**
   ```bash
   cd client
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for Drift, Riverpod, Freezed)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run -d linux
   ```

### Code Generation

The project uses code generation for:
- **Drift**: Database classes (`*.g.dart`)
- **Riverpod**: Provider generation
- **Freezed**: Immutable classes

Run code generation after modifying:
- Database schema
- Annotated providers
- Freezed classes

```bash
# Watch mode (auto-regenerate on changes)
flutter pub run build_runner watch

# One-time build
flutter pub run build_runner build
```

### Testing

**Client tests**:
```bash
cd client
flutter test
```

Tests live in `client/test/`, mirroring `lib/` (`core/`, `data/`, `domain/`, `widgets/`). Three environment quirks come up repeatedly and are worth knowing before debugging a confusing failure:

- **Images never finish loading under `pumpAndSettle`.** The binding's fake async does not advance a decode, so an image lays out zero-height and cannot be tapped. Precache inside `tester.runAsync` first (see `test/widgets/editor_image_embed_test.dart`).
- **`HttpClient` is stubbed to return 400 for every request.** Tests that talk to the app's own loopback server must set `HttpOverrides.global = null` (see `test/data/attachment_media_server_test.dart`).
- **Anything reaching a platform channel or the database needs `runAsync`** when driven from a widget test — the clipboard paste test wraps its key events for exactly this reason.

Quill's editor also needs `FlutterQuillLocalizations.delegate` on the test `MaterialApp`. Its HTML paste path throws `UnimplementedError` under the test binding — `quill_native_bridge` has no test implementation — so a test that pastes must install `ResilientClipboardService` the way `main()` does, or the throw takes the paste with it (see `test/widgets/editor_paste_test.dart`, which is exactly that regression).

**Server tests** live with the server, in the `noo-relay` repository.

### Building

**Linux Desktop** (Manual):
```bash
flutter build linux
```

Output: `build/linux/x64/release/bundle/`

**Linux AppImage** (Automated):
```bash
python scripts/build_linux.py
```

The build script (`scripts/build_linux.py`) provides automated AppImage creation:
- `--release`: Build in release mode (default)
- `--debug`: Build in debug mode
- `--skip-build`: Skip Flutter build, use existing bundle
- `--clean`: Clean build artifacts before building

Features:
- Automatic dependency checking (Flutter, appimagetool, native pkg-config libs)
- AppDir structure creation with proper desktop integration
- Automatic appimagetool download if not present
- Library path configuration for SQLCipher support
- GStreamer bundling for audio attachment playback (see below)

Output: `build/Noo-x86_64.AppImage`

**GStreamer in the AppImage.** Flutter's bundle ships only its own libraries, so
without help the AppImage would need `gstreamer1.0-plugins-*` installed on the
user's machine and audio attachments would fail at startup instead of at build
time. `bundle_gstreamer()` copies the plugins listed in `GST_PLUGINS` plus
`gst-plugin-scanner` into `usr/bin/lib/gstreamer-1.0/`, walks `ldd` recursively
to pull in their dependencies, and `AppRun` points `GST_PLUGIN_SYSTEM_PATH_1_0`
and friends at that directory. `GST_REGISTRY_1_0` is redirected to
`~/.cache/noo/` because the AppImage mount is read-only.

Two constraints shape which libraries travel with the build:

- `HOST_LIB_PREFIXES` keeps glib, GTK, GL, X11/Wayland, ALSA/PulseAudio and dbus
  coming from the host. Those are already loaded by the Flutter shell, and a
  second bundled copy is the standard way to make an AppImage that only runs on
  the distro it was built on.
- AAC/m4a decoding uses `faad`, not `libav`. `libav` would work, but it pulls in
  the whole FFmpeg stack — video encoders, Vulkan, OpenCL — for 208 MB against
  14 MB. Formats covered: mp3, wav, ogg/vorbis, opus, flac, m4a/aac.

`faad` ships in `gstreamer1.0-plugins-bad` and `mpg123` in `-ugly`. If a plugin
is missing on the build machine the script warns with the package to install and
continues, so a rebuild elsewhere degrades loudly rather than silently shipping
an AppImage that cannot play mp3.

**Windows Desktop** (Manual):
```bash
flutter build windows
```

Output: `build/windows/x64/runner/Release/`

**Android AAB/APK** (Automated):
```bash
python scripts/build_android.py
```

- `--release` / `--debug`: build mode (release is the default)
- `--apk`: also build a universal APK alongside the AAB
- `--clean`: clean Android build artifacts first

Release signing, the Play Store checklist and store assets live in
`docs/PLAY_RELEASE.md`; the port's design notes are in `docs/ANDROID_PORT.md`.

**Windows ZIP** (Automated):
```bash
python scripts/build_windows.py
```

The build script (`scripts/build_windows.py`) provides automated ZIP archive creation:
- `--release`: Build in release mode (default)
- `--debug`: Build in debug mode
- `--skip-build`: Skip Flutter build, use existing bundle
- `--no-clean`: Keep previous build artifacts (unlike the Linux script, this one cleans by default and has no `--clean`)

Features:
- OpenSSL/vcpkg library configuration (OPENSSL_ROOT_DIR)
- Distributable ZIP with all DLLs and data directory
- Version extraction from pubspec.yaml
- Also copies the ZIP to `scripts/releases/`

Output: `build/noo-{version}-windows-x64.zip`. The unzipped app is in `build/windows_dist/noo/`. The ZIP is attached to the GitHub release; Check for Update on Windows only links to it.

### Releasing

Cutting a release — the signing key, the download host, the GitHub release and
how the public repository is regenerated — is documented in `docs/RELEASING.md`.
Nothing a build script writes to `scripts/releases/` is downloadable by anyone
until a publish step runs, which is what keeps a local test build off the web.

Work happens on `master`, which tracks `origin/master` and is **never pushed
to GitHub**. What is published — the `github` branch here, `main` on GitHub —
is **generated** from it: one squashed commit with no history, rebuilt and
force-pushed by `scripts/publish_public.py`, so anything committed to it is
discarded on the next publish. `docs/RELEASING.md`, the publishing scripts and
`scripts/hooks/pre-push` (the guard against pushing `master` to GitHub —
install it in every checkout) are withheld from the snapshot; no code is.

---

## Sync Server

The centralized relay lives in its own repository, **`noo-relay`** (checked out
alongside this one as `../relay`). It is a Go zero-knowledge server: it
stores only encrypted opaque blobs, never sees plaintext, and contains no sync logic.
All encryption, decryption, packaging, and conflict resolution happen here, on the
client. Running it, its schema, its env vars, and its deployment are documented there.

What the client needs to know about it:

- **Protocol v2**, `/api/v2/…` — per-device packet streams with client-assigned
  contiguous counters, exchanged via version vectors. There is no server-assigned
  global sequence. Specified in [docs/P2P_SYNC.md](docs/P2P_SYNC.md); the retired v1
  wire format, whose merge semantics v2 keeps unchanged, is in
  [docs/RELAY_PROTOCOL.md](docs/RELAY_PROTOCOL.md).
- **Endpoints the client calls**: `auth/register`, `auth/login`, `auth/refresh`,
  `devices/` (list, register, delete), `changes/vector`, `POST changes/` (headers
  `X-Noo-Origin-Device`, `X-Noo-Counter`, and `X-Noo-Snapshot-Covers` when
  compacting), `GET changes/?have={vector}&limit={n}`, `changes/usage` for the
  storage panel, `GET changes/hashes?device={id}&from={n}&to={n}` for stream
  verification (§3.3), `PUT`/`HEAD`/`GET blobs/{id}` for attachment blobs
  (§3.5; `POST changes/` declares a packet's blobs in `X-Noo-Blobs`), and
  `/health` for the connection test.
- **Compaction** (`docs/P2P_SYNC_COMPACTION.md`): a snapshot upload declares the
  packets it supersedes and the relay deletes them. Both sides keep per-device
  high-water marks separately from the packets, so pruning never lowers "what comes
  next"; on the client that mark is `max(stored counter, adopted coverage)`, which is
  what `NooDatabase.getSyncVector` and `maxSyncCounterFor` return.
- **Auth**: JWT, 15-minute access token and 30-day refresh, obtained with the *server*
  password (distinct from the database password — see [Sync Security](#sync-security)).
- The relay is one of two transports. LAN peer sync (`docs/P2P_SYNC.md`) runs
  concurrently and either path alone eventually converges every device.

Client-side implementation: `client/lib/data/services/sync_service.dart`,
`sync_api_client.dart`, `sync_crypto.dart`, `sync_change_packager.dart`.

---

## Database Security

### Encryption
- Uses SQLCipher for at-rest encryption
- Password-based key derivation
- Encrypted database files
- No plaintext data on disk

### Password Management
- Required on database creation
- Prompted on database open
- Optional secure password storage using platform keychain:
  - Linux: Secret Service API (GNOME Keyring / KWallet)
  - macOS: Keychain Services
  - Windows: DPAPI-encrypted file in Roaming AppData (legacy Credential Manager entries auto-migrated)
- User-controlled via "Remember password" setting in Preferences
- Saved password auto-cleared on authentication failure

### Sync Security

Two separate secrets per user:
1. **Database password** — encrypts local SQLCipher DB AND derives the AES-256-GCM sync key via HKDF-SHA256. Must be identical on all devices.
2. **Server password** — authenticates with relay server (JWT login). Stored in platform keychain. Separate from DB password.

| Concern | Solution |
|---------|----------|
| Encryption | AES-256-GCM (authenticated encryption) |
| Key derivation | HKDF-SHA256 from DB password, username as salt; two independent keys — `noo-sync-v2` for packet payloads, `noo-p2p-v2` for LAN peer auth |
| Nonce | 12 random bytes per blob, prepended to ciphertext |
| Integrity | GCM auth tag (128-bit) |
| Tamper detection | GCM tag + `{origin_device_id}:{counter}` as AAD, so a blob re-served under any other slot fails authentication |
| Replay prevention | Packet identity `(user, origin device, counter)` is UNIQUE on the relay — a re-upload is a no-op; a client pulls only what its version vector says it lacks |
| Server auth | JWT with bcrypt-hashed server password |
| Transport | HTTPS (TLS) in production |
| Fork detection | Every node stores `sha256` of each packet blob and can be asked for `{counter → hash}` over one device's stream. A device verifies its *own* recent stream against every node it talks to, so a restored backup that re-issues packet identities is caught at the exact counter where the streams parted — not only while its counter is still visibly behind (docs/P2P_SYNC.md §3.3) |
| Fork recovery | A restore that merely *lost* history (nothing re-issued, overlap verified identical) heals itself: the run packages nothing and pulls the missing packets back. A confirmed divergence is recovered by **Preferences → Sync → Reset device identity**, which takes a fresh `device_id`, drops the contested packets, and republishes the whole database as one full-state snapshot that merges everywhere by ordinary LWW (§3.4) |
| Zero-knowledge | Relay sees only: user_id, origin device_id, counter, content hash, stored-at timestamp, encrypted blob, size |

### MCP Security

The MCP server hands the whole outline in plaintext to whatever connects, so the boundary is worth stating plainly.

| Concern | Solution |
|---------|----------|
| Off by default | Nothing binds a socket until the user enables it in Preferences → MCP |
| Reachability | `127.0.0.1` only — never `anyIPv4`, unlike the LAN peer server |
| Authentication | Bearer token, 32 random bytes from `Random.secure()`, compared in constant time |
| Token storage | Platform keychain only (`SecureStorageKeys.mcpToken`), never SharedPreferences — on desktop that is a world-readable JSON file |
| Revocation | Regenerate in Preferences; takes effect on the next request without rebinding the socket |
| DNS rebinding | `Origin` validated against exact hosts; a present, non-loopback origin is 403 |
| Scope of damage | Read-only mode withholds every write tool, in `tools/list` and in `tools/call` |
| Scope of exposure | Branches marked `TaskFlags.mcpExcluded` are withheld from every tool, reads and writes alike; the flag syncs, so the branch stays hidden on the user's other devices |
| Lifetime | Bound only while a database is open and unlocked; a lock, swap or close unbinds it |
| Audit | Rejected requests are counted and shown in the preferences tab |

**Loopback is not privacy.** Any process running as this user can reach the port — the same assumption the attachment media server documents — so the token is the entire boundary. Unlike that server's per-run token, this one is long-lived by design, because it lives in agent config files.

### Choosing excluded branches

`mcp_excluded_branches_dialog.dart` is a tree of the whole outline with a checkbox per task, opened from Preferences → MCP. Desktop gets the `AlertDialog` the other property sheets use; a phone gets the same content as a `Dialog.fullscreen` with close/check in an `AppBar`, matching `PreferencesDialog`.

- **Nothing is written until OK.** The flag is document data — it syncs, and the Preferences dialog's own Cancel restores *preferences*, not the outline — so a user who ticks four boxes and thinks better of it needs a way back that does not depend on the dialog behind this one. Only the boxes that actually moved are written, because each one is a history row and a change on the wire
- **A descendant of a hidden task is ticked and disabled**, labelled "hidden with parent". It *is* hidden, so an unticked box would be a lie; the flag doing the hiding belongs to the ancestor, so the way back is to untick that one. A node keeps its own flag underneath, and reappears hidden when the ancestor is revealed
- **Opens with the path to every hidden branch expanded**, and expands a branch as it is ticked — the question this dialog exists to answer is "what have I hidden", and a collapsed tree answers it with a blank screen
- Reads through `NooDatabase.getTaskOutline()`, not `getAllTasks()`: the latter carries `content`, which is the note body of every task in the database, read and decrypted to render a list of titles

**One token for the app, not per database.** An agent configured while `work.noo` was open will read `personal.noo` if the user switches. Per-database tokens would mean reconfiguring every agent on each switch, which nobody would do; the consequence is stated in the preferences tab instead, and the server names the open database file in its `initialize` instructions so an agent can tell which one it reached.

---

## Project Structure Details

### Entry Point
- `lib/main.dart`: Application entry, provider setup, SQLCipher initialization

### App Configuration
- `lib/app.dart`: MaterialApp configuration, theme, localization

### Core Utilities

**Duration Formatter** (`lib/core/utils/duration_formatter.dart`):
- Human-readable time formatting
- HH:MM:SS display
- Cumulative time displays
- `formatMediaPosition()`: player-style `1:02` / `1:03:20`, used by the attachment audio bar

**Attachment URI** (`lib/core/utils/attachment_uri.dart`):
- `attachmentUri(worldId)` / `attachmentWorldIdOf(url)`: the `noo-attachment://` scheme that lets task content reference an attachment's bytes (deliberately not `Uri.parse`, which would fold the worldId's case)
- `imageSourcesInContent(content)` / `attachmentRefsInContent(content)`: pull image references out of stored Delta JSON — used by the exporter and by the "is this image still referenced?" check before deleting an attachment

**Date Utils** (`lib/core/utils/date_utils.dart`):
- Date manipulation
- Range calculations
- Day/week/month boundaries

**Content Utils** (`lib/core/utils/content_utils.dart`):
- `extractPlaintext(content)`: Strip Quill Delta JSON or HTML to plain text (used by search and report generators)
- `extractSnippet(plaintext, query)`: Extract a context snippet around the first match of a search query

**Diff Utils** (`lib/core/utils/diff_utils.dart`):
- Text diff computation using diff_match_patch
- `computeDiff()`: Generate patch between old and new text
- `applyDiff()`: Apply patch to reconstruct new text (used by history chain replay)
- `isPatch()`: Whether a stored history value is a patch (dmp hunk header) or a full value
- Diff fields are title and content (`shouldUseDiff`)

**Theme** (`lib/core/theme/app_theme.dart`):
- Light theme definition
- Dark theme definition
- Color schemes
- Typography

### Error Handling
- `lib/core/errors/exceptions.dart`: Custom exception types
- Database exceptions
- Validation exceptions
- Not found exceptions

---

## Future Enhancements

### Planned Features
1. **iOS Support**: iOS build (Android has shipped — see Platform Support)
2. **Tags/Labels**: Task categorization
3. **Recurring Tasks**: Scheduled task creation
4. **Notifications**: Task reminders
5. **Collaboration**: Shared task trees
6. **Plugin System**: Extensibility framework

### Sync Hardening (Future)
1. Large file attachment handling (streaming/chunking)
2. Retry with exponential backoff
3. Offline queue (sync when connectivity returns)
4. Per-user storage quotas on server

### Platform Support
- **Linux**: Shipped (AppImage via `scripts/build_linux.py`)
- **Windows**: Shipped (ZIP via `scripts/build_windows.py`)
- **macOS**: Shipped (`scripts/build_macos.py`)
- **Android**: Shipped (AAB/APK via `scripts/build_android.py`); pending Play
  Console submission — see `docs/PLAY_RELEASE.md`
- **iOS**: Not started
- **Web**: Not started (would need a local-storage persistence layer)

---

## Notes

### Design Decisions

1. **Clean Architecture**: Ensures testability, maintainability, and scalability
2. **WorldId**: Enables synchronization without database ID conflicts
3. **SQLCipher**: Privacy-first approach with encryption by default
4. **Lazy Loading**: Content loaded on-demand for performance
5. **Modification Tracking**: Optimistic updates with delta synchronization
6. **Tree Structure**: Unlimited nesting for flexible organization
7. **Riverpod**: Type-safe, compile-time checked dependency injection
8. **Change History**: Comprehensive audit trail for all entity modifications
9. **Diff-based Storage**: Title/content history rows store forward patches only; old values are reconstructed by replaying the chain (`HistoryService.reconstructTaskFieldChain` — the history viewer uses this). Diffs do NOT cross device boundaries — sync sends full values.
10. **Soft Delete**: All entities use a `removed` flag instead of hard deletion, enabling undo and sync
11. **BLOB Attachments**: Files stored as binary blobs directly in the encrypted database for portability
12. **Zero-Knowledge Sync**: Server never sees plaintext. AES-256-GCM with HKDF key derivation from DB password ensures only devices with the correct password can decrypt.
13. **Field-Level LWW Conflict Resolution**: Last-Writer-Wins applied per entity+field, not per entity. Allows concurrent edits to different fields of the same task without data loss. Concurrent edits to the *same* title/content field don't lose the older side either — it survives as a conflict-copy sibling task (docs/P2P_SYNC.md §8.3).
14. **Monotonic Sequence Numbers**: Server assigns per-user monotonic sequences to avoid clock-skew issues. Client timestamps inside encrypted payloads are used for conflict resolution.
15. **Coalescing**: Multiple changes to the same entity+field since last sync are collapsed into a single change carrying only the final value, reducing bandwidth.

### Qt Compatibility
The codebase includes comments referencing "Qt implementation", suggesting this is a Flutter port/reimplementation of an existing Qt-based application. Key compatibility:
- Task flags match Qt implementation, except `TaskFlags.mcpExcluded` (bit 2), which is Flutter-only — a Qt client neither sets nor understands it, but round-trips it, since `flags` travels as one integer
- Entity structure mirrors Qt classes
- WorldId concept preserved
- Database schema compatible

---

## Contributing

### Code Style
- Follow Dart style guide
- Use `flutter_lints` rules
- Document public APIs
- Write tests for new features

### Commit Guidelines
- Clear, descriptive commit messages
- Atomic commits (one feature/fix per commit)
- Reference issues when applicable

### Pull Request Process
1. Create feature branch
2. Implement changes with tests
3. Run code generation
4. Ensure all tests pass
5. Update documentation
6. Submit PR with description

---

## License

(License information not specified in current codebase)

---

## Contact & Support

For questions, issues, or contributions, please refer to the project repository.

---

**Last Updated**: 2026-09-24
**Version**: 1.2.8
**Database Schema Version**: 14
**Flutter Version**: 3.44.0+
**Dart Version**: 3.12.0+
**Python Version**: 3.10+ (build scripts)
