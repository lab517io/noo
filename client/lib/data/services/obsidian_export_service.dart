import 'dart:convert';
import 'dart:io';

import '../../core/utils/attachment_uri.dart';
import '../../core/utils/task_link.dart';
import '../database/database.dart';
import '../../l10n/l10n.dart';

/// Result of an Obsidian-format export operation.
class ObsidianExportResult {
  final bool success;
  final int tasksExported;
  final int timelineFilesExported;
  final int imagesExported;
  final String? error;

  const ObsidianExportResult({
    required this.success,
    this.tasksExported = 0,
    this.timelineFilesExported = 0,
    this.imagesExported = 0,
    this.error,
  });

  factory ObsidianExportResult.failure(String error) =>
      ObsidianExportResult(success: false, error: error);
}

/// Exports the database to an Obsidian-compatible directory structure.
///
/// See EXPORT_FORMAT.md for the full specification.
class ObsidianExportService {
  /// Vault-level folder that receives the images embedded in task content.
  /// One copy per attachment, however many notes reference it.
  static const String imagesDirName = '_images';

  final NooDatabase _db;

  ObsidianExportService(this._db);

  /// Export root, needed to place `_images/` and to build links relative to it.
  late Directory _root;

  /// attachment worldId (or data-URI hash) -> path of the written image file,
  /// so an image referenced from several notes is written once.
  final Map<String, String> _writtenImages = {};

  /// File names already claimed inside `_images/`.
  final Set<String> _imageNames = {};

  int _imagesExported = 0;

  /// task id -> the file (or folder) name it is written under, decided for
  /// the whole tree before the first note is written — see [_planNames].
  final Map<int, String> _names = {};

  /// task worldId -> its note's path from the export root, `/`-separated and
  /// without `.md`: what a `[[wikilink]]` to it names.
  final Map<String, String> _notePaths = {};

  /// Lowercased note name -> how many notes in the vault carry it. A name
  /// held by one note is enough to link to it; a shared one needs the path.
  final Map<String, int> _noteNameCounts = {};

  /// Decides every task's file name and note path ahead of the export.
  ///
  /// A link between notes is written as a wikilink naming the *target's*
  /// file, and the target may be a task the walk has not reached yet — its
  /// name, ` (2)` suffix included, has to be known first. Names are claimed
  /// in the order the export walks, case-insensitively per directory, so
  /// sibling tasks with identical or colliding titles get distinct files.
  Future<void> _planNames() async {
    Future<void> plan(
        TaskRow task, String parentPath, Set<String> usedNames) async {
      final name =
          _uniqueName(_sanitizeFilename(task.title, task.id), usedNames);
      _names[task.id] = name;
      final children = await _db.getChildTasks(task.id);
      final dirPath = children.isEmpty ? parentPath : '$parentPath$name/';
      _notePaths[task.worldId] = '$dirPath$name';
      _noteNameCounts.update(name.toLowerCase(), (n) => n + 1,
          ifAbsent: () => 1);
      if (children.isEmpty) return;
      // Seeded with the parent's own note, so a child titled like the parent
      // doesn't overwrite <Parent>/<Parent>.md.
      final childNames = <String>{name.toLowerCase()};
      for (final child in children) {
        await plan(child, dirPath, childNames);
      }
    }

    // The images folder lives beside the top-level tasks, so a task with
    // that title must not be written into it.
    final topNames = <String>{imagesDirName.toLowerCase()};
    for (final task in await _db.getTopLevelTasks()) {
      await plan(task, '', topNames);
    }
  }

  /// Characters Obsidian gives a meaning to inside a wikilink's target.
  static final _wikiTargetUnsafe = RegExp(r'[#^\[\]|]');

  /// Characters that would end a wikilink's display text early.
  static final _wikiTextUnsafe = RegExp(r'[\[\]|\n]');

  /// The wikilink from a note to the task [worldId], shown as [text], or
  /// null when it cannot be written as one: the task is not in the export,
  /// or a name or the text holds a character wikilink syntax reserves.
  String? _wikiLink(String worldId, String text) {
    final path = _notePaths[worldId];
    if (path == null) return null;
    if (_wikiTargetUnsafe.hasMatch(path) || _wikiTextUnsafe.hasMatch(text)) {
      return null;
    }
    final name = path.substring(path.lastIndexOf('/') + 1);
    final target = _noteNameCounts[name.toLowerCase()] == 1 ? name : path;
    return text == target ? '[[$target]]' : '[[$target|$text]]';
  }

  /// Export all tasks to the given directory.
  Future<ObsidianExportResult> export(String directoryPath) async {
    final dir = Directory(directoryPath);
    _root = dir;
    _writtenImages.clear();
    _imageNames.clear();
    _imagesExported = 0;
    _names.clear();
    _notePaths.clear();
    _noteNameCounts.clear();
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      int tasksExported = 0;
      int timelineFilesExported = 0;

      await _planNames();

      Future<void> exportTask(
          TaskRow task, Directory parentDir, bool isLeaf) async {
        // Null for a task created after the names were planned (a sync
        // landing mid-export): it has no name, and joins the next export.
        final safeName = _names[task.id];
        if (safeName == null) return;

        if (isLeaf) {
          // Leaf task: write <Title>.md and optionally <Title> - timeline.txt
          final mdFile = File('${parentDir.path}/$safeName.md');
          await mdFile.writeAsString(
            await _buildMarkdown(task.title, task.content, parentDir),
          );
          tasksExported++;

          final records = await _db.getTimelineForTask(task.id);
          if (records.isNotEmpty) {
            final tlFile = File('${parentDir.path}/$safeName - timeline.txt');
            await tlFile.writeAsString(_buildTimeline(task.title, records));
            timelineFilesExported++;
          }
        } else {
          // Parent task: create directory, write <Title>.md and timeline.txt inside
          final taskDir = Directory('${parentDir.path}/$safeName');
          await taskDir.create(recursive: true);

          final mdFile = File('${taskDir.path}/$safeName.md');
          await mdFile.writeAsString(
            await _buildMarkdown(task.title, task.content, taskDir),
          );
          tasksExported++;

          final records = await _db.getTimelineForTask(task.id);
          if (records.isNotEmpty) {
            final tlFile = File('${taskDir.path}/timeline.txt');
            await tlFile.writeAsString(_buildTimeline(task.title, records));
            timelineFilesExported++;
          }

          final children = await _db.getChildTasks(task.id);
          for (final child in children) {
            final childChildren = await _db.getChildTasks(child.id);
            await exportTask(child, taskDir, childChildren.isEmpty);
          }
        }
      }

      final topTasks = await _db.getTopLevelTasks();
      for (final task in topTasks) {
        final children = await _db.getChildTasks(task.id);
        await exportTask(task, dir, children.isEmpty);
      }

      return ObsidianExportResult(
        success: true,
        tasksExported: tasksExported,
        timelineFilesExported: timelineFilesExported,
        imagesExported: _imagesExported,
      );
    } catch (e) {
      return ObsidianExportResult.failure(appL10n.appExportFailed('$e'));
    }
  }

  /// Build markdown file content: # Title + converted content.
  ///
  /// [mdDir] is the directory the note is written to; image links are made
  /// relative to it.
  Future<String> _buildMarkdown(
    String title,
    String? content,
    Directory mdDir,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('# $title');
    buffer.writeln();

    if (content != null && content.isNotEmpty) {
      buffer.write(await _contentToMarkdown(content, mdDir));
    }

    return buffer.toString();
  }

  /// Convert stored content (Delta JSON or HTML) to markdown.
  Future<String> _contentToMarkdown(String content, Directory mdDir) async {
    final trimmed = content.trim();

    // Delta JSON
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final ops = jsonDecode(trimmed) as List<dynamic>;
        return await _deltaToMarkdown(ops, mdDir);
      } catch (_) {
        // Fall through to HTML
      }
    }

    // HTML to markdown
    return _htmlToMarkdown(trimmed);
  }

  /// Convert Delta JSON ops to markdown.
  ///
  /// Quill keeps a line's block format — header, list, blockquote, code —
  /// as attributes of the `"\n"` that ends it, not of the text, so the ops
  /// are walked a line at a time: inline runs accumulate, and the newline
  /// that closes them decides the prefix the line is written with. Writing
  /// ops one by one lost every one of those (a bulleted list came out as bare
  /// lines) because the newline op carries no text to wrap.
  Future<String> _deltaToMarkdown(List<dynamic> ops, Directory mdDir) async {
    final buffer = StringBuffer();
    // Inline runs of the line being assembled. Held back rather than written
    // as they arrive because whether they are prose or code is only known
    // from the newline that ends the line — inside a fence a `**` is text.
    final runs = <({String text, Map<String, dynamic>? attrs})>[];
    var inCodeBlock = false;

    void endLine(Map<String, dynamic>? attrs) {
      final code = attrs?.containsKey('code-block') ?? false;
      if (code != inCodeBlock) {
        buffer.writeln('```');
        inCodeBlock = code;
      }
      if (!code) buffer.write(_linePrefix(attrs));
      for (final run in runs) {
        buffer.write(code ? run.text : _inlineMarkdown(run.text, run.attrs));
      }
      buffer.writeln();
      runs.clear();
    }

    void closeCodeBlock() {
      if (!inCodeBlock) return;
      buffer.writeln('```');
      inCodeBlock = false;
    }

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map?)?.cast<String, dynamic>();

      // Embeds: only images are representable in markdown. The bytes live in
      // the attachment store, so they are copied into the vault and linked.
      if (insert is Map) {
        final image = insert['image'];
        if (image is String && image.isNotEmpty) {
          final link = await _exportImage(image, mdDir);
          if (link != null) {
            if (runs.isNotEmpty) endLine(null);
            closeCodeBlock();
            buffer.writeln('![]($link)');
          }
        }
        continue;
      }

      if (insert is! String) continue;

      // Text may span several lines; only the last segment stays open.
      final segments = insert.split('\n');
      for (var i = 0; i < segments.length; i++) {
        final segment = segments[i];
        if (segment.isNotEmpty) runs.add((text: segment, attrs: attrs));
        if (i < segments.length - 1) endLine(attrs);
      }
    }

    if (runs.isNotEmpty) endLine(null);
    closeCodeBlock();
    return buffer.toString();
  }

  /// The markdown prefix for a line carrying Quill block [attrs].
  String _linePrefix(Map<String, dynamic>? attrs) {
    if (attrs == null) return '';
    final prefix = StringBuffer();
    final indent = attrs['indent'];
    if (indent is int && indent > 0) prefix.write('    ' * indent);
    if (attrs.containsKey('blockquote')) prefix.write('> ');
    final header = attrs['header'];
    if (header is int && header >= 1 && header <= 6) {
      prefix.write('${'#' * header} ');
    }
    switch (attrs['list']) {
      case 'ordered':
        prefix.write('1. ');
      case 'checked':
        prefix.write('- [x] ');
      case 'unchecked':
        prefix.write('- [ ] ');
      case 'bullet':
        prefix.write('- ');
    }
    return prefix.toString();
  }

  /// Inline formatting of one text run.
  String _inlineMarkdown(String text, Map<String, dynamic>? attrs) {
    if (attrs == null) return text;
    var link = attrs['link'];

    // A link to another task becomes a wikilink to that task's note. The
    // marks go around it, not inside: Obsidian shows a wikilink's text as
    // written. `code` is dropped — inside backticks the brackets are text.
    final taskWorldId = link is String ? taskLinkWorldIdOf(link) : null;
    if (taskWorldId != null) {
      var wiki = _wikiLink(taskWorldId, text);
      if (wiki != null) {
        if (attrs.containsKey('bold')) wiki = '**$wiki**';
        if (attrs.containsKey('italic')) wiki = '*$wiki*';
        if (attrs.containsKey('strike')) wiki = '~~$wiki~~';
        return wiki;
      }
      // A task that is not in the export (deleted, or not synced here yet)
      // leaves its text without a link that leads nowhere. One that merely
      // cannot be spelled as a wikilink keeps the reference as it is stored.
      if (!_notePaths.containsKey(taskWorldId)) link = null;
    }

    var out = text;
    if (attrs.containsKey('code')) out = '`$out`';
    if (attrs.containsKey('bold')) out = '**$out**';
    if (attrs.containsKey('italic')) out = '*$out*';
    if (attrs.containsKey('strike')) out = '~~$out~~';
    if (link is String && link.isNotEmpty) out = '[$out]($link)';
    return out;
  }

  /// Copy the image [source] into the vault and return the link target to use
  /// from a note in [mdDir], or null when it cannot be resolved.
  ///
  /// Remote images keep their URL; attachment-backed ones are written to
  /// `<root>/_images/` once and linked relatively from every note using them.
  Future<String?> _exportImage(String source, Directory mdDir) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return source;
    }

    final worldId = attachmentWorldIdOf(source);
    if (worldId == null) return null;

    final existing = _writtenImages[worldId];
    if (existing != null) return _relativeLink(existing, mdDir);

    final file = await _db.getAttachmentByWorldId(worldId);
    final bytes = file?.content;
    if (file == null || bytes == null || file.removed != 0) return null;

    final imagesDir = Directory('${_root.path}/$imagesDirName');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final base = _sanitizeImageName(file.filename, worldId);
    final name = _uniqueImageName(base);
    final imagePath = '${imagesDir.path}/$name';
    await File(imagePath).writeAsBytes(bytes);

    _writtenImages[worldId] = imagePath;
    _imagesExported++;
    return _relativeLink(imagePath, mdDir);
  }

  /// Markdown link from a note in [mdDir] to the file at [imagePath], with
  /// forward slashes and percent-encoded segments so spaces survive.
  String _relativeLink(String imagePath, Directory mdDir) {
    final from = mdDir.path.replaceAll('\\', '/');
    final to = imagePath.replaceAll('\\', '/');

    // Every note lives at or below the export root, and images live directly
    // under it, so the relative path is "../" per level plus the file name.
    final rootPath = _root.path.replaceAll('\\', '/');
    final depth = from == rootPath
        ? 0
        : from
            .substring(rootPath.length)
            .split('/')
            .where((s) => s.isNotEmpty)
            .length;

    final relative =
        '${'../' * depth}$imagesDirName/${to.split('/').last}';
    return relative.split('/').map(Uri.encodeComponent).join('/');
  }

  /// Keep the attachment's own name where possible — it is what the user sees
  /// in the attachments panel — falling back to the worldId.
  String _sanitizeImageName(String filename, String worldId) {
    var safe = filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();
    safe = safe.replaceAll(RegExp(r'[.\s]+$'), '');
    if (safe.isEmpty) return '$worldId.png';
    if (safe.length > 200) safe = safe.substring(safe.length - 200);
    return _avoidReservedName(safe);
  }

  /// Like [_uniqueName], but inserting the counter before the extension so the
  /// file keeps a usable suffix.
  String _uniqueImageName(String base) {
    if (!_imageNames.contains(base.toLowerCase())) {
      _imageNames.add(base.toLowerCase());
      return base;
    }

    final dot = base.lastIndexOf('.');
    final stem = dot <= 0 ? base : base.substring(0, dot);
    final ext = dot <= 0 ? '' : base.substring(dot);

    var n = 2;
    while (_imageNames.contains('$stem ($n)$ext'.toLowerCase())) {
      n++;
    }
    final name = '$stem ($n)$ext';
    _imageNames.add(name.toLowerCase());
    return name;
  }

  /// Simple HTML to markdown conversion.
  String _htmlToMarkdown(String html) {
    var result = html;

    // Links to other tasks, before anything strips the tags they are. An
    // imported note is stored as HTML until it is first edited, and its
    // wikilinks arrived as these.
    result = result.replaceAllMapped(
      RegExp(r'<a\b[^>]*\bhref="(noo-task://[^"]+)"[^>]*>(.*?)</a>',
          dotAll: true),
      (m) {
        final text = _stripTags(m.group(2)!);
        final worldId = taskLinkWorldIdOf(m.group(1));
        return (worldId == null ? null : _wikiLink(worldId, text)) ?? text;
      },
    );

    // Block elements
    result = result.replaceAllMapped(
      RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', dotAll: true),
      (m) => '${'#' * int.parse(m.group(1)!)} ${_stripTags(m.group(2)!)}\n\n',
    );
    result = result.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true),
      (m) => '${_stripTags(m.group(1)!)}\n\n',
    );
    result = result.replaceAllMapped(
      RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true),
      (m) => '- ${_stripTags(m.group(1)!)}\n',
    );
    result = result.replaceAllMapped(
      RegExp(r'<pre[^>]*><code[^>]*>(.*?)</code></pre>', dotAll: true),
      (m) => '```\n${_stripTags(m.group(1)!)}\n```\n\n',
    );

    // Inline elements
    result = result.replaceAllMapped(
      RegExp(r'<b>(.*?)</b>|<strong>(.*?)</strong>', dotAll: true),
      (m) => '**${m.group(1) ?? m.group(2)}**',
    );
    result = result.replaceAllMapped(
      RegExp(r'<i>(.*?)</i>|<em>(.*?)</em>', dotAll: true),
      (m) => '*${m.group(1) ?? m.group(2)}*',
    );
    result = result.replaceAllMapped(
      RegExp(r'<code>(.*?)</code>', dotAll: true),
      (m) => '`${m.group(1)}`',
    );

    // Remove remaining tags and list wrappers
    result = result.replaceAll(RegExp(r'</?(?:ul|ol)[^>]*>'), '');
    result = result.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    result = _stripTags(result);

    // Collapse excessive blank lines
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result.trim();
  }

  String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
  }

  /// Build timeline file content.
  String _buildTimeline(String taskTitle, List<TimelineEntry> records) {
    final buffer = StringBuffer();

    // Calculate total time
    var totalDuration = Duration.zero;
    for (final r in records) {
      final start = DateTime.parse(r.startTime);
      final end = r.endTime != null ? DateTime.parse(r.endTime!) : null;
      if (end != null) {
        totalDuration += end.difference(start);
      }
    }

    buffer.writeln('# Time records for: $taskTitle');
    buffer.writeln('# Total time: ${_formatDuration(totalDuration)}');
    buffer.writeln();

    for (final r in records) {
      final start = DateTime.parse(r.startTime).toLocal();
      final end = r.endTime != null ? DateTime.parse(r.endTime!).toLocal() : null;
      if (end == null) continue; // Skip active/open records

      final duration = end.difference(start);
      buffer.writeln(
        '${_formatDateTime(start)}  ->  ${_formatDateTime(end)}  (${_formatDuration(duration)})',
      );
    }

    return buffer.toString();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Return a name not yet present in [used] (case-insensitively), appending
  /// " (2)", " (3)", … on collision. Records the chosen name in [used].
  String _uniqueName(String base, Set<String> used) {
    if (!used.contains(base.toLowerCase())) {
      used.add(base.toLowerCase());
      return base;
    }
    var n = 2;
    while (used.contains('$base ($n)'.toLowerCase())) {
      n++;
    }
    final name = '$base ($n)';
    used.add(name.toLowerCase());
    return name;
  }

  /// Sanitize a task title for use as a filename.
  String _sanitizeFilename(String title, int id) {
    if (title.trim().isEmpty) return 'untitled_$id';

    var safe = title.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    // Strip trailing dots and spaces
    safe = safe.replaceAll(RegExp(r'[.\s]+$'), '');
    // A leading dot makes a hidden entry, which Obsidian does not show and
    // the importer skips (it is how `.obsidian/` stays out of the outline),
    // so a branch titled `.plans` would vanish on the way back. The title
    // itself travels in the note's heading, so the file name is free to differ.
    if (safe.startsWith('.')) safe = '_${safe.substring(1)}';
    // Cap length
    if (safe.length > 200) safe = safe.substring(0, 200);
    if (safe.isEmpty) return 'untitled_$id';
    return _avoidReservedName(safe);
  }

  /// Windows reserves the DOS device names, with or without an extension:
  /// `NUL.md` is the null device, so a task titled "NUL" silently exports
  /// nothing, and `CON` or `COM1` fail the whole run. Suffixing the stem keeps
  /// the name recognisable on every platform, including a vault that is later
  /// copied to Windows.
  static final _reservedStem = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])$',
    caseSensitive: false,
  );

  static String _avoidReservedName(String name) {
    final dot = name.indexOf('.');
    final stem = dot < 0 ? name : name.substring(0, dot);
    if (!_reservedStem.hasMatch(stem.trim())) return name;
    return '${stem}_${dot < 0 ? '' : name.substring(dot)}';
  }
}
