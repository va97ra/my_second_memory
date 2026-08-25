import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../../shared/ui/memory_card/memory_item_card.dart';
import 'package:ez_domain/ez_domain.dart';
import '../state/memory_items_controller.dart';
import '../../recurrence/recurrence.dart';
import '../state/memory_item_selectors.dart';
import '../../../navigation/page_turn_navigation.dart';

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
    final items = ref.watch(archivedMemoryItemsProvider).where((item) {
      return _selectedType == null || item.type == _selectedType;
    }).toList();

    return WarmGradientBackground(
      child: CustomScrollView(
        slivers: [
          MainSliverAppBar(
            title: strings.memoryArchive,
            backLocation: '/settings',
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(strings.archive),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  for (final type in editableMemoryTypes) ...[
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
              child: Center(
                child: AppEmptyState(
                  icon: Icons.inventory_2_rounded,
                  title: strings.emptyArchive,
                  actionLabel: strings.feed,
                  onAction: () => context.pageTurnGo(
                    '/',
                    direction: PageTurnDirection.backward,
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return MemoryItemCard(
                  item: item,
                  onOpen: () {
                    context.pageTurnPush(
                      '/memory/view/${Uri.encodeComponent(item.id)}',
                    );
                  },
                  onRestore: () {
                    // Здесь вопрос шире, чем в ленте и в дне: там спрашивают,
                    // есть ли у вхождения своя строка, а тут — принадлежит ли
                    // оно серии вообще. Возврат через серию заодно убирает
                    // старую материализованную строку, если она осталась от
                    // прошлых версий.
                    if (item.seriesId != null) {
                      ref
                          .read(recurrenceSeriesControllerProvider.notifier)
                          .restoreOccurrence(item);
                    } else {
                      ref
                          .read(memoryItemsControllerProvider.notifier)
                          .restore(item.id);
                    }
                  },
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }
}
