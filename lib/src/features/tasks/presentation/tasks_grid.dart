import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/common_widgets/async_value_widget.dart';
import 'package:flutter_task_manager/src/constants/app_sizes.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/task_card.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_state.dart';
import 'package:flutter_task_manager/src/localization/string_hardcoded.dart';

/// A widget that displays the list of tasks that match the search query.
class TasksGrid extends ConsumerWidget {
  const TasksGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksState = ref.watch(tasksControllerProvider);

    return AsyncValueWidget<TasksState>(
      value: tasksState,
      data: (state) {
        final tasks = state.filteredTasks;

        if (tasks.isEmpty) {
          return Center(
            child: Text(
              state.searchQuery.isEmpty
                  ? 'No tasks found'.hardcoded
                  : 'No tasks match "${state.searchQuery}"'.hardcoded,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          );
        }

        return TasksLayoutGrid(
          itemCount: tasks.length,
          itemBuilder: (_, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onPressed: () {
                // TODO: Navigate to task details or perform action
              },
              onDelete: () async {
                final shouldDelete = await _showDeleteConfirmation(
                  context,
                  task,
                );
                if (shouldDelete == true) {
                  try {
                    await ref
                        .read(tasksControllerProvider.notifier)
                        .deleteTask(task.pid);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task "${task.name}" terminated'.hardcoded,
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to terminate task: $e'.hardcoded,
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, Task task) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kill task'.hardcoded),
          content: Text(
            'Are you sure you want to kill "${task.name}" (PID: ${task.pid})?'
                .hardcoded,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'.hardcoded),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Kill'.hardcoded),
            ),
          ],
        );
      },
    );
  }
}

/// Grid widget with content-sized items.
class TasksLayoutGrid extends StatelessWidget {
  const TasksLayoutGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;

  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // use a LayoutBuilder to determine the crossAxisCount
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 1 column for width < 500px
        // then add one more column for each 250px
        final crossAxisCount = max(1, width ~/ 250);
        // once the crossAxisCount is known, calculate the column and row sizes
        // set some flexible track sizes based on the crossAxisCount with 1.fr
        final columnSizes = List.generate(crossAxisCount, (_) => 1.fr);
        final numRows = (itemCount / crossAxisCount).ceil();
        // set all the row sizes to auto (self-sizing height)
        final rowSizes = List.generate(numRows, (_) => auto);
        return LayoutGrid(
          columnSizes: columnSizes,
          rowSizes: rowSizes,
          rowGap: Sizes.p24, // equivalent to mainAxisSpacing
          columnGap: Sizes.p24, // equivalent to crossAxisSpacing
          children: [
            for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
          ],
        );
      },
    );
  }
}
