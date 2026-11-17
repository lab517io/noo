import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/content_merge.dart';

/// Content as the editor stores it.
String doc(void Function(Delta d) build) {
  final d = Delta();
  build(d);
  return jsonEncode(d.toJson());
}

String plain(String text) => doc((d) => d.insert('$text\n'));

/// The merge's plain text, for assertions that do not care about attributes.
String textOf(String? content) =>
    Delta.fromJson(jsonDecode(content!) as List).toList().map((op) {
      final data = op.data;
      return data is String ? data : '[embed]';
    }).join();

void main() {
  group('mergeContent', () {
    test('keeps edits to different paragraphs', () {
      final base = plain('one\ntwo\nthree');
      final merged = mergeContent(
        base: base,
        local: plain('ONE\ntwo\nthree'),
        remote: plain('one\ntwo\nTHREE'),
      );
      expect(textOf(merged), 'ONE\ntwo\nTHREE\n');
    });

    test('keeps both lines appended at the end, remote first', () {
      final base = plain('log');
      final merged = mergeContent(
        base: base,
        local: plain('log\nfrom laptop'),
        remote: plain('log\nfrom phone'),
      );
      expect(textOf(merged), 'log\nfrom phone\nfrom laptop\n');
    });

    test('keeps edits within one line when they do not overlap', () {
      final merged = mergeContent(
        base: plain('the colour of the sky'),
        local: plain('The colour of the sky'),
        remote: plain('the color of the sky'),
      );
      expect(textOf(merged), 'The color of the sky\n');
    });

    test('refuses when both rewrote the same words', () {
      expect(
        mergeContent(
          base: plain('meet on Monday'),
          local: plain('meet on Tuesday'),
          remote: plain('meet on Friday'),
        ),
        isNull,
      );
    });

    test('refuses an insertion where the other side replaced text', () {
      expect(
        mergeContent(
          base: plain('meet on Monday'),
          local: plain('meet on next Monday'),
          remote: plain('meet on Friday'),
        ),
        isNull,
      );
    });

    test('puts two additions to the end of one line on separate lines', () {
      final base = doc(
        (d) => d
          ..insert('Buy milk')
          ..insert('\n', {'list': 'bullet'}),
      );
      final merged = mergeContent(
        base: base,
        local: doc(
          (d) => d
            ..insert('Buy milk and eggs')
            ..insert('\n', {'list': 'bullet'}),
        ),
        remote: doc(
          (d) => d
            ..insert('Buy milk and bread')
            ..insert('\n', {'list': 'bullet'}),
        ),
      );
      // Both lines stay list items.
      expect(
        Delta.fromJson(jsonDecode(merged!) as List),
        Delta()
          ..insert('Buy milk and bread')
          ..insert('\n', {'list': 'bullet'})
          ..insert(' and eggs')
          ..insert('\n', {'list': 'bullet'}),
      );
    });

    test('refuses two insertions at one point mid-sentence', () {
      expect(
        mergeContent(
          base: plain('a  b'),
          local: plain('a x b'),
          remote: plain('a y b'),
        ),
        isNull,
      );
    });

    test('refuses two insertions at one point even after a reformat', () {
      // Local bolds "abc" and inserts right after it; the reformat used to
      // swallow the insertion into one text-less span, and the remote
      // insertion at the same point slipped past the same-point rule to
      // produce "YX".
      final base = plain('abc def');
      final local = doc(
        (d) => d
          ..insert('abc', {'bold': true})
          ..insert('X def\n'),
      );
      expect(
        mergeContent(base: base, local: local, remote: plain('abcY def')),
        isNull,
      );
      expect(
        mergeContent(base: base, local: plain('abcY def'), remote: local),
        isNull,
      );
    });

    test('refuses an insertion at the start of a range the other side deleted, '
        'whichever side inserted', () {
      final base = plain('the cat');
      final deleted = plain('the ');
      final inserted = plain('the big cat');
      expect(
          mergeContent(base: base, local: inserted, remote: deleted), isNull);
      // Used to merge to "the big " in this direction alone.
      expect(
          mergeContent(base: base, local: deleted, remote: inserted), isNull);
    });

    test('refuses when one side deleted what the other edited', () {
      expect(
        mergeContent(
          base: plain('keep\ndrop this line\nkeep'),
          local: plain('keep\ndrop THIS line\nkeep'),
          remote: plain('keep\nkeep'),
        ),
        isNull,
      );
    });

    test('merges formatting and text from different sides', () {
      final base = plain('alpha beta');
      final local = doc(
        (d) => d
          ..insert('alpha', {'bold': true})
          ..insert(' beta\n'),
      );
      final remote = plain('alpha beta gamma');
      final merged = Delta.fromJson(
        jsonDecode(mergeContent(base: base, local: local, remote: remote)!)
            as List,
      );
      expect(
        merged,
        Delta()
          ..insert('alpha', {'bold': true})
          ..insert(' beta gamma\n'),
      );
    });

    test('carries embeds through', () {
      final image = {'image': 'noo-attachment://abc'};
      final base = doc(
        (d) => d
          ..insert('top\n')
          ..insert(image)
          ..insert('\nbottom\n'),
      );
      final local = doc(
        (d) => d
          ..insert('TOP\n')
          ..insert(image)
          ..insert('\nbottom\n'),
      );
      final remote = doc(
        (d) => d
          ..insert('top\n')
          ..insert(image)
          ..insert('\nbottom line\n'),
      );
      expect(
        textOf(mergeContent(base: base, local: local, remote: remote)),
        'TOP\n[embed]\nbottom line\n',
      );
    });

    test('treats an empty base as the empty document', () {
      expect(
        textOf(
          mergeContent(
            base: null,
            local: plain('mine'),
            remote: plain('theirs'),
          ),
        ),
        'theirs\nmine\n',
      );
    });

    test('refuses content that is not Delta JSON', () {
      expect(
        mergeContent(base: '<p>old</p>', local: plain('a'), remote: plain('b')),
        isNull,
      );
      expect(
        mergeContent(base: plain('x'), local: plain('a'), remote: '[{"oops"'),
        isNull,
      );
    });
  });
}
