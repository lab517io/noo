import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import 'obsidian_export_service.dart';

/// Result of an Obsidian-format import operation.
class ObsidianImportResult {
  final bool success;
  final int tasksImported;
  final int timeRecordsImported;
  final String? error;

  const ObsidianImportResult({
    required this.success,
    this.tasksImported = 0,
    this.timeRecordsImported = 0,
    this.error,
  });

  factory ObsidianImportResult.failure(String error) =>
      ObsidianImportResult(success: false, error: error);
}

/// Imports data from an Obsidian-like directory structure (as exported by Noo)
/// into the current database.
///
/// Expected format (see EXPORT_FORMAT.md):
/// - Task with children = directory, content in `<Title>.md`, time in `timeline.txt`
/// - Leaf task = `<Title>.md` file, time in `<Title> - timeline.txt`
/// - Markdown files start with `# Title` heading
/// - Timeline files have lines: `yyyy-MM-dd HH:mm:ss  ->  yyyy-MM-dd HH:mm:ss  (HH:MM:SS)`
class ObsidianImportService {
  final NooDatabase _db;
  final _uuid = const Uuid();

  ObsidianImportService(this._db);

  /// Import all data from a directory into the current database.
  ///
  /// Data is appended to existing data.
  Future<ObsidianImportResult> import(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      return ObsidianImportResult.failure('Directory does not exist: $directoryPath');
    }

    try {
      // Determine the next orderId for top-level tasks
      final existingTopLevel = await _db.getTopLevelTasks();
      int nextTopLevelOrder = existingTopLevel.isEmpty
          ? 0
          : existingTopLevel.last.orderId + 1;

      int tasksImported = 0;
      int timeRecordsImported = 0;

      /// Recursively import entries from a directory.
      Future<void> importDirectory(Directory dir, int? parentId, int orderOffset,
          {bool isRoot = false}) async {
        // Collect items in this directory
        final entries = await dir.list().toList();

        // Separate directories and markdown files
        final subDirs = <Directory>[];
        final mdFiles = <File>[];
        final timelineFiles = <String, File>{}; // baseName -> file

        for (final entry in entries) {
          final name = _baseName(entry.path);
          if (entry is Directory) {
            // The exporter's own image store is not a task, and neither is
            // Obsidian's `.obsidian/` or any other hidden folder. Without
            // this an exported vault gained an `_images` task on every
            // re-import.
            if (name.startsWith('.')) continue;
            if (isRoot && name == ObsidianExportService.imagesDirName) {
              continue;
            }
            subDirs.add(entry);
          } else if (entry is File) {
            if (name.endsWith('.md')) {
              mdFiles.add(entry);
            } else if (name == 'timeline.txt' || name.endsWith(' - timeline.txt')) {
              timelineFiles[name] = entry;
            }
          }
        }

        // Sort for deterministic order
        subDirs.sort((a, b) => _baseName(a.path).compareTo(_baseName(b.path)));
        mdFiles.sort((a, b) => _baseName(a.path).compareTo(_baseName(b.path)));

        // Directories represent tasks with children.
        // The directory's own content is in `<DirName>.md` inside it.
        // Leaf tasks are .md files that do NOT correspond to a subdirectory.

        // Build set of directory names to distinguish leaf vs parent .md files
        final dirNames = subDirs.map((d) => _baseName(d.path)).toSet();

        // Find leaf .md files (no matching subdirectory, and not a dir's self-content file)
        // A file `Foo.md` is a leaf if there's no subdirectory named `Foo` at the same level.
        // But `Foo.md` inside directory `Foo/` is the directory's own content — skip it here.
        //
        // A `Foo.md` *beside* `Foo/` is Obsidian's folder-note layout: the
        // note of the folder itself. The exporter never writes one (a leaf
        // titled like a sibling folder gets ` (2)`), so it only comes from a
        // foreign vault, and it stands in for the folder's own note when the
        // folder has none. When the folder has both, the sibling is a note of
        // its own and is imported as a leaf rather than dropped.
        final folderNotes = <String, File>{};
        final leafMdFiles = <File>[];
        for (final f in mdFiles) {
          final titleFromFile = _baseName(f.path).replaceAll(RegExp(r'\.md$'), '');
          if (dirNames.contains(titleFromFile)) {
            final inner = File(p.join(dir.path, titleFromFile, '$titleFromFile.md'));
            if (!await inner.exists()) {
              folderNotes[titleFromFile] = f;
              continue;
            }
          }
          // Skip a `<dirName>.md` that is this directory's own content file —
          // but only when `dir` is itself a task directory (its content was
          // already consumed by the parent). At the vault root there is no such
          // parent task, so a top-level leaf named like the folder must be kept.
          if (!isRoot) {
            final parentDirName = _baseName(dir.path);
            if (titleFromFile == parentDirName) continue;
          }
          leafMdFiles.add(f);
        }

        int currentOrder = orderOffset;

        // Import subdirectories as tasks with children
        for (final subDir in subDirs) {
          final dirName = _baseName(subDir.path);

          // Read the directory's own content from `<DirName>.md` inside it
          String title = dirName;
          String? content;
          final selfMdFile =
              folderNotes[dirName] ?? File(p.join(subDir.path, '$dirName.md'));
          if (await selfMdFile.exists()) {
            final parsed = await _parseMdFile(selfMdFile);
            title = parsed.title;
            content = parsed.content;
          }

          final taskId = await _db.createTask(
            parentId: parentId,
            worldId: _uuid.v4(),
            orderId: currentOrder++,
            title: title,
            content: content,
          );
          tasksImported++;

          // Import timeline for this directory task
          final dirTimelineFile = File(p.join(subDir.path, 'timeline.txt'));
          if (await dirTimelineFile.exists()) {
            final records = await _parseTimelineFile(dirTimelineFile);
            for (final record in records) {
              await _db.createTimeRecord(
                taskId: taskId,
                worldId: _uuid.v4(),
                startTime: record.startTime,
                endTime: record.endTime,
              );
              timeRecordsImported++;
            }
          }

          // Recursively import children (starting at order 0)
          await importDirectory(subDir, taskId, 0);
        }

        // Import leaf .md files as tasks without children
        for (final mdFile in leafMdFiles) {
          final parsed = await _parseMdFile(mdFile);

          final taskId = await _db.createTask(
            parentId: parentId,
            worldId: _uuid.v4(),
            orderId: currentOrder++,
            title: parsed.title,
            content: parsed.content,
          );
          tasksImported++;

          // Check for corresponding timeline file: `<Title> - timeline.txt`
          final titleFromFile = _baseName(mdFile.path).replaceAll(RegExp(r'\.md$'), '');
          final timelineFileName = '$titleFromFile - timeline.txt';
          final timelineFile = timelineFiles[timelineFileName];
          if (timelineFile != null) {
            final records = await _parseTimelineFile(timelineFile);
            for (final record in records) {
              await _db.createTimeRecord(
                taskId: taskId,
                worldId: _uuid.v4(),
                startTime: record.startTime,
                endTime: record.endTime,
              );
              timeRecordsImported++;
            }
          }
        }
      }

      await _db.transaction(() async {
        await importDirectory(dir, null, nextTopLevelOrder, isRoot: true);
      });

      return ObsidianImportResult(
        success: true,
        tasksImported: tasksImported,
        timeRecordsImported: timeRecordsImported,
      );
    } catch (e) {
      return ObsidianImportResult.failure('Import failed: $e');
    }
  }

  /// Parse a markdown file into title and HTML content.
  Future<_ParsedMd> _parseMdFile(File file) async {
    final text = await file.readAsString();
    final lines = text.split('\n');

    // Extract title from first `# ` heading
    String title = _baseName(file.path).replaceAll(RegExp(r'\.md$'), '');
    int contentStartLine = 0;

    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      if (trimmed.startsWith('# ')) {
        title = trimmed.substring(2).trim();
        contentStartLine = i + 1;
        // Skip blank line after heading
        if (contentStartLine < lines.length && lines[contentStartLine].trim().isEmpty) {
          contentStartLine++;
        }
        break;
      }
      // Skip leading blank lines
      if (trimmed.isNotEmpty) break;
    }

    // Convert remaining lines to simple HTML content
    final contentLines = lines.sublist(contentStartLine);
    // Trim trailing empty lines
    while (contentLines.isNotEmpty && contentLines.last.trim().isEmpty) {
      contentLines.removeLast();
    }

    String? content;
    if (contentLines.isNotEmpty) {
      content = _markdownToHtml(contentLines.join('\n'));
    }

    return _ParsedMd(title: title, content: content);
  }

  /// Simple markdown to HTML conversion.
  /// Handles paragraphs, headings, bold, italic, lists, and code blocks.
  String _markdownToHtml(String markdown) {
    final lines = markdown.split('\n');
    final buffer = StringBuffer();
    var inCodeBlock = false;
    var inList = false;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      // Code blocks
      if (line.trimLeft().startsWith('```')) {
        if (inCodeBlock) {
          buffer.write('</code></pre>');
          inCodeBlock = false;
        } else {
          if (inList) {
            buffer.write('</ul>');
            inList = false;
          }
          buffer.write('<pre><code>');
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        buffer.write(_escapeHtml(line));
        buffer.write('\n');
        continue;
      }

      // Blank line = end list / paragraph break
      if (line.trim().isEmpty) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        continue;
      }

      // Headings
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        final level = headingMatch.group(1)!.length;
        final text = _inlineMarkdown(headingMatch.group(2)!);
        buffer.write('<h$level>$text</h$level>');
        continue;
      }

      // Unordered list items
      final ulMatch = RegExp(r'^[\s]*[-*+]\s+(.+)$').firstMatch(line);
      if (ulMatch != null) {
        if (!inList) {
          buffer.write('<ul>');
          inList = true;
        }
        buffer.write('<li>${_inlineMarkdown(ulMatch.group(1)!)}</li>');
        continue;
      }

      // Ordered list items
      final olMatch = RegExp(r'^[\s]*\d+\.\s+(.+)$').firstMatch(line);
      if (olMatch != null) {
        if (!inList) {
          buffer.write('<ul>');
          inList = true;
        }
        buffer.write('<li>${_inlineMarkdown(olMatch.group(1)!)}</li>');
        continue;
      }

      // Block quotes
      final quoteMatch = RegExp(r'^\s*>\s?(.*)$').firstMatch(line);
      if (quoteMatch != null) {
        if (inList) {
          buffer.write('</ul>');
          inList = false;
        }
        buffer.write(
            '<blockquote>${_inlineMarkdown(quoteMatch.group(1)!)}</blockquote>');
        continue;
      }

      // Regular paragraph
      if (inList) {
        buffer.write('</ul>');
        inList = false;
      }
      buffer.write('<p>${_inlineMarkdown(line)}</p>');
    }

    if (inCodeBlock) {
      buffer.write('</code></pre>');
    }
    if (inList) {
      buffer.write('</ul>');
    }

    return buffer.toString();
  }

  /// Convert inline markdown (bold, italic, code, links) to HTML.
  String _inlineMarkdown(String text) {
    var result = _escapeHtml(text);
    // Bold: **text** or __text__
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*|__(.+?)__'),
      (m) => '<b>${m.group(1) ?? m.group(2)}</b>',
    );
    // Italic: *text* or _text_
    result = result.replaceAllMapped(
      RegExp(r'\*(.+?)\*|_(.+?)_'),
      (m) => '<i>${m.group(1) ?? m.group(2)}</i>',
    );
    // Inline code: `text`
    result = result.replaceAllMapped(
      RegExp(r'`(.+?)`'),
      (m) => '<code>${m.group(1)}</code>',
    );
    // Links: [text](url)
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)\s]+)\)'),
      (m) => '<a href="${m.group(2)}">${m.group(1)}</a>',
    );
    return result;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  /// Parse a timeline.txt file into time records.
  Future<List<_ParsedTimeRecord>> _parseTimelineFile(File file) async {
    final text = await file.readAsString();
    final records = <_ParsedTimeRecord>[];

    // Pattern: 2026-01-10 09:00:00  ->  2026-01-10 12:30:00  (03:30:00)
    final linePattern = RegExp(
      r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s+->\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})',
    );

    for (final line in text.split('\n')) {
      final match = linePattern.firstMatch(line);
      if (match == null) continue;

      final startStr = match.group(1)!.trim();
      final endStr = match.group(2)!.trim();

      // Parse as local time, convert to ISO8601 UTC for storage
      try {
        final start = DateTime.parse(startStr.replaceFirst(' ', 'T'));
        final end = DateTime.parse(endStr.replaceFirst(' ', 'T'));

        records.add(_ParsedTimeRecord(
          startTime: start.toUtc().toIso8601String(),
          endTime: end.toUtc().toIso8601String(),
        ));
      } catch (_) {
        // Skip malformed lines
      }
    }

    return records;
  }

  /// Extract the file/directory name from a path. `package:path`, because a
  /// path built here as `<dir>/<name>.md` under a Windows `<dir>` mixes both
  /// separators, and splitting on the first one seen gave `Parent/Parent`.
  String _baseName(String path) => p.basename(path);
}

class _ParsedMd {
  final String title;
  final String? content;
  _ParsedMd({required this.title, this.content});
}

class _ParsedTimeRecord {
  final String startTime;
  final String? endTime;
  _ParsedTimeRecord({required this.startTime, this.endTime});
}
