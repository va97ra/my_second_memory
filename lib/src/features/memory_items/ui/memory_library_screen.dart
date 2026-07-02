import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../domain/memory_type.dart';
import '../state/memory_items_controller.dart';

class MemoryLibraryScreen extends ConsumerStatefulWidget {
  const MemoryLibraryScreen({super.key});

  @override
  ConsumerState<MemoryLibraryScreen> createState() =>
      _MemoryLibraryScreenState();
}

class _MemoryLibraryScreenState extends ConsumerState<MemoryLibraryScreen> {
  MemoryType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final allItems = ref.watch(memoryItemsControllerProvider);
    final items = allItems.where((item) {
      return !item.isArchived &&
          (_selectedType == null || item.type == _selectedType);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.memoryBase)),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(strings.memoryBase),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  for (final type in MemoryType.values) ...[
                    FilterChip(
                      label: Text(type.label(locale)),
                      selected: _selectedType == type,
                      onSelected: (_) => setState(() => _selectedType = type),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(strings.emptyFeed)),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => MemoryItemCard(
                item: items[index],
                onOpen: () {
                  context.push(
                    '/memory/item/${Uri.encodeComponent(items[index].id)}',
                  );
                },
                onToggleDone: () {
                  ref
                      .read(memoryItemsControllerProvider.notifier)
                      .toggleDone(items[index].id);
                },
              ),
            ),
        ],
      ),
    );
  }
}
