import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';

/// State class that holds both tasks and search query
class TasksState {
  const TasksState({required this.allTasks, this.searchQuery = ''});

  final List<Task> allTasks;
  final String searchQuery;

  /// Get filtered tasks based on search query
  List<Task> get filteredTasks {
    if (searchQuery.isEmpty) {
      return allTasks;
    }
    return allTasks.where((task) {
      return task.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  TasksState copyWith({List<Task>? allTasks, String? searchQuery}) {
    return TasksState(
      allTasks: allTasks ?? this.allTasks,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
