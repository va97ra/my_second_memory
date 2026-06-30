import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/state/memory_items_controller.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final groups = groupItemsByDate(ref.watch(memoryItemsControllerProvider));
    final locale = Localizations.localeOf(context).languageCode;

    return AppShell(
      currentIndex: 1,
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(strings.calendar)),
          if (groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(strings.emptyFeed)),
            )
          else
            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Text(
                    DateFormat.yMMMMEEEEd(locale).format(group.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: group.items.length,
                itemBuilder: (context, index) =>
                    MemoryItemCard(item: group.items[index]),
              ),
            ],
        ],
      ),
    );
  }
}
