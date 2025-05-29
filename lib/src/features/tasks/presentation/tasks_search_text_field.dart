import 'package:flutter/material.dart';
import 'package:flutter_task_manager/src/localization/string_hardcoded.dart';

/// Search field used to filter Tasks by name
class TasksSearchTextField extends StatefulWidget {
  const TasksSearchTextField({super.key});

  @override
  State<TasksSearchTextField> createState() => _TasksSearchTextFieldState();
}

class _TasksSearchTextFieldState extends State<TasksSearchTextField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // * TextEditingControllers should be always disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // See this article for more info about how to use [ValueListenableBuilder]
    // with TextField:
    // https://codewithandrea.com/articles/flutter-text-field-form-validation/
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
                      // TODO: Clear search state
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          // TODO: Implement onChanged
          onChanged: null,
        );
      },
    );
  }
}
