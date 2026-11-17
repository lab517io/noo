# F-Droid

Noo is built by F-Droid from the public repository (`lab517io/noo`), from the
recipe in [`fdroid/io.lab517.noo.yml`](../fdroid/io.lab517.noo.yml). That file
is a copy: the one F-Droid reads lives in
[fdroiddata](https://gitlab.com/fdroid/fdroiddata) as
`metadata/io.lab517.noo.yml`, and after the first merge F-Droid's bot keeps it
up to date from our tags by itself. Keep the copy here in step when the recipe
changes by hand.

The store listing — title, descriptions, icon, screenshots, per-release
changelog — comes from [`fastlane/metadata/android/en-US/`](../fastlane/metadata/android/en-US),
read from each tagged commit.

## One APK, one key, both channels

F-Droid ships **our** APK, signed with our key — the same file attached to the
GitHub release. That is F-Droid's reproducible-build mode, set by two lines of
the recipe:

```yaml
Binaries: https://github.com/lab517io/noo/releases/download/v%v/noo-%v-android.apk
AllowedAPKSigningKeys: 0eb42dbdecdbdd996ab12a79617d4e1015b482f0a78aa0912f5b020dac6cfffc
```

F-Droid still builds every release from source, unsigned. Then it downloads the
APK at `Binaries`, checks that its signer is the certificate above (ours,
`CN=Noo, O=lab517` — the key every GitHub APK since the first has carried), and
copies our signature onto its own build. If that copy verifies, the two are the
same bytes and it publishes ours; if not, **it publishes nothing for that
version** — there is no fallback to F-Droid's own key. A user can therefore
move between the GitHub APK and F-Droid without uninstalling, and updates from
either apply over the other.

So the GitHub APK must be byte-identical to F-Droid's build of the same tag, and
an ordinary `flutter build apk` is not: the native libraries embed the source
paths they were compiled at (`__FILE__`), and the Dart snapshot and Build IDs
change with the project and pub-cache paths. Measured: two builds of one commit
in different directories differ in 12 of 425 entries, all native.

`scripts/build_android_reproducible.py` makes it identical by not imitating
F-Droid's build but running it: fdroidserver at the commit fdroiddata's CI pins,
in F-Droid's buildserver image (`registry.gitlab.com/fdroid/fdroidserver:buildserver-trixie`),
from this recipe, at F-Droid's paths, on the committed tree at `--ref`. It then
signs the unsigned result on the host (APK Signature Scheme v2, as Gradle signs,
and `--alignment-preserved` — by default apksigner re-aligns every entry, which
is enough for F-Droid's signature copy to fail). Verified for 1.2.16:

- two independent runs give the same SHA-256 (`a770e610…`);
- fdroidserver's own `verify_apks` accepts run 1 signed against run 2 unsigned;
- all 24 native libraries stay uncompressed and 16 KB-aligned.

**When fdroiddata moves its CI to a new image or fdroidserver commit**
(`IMAGE`, `FDROIDSERVER_COMMIT` in the script, from fdroiddata's
`.gitlab-ci.yml`), move them here too, or the next release may not match.

Since the two channels are one file, nothing decided at build time can tell
them apart. Check for Update is hidden at run time instead, when an app store
installed the copy (`InstallSource`, `core/utils/install_source.dart`): F-Droid
and its clients, and Play. Play's own build stays separate — the AAB from
`build_android.py`, re-signed by Play App Signing — so a Play install cannot be
updated from either of the others.

## Why the build is acceptable to F-Droid

F-Droid builds everything from source and refuses prebuilt binaries outside a
short list of trusted repositories (Maven Central, Google's Maven, …). What that
took here:

- **SQLite** — compiled from `client/third_party/sqlite3mc` by `package:sqlite3`'s
  build hook, in SQLCipher 4 mode. Until 1.2.17 the hook downloaded a prebuilt
  SQLCipher from GitHub releases, which was the one blocker. See the `hooks:`
  section of `client/pubspec.yaml`.
- **ffmpeg-kit** — replaced by the stub in `client/packages/` (it ships prebuilt
  native libraries; this app never calls it).
- **whisper.cpp, libopus, libogg** — `whisper_ggml` and `voice_audio` compile
  them from their own sources with CMake.
- **No Google Play Services, Firebase or trackers.** `local_auth`,
  `flutter_secure_storage` and the rest use AndroidX only.

The recipe sets `PUB_CACHE` inside the build tree and `scandelete`s it, the usual
pattern for Flutter apps: F-Droid's scanner then sees the plugins' sources, and
deletes what it flags there (Gradle wrapper jars, iOS/macOS binaries) before the
build — none of which the Android build uses.

The recipe uses one NDK, Flutter's own (`28.2.13676358`). `whisper_ggml` pins
`29.0.13113456` in its own `build.gradle`; prebuild rewrites that to Flutter's
NDK, because fdroiddata's tooling accepts a single `ndk:` value.

Anti-features: none. The relay is optional, self-hosted and open source
(`lab517io/noo-relay`), and LAN sync needs no server at all. The whisper model is
downloaded only on the user's request, and it is data, not code.

## Releasing with F-Droid in the loop

F-Droid's bot checks the tags of the public repository, and for a new tag
`vX.Y.Z` reads two lines of `client/pubspec.yaml`: `version:` and
`# fdroid-version-code:`. With those it writes a new build entry and builds it,
usually within a few days.

It then downloads the APK from the GitHub release named in `Binaries`, so that
APK has to be there by the time F-Droid builds — attach it when the tag goes up.

So every release must:

1. **Bump both lines of `client/pubspec.yaml`** — `version: X.Y.Z` and
   `# fdroid-version-code: N`, where N = X·10000 + Y·100 + Z (the code Gradle
   derives). The Android build refuses to run when they disagree.
2. **Add `fastlane/metadata/android/en-US/changelogs/N.txt`** — what changed, at
   most 500 characters, plain text. Without it F-Droid shows no notes for that
   release.
3. **Build the APK with `build_android_reproducible.py --ref vX.Y.Z`** (or
   from the commit the tag will point at), never with `build_android.py --apk`
   — which now writes only a `-local.apk` to `build/`, so it cannot reach
   `scripts/releases/` by accident. The script is ~20 minutes and needs docker.
   Attach its `noo-X.Y.Z-android.apk` to the GitHub release.
4. **Publish with a tag that is new**: `publish_public.py --tag vX.Y.Z`. **Never
   move or delete a tag F-Droid has already built from.** F-Droid records the
   commit the tag pointed at; the public branch is rebuilt as a fresh orphan
   commit on every publish, so a tag is the only thing keeping a built commit
   reachable. A tag moved after the build leaves F-Droid's record pointing at a
   commit that may no longer exist, and a rebuild or verification fails.

A release whose Android build breaks F-Droid (a new plugin that downloads a
binary, a new non-free dependency), or whose GitHub APK does not match F-Droid's
build, will simply not appear there; the bot's
failure shows on [the app's build log](https://monitor.f-droid.org/builds) and in
fdroiddata's issues.

## Submitting (first time)

1. Fork <https://gitlab.com/fdroid/fdroiddata> on GitLab and create a branch
   named `io.lab517.noo`.
2. Copy `fdroid/io.lab517.noo.yml` to `metadata/io.lab517.noo.yml` there.
3. Check it: `fdroid readmeta && fdroid lint io.lab517.noo && fdroid rewritemeta io.lab517.noo`
   (`rewritemeta` must leave the file unchanged), then `fdroid build -v -l io.lab517.noo`
   in F-Droid's build container — or push and let the fork's CI run the same.
4. Commit as `New app: io.lab517.noo`, push, and open a merge request against
   `fdroid/fdroiddata`. Reviewers usually ask questions; answer them on the MR.
5. After the merge the app appears in the F-Droid client once the next build
   cycle has run and been signed — typically one to a few days.

### Testing the recipe locally

`python scripts/build_android_reproducible.py --no-sign` *is* the local test:
it runs `fdroid build` — scanner included — exactly as fdroiddata's CI does, and
leaves the unsigned APK in `build/noo-<version>-android-unsigned.apk`. To check
a signed APK against an F-Droid build the way F-Droid will, with fdroidserver
from pip:

```python
from fdroidserver import common
common.config = {'sdk_path': '<Android SDK>'}; common.fill_config_defaults(common.config)
common.verify_apks('noo-X.Y.Z-android.apk', 'noo-X.Y.Z-android-unsigned.apk', '/tmp/v')  # None = match
```
