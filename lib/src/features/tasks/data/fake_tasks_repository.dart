import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/constants/test_products.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_task_manager/src/utils/delay.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_tasks_repository.g.dart';

class FakeTasksRepository {
  FakeTasksRepository({this.addDelay = true});
  final bool addDelay;
  final List<Task> _tasks = kTestTasks;

  List<Task> getTasksList() {
    return _tasks;
  }

  Task? getTask(String pid) {
    return _getTask(_tasks, pid);
  }

  Future<List<Task>> fetchTasksList() async {
    await delay(addDelay);
    return Future.value(_tasks);
  }

  Stream<List<Task>> watchTasksList() async* {
    await delay(addDelay);
    yield _tasks;
  }

  Stream<Task?> watchTask(String pid) {
    return watchTasksList().map((tasks) => _getTask(tasks, pid));
  }

  static Task? _getTask(List<Task> tasks, String pid) {
    try {
      return tasks.firstWhere((task) => task.pid == pid);
    } catch (e) {
      return null;
    }
  }
}

@riverpod
FakeTasksRepository tasksRepository(Ref ref) {
  return FakeTasksRepository();
}

@riverpod
Stream<List<Task>> tasksListStream(Ref ref) {
  final tasksRepository = ref.watch(tasksRepositoryProvider);
  return tasksRepository.watchTasksList();
}

@riverpod
Future<List<Task>> tasksListFuture(Ref ref) {
  final tasksRepository = ref.watch(tasksRepositoryProvider);
  return tasksRepository.fetchTasksList();
}

@riverpod
Stream<Task?> task(Ref ref, String pid) {
  final tasksRepository = ref.watch(tasksRepositoryProvider);
  return tasksRepository.watchTask(pid);
}
