import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/chrome/main_page_header.dart';
import '../../../shared/ui/memory_card/memory_item_card.dart';
import '../../../shared/ui/memory_filter_button.dart';
import '../../recurrence/recurrence.dart';
import '../state/memory_item_selectors.dart';
import '../state/memory_items_controller.dart';

/// Архив памяти: всё, что убрали с глаз, и ничего больше.
///
/// Пустой архив показывает пустой лист — как пустой день ленты. Плашка
/// «здесь ничего нет» посреди страницы сообщала бы то же, что и сама пустота,
/// и уводила бы кнопкой туда, куда человек не собирался.
class MemoryLibraryScreen extends ConsumerStatefulWidget {
  const MemoryLibraryScreen({super.key});

  @override
  ConsumerState<MemoryLibraryScreen> createState() =>
      _MemoryLibraryScreenState();
}

class _MemoryLibraryScreenState extends ConsumerState<MemoryLibraryScreen> {
  FeedFilter _filter = FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = ref
        .watch(archivedMemoryItemsProvider)
        .where((item) => matchesFeedFilter(item, _filter))
        .toList();

    return WarmGradientBackground(
      child: Column(
        children: [
          MainPageHeader(
            title: strings.memoryArchive,
            backLocation: '/settings',
            // Фильтр стоит там же, где в ленте: видов записей больше десятка,
            // в ряд кнопок они не помещаются.
            trailing: MemoryFilterButton(
              filters: [FeedFilter.all, ...FeedFilter.byMemoryType],
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: items.length,
              itemBuilder: (context, index) => _card(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(MemoryItem item) {
    return MemoryItemCard(
      item: item,
      onOpen: () => context.pageTurnPush(
        '/memory/view/${Uri.encodeComponent(item.id)}',
      ),
      onRestore: () => _restore(item),
    );
  }

  /// Здесь вопрос шире, чем в ленте и в дне: там спрашивают, есть ли у
  /// вхождения своя строка, а тут — принадлежит ли оно серии вообще. Возврат
  /// через серию заодно убирает старую материализованную строку, если она
  /// осталась от прошлых версий.
  void _restore(MemoryItem item) {
    if (item.seriesId != null) {
      ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .restoreOccurrence(item);
      return;
    }
    ref.read(memoryItemsControllerProvider.notifier).restore(item.id);
  }
}
