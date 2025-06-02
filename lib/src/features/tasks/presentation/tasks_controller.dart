import 'dart:async';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_controller.g.dart';

/// Controller manages the application state for tasks
/// This is where we handle the business logic and state mutations
@riverpod
class TasksController extends _$TasksController {
  Timer? _refreshTimer;

  @override
  FutureOr<TasksState> build() async {
    // Start auto-refresh timer
    _startAutoRefresh();

    // Cancel timer when the provider is disposed
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    final repository = ref.read(tasksRepositoryProvider);
    final allTasks = await repository.fetchTasksList();
    return TasksState(allTasks: allTasks);
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refresh();
    });
  }

  /// Update the search query
  void updateSearchQuery(String query) {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    }
  }

  /// Clear the search query
  void clearSearch() {
    updateSearchQuery('');
  }

  Future<void> deleteTask(String pid) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.deleteTask(pid);

      // After deleting, refresh the entire list
      await refresh();
    } catch (error, stackTrace) {
      // Restore previous state on error
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    final currentState = state.value;
    final currentSearchQuery = currentState?.searchQuery ?? '';

    // Don't show loading state during auto-refresh to avoid UI flicker
    final isAutoRefresh = state.hasValue;

    if (!isAutoRefresh) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = ref.read(tasksRepositoryProvider);
      final tasks = await repository.fetchTasksList();
      state = AsyncValue.data(
        TasksState(
          allTasks: tasks,
          searchQuery: currentSearchQuery, // Preserve search query
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
