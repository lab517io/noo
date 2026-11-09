import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/attachment_uri.dart';

void main() {
  const worldId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  test('round-trips a worldId through the content reference', () {
    final uri = attachmentUri(worldId);
    expect(uri, 'noo-attachment://$worldId');
    expect(attachmentWorldIdOf(uri), worldId);
  });

  test('ignores other image sources', () {
    expect(attachmentWorldIdOf('https://example.com/a.png'), isNull);
    expect(attachmentWorldIdOf('data:image/png;base64,AAAA'), isNull);
    expect(attachmentWorldIdOf(r'C:\pictures\a.png'), isNull);
    expect(attachmentWorldIdOf('noo-attachment://'), isNull);
    expect(attachmentWorldIdOf(null), isNull);
  });

  test('preserves worldId case, which Uri.parse would fold', () {
    const mixed = '3F2504E0-4f89-11D3-9a0c-0305E82C3301';
    expect(attachmentWorldIdOf(attachmentUri(mixed)), mixed);
  });

  test('collects attachment references from Delta JSON content', () {
    final content = jsonEncode([
      {'insert': 'before'},
      {
        'insert': {'image': attachmentUri(worldId)}
      },
      {
        'insert': {'image': 'https://example.com/remote.png'}
      },
      {
        // The same image twice: the reference set collapses it, the source
        // list does not.
        'insert': {'image': attachmentUri(worldId)}
      },
      {'insert': '\n'},
    ]);

    expect(attachmentRefsInContent(content), {worldId});
    expect(imageSourcesInContent(content).length, 3);
  });

  test('treats HTML and malformed content as reference-free', () {
    expect(attachmentRefsInContent('<p>legacy</p>'), isEmpty);
    expect(attachmentRefsInContent('[not json'), isEmpty);
    expect(attachmentRefsInContent(''), isEmpty);
    expect(attachmentRefsInContent(null), isEmpty);
  });
}
