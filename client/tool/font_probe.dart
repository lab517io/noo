// Dev-time probe. Asks the *real* engine what it makes of a font family name,
// which nothing in the test suite can answer: `flutter test` lays text out in
// a stub font, so every family looks the same there — and, being fixed-width
// itself, makes a proportional fallback look fixed-width too.
//
// A family the platform cannot resolve is not an error: Flutter falls back to
// the default font and lays the text out in it, so "Format as table" pads its
// columns correctly and they still do not line up. This prints what each
// family actually measures, which is the only way to tell.
//
//   flutter build linux --debug -t tool/font_probe.dart
//   xvfb-run -a ./build/linux/x64/debug/bundle/noo
//
// A family whose iii and WWW come out the same width is fixed-width; one that
// measures exactly like "(default)" did not resolve at all.
//
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:noo/core/constants/fonts.dart';

double _width(String text, String? family) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: family, fontSize: 20),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

/// How much ink a rendering lays down, as a fraction of the bitmap. A bold
/// face covers noticeably more than a regular one, which is the only way to
/// ask "is what I am getting actually bold?" — Flutter will not name the face
/// it resolved, and a weight it cannot satisfy is met with a synthetic one or
/// with whatever the platform had.
Future<double> _inkCoverage(String? family, FontWeight weight) async {
  const size = 40.0;
  final painter = TextPainter(
    text: TextSpan(
      text: 'Handgloves',
      style: TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        color: const Color(0xFF000000),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Offset.zero);
  final width = painter.width.ceil();
  final height = painter.height.ceil();
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData();
  if (data == null) return 0;

  var ink = 0;
  for (var i = 3; i < data.lengthInBytes; i += 4) {
    ink += data.getUint8(i); // alpha
  }
  return ink / (width * height * 255);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final families = <String?>[
    null,
    ...kCuratedFonts.whereType<String>(),
    'sans-serif',
    'serif',
    'Consolas',
    'Noto Sans Mono',
    'DejaVu Sans Mono',
    'Courier New',
    'Definitely Not A Font',
  ];

  final defaultNarrow = _width('iii', null);
  print('family                     iii     WWW   fixed-width?  resolved?');
  for (final family in families) {
    final narrow = _width('iii', family);
    final wide = _width('WWW', family);
    final fixed = (narrow - wide).abs() < 0.01;
    final resolved = family == null || (narrow - defaultNarrow).abs() > 0.01;
    print('${(family ?? '(default)').padRight(24)} '
        '${narrow.toStringAsFixed(1).padLeft(6)} '
        '${wide.toStringAsFixed(1).padLeft(6)}   '
        '${(fixed ? 'yes' : 'no').padRight(12)} '
        '${resolved ? 'yes' : 'no — fell back'}');
  }

  print('');
  print('ink laid down, regular vs bold — a family whose two are the same is '
      'giving you one face for both');
  print('family                   regular    bold   bold/regular');
  for (final family in <String?>[null, ...kMonospaceFonts, 'Noto Sans']) {
    final regular = await _inkCoverage(family, FontWeight.w400);
    final bold = await _inkCoverage(family, FontWeight.w700);
    print('${(family ?? '(default)').padRight(22)} '
        '${regular.toStringAsFixed(4).padLeft(7)} '
        '${bold.toStringAsFixed(4).padLeft(7)} '
        '${(bold / regular).toStringAsFixed(2).padLeft(8)}');
  }

  exit(0);
}
