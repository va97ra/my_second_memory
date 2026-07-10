import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/empty_state.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../home_feed/ui/widgets/memory_item_card.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';

class CalendarDayScreen extends ConsumerWidget {
  const CalendarDayScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final strings = AppStrings.of(context);
    final dayItems = ref
        .watch(memoryItemsControllerProvider)
        .where((item) => isSameDay(item.memoryDate, date))
        .toList()
      ..sort(_compareDayItems);
    final workingSchedules = ref
        .watch(shiftSchedulesControllerProvider)
        .where((schedule) => schedule.isWorkday(date))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE9DECF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1E7DA),
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(fallbackLocation: '/calendar'),
        titleSpacing: 0,
        title: Text(
          DateFormat.yMMMMEEEEd(locale).format(date),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF172033),
              ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFDDE7F3)),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF1E7DA),
              Color(0xFFE9DECF),
              Color(0xFFF4EBDF),
            ],
          ),
        ),
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
                            onToggleDone: () => ref
                                .read(memoryItemsControllerProvider.notifier)
                                .toggleDone(item.id),
                            onArchive: item.isArchived
                                ? null
                                : () => ref
                                    .read(
                                        memoryItemsControllerProvider.notifier)
                                    .archive(item.id),
                            onRestore: item.isArchived
                                ? () => ref
                                    .read(
                                        memoryItemsControllerProvider.notifier)
                                    .restore(item.id)
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
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${strings.workingToday}: ${schedule.organizationName}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF172033),
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
        color: const Color(0xFFFFFCF7).withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: Color(0xFFDED3C5))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
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
