import 'package:flutter_task_manager/src/features/tasks/application/process_service.dart';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';

class RealTasksRepository implements TasksRepository {
  RealTasksRepository({ProcessService? processService})
    : _processService = processService ?? ProcessService();

  final ProcessService _processService;

  @override
  Future<List<Task>> fetchTasksList() async {
    return await _processService.getRunningProcesses();
  }

  @override
  Future<Task?> fetchTask(String pid) async {
    final tasks = await fetchTasksList();
    try {
      return tasks.firstWhere((task) => task.pid == pid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteTask(String pid) async {
    final success = await _processService.killProcess(pid);
    if (!success) {
      throw Exception('Failed to terminate process with PID: $pid');
    }
  }
}
