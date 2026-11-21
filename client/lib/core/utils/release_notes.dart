/// What of a GitHub release's notes the update dialog shows.
///
/// The notes are written for the release page: a download table, fenced
/// commands for verifying a file, the APK's signing certificate. None of that
/// helps someone deciding whether to update from a 440px dialog, and the
/// dialog's Markdown renderer (`MarkdownText`) sets a code fence in monospace
/// and flattens a table, neither of which fits. [dialogReleaseNotes] keeps the
/// prose.
library;

/// Written by `scripts/publish_release.py` in front of the sections that
/// describe the release's files. An HTML comment, so GitHub does not show it.
/// The dialog shows only what comes before it.
const String kReleaseNotesFilesMarker = '<!-- noo:files -->';

final RegExp _heading = RegExp(r'^(#{1,6})\s');

/// The part of [body] worth showing in the update dialog.
///
/// Everything after [kReleaseNotesFilesMarker] is dropped. Whatever remains —
/// all of it, for a release published before the marker existed or with
/// hand-written notes — loses its fenced code blocks and tables, and then any
/// heading left with nothing under it. Blank runs are collapsed.
String dialogReleaseNotes(String body) {
  var text = body.replaceAll('\r\n', '\n');
  final marker = text.indexOf(kReleaseNotesFilesMarker);
  if (marker >= 0) text = text.substring(0, marker);

  // Fences and tables.
  final kept = <String>[];
  String? fence;
  for (final line in text.split('\n')) {
    final lead = line.trimLeft();
    if (fence != null) {
      if (lead.startsWith(fence)) fence = null;
      continue;
    }
    if (lead.startsWith('```') || lead.startsWith('~~~')) {
      fence = lead.substring(0, 3);
      continue;
    }
    if (lead.startsWith('|')) continue;
    kept.add(line.trimRight());
  }

  // Headings whose section is now empty. A section runs to the next heading
  // of the same or a higher level, so a heading over non-empty subsections
  // stays.
  final lines = <String>[];
  for (var i = 0; i < kept.length; i++) {
    final line = kept[i];
    final match = _heading.firstMatch(line);
    if (match == null) {
      lines.add(line);
      continue;
    }
    final level = match.group(1)!.length;
    var empty = true;
    for (var j = i + 1; j < kept.length; j++) {
      final next = _heading.firstMatch(kept[j]);
      if (next != null && next.group(1)!.length <= level) break;
      if (kept[j].trim().isNotEmpty) {
        empty = false;
        break;
      }
    }
    if (!empty) lines.add(line);
  }

  // Collapse blank runs.
  final out = StringBuffer();
  var blank = true;
  for (final line in lines) {
    if (line.trim().isEmpty) {
      blank = true;
      continue;
    }
    if (blank && out.isNotEmpty) out.write('\n');
    out.write(line);
    out.write('\n');
    blank = false;
  }
  return out.toString().trim();
}
