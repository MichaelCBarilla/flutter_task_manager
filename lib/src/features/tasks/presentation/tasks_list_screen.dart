import 'package:flutter/material.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/home_app_bar.dart';

class TasksListScreen extends StatelessWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const HomeAppBar(), body: const Placeholder());
  }
}
