import 'package:flutter_task_manager/src/constants/test_tasks.dart';
import 'package:flutter_task_manager/src/features/tasks/data/fake_tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../task_robot.dart';

void main() {
  testWidgets('Empty Message Shows', (tester) async {
    final r = TaskRobot(tester);
    final tasksRepository = MockTasksRepository();
    when(
      tasksRepository.fetchTasksList,
    ).thenAnswer((_) => Future<List<Task>>.value([]));
    await r.pumpTasksGrid(tasksRepository: tasksRepository);
    await tester.pump(); // pump again to get past loading state
    r.expectEmptyTasksMessage();
  });

  testWidgets('Tasks Delete, Cancel', (tester) async {
    final r = TaskRobot(tester);
    final tasksRepository = MockTasksRepository();
    when(
      tasksRepository.fetchTasksList,
    ).thenAnswer((_) => Future<List<Task>>.value(kTestTasks));
    await r.pumpTasksGrid(tasksRepository: tasksRepository);
    await tester.pump(); // pump again to get past loading state
    r.expectTasksGrid();
    await r.tapTaskCardDelete();
    r.expectDeleteConfirmFound();
    await r.tapTaskCardDeleteCancel();
    r.expectDeleteConfirmNotFound();
  });

  testWidgets('Tasks Delete, success', (tester) async {
    final r = TaskRobot(tester);
    final tasksRepository = FakeTasksRepository(addDelay: false);
    await r.pumpTasksGrid(tasksRepository: tasksRepository);
    await tester.pump(); // pump again to get past loading state
    r.expectTasksGrid();
    await r.tapTaskCardDelete();
    r.expectDeleteConfirmFound();
    await r.tapTaskCardDeleteKill();
    r.expectDeleteConfirmNotFound();
    r.expectErrorMessageNotFound();
  });

  testWidgets('Tasks Delete, failure', (tester) async {
    final r = TaskRobot(tester);
    final tasksRepository = MockTasksRepository();
    when(
      tasksRepository.fetchTasksList,
    ).thenAnswer((_) => Future<List<Task>>.value(kTestTasks));
    await r.pumpTasksGrid(tasksRepository: tasksRepository);
    await tester.pump(); // pump again to get past loading state
    r.expectTasksGrid();

    final exception = Exception('Failed to delete task');
    when(() => tasksRepository.deleteTask('1')).thenThrow(exception);

    await r.tapTaskCardDelete();
    r.expectDeleteConfirmFound();
    await r.tapTaskCardDeleteKill();
    r.expectDeleteConfirmNotFound();
    r.expectErrorMessageFound();
    r.expectErrorMessageSnackbarFound();
  });
}
