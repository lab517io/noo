import 'package:flutter_test/flutter_test.dart';
import 'package:noo/domain/entities/task.dart';

void main() {
  group('Task.copyWith parentId', () {
    test('clears parentId when explicitly set to null', () {
      final task = Task.create(parentId: 42, title: 'child');

      final moved = task.copyWith(parentId: null);

      expect(moved.parentId, isNull);
    });

    test('keeps parentId when omitted', () {
      final task = Task.create(parentId: 42, title: 'child');

      final renamed = task.copyWith(title: 'renamed');

      expect(renamed.parentId, 42);
      expect(renamed.title, 'renamed');
    });

    test('replaces parentId with a new value', () {
      final task = Task.create(parentId: 42, title: 'child');

      final moved = task.copyWith(parentId: 7);

      expect(moved.parentId, 7);
    });
  });
}
