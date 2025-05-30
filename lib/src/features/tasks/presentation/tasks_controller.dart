import 'dart:async';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_controller.g.dart';

/// Controller manages the application state for tasks
/// This is where we handle the business logic and state mutations
@riverpod
class TasksController extends _$TasksController {
  Timer? _refreshTimer;

  @override
  FutureOr<List<Task>> build() async {
    // Start auto-refresh timer
    _startAutoRefresh();

    // Cancel timer when the provider is disposed
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    final repository = ref.read(tasksRepositoryProvider);
    final allTasks = await repository.fetchTasksList();
    return allTasks;
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refresh();
    });
  }

  Future<void> deleteTask(String pid) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.deleteTask(pid);

      // After deleting, refresh the entire list
      await refresh();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    // Don't show loading state during auto-refresh to avoid UI flicker
    final isAutoRefresh = state.hasValue;

    if (!isAutoRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = ref.read(tasksRepositoryProvider);
      final tasks = await repository.fetchTasksList();
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
