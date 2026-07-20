import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';

class CalendarDayScreen extends ConsumerWidget {
  const CalendarDayScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.of(context);
    final dayItems = ref.watch(memoryItemsForDayProvider(date)).toList()
      ..sort(_compareDayItems);
    final workingSchedules = ref
        .watch(shiftSchedulesControllerProvider)
        .where((schedule) => schedule.isWorkday(date))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(fallbackLocation: '/calendar'),
        titleSpacing: 0,
        title: Text(
          DateFormat.yMMMMEEEEd(locale).format(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: WarmGradientBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (workingSchedules.isNotEmpty)
                _WorkingShiftChips(schedules: workingSchedules),
              Expanded(
                child: dayItems.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: Icons.view_agenda_outlined,
                          title: strings.noMessagesForDay,
                          actionLabel: strings.addRecord,
                          onAction: () => _openNewRecord(context),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                        itemCount: dayItems.length,
                        itemBuilder: (context, index) {
                          final item = dayItems[index];
                          return MemoryItemCard(
                            item: item,
                            showDate: false,
                            margin: const EdgeInsets.only(bottom: 8),
                            onOpen: () => context.push(
                              '/memory/item/${Uri.encodeComponent(item.id)}',
                            ),
                            onToggleDone: () => _toggleDone(ref, item),
                            onArchive: item.isArchived
                                ? null
                                : () => _archive(ref, item),
                            onRestore: item.isArchived
                                ? () => _restore(ref, item)
                                : null,
                          );
                        },
                      ),
              ),
              _AddRecordBar(onPressed: () => _openNewRecord(context)),
            ],
          ),
        ),
      ),
    );
  }

  void _openNewRecord(BuildContext context) {
    context.push(
      '/memory/new?date=${DateFormat('yyyy-MM-dd').format(date)}',
    );
  }

  void _toggleDone(WidgetRef ref, MemoryItem item) {
    if (item.isGeneratedOccurrence) {
      ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .toggleOccurrenceDone(item);
    } else {
      ref.read(memoryItemsControllerProvider.notifier).toggleDone(item.id);
    }
  }

  void _archive(WidgetRef ref, MemoryItem item) {
    if (item.isGeneratedOccurrence) {
      ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .archiveOccurrence(item);
    } else {
      ref.read(memoryItemsControllerProvider.notifier).archive(item.id);
    }
  }

  void _restore(WidgetRef ref, MemoryItem item) {
    if (item.isGeneratedOccurrence) {
      ref
          .read(recurrenceSeriesControllerProvider.notifier)
          .restoreOccurrence(item);
    } else {
      ref.read(memoryItemsControllerProvider.notifier).restore(item.id);
    }
  }

  static int _compareDayItems(MemoryItem a, MemoryItem b) {
    final byTime = _visibleTimeMinutes(a).compareTo(_visibleTimeMinutes(b));
    return byTime != 0 ? byTime : a.createdAt.compareTo(b.createdAt);
  }

  static int _visibleTimeMinutes(MemoryItem item) {
    return item.timeMinutes ?? item.createdAt.hour * 60 + item.createdAt.minute;
  }
}

class _WorkingShiftChips extends StatelessWidget {
  const _WorkingShiftChips({required this.schedules});

  final List<ShiftSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final schedule in schedules)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(schedule.colorValue).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(schedule.colorValue).withValues(alpha: 0.34),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(schedule.colorValue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${strings.workingToday}: ${schedule.organizationName}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddRecordBar extends StatelessWidget {
  const _AddRecordBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('calendar_day_add_record'),
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(strings.addRecord),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
