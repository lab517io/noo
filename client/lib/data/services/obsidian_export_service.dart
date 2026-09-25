import 'dart:convert';
import 'dart:io';

import '../../core/utils/attachment_uri.dart';
import '../database/database.dart';

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

  /// Export all tasks to the given directory.
  Future<ObsidianExportResult> export(String directoryPath) async {
    final dir = Directory(directoryPath);
    _root = dir;
    _writtenImages.clear();
    _imageNames.clear();
    _imagesExported = 0;
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      int tasksExported = 0;
      int timelineFilesExported = 0;

      // Track claimed names (lowercased, for case-insensitive filesystems)
      // within each output directory so sibling tasks with identical or
      // colliding titles don't overwrite each other's files.
      Future<void> exportTask(TaskRow task, Directory parentDir, bool isLeaf,
          Set<String> usedNames) async {
        final base = _sanitizeFilename(task.title, task.id);
        final safeName = _uniqueName(base, usedNames);

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

          // Export children. Seed the child name set with the parent's own
          // content-file name so a child titled like the parent doesn't
          // overwrite <Parent>/<Parent>.md.
          final childNames = <String>{safeName.toLowerCase()};
          final children = await _db.getChildTasks(task.id);
          for (final child in children) {
            final childChildren = await _db.getChildTasks(child.id);
            await exportTask(child, taskDir, childChildren.isEmpty, childNames);
          }
        }
      }

      final topNames = <String>{};
      final topTasks = await _db.getTopLevelTasks();
      for (final task in topTasks) {
        final children = await _db.getChildTasks(task.id);
        await exportTask(task, dir, children.isEmpty, topNames);
      }

      return ObsidianExportResult(
        success: true,
        tasksExported: tasksExported,
        timelineFilesExported: timelineFilesExported,
        imagesExported: _imagesExported,
      );
    } catch (e) {
      return ObsidianExportResult.failure('Export failed: $e');
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
  Future<String> _deltaToMarkdown(List<dynamic> ops, Directory mdDir) async {
    final buffer = StringBuffer();

    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];

      // Embeds: only images are representable in markdown. The bytes live in
      // the attachment store, so they are copied into the vault and linked.
      if (insert is Map) {
        final image = insert['image'];
        if (image is String && image.isNotEmpty) {
          final link = await _exportImage(image, mdDir);
          if (link != null) buffer.write('\n![]($link)\n');
        }
        continue;
      }

      if (insert is! String) continue;

      final attrs = op['attributes'] as Map<String, dynamic>?;

      var text = insert;

      if (attrs != null) {
        if (attrs.containsKey('bold')) text = '**$text**';
        if (attrs.containsKey('italic')) text = '*$text*';
        if (attrs.containsKey('code')) text = '`$text`';
      }

      buffer.write(text);
    }

    return buffer.toString();
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
    return safe;
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
    // Cap length
    if (safe.length > 200) safe = safe.substring(0, 200);
    if (safe.isEmpty) return 'untitled_$id';
    return safe;
  }
}
