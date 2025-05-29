import 'package:flutter/material.dart';
import 'package:flutter_task_manager/src/constants/app_sizes.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';

/// Used to show a single task inside a card.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onPressed,
    this.onDelete,
  });
  final Task task;
  final VoidCallback? onPressed;
  final VoidCallback? onDelete;

  // * Keys for testing using find.byKey()
  static const taskCardKey = Key('task-card');
  static const deleteButtonKey = Key('delete-button');

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: taskCardKey,
        onTap: onPressed,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    task.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  gapH24,
                  Text(
                    task.pid,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  gapH4,
                ],
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: Sizes.p4,
                right: Sizes.p4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: deleteButtonKey,
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(Sizes.p4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
