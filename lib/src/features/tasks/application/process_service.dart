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
    } else if (Platform.isLinux) {
      return _getLinuxProcessesDart();
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

  Future<List<Task>> _getLinuxProcessesDart() async {
    try {
      // Use 'ps' command to get all processes with their PID and command
      // -e: all processes
      // -o: output format (pid,comm)
      // --no-headers: don't show column headers
      final result = await Process.run('ps', [
        '-e',
        '-o',
        'pid,comm',
        '--no-headers',
      ]);

      if (result.exitCode != 0) {
        print('Error running ps command: ${result.stderr}');
        return [];
      }

      final processes = <Task>[];
      final lines = (result.stdout as String).split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Parse the output: PID followed by command name
        final parts = trimmedLine.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final pid = parts[0];
          final name = parts.sublist(1).join(' '); // In case command has spaces

          // Skip kernel threads (usually in brackets like [kthreadd])
          if (name.startsWith('[') && name.endsWith(']')) {
            continue;
          }

          processes.add(Task(pid: pid, name: name));
        }
      }

      // Sort by name for consistency
      processes.sort((a, b) => a.name.compareTo(b.name));
      return processes;
    } catch (e) {
      print('Error getting Linux processes: $e');
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
      } else if (Platform.isLinux) {
        return _killLinuxProcessDart(pid);
      }
      return false;
    } catch (e) {
      print('Error killing process $pid: $e');
      return false;
    }
  }

  Future<bool> _killLinuxProcessDart(String pid) async {
    try {
      // Try SIGTERM first (graceful termination)
      final termResult = await Process.run('kill', ['-TERM', pid]);

      if (termResult.exitCode == 0) {
        return true;
      }

      // If SIGTERM failed, try SIGKILL (force termination)
      final killResult = await Process.run('kill', ['-KILL', pid]);
      return killResult.exitCode == 0;
    } catch (e) {
      print('Error killing Linux process $pid: $e');
      return false;
    }
  }
}
