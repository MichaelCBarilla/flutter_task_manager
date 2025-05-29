import 'package:flutter_task_manager/src/constants/test_tasks.dart';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_task_manager/src/utils/delay.dart';

class FakeTasksRepository implements TasksRepository {
  FakeTasksRepository({this.addDelay = true});
  final bool addDelay;

  @override
  Future<List<Task>> fetchTasksList() async {
    await delay(addDelay);
    // Always return the original test data (simulating fresh API call)
    return Future.value(List.from(kTestTasks));
  }

  @override
  Future<Task?> fetchTask(String pid) async {
    await delay(addDelay);
    try {
      return kTestTasks.firstWhere((task) => task.pid == pid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteTask(String pid) async {
    await delay(addDelay, 500);
    // In a real repo, this would make an API call to delete the task
  }
}
