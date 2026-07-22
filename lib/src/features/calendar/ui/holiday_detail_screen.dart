import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/notebook/notebook_background.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../domain/holiday_calendar_service.dart';
import '../domain/holiday_occurrence.dart';
import '../state/calendar_preferences_controller.dart';

class HolidayDetailScreen extends ConsumerWidget {
  const HolidayDetailScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final isRu = locale == 'ru';
    final holidays = ref.watch(appHolidaysProvider)
        ? ref.watch(holidayCalendarServiceProvider).holidaysForDate(date)
        : const <HolidayOccurrence>[];
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppPageAppBar(
        fallbackLocation:
            '/calendar/day?date=${DateFormat('yyyy-MM-dd').format(date)}',
        title: Text(
          isRu ? 'Праздники' : 'Holidays',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      body: WarmGradientBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                DateFormat.yMMMMEEEEd(locale).format(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              for (final holiday in holidays) ...[
                NotebookPageSurface(
                  showLines: true,
                  lineTop: 54,
                  lineHeight: 26,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.celebration_outlined,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              holiday.title(locale),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        holiday.description(locale),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              height: 1.55,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
