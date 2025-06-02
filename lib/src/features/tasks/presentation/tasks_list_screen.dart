import 'package:flutter/material.dart';
import 'package:flutter_task_manager/src/common_widgets/responsive_center.dart';
import 'package:flutter_task_manager/src/constants/app_sizes.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/home_app_bar.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_grid.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_search_text_field.dart';

/// Shows the list of Tasks with a search field at the top.
class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  // * Use a [ScrollController] to register a listener that dismisses the
  // * on-screen keyboard when the user scrolls.
  // * This is needed because this page has a search field that the user can
  // * type into.
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_dismissOnScreenKeyboard);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_dismissOnScreenKeyboard);
    super.dispose();
  }

  // When the search text field gets the focus, the keyboard appears on mobile.
  // This method is used to dismiss the keyboard when the user scrolls.
  void _dismissOnScreenKeyboard() {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: Column(
        children: [
          // Fixed search bar at the top
          const ResponsiveCenter(
            padding: EdgeInsets.all(Sizes.p16),
            child: TasksSearchTextField(),
          ),
          // Scrollable tasks grid below
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: const ResponsiveCenter(
                padding: EdgeInsets.all(Sizes.p16),
                child: TasksGrid(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
