// ignore: library_annotations
@Timeout(Duration(milliseconds: 500))
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/constants/test_tasks.dart';
import 'package:flutter_task_manager/src/features/tasks/data/tasks_repository.dart';
import 'package:flutter_task_manager/src/features/tasks/domain/task.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_controller.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_state.dart';
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
    registerFallbackValue(const AsyncLoading<TasksState>());
    registerFallbackValue(
      const AsyncData<TasksState>(TasksState(allTasks: [])),
    );
  });

  group('TasksController', () {
    test('initial state is AsyncLoading then AsyncData with tasks', () async {
      // setup
      final taskRepository = MockTasksRepository();
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));

      final container = makeProviderContainer(taskRepository);
      final listener = Listener<AsyncValue<TasksState>>();

      container.listen(
        tasksControllerProvider,
        listener.call,
        fireImmediately: true,
      );

      // run
      await container.read(tasksControllerProvider.future);

      // verify - check the exact sequence manually
      final capturedCalls = verify(
        () => listener(captureAny(), captureAny()),
      ).captured;

      // Should have 2 calls total
      expect(capturedCalls.length, 4);

      // First call: (null, AsyncLoading)
      expect(capturedCalls[0], isNull);
      expect(capturedCalls[1], isA<AsyncLoading<TasksState>>());

      // Second call: (AsyncLoading, AsyncData)
      expect(capturedCalls[2], isA<AsyncLoading<TasksState>>());
      expect(capturedCalls[3], isA<AsyncData<TasksState>>());

      verifyNoMoreInteractions(listener);
    });

    test('deleteTask removes task from state', () async {
      // setup
      final taskRepository = MockTasksRepository();

      final listener = Listener<AsyncValue<TasksState>>();
      final container = makeProviderContainer(taskRepository);

      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));
      final initialState = await container.read(tasksControllerProvider.future);
      expect(initialState.allTasks, kTestTasks);

      // Setup mock for delete call
      when(
        () => taskRepository.deleteTask('1'),
      ).thenAnswer((_) => Future.value());
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks.sublist(1)));

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

      expect(controller.state.value!.allTasks, expectedTasksAfterDelete);

      verifyInOrder([
        () => listener(
          any(that: isA<AsyncData>()),
          any(that: isA<AsyncLoading>()),
        ),
        () => listener(
          any(that: isA<AsyncLoading>()),
          any(that: isA<AsyncData>()),
        ),
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

      final listener = Listener<AsyncValue<TasksState>>();

      // Just reading the provider will trigger the initial build
      final initialState = await container.read(tasksControllerProvider.future);
      expect(initialState.allTasks, kTestTasks);

      // Setup mock for refresh call
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(refreshedTasks));

      container.listen(
        tasksControllerProvider,
        listener,
        fireImmediately: true,
      );
      clearInteractions(listener);

      // run
      final controller = container.read(
        tasksControllerProvider.notifier,
      ); // second read does not trigger another build
      await controller.refresh();

      // verify
      expect(controller.state.value!.allTasks, refreshedTasks);

      // No loading state to avoid autoRefresh UI flicker
      verifyInOrder([
        () =>
            listener(any(that: isA<AsyncData>()), any(that: isA<AsyncData>())),
      ]);
      verifyNoMoreInteractions(listener);
      verify(() => taskRepository.fetchTasksList()).called(2);
    });

    test('updateSearchQuery updates search state', () async {
      // setup
      final taskRepository = MockTasksRepository();
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));

      final container = makeProviderContainer(taskRepository);

      // wait for initial load
      final initialState = await container.read(tasksControllerProvider.future);
      expect(initialState.searchQuery, '');
      expect(initialState.filteredTasks.length, kTestTasks.length);

      // run
      final controller = container.read(tasksControllerProvider.notifier);
      controller.updateSearchQuery('Firefox');

      // verify
      final updatedState = controller.state.value!;
      expect(updatedState.searchQuery, 'Firefox');
      expect(updatedState.filteredTasks.length, 1);
      expect(updatedState.filteredTasks.first.name, 'Firefox');
    });

    test('clearSearch resets search query', () async {
      // setup
      final taskRepository = MockTasksRepository();
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));

      final container = makeProviderContainer(taskRepository);

      // wait for initial load
      await container.read(tasksControllerProvider.future);

      final controller = container.read(tasksControllerProvider.notifier);

      // set a search query first
      controller.updateSearchQuery('Firefox');
      expect(controller.state.value!.searchQuery, 'Firefox');

      // run
      controller.clearSearch();

      // verify
      final clearedState = controller.state.value!;
      expect(clearedState.searchQuery, '');
      expect(clearedState.filteredTasks.length, kTestTasks.length);
    });

    test('search query persists through refresh', () async {
      // setup
      final taskRepository = MockTasksRepository();
      when(
        taskRepository.fetchTasksList,
      ).thenAnswer((_) => Future.value(kTestTasks));

      final container = makeProviderContainer(taskRepository);
      await container.read(tasksControllerProvider.future);

      final controller = container.read(tasksControllerProvider.notifier);

      // set search query
      controller.updateSearchQuery('Chrome');
      expect(controller.state.value!.searchQuery, 'Chrome');

      // refresh
      await controller.refresh();

      // verify search query is preserved
      final refreshedState = controller.state.value!;
      expect(refreshedState.searchQuery, 'Chrome');
      expect(refreshedState.filteredTasks.length, 1);
      expect(refreshedState.filteredTasks.first.name, 'Chrome');
    });
  });
}
