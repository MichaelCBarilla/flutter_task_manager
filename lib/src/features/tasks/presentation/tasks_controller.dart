import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_controller.g.dart';

/// Controller manages the application state for tasks
/// This is where we handle the business logic and state mutations
@riverpod
class TasksController extends _$TasksController {
  @override
  FutureOr<List<Task>> build() async {
    final repository = ref.read(tasksRepositoryProvider);
    final allTasks = await repository.fetchTasksList();
    return allTasks;
  }

  Future<void> deleteTask(String pid) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.deleteTask(pid);

      final currentTasks = await AsyncValue.guard(() async {
        final tasks = state.value ?? [];
        return tasks.where((task) => task.pid != pid).toList();
      });

      state = currentTasks;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tasksRepositoryProvider);
      final tasks = await repository.fetchTasksList();
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
