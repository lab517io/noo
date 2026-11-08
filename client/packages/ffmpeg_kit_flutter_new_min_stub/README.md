# ffmpeg_kit_flutter_new_min (stub)

This package deliberately shadows the real `ffmpeg_kit_flutter_new_min` via
`dependency_overrides` in `client/pubspec.yaml`. It exists to keep ~57 MB of
ffmpeg native libraries out of the app.

## Why

`whisper_ggml` depends on `ffmpeg_kit_flutter_new_min` unconditionally, but uses
it from exactly one place: `WhisperAudioConvert`, constructed only inside
`Whisper.transcribe` — the *file* API. This app never calls that API. As
`lib/data/services/audio/whisper_service.dart` documents, it uses only the live
session and feeds it raw in-memory PCM, precisely to avoid ffmpeg.

The real package therefore contributed only dead weight: `libavcodec`,
`libavfilter`, `libavformat`, `libavutil`, `libswscale`, `libswresample` and
`libffmpegkit` across every ABI, roughly 57 MB of the Android bundle's native
payload, plus the equivalent iOS/macOS frameworks.

## Why a stub rather than an exclusion

Neither Gradle-level route works:

* Excluding the `com.antonkarpenko:ffmpeg-kit-min` artifact breaks compilation —
  `FFmpegKitFlutterPlugin.java` imports ~17 classes from it.
* Stripping the `.so` files with `packaging { jniLibs { excludes } }` compiles,
  but crashes on launch. `onAttachedToActivity` calls `registerGlobalCallbacks`,
  which touches `FFmpegKitConfig`, whose static initialiser loads the native
  library. `GeneratedPluginRegistrant` catches `Exception`, and an
  `UnsatisfiedLinkError` is an `Error`, so it is not swallowed.

Replacing the Dart package removes the Flutter plugin altogether: no registrant
entry, no Maven artifact, no `.so`, and one fewer plugin applying the external
Kotlin Gradle plugin.

## Behaviour

`FFmpegKit.execute` reports a plain failure return code, so `WhisperAudioConvert`
falls through to its "conversion error" branch and returns null. That is exactly
what the real package does on a machine without ffmpeg, which `whisper_ggml`
already handles.

## Maintenance

The surface below is everything `whisper_ggml` 2.6.0 touches. If a future version
uses more of the ffmpeg API, this stub stops compiling — a loud failure, which is
the intent. Re-check when upgrading `whisper_ggml`.
