import 'package:flutter/material.dart';
import 'package:flutter_task_manager/src/constants/app_sizes.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';

/// Used to show a single task inside a card.
const kDeleteButtonKey = Key('delete-button');

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  gapH8,
                  Row(
                    children: [
                      Icon(Icons.memory, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'PID: ${task.pid}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                    key: kDeleteButtonKey,
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
