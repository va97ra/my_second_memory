import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/ui/widgets/memory_item_presentation.dart';
import '../domain/recurrence_series.dart';
import '../state/recurrence_controller.dart';

class RecurringOverviewScreen extends ConsumerStatefulWidget {
  const RecurringOverviewScreen({required this.frequency, super.key});

  final RecurrenceFrequency frequency;

  @override
  ConsumerState<RecurringOverviewScreen> createState() =>
      _RecurringOverviewScreenState();
}

class _RecurringOverviewScreenState
    extends ConsumerState<RecurringOverviewScreen> {
  late DateTime _period = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final series = ref
        .watch(recurrenceSeriesControllerProvider)
        .where((item) => item.frequency == widget.frequency)
        .toList();
    final seriesById = {for (final item in series) item.id: item};
    final occurrences = ref.watch(memoryItemsControllerProvider).where((item) {
      if (!seriesById.containsKey(item.seriesId)) return false;
      return widget.frequency == RecurrenceFrequency.monthly
          ? item.memoryDate.year == _period.year &&
              item.memoryDate.month == _period.month
          : item.memoryDate.year == _period.year;
    }).toList()
      ..sort((a, b) => a.memoryDate.compareTo(b.memoryDate));
    final title = widget.frequency == RecurrenceFrequency.monthly
        ? (locale == 'ru' ? 'Каждый месяц' : 'Every month')
        : (locale == 'ru' ? 'Каждый год' : 'Every year');
    final periodText = widget.frequency == RecurrenceFrequency.monthly
        ? DateFormat.yMMMM(locale).format(_period)
        : DateFormat.y(locale).format(_period);

    return Scaffold(
      body: WarmGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              MainPageHeader(title: title, backLocation: '/'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        periodText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: occurrences.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: Icons.event_repeat,
                          title: locale == 'ru'
                              ? 'Повторяющихся записей нет'
                              : 'No recurring records',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: occurrences.length,
                        itemBuilder: (context, index) {
                          final item = occurrences[index];
                          final entry = seriesById[item.seriesId]!;
                          return _OccurrenceTile(
                            item: item,
                            enabled: entry.isEnabled,
                            onOpen: () => context.push(
                              '/memory/item/${Uri.encodeComponent(item.id)}',
                            ),
                            onEnabled: (value) => ref
                                .read(
                                    recurrenceSeriesControllerProvider.notifier)
                                .setEnabled(entry.id, value),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _move(int amount) {
    setState(() {
      _period = widget.frequency == RecurrenceFrequency.monthly
          ? DateTime(_period.year, _period.month + amount)
          : DateTime(_period.year + amount, _period.month);
    });
  }
}

class _OccurrenceTile extends StatelessWidget {
  const _OccurrenceTile({
    required this.item,
    required this.enabled,
    required this.onOpen,
    required this.onEnabled,
  });

  final MemoryItem item;
  final bool enabled;
  final VoidCallback onOpen;
  final ValueChanged<bool> onEnabled;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final color = memoryTypeColor(item.type);
    final age = item.type == MemoryType.birthday && item.birthYear != null
        ? item.memoryDate.year - item.birthYear!
        : null;
    final amount = item.amountMinor == null
        ? null
        : '${NumberFormat.decimalPattern('ru').format(item.amountMinor! ~/ 100)} ₽';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onOpen,
        leading: Icon(memoryTypeIcon(item.type), color: color),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([
          DateFormat.yMMMd(locale).format(item.memoryDate),
          if (age != null) '$age ${locale == 'ru' ? 'лет' : 'years'}',
          if (amount != null) amount,
          if (item.type == MemoryType.payment && item.isDone)
            locale == 'ru' ? 'Оплачено' : 'Paid',
        ].join(' · ')),
        trailing: Switch(value: enabled, onChanged: onEnabled),
      ),
    );
  }
}
