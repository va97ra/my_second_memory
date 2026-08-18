import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late final AnimationController _calendarPageController;
  DateTime? _outgoingMonth;
  Axis _transitionAxis = Axis.horizontal;
  int _transitionDirection = 1;
  double _monthDragExtent = 0;
  double _yearDragExtent = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _calendarPageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _calendarPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final loadState = ref.watch(memoryItemsLoadProvider);
    final monthData = ref.watch(calendarMonthDataProvider(_visibleMonth));
    final outgoingMonth = _outgoingMonth;
    final outgoingMonthData = outgoingMonth == null
        ? null
        : ref.watch(calendarMonthDataProvider(outgoingMonth));
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
        final panel = _buildPanel(
          locale,
          monthData,
          outgoingMonthData,
          showHints,
          enableYearSwipe: !needsLandscapeScroll,
        );

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
    CalendarMonthData? outgoingMonthData,
    bool showHints, {
    required bool enableYearSwipe,
  }) {
    return GestureDetector(
      key: const ValueKey('calendar_month_swipe_area'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _monthDragExtent = 0,
      onHorizontalDragUpdate: (details) {
        _monthDragExtent += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: _finishMonthSwipe,
      onHorizontalDragCancel: () => _monthDragExtent = 0,
      onVerticalDragStart: enableYearSwipe ? (_) => _yearDragExtent = 0 : null,
      onVerticalDragUpdate: enableYearSwipe
          ? (details) {
              _yearDragExtent += details.primaryDelta ?? 0;
            }
          : null,
      onVerticalDragEnd: enableYearSwipe ? _finishYearSwipe : null,
      onVerticalDragCancel: enableYearSwipe ? () => _yearDragExtent = 0 : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: AnimatedBuilder(
              animation: _calendarPageController,
              builder: (context, _) {
                final outgoingMonth = _outgoingMonth;
                if (outgoingMonth == null || outgoingMonthData == null) {
                  return _calendarPanel(
                    locale: locale,
                    visibleMonth: _visibleMonth,
                    monthData: monthData,
                    showHints: showHints,
                  );
                }

                final progress = Curves.easeOutCubic.transform(
                  _calendarPageController.value,
                );
                final horizontal = _transitionAxis == Axis.horizontal;
                final extent =
                    horizontal ? constraints.maxWidth : constraints.maxHeight;
                final outgoingOffset =
                    -_transitionDirection * extent * progress;
                final incomingOffset =
                    _transitionDirection * extent * (1 - progress);
                Offset offsetFor(double value) =>
                    horizontal ? Offset(value, 0) : Offset(0, value);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.translate(
                      key: const ValueKey('calendar_page_outgoing'),
                      offset: offsetFor(outgoingOffset),
                      child: IgnorePointer(
                        child: _calendarPanel(
                          locale: locale,
                          visibleMonth: outgoingMonth,
                          monthData: outgoingMonthData,
                          showHints: showHints,
                        ),
                      ),
                    ),
                    Transform.translate(
                      key: const ValueKey('calendar_page_incoming'),
                      offset: offsetFor(incomingOffset),
                      child: _calendarPanel(
                        locale: locale,
                        visibleMonth: _visibleMonth,
                        monthData: monthData,
                        showHints: showHints,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _calendarPanel({
    required String locale,
    required DateTime visibleMonth,
    required CalendarMonthData monthData,
    required bool showHints,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: _CalendarPanel(
        locale: locale,
        visibleMonth: visibleMonth,
        selectedDate: _selectedDate,
        monthData: monthData,
        showHints: showHints,
        onPreviousMonth: () => _changeMonth(-1),
        onNextMonth: () => _changeMonth(1),
        onToday: _goToToday,
        onSelectDate: _openDayDialog,
      ),
    );
  }

  void _finishMonthSwipe(DragEndDetails details) {
    const distanceThreshold = 48.0;
    const velocityThreshold = 350.0;
    final velocity = details.primaryVelocity ?? 0;
    final distance = _monthDragExtent;
    _monthDragExtent = 0;

    if (distance.abs() >= distanceThreshold) {
      _changeMonth(distance < 0 ? 1 : -1);
      return;
    }
    if (velocity.abs() >= velocityThreshold) {
      _changeMonth(velocity < 0 ? 1 : -1);
    }
  }

  void _finishYearSwipe(DragEndDetails details) {
    const distanceThreshold = 48.0;
    const velocityThreshold = 350.0;
    final velocity = details.primaryVelocity ?? 0;
    final distance = _yearDragExtent;
    _yearDragExtent = 0;

    if (distance.abs() >= distanceThreshold) {
      _changeYear(distance < 0 ? 1 : -1);
      return;
    }
    if (velocity.abs() >= velocityThreshold) {
      _changeYear(velocity < 0 ? 1 : -1);
    }
  }

  void _changeMonth(int offset) {
    _startCalendarTransition(
      DateTime(_visibleMonth.year, _visibleMonth.month + offset),
      axis: Axis.horizontal,
      direction: offset.sign,
    );
  }

  void _changeYear(int offset) {
    _startCalendarTransition(
      DateTime(_visibleMonth.year + offset, _visibleMonth.month),
      axis: Axis.vertical,
      direction: offset.sign,
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetMonth = DateTime(today.year, today.month);
    if (targetMonth == _visibleMonth) {
      setState(() => _selectedDate = today);
      return;
    }

    final direction = targetMonth.isAfter(_visibleMonth) ? 1 : -1;
    _startCalendarTransition(
      targetMonth,
      axis: Axis.horizontal,
      direction: direction,
      selectedDate: today,
    );
  }

  void _startCalendarTransition(
    DateTime targetMonth, {
    required Axis axis,
    required int direction,
    DateTime? selectedDate,
  }) {
    if (_calendarPageController.isAnimating || targetMonth == _visibleMonth) {
      return;
    }

    final outgoingMonth = _visibleMonth;
    setState(() {
      _outgoingMonth = outgoingMonth;
      _visibleMonth = targetMonth;
      _transitionAxis = axis;
      _transitionDirection = direction;
      if (selectedDate != null) _selectedDate = selectedDate;
    });

    _calendarPageController.forward(from: 0).whenComplete(() {
      if (!mounted || _outgoingMonth != outgoingMonth) return;
      setState(() => _outgoingMonth = null);
      _calendarPageController.value = 0;
    });
  }

  Future<void> _openDayDialog(DateTime date) async {
    final selected = DateTime(date.year, date.month, date.day);
    final location =
        '/calendar/day?date=${DateFormat('yyyy-MM-dd').format(selected)}';
    final isWindows =
        !kIsWeb && Theme.of(context).platform == TargetPlatform.windows;
    if (!isWindows) {
      setState(() {
        _selectedDate = selected;
        _visibleMonth = DateTime(selected.year, selected.month);
      });
      context.go(location);
      return;
    }

    await context.push(location);
    if (!mounted) return;

    final selectedMonth = DateTime(selected.year, selected.month);
    if (_selectedDate == selected && _visibleMonth == selectedMonth) return;
    setState(() {
      _selectedDate = selected;
      _visibleMonth = selectedMonth;
    });
  }
}
