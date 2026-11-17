import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// How long the hint over a search match stays on screen, fade included.
const kSearchHintDuration = Duration(milliseconds: 2200);

/// Scrolls [scrollController] so the line holding [selection] sits near the
/// vertical centre of the editor's viewport, as far as the document allows.
///
/// Quill's own reveal scrolls only as far as needed, which puts a match
/// below the visible area on the bottom line — the last place the eye looks.
void centerSelection(
  RenderEditor render,
  ScrollController scrollController,
  TextSelection selection,
) {
  if (!scrollController.hasClients || !render.attached) return;
  final position = scrollController.position;
  final viewport = RenderAbstractViewport.maybeOf(render);
  if (viewport == null) return;

  final caret = render.getLocalRectForCaret(selection.base);
  // Where the editor's top currently sits in the viewport, plus the scroll
  // offset, is the editor's top in scroll-content coordinates.
  final editorTop = render.localToGlobal(Offset.zero, ancestor: viewport).dy;
  final caretInContent = position.pixels + editorTop + caret.center.dy;
  final target = (caretInContent - position.viewportDimension / 2)
      .clamp(position.minScrollExtent, position.maxScrollExtent);
  if ((target - position.pixels).abs() < 1) return;
  // A jump, not an animation — see QuillEditorWrapperState._applyReveal.
  scrollController.jumpTo(target);
}

/// The rectangles [selection] covers, in [render]'s coordinates — one per
/// visual line, since a match can wrap.
List<Rect> selectionRects(RenderEditor render, TextSelection selection) {
  final points = render.getEndpointsForSelection(selection);
  if (points.length < 2) return const [];
  final start = points.first.point;
  final end = points.last.point;
  final startHeight = render.preferredLineHeight(selection.base);
  final endHeight = render.preferredLineHeight(selection.extent);
  final width = render.size.width;

  // Same visual line: the endpoints share a baseline.
  if ((start.dy - end.dy).abs() < 1) {
    return [
      Rect.fromLTRB(math.min(start.dx, end.dx), start.dy - startHeight,
          math.max(start.dx, end.dx), start.dy),
    ];
  }
  return [
    Rect.fromLTRB(start.dx, start.dy - startHeight, width, start.dy),
    if (end.dy - endHeight > start.dy + 1)
      Rect.fromLTRB(0, start.dy, width, end.dy - endHeight),
    Rect.fromLTRB(0, end.dy - endHeight, end.dx, end.dy),
  ];
}

/// A short-lived glow around a search match: it starts a little larger than
/// the text, settles onto it and fades, so the eye is drawn to where the
/// caret landed without anything being left behind on the note.
///
/// Painted over the editor (never into the document — a highlight attribute
/// would be an edit, saved and synced) and measured afresh every frame, so it
/// follows the text while the centring scroll runs.
class SearchHintPainter extends CustomPainter {
  SearchHintPainter({
    required this.progress,
    required this.scroll,
    required this.rects,
    required this.color,
  }) : super(repaint: Listenable.merge([progress, scroll]));

  final Animation<double> progress;
  final ScrollController scroll;

  /// The match's rectangles in global coordinates, or empty when they cannot
  /// be measured (the editor gone, or the document changed under them).
  final List<Rect> Function() rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;

    // Fade in over the first 8%, hold, fade out over the last 45%.
    final opacity = t < 0.08
        ? t / 0.08
        : t > 0.55
            ? 1 - (t - 0.55) / 0.45
            : 1.0;
    // Starts loose around the text and closes in on it.
    final settle = Curves.easeOutCubic.transform((t / 0.3).clamp(0.0, 1.0));
    final inflate = 10 - 7 * settle;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final fill = Paint()..color = color.withValues(alpha: 0.22 * opacity);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.9 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final rect in rects()) {
      final r = RRect.fromRectAndRadius(
          rect.inflate(inflate), const Radius.circular(6));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SearchHintPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rects != rects;
}
