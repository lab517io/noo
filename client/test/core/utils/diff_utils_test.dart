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
}
