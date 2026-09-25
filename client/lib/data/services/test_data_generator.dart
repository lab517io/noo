import 'dart:math';

import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Generates test data for development and debugging purposes
class TestDataGenerator {
  final NooDatabase _db;
  final _uuid = const Uuid();
  final _random = Random();

  TestDataGenerator(this._db);

  /// Generate a complete test dataset with tasks, time records, etc.
  Future<void> generateTestData({
    int topLevelTasks = 5,
    int maxDepth = 3,
    int maxChildrenPerTask = 4,
    bool includeTimeRecords = true,
  }) async {
    for (int i = 0; i < topLevelTasks; i++) {
      await _createTaskWithChildren(
        parentId: null,
        depth: 0,
        maxDepth: maxDepth,
        maxChildren: maxChildrenPerTask,
        index: i,
        includeTimeRecords: includeTimeRecords,
      );
    }
  }

  Future<int> _createTaskWithChildren({
    required int? parentId,
    required int depth,
    required int maxDepth,
    required int maxChildren,
    required int index,
    required bool includeTimeRecords,
  }) async {
    final title = _generateTitle(depth, index);
    final content = _generateHtmlContent(depth);
    final flags = _random.nextDouble() < 0.1 ? 1 : 0; // 10% chance of noTimeTracking

    final taskId = await _db.createTask(
      parentId: parentId,
      worldId: _uuid.v4(),
      orderId: index,
      title: title,
      content: content,
      flags: flags,
    );

    // Add time records for some tasks
    if (includeTimeRecords && flags == 0 && _random.nextDouble() < 0.4) {
      await _createTimeRecords(taskId);
    }

    // Create children if not at max depth
    if (depth < maxDepth) {
      final numChildren = _random.nextInt(maxChildren + 1);
      for (int i = 0; i < numChildren; i++) {
        await _createTaskWithChildren(
          parentId: taskId,
          depth: depth + 1,
          maxDepth: maxDepth,
          maxChildren: maxChildren,
          index: i,
          includeTimeRecords: includeTimeRecords,
        );
      }
    }

    return taskId;
  }

  String _generateTitle(int depth, int index) {
    final prefixes = [
      ['Project', 'Initiative', 'Goal', 'Objective', 'Plan'],
      ['Phase', 'Module', 'Component', 'Section', 'Area'],
      ['Task', 'Item', 'Action', 'Step', 'Activity'],
      ['Subtask', 'Detail', 'Note', 'Point', 'Element'],
    ];

    final subjects = [
      'Development',
      'Research',
      'Design',
      'Testing',
      'Documentation',
      'Review',
      'Planning',
      'Implementation',
      'Analysis',
      'Integration',
    ];

    final depthIndex = depth.clamp(0, prefixes.length - 1);
    final prefix = prefixes[depthIndex][_random.nextInt(prefixes[depthIndex].length)];
    final subject = subjects[_random.nextInt(subjects.length)];

    return '$prefix: $subject ${index + 1}';
  }

  String _generateHtmlContent(int depth) {
    if (_random.nextDouble() < 0.3) {
      return ''; // 30% chance of empty content
    }

    final paragraphs = <String>[];
    final numParagraphs = _random.nextInt(3) + 1;

    for (int i = 0; i < numParagraphs; i++) {
      paragraphs.add('<p>${_generateParagraph()}</p>');
    }

    // Sometimes add a list
    if (_random.nextDouble() < 0.3) {
      paragraphs.add(_generateList());
    }

    return paragraphs.join('\n');
  }

  String _generateParagraph() {
    final sentences = [
      'This task requires careful attention to detail.',
      'Review the requirements before proceeding.',
      'Coordinate with the team for updates.',
      'Document all changes and decisions.',
      'Test thoroughly before marking complete.',
      'Consider edge cases and error handling.',
      'Ensure backwards compatibility.',
      'Follow the established coding standards.',
      'Update relevant documentation.',
      'Schedule a review meeting if needed.',
    ];

    final numSentences = _random.nextInt(3) + 1;
    final selected = <String>[];
    for (int i = 0; i < numSentences; i++) {
      selected.add(sentences[_random.nextInt(sentences.length)]);
    }
    return selected.join(' ');
  }

  String _generateList() {
    final items = [
      'Review specifications',
      'Update dependencies',
      'Write unit tests',
      'Perform code review',
      'Update documentation',
      'Deploy to staging',
      'Run integration tests',
      'Get stakeholder approval',
    ];

    final numItems = _random.nextInt(4) + 2;
    final buffer = StringBuffer('<ul>');
    for (int i = 0; i < numItems; i++) {
      buffer.write('<li>${items[_random.nextInt(items.length)]}</li>');
    }
    buffer.write('</ul>');
    return buffer.toString();
  }

  Future<void> _createTimeRecords(int taskId) async {
    final now = DateTime.now();
    final numRecords = _random.nextInt(5) + 1;

    for (int i = 0; i < numRecords; i++) {
      // Random start time within the last 30 days
      final daysAgo = _random.nextInt(30);
      final hoursAgo = _random.nextInt(24);
      final startTime = now.subtract(Duration(days: daysAgo, hours: hoursAgo));

      // Duration between 5 minutes and 4 hours
      final durationMinutes = _random.nextInt(235) + 5;
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      await _db.createTimeRecord(
        taskId: taskId,
        worldId: _uuid.v4(),
        startTime: startTime.toUtc().toIso8601String(),
        endTime: endTime.toUtc().toIso8601String(),
      );
    }
  }

  /// Clear all data from the database (use with caution!)
  Future<void> clearAllData() async {
    // The attachments table is named `file` (see Files.tableName); the old
    // `files` name raised "no such table" and aborted mid-wipe. Run in one
    // transaction so a failure can't leave the DB half-cleared.
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM timeline');
      await _db.customStatement('DELETE FROM file');
      await _db.customStatement('DELETE FROM history_task');
      await _db.customStatement('DELETE FROM history_file');
      await _db.customStatement('DELETE FROM history_timeline');
      await _db.customStatement('DELETE FROM tasks');
    });
  }
}
