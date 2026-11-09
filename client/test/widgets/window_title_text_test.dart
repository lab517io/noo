import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/window_title_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The window title names the app, the open database and the selected task —
/// the task by its own title only, never its path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('windowTitleText', () {
    expect(windowTitleText(null), 'Noo');
    expect(windowTitleText('work.noo'), 'Noo — work.noo');
    expect(windowTitleText('work.noo', taskTitle: 'Plans'),
        'Noo — work.noo — Plans');
    expect(windowTitleText(null, taskTitle: 'Plans'), 'Noo',
        reason: 'no task without a database');
  });

  test('selectedTaskTitleProvider follows the selection and renames',
      () async {
    SharedPreferences.setMockInitialValues({});
    final db = NooDatabase.memory();
    addTearDown(db.close);
    final parent = await db.createTask(
        worldId: WorldId.create().value, title: 'Parent', orderId: 0);
    final child = await db.createTask(
        worldId: WorldId.create().value,
        parentId: parent,
        title: 'Child',
        orderId: 0);
    final blank = await db.createTask(
        worldId: WorldId.create().value, title: '', orderId: 1);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final controller = container.read(taskTreeControllerProvider)!;
    // The provider starts the load itself; wait for it to finish.
    while (!controller.isLoaded || controller.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(container.read(selectedTaskTitleProvider), isNull);

    container.read(selectedTaskIdProvider.notifier).value = child;
    expect(container.read(selectedTaskTitleProvider), 'Child',
        reason: 'its own title, not Parent / Child');

    controller.updateTaskTitleInMemory(child, 'Renamed');
    expect(container.read(selectedTaskTitleProvider), 'Renamed');

    container.read(selectedTaskIdProvider.notifier).value = blank;
    expect(container.read(selectedTaskTitleProvider), 'Untitled');
  });
}
