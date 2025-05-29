import 'package:flutter_task_manager/src/constants/test_tasks.dart';
import 'package:flutter_task_manager/src/features/tasks/data/fake_tasks_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FakeTasksRepository makeTasksRepository() =>
      FakeTasksRepository(addDelay: false);

  group('FakeTasksRepository', () {
    test('fetchTasksList returns global list', () async {
      final tasksRepository = makeTasksRepository();
      expect(await tasksRepository.fetchTasksList(), kTestTasks);
    });

    test('fetchTask(1) returns first item', () async {
      final tasksRepository = makeTasksRepository();
      expect(await tasksRepository.fetchTask('1'), kTestTasks[0]);
    });

    test('fetchTask(100) returns null', () async {
      final tasksRepository = makeTasksRepository();
      expect(await tasksRepository.fetchTask('100'), null);
    });

    test('deleteTask completes without error', () async {
      final tasksRepository = makeTasksRepository();
      // Should complete without throwing
      await expectLater(tasksRepository.deleteTask('1'), completes);
    });
  });
}
