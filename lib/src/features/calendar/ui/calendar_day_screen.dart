import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../memory_items/state/memory_item_selectors.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import '../state/calendar_preferences_controller.dart';
import '../state/holiday_providers.dart';
import 'widgets/add_record_bar.dart';
import 'widgets/day_records_list.dart';
import 'widgets/holiday_summary_card.dart';
import 'widgets/working_shift_chips.dart';

/// День календаря: что на него записано, кто в этот день работает и какие
/// праздники приходятся на него.
class CalendarDayScreen extends ConsumerWidget {
  const CalendarDayScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final items = ref.watch(memoryItemsForDayProvider(date)).toList()
      ..sort(compareByVisibleTime);
    final workingSchedules = ref
        .watch(shiftSchedulesControllerProvider)
        .where((schedule) => schedule.isWorkday(date))
        .toList();
    final holidays = ref.watch(appHolidaysProvider)
        ? ref.watch(holidayCalendarServiceProvider).holidaysForDate(date)
        : const <HolidayOccurrence>[];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(context, locale),
      body: WarmGradientBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (workingSchedules.isNotEmpty)
                WorkingShiftChips(schedules: workingSchedules, date: date),
              Expanded(child: DayRecordsList(items: items)),
              if (holidays.isNotEmpty)
                HolidaySummaryCard(
                  holidays: holidays,
                  date: date,
                  locale: locale,
                ),
              AddRecordBar(onPressed: () => _openNewRecord(context)),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, String locale) {
    return AppPageAppBar(
      fallbackLocation: '/calendar',
      title: Text(
        DateFormat.yMMMMEEEEd(locale).format(date),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.08,
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
    );
  }

  void _openNewRecord(BuildContext context) {
    context.pageTurnPush(
      '/memory/new?date=${DateFormat('yyyy-MM-dd').format(date)}',
    );
  }
}
