import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/diff_utils.dart';

void main() {
  group('DiffUtils.applyDiff', () {
    test('replays a patch onto the text it was made from', () {
      final patch = DiffUtils.computeDiff('one two', 'one two three')!;
      expect(DiffUtils.applyDiff('one two', patch), 'one two three');
    });

    test('an empty patch is the identity', () {
      expect(DiffUtils.applyDiff('same', ''), 'same');
    });

    test(
        'a patch whose context is missing returns null rather than a '
        'partial result (DEEPSEEK L3)', () {
      final patch = DiffUtils.computeDiff(
          'the quick brown fox jumps', 'the quick red fox jumps')!;
      // dmp would apply what it can and hand back the rest untouched; that
      // is a value nobody ever stored.
      expect(DiffUtils.applyDiff('lorem ipsum dolor sit amet', patch), isNull);
    });

    test('a malformed patch string returns null', () {
      expect(DiffUtils.applyDiff('text', '@@ -not a hunk'), isNull);
    });
  });

  group('DiffUtils.isPatch', () {
    test('recognises every hunk header shape dmp writes', () {
      expect(DiffUtils.isPatch(DiffUtils.computeDiff('one two', 'one 2')!),
          isTrue);
      // One-character and empty ranges drop the count.
      expect(DiffUtils.isPatch(DiffUtils.computeDiff('', 'a')!), isTrue);
      expect(DiffUtils.isPatch('@@ -1 +1 @@\n-a\n+b\n'), isTrue);
      expect(DiffUtils.isPatch('@@ -0,0 +1,3 @@\n+abc\n'), isTrue);
    });

    test('a value that merely begins like a header is a full value', () {
      expect(DiffUtils.isPatch('@@ -not a hunk'), isFalse);
      expect(DiffUtils.isPatch('@@ - meeting notes'), isFalse);
      expect(DiffUtils.isPatch('@@ -1,2 +x @@'), isFalse);
      expect(DiffUtils.isPatch(''), isFalse);
    });
  });
}
