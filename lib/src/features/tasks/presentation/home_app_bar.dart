import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_task_manager/src/localization/string_hardcoded.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksValue = ref.watch(tasksControllerProvider);

    return AppBar(
      title: Row(
        children: [
          Text('Task Manager'.hardcoded),
          const SizedBox(width: 16),
          if (tasksValue.hasValue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasksValue.value!.length} tasks',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(tasksControllerProvider.notifier).refresh();
          },
          tooltip: 'Refresh tasks'.hardcoded,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}
