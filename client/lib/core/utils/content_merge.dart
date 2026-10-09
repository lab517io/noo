import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Three-way merge of task content (Quill Delta JSON).
///
/// [base] is the version both sides started from, [local] and [remote] the two
/// edits made on top of it without seeing each other. Each side's change is
/// taken as a Delta diff from [base]; the remote change is applied first and
/// the local one transformed over it (Quill's own OT), so formatting and
/// embeds merge as operations rather than as JSON text, which a textual merge
/// could leave unparseable.
///
/// Returns the merged content, or null when it cannot be merged safely:
/// - any side is not Delta JSON (legacy HTML rows, garbage), or
/// - the two edits touch overlapping text — both rewrote the same words, or
///   one deleted what the other was editing. OT would still produce *a*
///   result there, but an interleaving of two rewrites of one sentence reads
///   as damage; the caller keeps both versions whole instead.
///
/// Insertions at the same point are kept, the remote one first, when they can
/// be told apart: one of them breaks the line, or the point is the end of a
/// line, where the local one is moved onto a line of its own. That covers the
/// common case of two devices each appending to a note. Two insertions at one
/// point mid-sentence would run together, and are a clash.
String? mergeContent({
  required String? base,
  required String? local,
  required String? remote,
}) {
  try {
    final baseDoc = _parseDocument(base);
    final localDoc = _parseDocument(local);
    final remoteDoc = _parseDocument(remote);
    if (baseDoc == null || localDoc == null || remoteDoc == null) return null;

    final localChange = baseDoc.diff(localDoc);
    final remoteChange = baseDoc.diff(remoteDoc);
    final localSpans = _changedSpans(localChange);
    final remoteSpans = _changedSpans(remoteChange);
    if (_clashes(localSpans, remoteSpans)) return null;

    // Two insertions at one point are applied remote first and would run
    // together into one word. Where one of them breaks the line that is
    // harmless; at the end of a line the local text is moved onto a line of
    // its own; anywhere else the point is mid-sentence and nothing reads
    // right, so it is a clash after all.
    final baseText = _textOf(baseDoc);
    final splitAt = <int>{};
    for (final l in localSpans.where((s) => s.inserted != null)) {
      for (final r in remoteSpans.where((s) => s.start == l.start)) {
        if (l.inserted!.startsWith('\n')) continue;
        final remoteText = r.inserted;
        // A remote replacement starting here puts its new text in front of
        // the local insertion, and its deletion after — the insertion lands
        // in the wrong place as well as running into the remote text.
        if (remoteText == null) return null;
        if (remoteText.endsWith('\n')) continue;
        if (baseText[l.start] != '\n') return null;
        splitAt.add(l.start);
      }
    }
    final localOverRemote = remoteChange.transform(
      splitAt.isEmpty
          ? localChange
          : _breakLines(localChange, splitAt, baseDoc),
      true,
    );

    final merged = baseDoc.compose(remoteChange).compose(localOverRemote);
    if (!_isDocument(merged)) return null;
    return jsonEncode(merged.toJson());
  } catch (_) {
    // Delta operations assert on malformed input; anything that throws is
    // simply not mergeable.
    return null;
  }
}

/// Parses stored content as a document delta. Empty content is the empty
/// document, as the editor treats it; anything that is not Delta JSON is null.
Delta? _parseDocument(String? content) {
  if (content == null || content.trim().isEmpty) {
    return Delta()..insert('\n');
  }
  final trimmed = content.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return null;
  final decoded = jsonDecode(trimmed);
  if (decoded is! List) return null;
  final delta = Delta.fromJson(decoded);
  return _isDocument(delta) ? delta : null;
}

/// A document delta holds only inserts and ends in a newline.
bool _isDocument(Delta delta) {
  if (delta.isEmpty) return false;
  if (!delta.toList().every((op) => op.isInsert)) return false;
  final last = delta.last.data;
  return last is String && last.endsWith('\n');
}

/// A range of [base] a change touches: `[start, end)`, or a point
/// (`start == end`) for a pure insertion, which carries the text it inserts
/// (an embed reads as one placeholder character).
typedef _Span = ({int start, int end, String? inserted});

/// The document's text with each embed as one character, so offsets match
/// Delta lengths.
String _textOf(Delta doc) => doc
    .toList()
    .map((op) => op.data is String ? op.data as String : '\u0000')
    .join();

/// The base ranges [change] deletes, reformats or inserts into, with adjacent
/// pieces joined — a replacement is a delete and an insert at one spot, and
/// is one edit. Only a span that is nothing but an insertion keeps its text.
List<_Span> _changedSpans(Delta change) {
  final spans = <_Span>[];
  void add(int start, int end, String? inserted) {
    if (spans.isNotEmpty && spans.last.end >= start) {
      final last = spans.removeLast();
      final point = last.start == last.end && start == end;
      spans.add((
        start: last.start,
        end: end > last.end ? end : last.end,
        inserted: point ? '${last.inserted}$inserted' : null,
      ));
    } else {
      spans.add((start: start, end: end, inserted: inserted));
    }
  }

  var pos = 0;
  for (final op in change.toList()) {
    final length = op.length!;
    if (op.isInsert) {
      add(pos, pos, op.data is String ? op.data as String : '\u0000');
    } else if (op.isDelete) {
      add(pos, pos + length, null);
      pos += length;
    } else {
      if (op.attributes?.isNotEmpty ?? false) add(pos, pos + length, null);
      pos += length;
    }
  }
  return spans;
}

/// [change] with a line break put in front of what it inserts at each base
/// offset in [at]. Every such offset sits on a newline of [base]; the new one
/// copies its attributes, so the line it closes keeps its list, header or
/// alignment and the original newline goes on closing the inserted text.
Delta _breakLines(Delta change, Set<int> at, Delta base) {
  final result = Delta();
  var pos = 0;
  final broken = <int>{};
  for (final op in change.toList()) {
    if (op.isInsert && at.contains(pos) && broken.add(pos)) {
      result.insert('\n', _attributesAt(base, pos));
    }
    result.push(op);
    if (!op.isInsert) pos += op.length!;
  }
  return result;
}

Map<String, dynamic>? _attributesAt(Delta doc, int offset) {
  var pos = 0;
  for (final op in doc.toList()) {
    final length = op.length!;
    if (offset < pos + length) return op.attributes;
    pos += length;
  }
  return null;
}

bool _clashes(List<_Span> a, List<_Span> b) {
  for (final x in a) {
    for (final y in b) {
      if (_overlap(x, y)) return true;
    }
  }
  return false;
}

bool _overlap(_Span x, _Span y) {
  final xPoint = x.start == x.end;
  final yPoint = y.start == y.end;
  if (xPoint && yPoint) return false;
  if (xPoint) return y.start < x.start && x.start < y.end;
  if (yPoint) return x.start < y.start && y.start < x.end;
  return x.start < y.end && y.start < x.end;
}
