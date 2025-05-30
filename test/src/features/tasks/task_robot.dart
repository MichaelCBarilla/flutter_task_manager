import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/common_widgets/error_message_widget.dart';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/task_card.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_grid.dart';
import 'package:flutter_test/flutter_test.dart';

class TaskRobot {
  TaskRobot(this.tester);
  final WidgetTester tester;

  Future<void> pumpTasksGrid({TasksRepository? tasksRepository}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (tasksRepository != null)
            tasksRepositoryProvider.overrideWithValue(tasksRepository),
        ],
        child: MaterialApp(home: Scaffold(body: TasksGrid())),
      ),
    );
  }

  void expectEmptyTasksMessage() {
    final finder = find.text('No tasks found');
    expect(finder, findsOneWidget);
  }

  void expectTasksGrid({amount = 8}) {
    final finder = find.byType(TaskCard);
    expect(finder, findsExactly(amount));
  }

  Future<void> tapTaskCardDelete() async {
    final taskCardDelete = find.byKey(kDeleteButtonKey);
    expect(taskCardDelete, findsExactly(8));
    await tester.tap(taskCardDelete.first);
    await tester.pump();
  }

  void expectDeleteConfirmFound() {
    final finder = find.text('Kill task');
    expect(finder, findsOneWidget);
  }

  Future<void> tapTaskCardDeleteCancel() async {
    final taskCardDeleteCancel = find.text('Cancel');
    expect(taskCardDeleteCancel, findsOneWidget);
    await tester.tap(taskCardDeleteCancel);
    await tester.pump();
  }

  Future<void> tapTaskCardDeleteKill() async {
    final taskCardDeleteKill = find.text('Kill');
    expect(taskCardDeleteKill, findsOneWidget);
    await tester.tap(taskCardDeleteKill);
    await tester.pump();
  }

  void expectDeleteConfirmNotFound() {
    final finder = find.text('Kill task');
    expect(finder, findsNothing);
  }

  void expectErrorMessageFound() {
    final finder = find.byType(ErrorMessageWidget);
    expect(finder, findsOneWidget);
  }

  void expectErrorMessageNotFound() {
    final finder = find.byType(ErrorMessageWidget);
    expect(finder, findsNothing);
  }

  void expectErrorMessageSnackbarFound() {
    final finder = find.text('Failed to terminate task');
    expect(finder, findsNothing);
  }
}
