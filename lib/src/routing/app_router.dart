import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/features/tasks/presentation/tasks_list_screen.dart';
import 'package:flutter_task_manager/src/routing/not_found_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

enum AppRoute { home }

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: AppRoute.home.name,
        builder: (context, state) => const TasksListScreen(),
        routes: [],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}
