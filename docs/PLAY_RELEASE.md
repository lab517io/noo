# Android release & Play Store checklist

*Written 2026-08-02 (Phase 5 of the Android port). Companion to
docs/ANDROID_PORT.md.*

## Signing

Play uses **Play App Signing**: Google holds the app signing key, you upload
bundles signed with an *upload key*. Generate one once and keep it out of
git (`client/android/.gitignore` already excludes `key.properties`, `*.jks`,
`*.keystore`):

```bash
keytool -genkeypair -v \
  -keystore ~/keys/noo-upload.jks \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Then create `client/android/key.properties`:

```properties
storeFile=/home/you/keys/noo-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

`client/android/app/build.gradle.kts` picks this up automatically; without
it, release builds fall back to the **debug** key (fine locally, rejected by
Play). `scripts/build_android.py` prints the signing certificate of every
artifact it produces — check it says your CN, not `CN=Android Debug`.

If the upload key is ever lost, Play App Signing allows an upload-key reset
(Play Console → Setup → App signing), so losing it is recoverable — unlike a
pre-Play-App-Signing signing key.

## Building

```bash
python scripts/build_android.py            # release AAB → build/ + scripts/releases/
python scripts/build_android.py --apk      # additionally a universal APK (sideloading)
```

Versioning: `client/pubspec.yaml` carries a plain `version: X.Y.Z` with no
`+N` build suffix. `versionName` is that string verbatim; `versionCode` is
derived from it in `client/android/app/build.gradle.kts` as
`X*10000 + Y*100 + Z` (so `1.2.2` → `10202`). **Play requires `versionCode >= 1`,
strictly increasing per upload** — bump `Z` (or `Y`/`X`) every time an AAB goes
to any Play track, internal testing included. Keep `Y` and `Z` under 100 or the
encoding overflows and ordering breaks; the Gradle build fails loudly if you do.

SDK levels (from Flutter 3.44 defaults + our overrides): `minSdk 24`,
`targetSdk 36`, `compileSdk 36`. Play's target-API floor (API 35 for updates
as of Aug 2026) is satisfied; it ratchets annually, so a routine Flutter
upgrade keeps this current.

The AAB ships `libsqlcipher.so` for arm64-v8a, armeabi-v7a, and x86_64 via
the sqlite3 build hooks; Play serves each device only its own ABI.

## Play Console checklist

One-time app setup:

- [ ] Create app (io.lab517.noo), accept Play App Signing.
- [ ] **Privacy policy URL** — required for every app. Needs a public page;
      the strong story: all data stays on-device in an encrypted database,
      optional sync goes only to a server the user configures, no analytics,
      no third-party SDKs that collect data.
- [ ] **Data safety form** (Policy → App content). Truthful answers for Noo:
      - Does your app collect or share user data? **No** for collection in
        the Play sense *if* the developer does not operate a default sync
        server; sync is user-configured and end-to-end encrypted (packets
        are AES-256-GCM, key HKDF-derived from the DB password — the relay
        cannot read content). If you preconfigure/operate noo.lab517.io as a
        suggested server, declare: "Personal info → User IDs" (relay
        username) and "App activity → Other user-generated content"
        (encrypted blobs), collected, encrypted in transit, user-deletable,
        not shared, not used for ads.
      - Data deletion: relay account/device deletion exists
        (`DELETE /api/v2/devices/…`; admin removal per DEPLOYMENT.md in the
        `noo-relay` repository).
      - No ads SDK, no analytics, no crash reporting → "No" everywhere else.
- [ ] **App content declarations**: ads (none), target audience (13+ /
      general, not child-directed), news app (no), COVID app (no),
      government app (no), financial features (none), health (none).
- [ ] Content rating questionnaire (IARC) — utility/productivity, no UGC
      visible to others → Everyone.
- [ ] App category: Productivity. Contact email.
- [ ] **Permissions**: only `INTERNET` and `USE_BIOMETRIC` — neither is a
      sensitive/declared permission; no permission declaration form needed.

Listing assets (Store presence → Main store listing):

- [x] App icon 512×512 PNG — `docs/play-assets/icon-512.png`, rendered from
      `client/assets/icons/app_icon.svg` (the shipped PNG is only 256×256).
- [ ] Feature graphic 1024×500.
- [ ] ≥2 phone screenshots (16:9–9:16), e.g. task tree, editor with
      toolbar, timeline dialog, sync settings. Capture on the emulator with
      `adb exec-out screencap -p` (Block screenshots off).
- [ ] Short description (≤80 chars) / full description (≤4000).

Release flow:

- [ ] Internal testing track first: upload `noo-<version>-android.aab`,
      add tester emails, verify install + upgrade path (`versionCode`
      monotonicity) on a real device.
- [ ] Pre-launch report: Play runs the app on physical devices — watch for
      crashes on ABIs/API levels we haven't covered locally.
- [ ] Promote to production with staged rollout (e.g. 20%).

## Test matrix status (Phase 5)

| Item | Status |
|---|---|
| Emulator x86_64, API 36: full functional pass | done (Phases 0–4) |
| Rotation during edit | done 2026-08-02 — state survives |
| Process-death restoration ("Don't keep activities") | done 2026-08-02 — DB + timer survive, biometric gate re-arms |
| minSdk (API 24) emulator pass | **open** — needs an API 24 x86 image |
| Physical arm64 device (incl. SQLCipher spike `client/lib/spike/cipher_check.dart`) | **open** — no device on this machine |
| Large-DB performance | **open** — generate a few thousand tasks and profile tree + search |

## CI

The repo intentionally has no CI service config (releases are the
`scripts/build_*.py` family, run locally). `build_android.py` follows that
pattern. If CI is added later, the Android job is:
`flutter pub get && flutter analyze && flutter test && python scripts/build_android.py`
with `key.properties` provisioned from a secret.
