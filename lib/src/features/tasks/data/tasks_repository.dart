import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/features/tasks/data/fake_tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/data/real_tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_repository.g.dart';

abstract class TasksRepository {
  Future<List<Task>> fetchTasksList();
  Future<Task?> fetchTask(String pid);
  Future<void> deleteTask(String pid);
}

@riverpod
TasksRepository tasksRepository(Ref ref) {
  // Use real repository for desktop platforms, fake for others
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return RealTasksRepository();
  }
  return FakeTasksRepository();
}
