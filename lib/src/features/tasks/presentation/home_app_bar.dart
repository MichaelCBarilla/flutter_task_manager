import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_manager/src/localization/string_hardcoded.dart';

class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(title: Text('Tasks'.hardcoded), actions: []);
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}
