import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_state.dart';
import 'package:flutter_task_manager/src/localization/string_hardcoded.dart';

/// Search field used to filter Tasks by name
class TasksSearchTextField extends ConsumerStatefulWidget {
  const TasksSearchTextField({super.key});

  @override
  ConsumerState<TasksSearchTextField> createState() =>
      _TasksSearchTextFieldState();
}

class _TasksSearchTextFieldState extends ConsumerState<TasksSearchTextField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current search state if any
    final currentState = ref.read(tasksControllerProvider).value;
    if (currentState != null) {
      _controller.text = currentState.searchQuery;
    }
  }

  @override
  void dispose() {
    // * TextEditingControllers should be always disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to controller state changes to keep text field in sync
    ref.listen<AsyncValue<TasksState>>(tasksControllerProvider, (
      previous,
      next,
    ) {
      next.whenData((state) {
        if (_controller.text != state.searchQuery) {
          _controller.text = state.searchQuery;
        }
      });
    });

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          autofocus: false,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'Search tasks'.hardcoded,
            icon: const Icon(Icons.search),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _controller.clear();
                      ref.read(tasksControllerProvider.notifier).clearSearch();
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          onChanged: (query) {
            ref.read(tasksControllerProvider.notifier).updateSearchQuery(query);
          },
        );
      },
    );
  }
}
