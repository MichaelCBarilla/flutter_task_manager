// ignore: library_annotations
@Timeout(Duration(milliseconds: 500))
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/constants/test_tasks.dart';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  ProviderContainer makeProviderContainer(MockTasksRepository tasksRepository) {
    final container = ProviderContainer(
      overrides: [tasksRepositoryProvider.overrideWithValue(tasksRepository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUpAll(() {
    registerFallbackValue(const AsyncLoading<void>());
    registerFallbackValue(const AsyncData<List<Task>>([]));
  });

  group('TasksController', () {
    test('initial state is AsyncLoading then AsyncData with tasks', () async {
      // setup
      final taskRepository = MockTasksRepository();
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));

      final container = makeProviderContainer(taskRepository);
      final listener = Listener<AsyncValue<void>>();

      container.listen(
        tasksControllerProvider,
        listener.call,
        fireImmediately: true,
      );

      // run
      await container.read(tasksControllerProvider.future);

      // verify
      verifyInOrder([
        () => listener(null, const AsyncLoading<List<Task>>()),
        () => listener(
          const AsyncLoading<List<Task>>(),
          const AsyncData<List<Task>>(kTestTasks),
        ),
      ]);
      verifyNoMoreInteractions(listener);
    });
  });

  test('deleteTask removes task from state', () async {
    // setup
    final taskRepository = MockTasksRepository();

    final listener = Listener<AsyncValue<void>>();
    final container = makeProviderContainer(taskRepository);

    when(
      taskRepository.fetchTasksList,
    ).thenAnswer((_) => Future.value(kTestTasks));
    final initialState = await container.read(tasksControllerProvider.future);
    expect(initialState, kTestTasks);

    // Setup mock for delete call
    when(
      () => taskRepository.deleteTask('1'),
    ).thenAnswer((_) => Future.value());

    container.listen(
      tasksControllerProvider,
      listener.call,
      fireImmediately: false,
    );

    // run
    final controller = container.read(tasksControllerProvider.notifier);
    await controller.deleteTask('1');

    // verify
    final expectedTasksAfterDelete = kTestTasks
        .where((task) => task.pid != '1')
        .toList();

    expect(controller.state.value, expectedTasksAfterDelete);

    verifyInOrder([
      () =>
          listener(any(that: isA<AsyncData>()), any(that: isA<AsyncLoading>())),
      () =>
          listener(any(that: isA<AsyncLoading>()), any(that: isA<AsyncData>())),
    ]);
    verifyNoMoreInteractions(listener);
    verify(() => taskRepository.deleteTask('1')).called(1);
  });

  test('refresh gets latest values from repo', () async {
    // setup
    final taskRepository = MockTasksRepository();
    final container = makeProviderContainer(taskRepository);

    final refreshedTasks = [
      const Task(pid: '9', name: 'New Task'),
      const Task(pid: '10', name: 'Another Task'),
      ...kTestTasks,
    ];

    when(
      taskRepository.fetchTasksList,
    ).thenAnswer((_) => Future.value(kTestTasks));

    final listener = Listener<AsyncValue<List<Task>>>();

    // Just reading the provider will trigger the initial build
    final initialState = await container.read(tasksControllerProvider.future);
    expect(initialState, kTestTasks);

    // Setup mock for refresh call
    when(
      taskRepository.fetchTasksList,
    ).thenAnswer((_) => Future.value(refreshedTasks));

    container.listen(tasksControllerProvider, listener, fireImmediately: true);
    clearInteractions(listener);

    // run
    final controller = container.read(
      tasksControllerProvider.notifier,
    ); // second read does not trigger another build
    await controller.refresh();

    // verify
    expect(controller.state.value, refreshedTasks);

    verifyInOrder([
      () =>
          listener(any(that: isA<AsyncData>()), any(that: isA<AsyncLoading>())),
      () =>
          listener(any(that: isA<AsyncLoading>()), any(that: isA<AsyncData>())),
    ]);
    verifyNoMoreInteractions(listener);
    verify(() => taskRepository.fetchTasksList()).called(2);
  });
}
