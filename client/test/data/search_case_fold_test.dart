import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/fold_case.dart';
import 'package:noo/data/database/database.dart';

void main() {
  group('foldCase', () {
    test('folds Turkish dotless and dotted i together', () {
      expect(foldCase('ILIK'), foldCase('ılık'));
      expect(foldCase('İstanbul'), 'istanbul');
    });

    test('keeps the length, so offsets carry over', () {
      for (final s in ['İzmir', 'ILIK', 'Привет', 'Straße', 'ÉTÉ']) {
        expect(foldCase(s).length, s.length, reason: s);
      }
    });
  });

  group('searchTasks', () {
    late NooDatabase db;
    setUp(() => db = NooDatabase.memory());
    tearDown(() => db.close());

    Future<void> add(String title) =>
        db.createTask(worldId: title, title: title);

    test('ignores case outside ASCII', () async {
      await add('Привет мир');
      await add('Ilık su');
      await add('Übersicht');

      Future<List<String>> find(String q) async =>
          (await db.searchTasks(q)).map((r) => r.title).toList();

      expect(await find('привет'), ['Привет мир']);
      expect(await find('ılık'), ['Ilık su']);
      expect(await find('übersicht'), ['Übersicht']);
      expect(await find('ü'), ['Übersicht']);
    });

    test('ASCII queries are unchanged', () async {
      await add('Quarterly Report');
      expect((await db.searchTasks('quarterly')).single.title,
          'Quarterly Report');
    });
  });
}
