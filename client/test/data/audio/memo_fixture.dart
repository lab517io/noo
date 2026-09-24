/// A real recording for tests to hand around.
///
/// `test/fixtures/memo-1s.opus` is a 440 Hz tone encoded exactly as the app
/// records: Ogg Opus, 16 kHz mono, 20 ms frames, 24 kbit/s VBR, pre-skip 312.
/// `opusinfo` reports it as 1.000 s.
///
/// Using a real file rather than a placeholder matters because these bytes go
/// where real memo bytes go — into an attachment row, out through sync, and
/// back into a decoder if something asks for a transcript. A stand-in would
/// pass the tests that only check plumbing and hide the ones that do not.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:noo/data/services/audio/voice_memo_recorder.dart';

/// Playable length of the fixture, as its container reports it.
const Duration kMemoFixtureDuration = Duration(seconds: 1);

Uint8List? _cached;

/// The fixture's bytes.
Uint8List memoFixtureBytes() =>
    _cached ??= File('test/fixtures/memo-1s.opus').readAsBytesSync();

/// The fixture as a capture, ready to be returned from a fake engine.
VoiceMemoCapture memoFixture({Duration? duration}) => VoiceMemoCapture(
      bytes: memoFixtureBytes(),
      duration: duration ?? kMemoFixtureDuration,
    );
