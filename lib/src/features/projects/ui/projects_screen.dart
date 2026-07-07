import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final projects = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => item.type == MemoryType.project && !item.isArchived)
        .toList();

    return AppShell(
      currentIndex: 3,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(strings.projects),
          ),
          SliverList.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) => MemoryItemCard(
              item: projects[index],
              onOpen: () {
                context.push(
                  '/memory/item/${Uri.encodeComponent(projects[index].id)}',
                );
              },
              onToggleDone: () {
                ref
                    .read(memoryItemsControllerProvider.notifier)
                    .toggleDone(projects[index].id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
