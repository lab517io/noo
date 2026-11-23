/// Links from one note to another task.
///
/// A reference is quill's ordinary `link` attribute on a run of text, with a
/// target of `noo-task://<task worldId>`:
///
/// ```json
/// {"insert": "Quarterly report", "attributes": {"link": "noo-task://<worldId>"}}
/// ```
///
/// The **worldId**, not the row id, for the reason `noo-attachment://` uses
/// one: row ids are device-local, and the note is synced. The text is the
/// target's title as it was when the link was made — a copy, so that search,
/// export and the MCP tools, which all read plain text, still see it; a
/// rename leaves the link working and the text as it was.
library;

import '../../l10n/l10n.dart';
import 'fold_case.dart';

const String kTaskLinkScheme = 'noo-task';

/// The prefix every task link starts with.
const String kTaskLinkPrefix = '$kTaskLinkScheme://';

/// The link target for the task identified by [worldId].
String taskLinkUri(String worldId) => '$kTaskLinkPrefix$worldId';

/// The task worldId [url] points at, or null when [url] is an ordinary link.
///
/// Not `Uri.parse`, which would fold the worldId's case — see
/// `attachmentWorldIdOf`.
String? taskLinkWorldIdOf(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (!trimmed.startsWith(kTaskLinkPrefix)) return null;
  final worldId = trimmed.substring(kTaskLinkPrefix.length);
  return worldId.isEmpty ? null : worldId;
}

/// What a link's text is when the task has no title — in the interface
/// language, since it becomes the user's own text in their note.
String get kUntitledTaskLinkText => appL10n.commonUntitled;

/// An unfinished `[[…` the caret stands at the end of.
class TaskLinkTrigger {
  /// Offset of the first `[`.
  final int start;

  /// What has been typed after the brackets, as typed.
  final String query;

  const TaskLinkTrigger(this.start, this.query);

  /// Offset just past the query — where the caret is.
  int get end => start + 2 + query.length;

  @override
  bool operator ==(Object other) =>
      other is TaskLinkTrigger && other.start == start && other.query == query;

  @override
  int get hashCode => Object.hash(start, query);

  @override
  String toString() => 'TaskLinkTrigger($start, "$query")';
}

/// The longest query a trigger may carry. Past it the brackets are taken for
/// ordinary text, so a stray `[[` does not cost a backwards scan of the whole
/// line on every keystroke after it.
const int kTaskLinkMaxQuery = 80;

/// The `[[query` ending at [caret] in [text], or null when the caret is not
/// in one.
///
/// The query runs from the nearest `[[` before the caret, on the same line,
/// with no `]` in between — a closed `[[…]]` is finished text, not a link
/// being typed. An embed (U+FFFC in a document's plain text) ends the scan
/// as a line break does.
TaskLinkTrigger? taskLinkTriggerAt(String text, int caret) {
  if (caret < 2 || caret > text.length) return null;
  final floor = caret - kTaskLinkMaxQuery - 2;
  for (var i = caret - 1; i >= 1 && i > floor; i--) {
    final c = text[i];
    if (c == '\n' || c == ']' || c == '￼') return null;
    if (c == '[' && text[i - 1] == '[') {
      return TaskLinkTrigger(i - 1, text.substring(i + 1, caret));
    }
  }
  return null;
}

/// A task that can be linked to, as the suggestion list shows it.
class TaskLinkTarget {
  final int id;
  final String worldId;
  final String title;

  /// Titles of the ancestors, outermost first, joined for display. Empty for
  /// a top-level task. Tells two tasks with the same title apart.
  final String path;

  const TaskLinkTarget({
    required this.id,
    required this.worldId,
    required this.title,
    this.path = '',
  });

  /// The text a link to this task is given.
  String get linkText {
    // A line break would split the link over two lines of the note.
    final text = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? kUntitledTaskLinkText : text;
  }
}

/// The [targets] matching [query], best first, at most [limit].
///
/// A title that starts with the query comes before one where the query starts
/// a later word, which comes before one that merely contains it; within each
/// group the order of [targets] — the outline's — is kept. An empty query
/// matches everything.
List<TaskLinkTarget> rankTaskLinkTargets(
  List<TaskLinkTarget> targets,
  String query, {
  int limit = 50,
}) {
  final needle = foldCase(query.trim());
  if (needle.isEmpty) return targets.take(limit).toList();

  final groups = [<TaskLinkTarget>[], <TaskLinkTarget>[], <TaskLinkTarget>[]];
  for (final target in targets) {
    final title = foldCase(target.title);
    final at = title.indexOf(needle);
    if (at < 0) continue;
    if (at == 0) {
      groups[0].add(target);
    } else if (_startsWord(title, needle)) {
      groups[1].add(target);
    } else {
      groups[2].add(target);
    }
  }
  return groups.expand((g) => g).take(limit).toList();
}

bool _startsWord(String title, String needle) {
  var at = title.indexOf(needle, 1);
  while (at > 0) {
    if (!_isWordChar(title.codeUnitAt(at - 1))) return true;
    at = title.indexOf(needle, at + 1);
  }
  return false;
}

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) || // 0-9
    (c >= 0x41 && c <= 0x5A) || // A-Z
    (c >= 0x61 && c <= 0x7A) || // a-z
    c > 0x7F; // anything beyond ASCII is taken for a letter
