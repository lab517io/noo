import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/task_link.dart';

void main() {
  group('task link uri', () {
    test('round-trips a worldId, case kept', () {
      expect(taskLinkWorldIdOf(taskLinkUri('AbC-1')), 'AbC-1');
    });

    test('is null for other links', () {
      expect(taskLinkWorldIdOf('https://example.com'), isNull);
      expect(taskLinkWorldIdOf('noo-attachment://x'), isNull);
      expect(taskLinkWorldIdOf('noo-task://'), isNull);
      expect(taskLinkWorldIdOf(null), isNull);
    });
  });

  group('taskLinkTriggerAt', () {
    TaskLinkTrigger? at(String text) => taskLinkTriggerAt(text, text.length);

    test('finds the query after the brackets', () {
      expect(at('see [[rep'), const TaskLinkTrigger(4, 'rep'));
      expect(at('[['), const TaskLinkTrigger(0, ''));
      expect(at('see [[two words'), const TaskLinkTrigger(4, 'two words'));
    });

    test('measures from the caret, not the end of the text', () {
      expect(taskLinkTriggerAt('a [[bc]] d', 6), const TaskLinkTrigger(2, 'bc'));
    });

    test('a single bracket, a closed pair and another line open nothing', () {
      expect(at('see [rep'), isNull);
      expect(at('see [[rep]] and'), isNull);
      expect(at('see [[rep\nnext'), isNull);
      expect(at('plain text'), isNull);
    });

    test('an embed ends the scan', () {
      expect(at('[[a￼b'), isNull);
    });

    test('a bracket inside the query is part of it', () {
      expect(at('[[a[b'), const TaskLinkTrigger(0, 'a[b'));
    });

    test('gives up on a query past the limit', () {
      expect(at('[[${'x' * kTaskLinkMaxQuery}'), isNotNull);
      expect(at('[[${'x' * (kTaskLinkMaxQuery + 1)}'), isNull);
    });
  });

  group('rankTaskLinkTargets', () {
    TaskLinkTarget t(int id, String title) =>
        TaskLinkTarget(id: id, worldId: 'w$id', title: title);
    final all = [
      t(1, 'Unreported'),
      t(2, 'Annual report'),
      t(3, 'Report Q3'),
      t(4, 'Groceries'),
      t(5, 'report drafts'),
    ];
    List<int> ids(String q, {int limit = 50}) =>
        [for (final r in rankTaskLinkTargets(all, q, limit: limit)) r.id];

    test('prefix, then word start, then anywhere; outline order within', () {
      expect(ids('rep'), [3, 5, 2, 1]);
    });

    test('an empty query offers everything in outline order', () {
      expect(ids(' '), [1, 2, 3, 4, 5]);
    });

    test('honours the limit', () {
      expect(ids('', limit: 2), [1, 2]);
    });

    test('link text never breaks a line and is never empty', () {
      expect(t(1, 'a\nb  c').linkText, 'a b c');
      expect(t(1, '').linkText, kUntitledTaskLinkText);
    });
  });
}
