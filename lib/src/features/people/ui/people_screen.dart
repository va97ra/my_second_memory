import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final people = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => item.type == MemoryType.person && !item.isArchived)
        .toList();

    return AppShell(
      currentIndex: 2,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.people)),
          SliverList.builder(
            itemCount: people.length,
            itemBuilder: (context, index) => MemoryItemCard(
              item: people[index],
              onOpen: () {
                context.push(
                  '/memory/item/${Uri.encodeComponent(people[index].id)}',
                );
              },
              onToggleDone: () {
                ref
                    .read(memoryItemsControllerProvider.notifier)
                    .toggleDone(people[index].id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
