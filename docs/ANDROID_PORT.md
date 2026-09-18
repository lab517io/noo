# Plan: Porting Noo to Android

*Drafted 2026-07-31. Status: Phases 0–5 complete (2026-08-02) — see findings
below. Remaining before a Play upload: generate the real upload keystore,
physical arm64 device pass, Play Console setup (docs/PLAY_RELEASE.md).*

## Phase 5 findings [impl]

- **Release signing** (`android/app/build.gradle.kts`): reads
  `android/key.properties` when present (gitignored by the template along
  with `*.jks`/`*.keystore`), otherwise falls back to debug keys so
  `flutter run --release` keeps working. Verified end-to-end with a
  throwaway keystore: the produced AAB was signed by its CN, not
  `CN=Android Debug`.
- **`scripts/build_android.py`** follows the `build_linux.py` conventions:
  release AAB (plus `--apk` for a universal sideload APK) → `build/` and
  `scripts/releases/` as `noo-<version>-android.aab`. It prints the signing
  certificate of every artifact (extracted from the bundle's signature
  block) so a debug-signed "release" can't slip through, and warns up front
  when `key.properties` is missing. Sets `GRADLE_USER_HOME=~/.gradle-noo`
  by default (stale-proxy workaround on this machine; harmless elsewhere).
- **versionCode**: pubspec was `1.2.1+0` — build number 0 maps to
  `versionCode 0`, which Play rejects. Superseded since: the `+N` suffix was
  dropped in favour of a plain `X.Y.Z`, with `versionCode` derived as
  `X*10000 + Y*100 + Z` in `app/build.gradle.kts` (a bare version would
  otherwise report `versionCode 1` forever). See docs/PLAY_RELEASE.md.
- **AAB verified** (75 MB): `libsqlcipher.so` present for arm64-v8a,
  armeabi-v7a, and x86_64 under `base/lib/`, with native debug symbols in
  `BUNDLE-METADATA` for Play crash symbolication. SDK levels: minSdk 24,
  target/compile 36 (Flutter 3.44 defaults) — above Play's current floor.
- **Play checklist** lives in docs/PLAY_RELEASE.md (signing how-to, data
  safety answers, listing assets, release flow). A 512×512 listing icon is
  pre-rendered at docs/play-assets/icon-512.png (the shipped PNG asset is
  only 256×256; the SVG source scales).
- **Test matrix run on emulator (API 36)**: rotation during edit — content
  and typed text survive a portrait↔landscape round trip; "Don't keep
  activities" — Home destroys the activity, reopening restores tree,
  selection, and a running timer; `am kill` (true background process death)
  — cold start, unlock, and the running timer resumes with correct elapsed
  time from the persisted start timestamp. Still open: API 24 emulator
  pass, physical arm64 device (incl. the SQLCipher spike), large-DB
  profiling.
- **No CI added deliberately** — the repo has no CI config for any
  platform; releases are the `scripts/build_*.py` family. The would-be CI
  recipe is noted at the end of docs/PLAY_RELEASE.md.

## Phase 4 findings [impl]

- **End-to-end sync verified on emulator (2026-08-02)** against a local relay
  (the `noo-relay` repository, uvicorn on :8080; the emulator reaches it as
  `http://10.0.2.2:8080`).
  Full pass: Android enrolls into an existing account (register → 409
  "username already exists" shown as an error in the Sync form, then login at
  sync time just works), bootstrap pull with an empty vector replays both
  desktop tasks (decryption proves the HKDF key from the shared DB password),
  a phone-created task round-trips back, and a concurrent-rename conflict
  converges to the newer edit on both sides (LWW).
- **Repeatable harness**: `test/e2e/relay_sync_e2e_test.dart` plays the
  desktop device with the real `SyncApiClient`/`SyncService` over HTTP.
  Skipped unless `NOO_E2E=1`; run one step at a time via
  `NOO_E2E_STEP=seed|verify_android|final` with `NOO_E2E_DIR` holding the
  file-backed DB between steps, driving the phone in between (see the file's
  doc comment).
- **Debug builds allow cleartext HTTP** (`src/debug/AndroidManifest.xml`,
  `android:usesCleartextTraffic="true"`) so the emulator can talk to a dev
  relay. Release builds keep the platform HTTPS-only default.
- **FLAG_SECURE ("Block screenshots", opt-in, off by default)**: a
  `MethodChannel` (`io.lab517.noo/secure_window`) in `MainActivity` adds/
  clears `WindowManager.LayoutParams.FLAG_SECURE`; `SecureWindow.apply` is
  called on settings load and on toggle. Verified live on emulator:
  `screencap` returns an all-black frame while enabled, normal capture after
  disabling.
- **Biometric unlock (opt-in, Android-only UI)**: `local_auth` 3.0.2 gates
  the remembered-password auto-unlock in `StartupScreen`
  (`BiometricGate.authenticate`); cancel/failure falls through to the
  password dialog without deleting the saved password. `MainActivity` now
  extends `FlutterFragmentActivity` (required), manifest adds
  `USE_BIOMETRIC`. Verified on emulator with a device PIN: prompt appears on
  launch (`mCurrentFocus=BiometricPrompt`), PIN unlocks without the password
  dialog, cancel lands on the password dialog. The checkbox is disabled until
  "Remember password" is on, and also while `BiometricGate.isAvailable()`
  (`isDeviceSupported()` — an *enrolled* biometric or a secure screen lock,
  hardware alone doesn't count) reports false; the hint then names the fix
  ("set up a fingerprint or screen lock in Android settings first") instead of
  looking like a bug. The probe runs on each dialog open rather than being
  cached, so enrolling a fingerprint and coming back re-enables the setting.
  `biometricOnly` stays false by product decision: BiometricPrompt keeps its
  "Use PIN" button, so a wet or unreadable finger falls back to the screen lock
  rather than forcing the database password to be retyped — the screen lock is
  the same trust level as the Keystore entry it protects.
- **local_auth 3.x error contract**: failures surface as `LocalAuthException`
  (`userCanceled`, `timeout`, …), *not* `PlatformException` — an uncaught
  cancel left the app stuck on the startup loading screen. `BiometricGate`
  catches both and fails closed. `persistAcrossBackgrounding` (stickyAuth)
  stays false — a startup gate has nothing to keep alive across app switches.
- **Emulator testing notes**: the BiometricPrompt/keyguard window is itself
  secure, so `screencap` shows black while it is up — check
  `adb shell dumpsys window | grep mCurrentFocus` instead; set a PIN with
  `adb shell locksettings set-pin 1111`; the credential screen needs two
  Back presses to cancel (the first is consumed by its input field); and
  `adb shell input text` drops everything after a space — use `%s`.
- Still open from earlier phases: physical arm64 device check of the
  SQLCipher spike.

## Phase 3 findings [impl]

- **Pause lifecycle** (`app.dart`): on mobile an `AppLifecycleListener.onPause`
  runs best-effort persistence — flush the editor's debounced auto-save,
  `PRAGMA wal_checkpoint(TRUNCATE)`, and (when sync-on-exit is enabled) a
  silent push of pending changes. Tracking sessions are deliberately left
  running.
- **Timer survives process death, verified**: started tracking, `am
  force-stop`, relaunch, unlock — the session resumed from the persisted
  open-ended record and the elapsed time landed in the time report (2m).
- **Share/open plumbing** (`core/utils/share_utils.dart`, share_plus 12 /
  open_filex / archive): everything that "saved to a path" on desktop now
  stages under the temp dir and goes through the system share sheet on
  mobile. Time Report "Save…" → "Share…"; attachment "Export" → "Share",
  plus a new "Open" action (tap = open in another app via open_filex, with
  a snackbar fallback when nothing handles the type).
- **Obsidian on mobile is zip-based**: export builds the vault in the temp
  dir, zips it (`archive`), and shares (verified: valid archive, correct
  vault layout including timeline.txt); import picks a `.zip`, extracts to
  the temp dir (descending into a single wrapping folder if present), and
  runs the normal importer (verified round-trip on emulator). Desktop keeps
  the directory flows.
- share_plus is held at 12.x (13 needs win32 6, blocked by the file_picker
  pin; same story as the other win32 holds in pubspec).
- **Deferred** (per plan, optional): foreground-service notification while a
  timer runs; `FLAG_SECURE` and biometric unlock belong to Phase 4.

## Phase 1–2 findings [impl]

- **Phase 1 needed no code changes.** `usesCustomTitleBar` and `registerApp()`
  already exclude Android, `main.dart`'s `isDesktop` guard keeps
  window_manager/single-instance dormant, and none of the desktop plugins
  break plugin registration.
- **Responsive layout is in** (`lib/core/utils/platform_info.dart`):
  `isCompactLayout` (<600dp) switches `MainScreen` between the desktop
  split view and a phone layout — `AppBar` (database name, search toggle,
  sync, overflow menu with the menu-bar actions) over a full-width tree,
  with a full-screen `TaskEditorScreen` pushed when a task is tapped
  (`_DraggableTreeTile.onOpen`, fired on a completed tap so scrolls/drags
  don't navigate; system back returns). Wide-on-mobile (tablets) keeps the
  menu-bar layout inside a `SafeArea`.
- **Touch affordances:** long-press on a tree node opens the same context
  menu as right-click (rename / add child / delete).
- **Dialog keyboard overflow fixed** with `scrollable: true` on
  `PasswordDialog`; the compact status bar drops the database path (the app
  bar already shows the file name) so node path + tracking controls + sync
  fit.
- Verified on emulator: create DB → create/rename task → edit content →
  navigate back → relaunch → unlock → everything persisted. `flutter test`
  (47) and the Linux release build stay green.
- **Phase 2 leftovers, all done (2026-08-01):**
  - Theme switching: "Theme..." in the compact overflow menu opens a
    System/Light/Dark radio dialog (`_showThemePicker`); applies live.
  - Preferences renders as a `Dialog.fullscreen` page under the compact
    breakpoint (close = cancel, check = OK; same tabs and snapshot/cancel
    semantics, system back still cancels via the existing PopScope).
  - Timeline dialog sizes itself to the screen (was fixed 500×400); Time
    Report stacks its controls pane above the preview on phones and wraps
    its footer buttons (was a fixed 380px pane + one-line footer).
  - Touch drag-to-reorder: on mobile the whole-tile `Draggable` is replaced
    by a trailing `drag_indicator` handle (a tile-wide immediate drag would
    win the arena against list scrolling); drop zones unchanged. Verified
    on emulator including drop-inside (reparent).
  - Search-result taps push the full-screen editor in compact layouts.
  - Quill editing with the soft keyboard verified on emulator: toolbar stays
    put, content resizes above the keyboard, text lands in the document.

## Phase 0 findings [impl]

- **SQLCipher via build hooks works on Android.** The debug APK ships
  `libsqlcipher.so` for `arm64-v8a`, `armeabi-v7a`, and `x86_64`;
  `PRAGMA cipher_version` returns `4.17.0 community` on the emulator, and an
  encrypted create → reopen → wrong-key-rejected round trip passes
  (`lib/spike/cipher_check.dart`, run with `flutter run -t`). Still to do on a
  physical arm64 device.
- **AGP is pinned to 8.13.2** (`android/settings.gradle.kts`), not the
  template's 9.0.1: on AGP 9, `file_picker` 11.x skips the external Kotlin
  plugin (assumes built-in Kotlin, which the Flutter template disables) while
  `flutter_keyboard_visibility_temp_fork` applies it (forbidden when built-in
  Kotlin is on) — no Kotlin setting satisfies both. Gradle wrapper is 8.14.3
  to match. Revisit when both plugins support AGP 9.
- **Smoke test passed end-to-end:** welcome screen → set password → main
  screen → create task → force-stop → password prompt → data intact. No
  desktop-plugin crashes at startup (the `isDesktop` guards held). Observed
  Phase 2 issues: the password dialog overflows by 155 px with the soft
  keyboard up, the desktop menu bar overlaps the system status bar, and the
  splitter layout is unusable on a phone — all expected UX-shell work.
- `minSdk` is set to 24, `allowBackup=false` and `INTERNET` are in the
  manifest.

## Starting point

Most of the stack is already Android-compatible: `drift`, `flutter_riverpod`,
`flutter_secure_storage` (uses Android Keystore), `shared_preferences`,
`path_provider`, `file_picker`, `flutter_quill`, `package_info_plus`, and the
sync layer (pure `http` + crypto) all support Android. The clean architecture
split means the domain and data layers should port nearly untouched. The work
concentrates in three areas: **the SQLCipher build**, **desktop-only
plumbing**, and **the UI/UX shell**.

## Phase 0 — De-risking spike (do this first)

1. **Verify SQLCipher via Dart build hooks on Android.** The single biggest
   technical risk. `pubspec.yaml` selects SQLCipher through
   `hooks.user_defines.sqlite3.source: sqlcipher`, and the old
   `sqlcipher_flutter_libs` plugin is EOL. Build hooks (native assets) on
   Android are new territory — confirm the hook fetches/builds the SQLCipher
   code asset for `arm64-v8a` (and decide whether to ship
   `armeabi-v7a`/`x86_64`), and that `PRAGMA cipher_version` passes on a real
   device. If this fails, the whole port strategy needs rethinking, so spike it
   before anything else.
2. **Scaffold the platform:** `flutter create --platforms=android .` in
   `client/`, set the application ID (e.g. `io.lab517.noo` to match the
   single-instance identifier), minSdk (24+ is a sensible floor), and target
   the current Play-required SDK.
3. **Smoke test:** launch on an emulator, create an encrypted DB, reopen it.
   Expect crashes from desktop plugins — that's Phase 1's worklist.

## Phase 1 — Make it run correctly

- **Gate desktop-only code.** `main.dart` already guards on `isDesktop`, but
  verify `window_manager`, `windows_single_instance`, and
  `unix_single_instance` don't break the Android build at
  compile/plugin-registration time; move them behind conditional imports if
  they do. Single-instance enforcement is a non-issue on Android (Activities
  handle this).
- **`registerApp()`** (`lib/platform/app_registration.dart`) becomes a no-op
  on Android — the launcher entry comes from the manifest.
- **Custom title bar / resize edges** (`window_title_bar.dart`, `app.dart`):
  skip entirely on mobile; Android provides the system chrome.
- **Database location:** `getApplicationDocumentsDirectory()` already works
  (app-private storage). The CLI-args DB path feature doesn't apply; later,
  "open DB from file" could arrive via an ACTION_VIEW intent filter.
- **Manifest hardening:** set `allowBackup=false` (Android auto-backup would
  restore the encrypted DB without its Keystore-held password — an
  inconsistent, confusing state), add `INTERNET` permission, and decide the
  cleartext-HTTP policy for the sync server (recommend requiring HTTPS;
  otherwise a network security config is needed).

## Phase 2 — Mobile UX adaptation (the bulk of the visible work)

- **Responsive layout.** `main_screen.dart` is a fixed splitter with tree +
  editor side by side. Introduce a breakpoint (~600dp): phones get a single
  pane with navigation (tree → tap task → editor screen, system back returns);
  tablets/landscape keep the split view. The largest UI refactor, but the
  panels (`TaskTreePanel`, `TaskEditorPanel`, `SearchPanel`) are already
  separate widgets, which helps a lot.
- **Menu & status bar.** Replace the desktop menu bar with an `AppBar` +
  overflow menu (and possibly a drawer for file/database actions). The
  status-bar items need a mobile home — bottom bar or app-bar actions.
- **Touch interaction.** Right-click context menus → long-press menus on tree
  nodes; drag-to-reorder with touch handles; comfortable hit targets; keep
  keyboard `Shortcuts` (they still work with hardware keyboards, just aren't
  the primary path).
- **Editor.** Verify the Quill toolbar works with the on-screen keyboard
  (toolbar pinned above keyboard is the usual pattern); handle viewport
  insets.
- **Dialogs.** Preferences, sync settings, time reports: convert to
  full-screen dialogs or bottom sheets under the phone breakpoint. Support
  predictive back.

## Phase 3 — Android lifecycle & files

- **Process death.** Android kills backgrounded apps freely. Verify time
  tracking stores the start *timestamp* in the DB (not in-memory elapsed time)
  so a running timer survives; flush/checkpoint the DB and optionally autosync
  on `AppLifecycleState.paused` — the desktop "shutdown sequence on close" has
  no Android equivalent, pause is the only reliable hook.
- **Optional (recommended follow-up):** a foreground service notification
  while a timer runs, with a stop action — the idiomatic Android affordance
  for time trackers, but not required for a first release since timestamps
  persist.
- **Attachments.** Import via `file_picker` works; for viewing/exporting, add
  `share_plus`/`open_filex` (share sheet + open-with) since writing to
  arbitrary paths isn't a thing under scoped storage.
- **Obsidian export/import.** Trickiest file feature: writing a vault
  directory tree needs SAF directory access (slow, awkward) — consider
  exporting/importing as a `.zip` via the share sheet on Android instead.
- **Time reports:** clipboard already works; replace "save to file" with the
  share sheet.

## Phase 4 — Security & sync polish

- End-to-end sync test: Android device ↔ relay server ↔ desktop, including
  first-device enrollment and conflict paths.
- Password remembering already maps to Keystore via `flutter_secure_storage`;
  consider biometric unlock (`local_auth`) as a natural follow-up.
- Consider an opt-in `FLAG_SECURE` (block screenshots/recents thumbnail) given
  the app's privacy positioning.

## Phase 5 — Release engineering

- Signing keystore + `key.properties`, AAB build, extend the
  `scripts/`/`build/` tooling and CI with an Android job.
- Play Store: data-safety form (local encrypted storage, optional self-hosted
  sync, no analytics — a strong privacy story), listing assets, and Play's
  current targetSdk requirement.
- Test matrix: minSdk emulator + arm64 physical device, rotation,
  process-death restoration (developer option "don't keep activities"),
  large-DB performance.

## Suggested milestones

| Milestone | Scope | Rough effort |
|---|---|---|
| M0 | SQLCipher spike + scaffold boots on emulator | days |
| M1 | Full functionality with desktop layout (ugly but working) | ~1 week |
| M2 | Phone-adapted UI (navigation, menus, dialogs, touch) | 2–3 weeks |
| M3 | Lifecycle, attachments/export, sync verified | ~1 week |
| M4 | Release pipeline + Play submission | ~1 week |

The critical path is M0: if the SQLCipher build hook doesn't produce Android
code assets, everything else waits on finding an alternative cipher delivery.
Everything after that is well-trodden Flutter ground.
