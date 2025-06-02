import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';

class ProcessService {
  static const _channel = MethodChannel(
    'com.example.flutterTaskManager/process',
  );

  Future<List<Task>> getRunningProcesses() async {
    if (Platform.isMacOS) {
      return _getMacOSProcesses();
    } else if (Platform.isWindows) {
      return _getWindowsProcesses();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  Future<List<Task>> _getMacOSProcesses() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getProcesses');
      final processes = <Task>[];

      for (final process in result) {
        final map = process as Map<dynamic, dynamic>;
        final pid = map['pid'] as String;
        final name = map['name'] as String;

        processes.add(Task(pid: pid, name: name));
      }

      // Sort by name for consistency
      processes.sort((a, b) => a.name.compareTo(b.name));
      return processes;
    } catch (e) {
      print('Error getting macOS processes: $e');
      return [];
    }
  }

  Future<List<Task>> _getWindowsProcesses() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getProcesses');
      final processes = <Task>[];

      for (final process in result) {
        final map = process as Map<dynamic, dynamic>;
        final pid = map['pid'] as String;
        final name = map['name'] as String;

        // Remove .exe extension for cleaner display
        final cleanName = name.endsWith('.exe') 
            ? name.substring(0, name.length - 4)
            : name;

        processes.add(Task(pid: pid, name: cleanName));
      }

      // Sort by name for consistency
      processes.sort((a, b) => a.name.compareTo(b.name));
      return processes;
    } catch (e) {
      print('Error getting Windows processes: $e');
      return [];
    }
  }

  Future<bool> killProcess(String pid) async {
    try {
      if (Platform.isMacOS || Platform.isWindows) {
        // Use method channel for macOS and Windows
        final bool result = await _channel.invokeMethod('killProcess', {
          'pid': pid,
        });
        return result;
      }
      return false;
    } catch (e) {
      print('Error killing process $pid: $e');
      return false;
    }
  }
}