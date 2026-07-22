import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_surface_palette.dart';
import '../../../core/theme/notebook/notebook_background.dart';
import '../../../core/theme/notebook/notebook_visuals.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../domain/holiday_occurrence.dart';
import '../state/calendar_month_data.dart';
import '../state/calendar_preferences_controller.dart';
import '../../home_feed/domain/feed_rules.dart';
import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../memory_items/ui/widgets/memory_item_presentation.dart';
import '../../shift_schedules/domain/shift_schedule.dart';
import '../../recurrence/state/recurrence_controller.dart';

part 'widgets/calendar_panel_widgets.dart';
part 'widgets/calendar_day_cell.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final loadState = ref.watch(memoryItemsLoadProvider);
    final monthData = ref.watch(calendarMonthDataProvider(_visibleMonth));
    final showHints = ref.watch(appHintsProvider);
    ref.watch(recurrenceLoadProvider);

    if (loadState.isLoading || loadState.hasError) {
      return WarmGradientBackground(
        child: Column(
          children: [
            MainPageHeader(title: strings.calendar, backLocation: '/'),
            Expanded(
              child: Center(
                child: loadState.isLoading
                    ? const CircularProgressIndicator()
                    : Text(strings.loadFailed),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final isLandscape =
            viewportConstraints.maxWidth > viewportConstraints.maxHeight;
        final needsLandscapeScroll =
            isLandscape && viewportConstraints.maxHeight < 680;
        final panel = _buildPanel(locale, monthData, showHints);

        return WarmGradientBackground(
          child: needsLandscapeScroll
              ? CustomScrollView(
                  key: const ValueKey('calendar_landscape_scroll'),
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    MainSliverAppBar(
                      title: strings.calendar,
                      backLocation: '/',
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 600,
                        child: panel,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    MainPageHeader(
                      title: strings.calendar,
                      backLocation: '/',
                    ),
                    Expanded(child: panel),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildPanel(
    String locale,
    CalendarMonthData monthData,
    bool showHints,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: _CalendarPanel(
        locale: locale,
        visibleMonth: _visibleMonth,
        selectedDate: _selectedDate,
        monthData: monthData,
        showHints: showHints,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onToday: () {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          setState(() {
            _selectedDate = today;
            _visibleMonth = DateTime(today.year, today.month);
          });
        },
        onSelectDate: _openDayDialog,
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  Future<void> _openDayDialog(DateTime date) async {
    final selected = DateTime(date.year, date.month, date.day);
    setState(() {
      _selectedDate = selected;
      _visibleMonth = DateTime(selected.year, selected.month);
    });

    context
        .go('/calendar/day?date=${DateFormat('yyyy-MM-dd').format(selected)}');
  }
}
