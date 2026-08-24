import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../state/calendar_month_data.dart';
import '../state/calendar_preferences_controller.dart';
import 'widgets/calendar_header.dart';
import 'widgets/calendar_loading_view.dart';
import 'widgets/calendar_month_pages.dart';

/// Календарь месяца: страница, которую листают стрелками и пальцем.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  late final AnimationController _pageController;
  DateTime? _outgoingMonth;
  Axis _transitionAxis = Axis.horizontal;
  int _transitionDirection = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final loadState = ref.watch(memoryItemsLoadProvider);
    final monthData = ref.watch(calendarMonthDataProvider(_visibleMonth));
    final showHints = ref.watch(appHintsProvider);
    ref.watch(recurrenceLoadProvider);

    if (loadState.isLoading || loadState.hasError) {
      return CalendarLoadingView(
        header: _header(locale, const []),
        isLoading: loadState.isLoading,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        // В низком ландшафте страница не помещается целиком, поэтому экран
        // прокручивается.
        final needsScroll = isLandscape && constraints.maxHeight < 680;
        final panel = _panel(locale, showHints, scrolls: needsScroll);
        final header = _header(locale, monthData.shiftSchedules);

        return WarmGradientBackground(
          child: needsScroll
              ? CustomScrollView(
                  key: const ValueKey('calendar_landscape_scroll'),
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: header),
                    SliverToBoxAdapter(
                      child: SizedBox(height: 600, child: panel),
                    ),
                  ],
                )
              : Column(children: [header, Expanded(child: panel)]),
        );
      },
    );
  }

  Widget _header(String locale, List<ShiftSchedule> schedules) =>
      CalendarHeader(
        visibleMonth: _visibleMonth,
        locale: locale,
        schedules: schedules,
        onToday: _goToToday,
        onChangeMonth: _changeMonth,
      );

  Widget _panel(String locale, bool showHints, {required bool scrolls}) {
    return PageSwipeArea(
      key: const ValueKey('calendar_month_swipe_area'),
      onHorizontalSwipe: _changeMonth,
      // В прокручиваемом ландшафте вертикальный жест принадлежит прокрутке.
      onVerticalSwipe: scrolls ? null : _changeYear,
      child: CalendarMonthPages(
        locale: locale,
        visibleMonth: _visibleMonth,
        outgoingMonth: _outgoingMonth,
        selectedDate: _selectedDate,
        showHints: showHints,
        animation: _pageController,
        axis: _transitionAxis,
        direction: _transitionDirection,
        onSelectDate: _openDay,
      ),
    );
  }

  void _changeMonth(int offset) => _startTransition(
        DateTime(_visibleMonth.year, _visibleMonth.month + offset),
        axis: Axis.horizontal,
        direction: offset.sign,
      );

  void _changeYear(int offset) => _startTransition(
        DateTime(_visibleMonth.year + offset, _visibleMonth.month),
        axis: Axis.vertical,
        direction: offset.sign,
      );

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetMonth = DateTime(today.year, today.month);
    if (targetMonth == _visibleMonth) {
      setState(() => _selectedDate = today);
      return;
    }

    _startTransition(
      targetMonth,
      axis: Axis.horizontal,
      direction: targetMonth.isAfter(_visibleMonth) ? 1 : -1,
      selectedDate: today,
    );
  }

  void _startTransition(
    DateTime targetMonth, {
    required Axis axis,
    required int direction,
    DateTime? selectedDate,
  }) {
    if (_pageController.isAnimating || targetMonth == _visibleMonth) return;

    final outgoingMonth = _visibleMonth;
    setState(() {
      _outgoingMonth = outgoingMonth;
      _visibleMonth = targetMonth;
      _transitionAxis = axis;
      _transitionDirection = direction;
      if (selectedDate != null) _selectedDate = selectedDate;
    });

    _pageController.forward(from: 0).whenComplete(() {
      if (!mounted || _outgoingMonth != outgoingMonth) return;
      setState(() => _outgoingMonth = null);
      _pageController.value = 0;
    });
  }

  Future<void> _openDay(DateTime date) async {
    final selected = DateTime(date.year, date.month, date.day);
    final location =
        '/calendar/day?date=${DateFormat('yyyy-MM-dd').format(selected)}';

    // На Windows день открывается поверх календаря, поэтому выбранная дата
    // переносится уже после возвращения.
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.windows) {
      await context.pageTurnPush(location);
      if (mounted) _selectDay(selected);
      return;
    }
    _selectDay(selected);
    await context.pageTurnGo(location);
  }

  void _selectDay(DateTime day) {
    final month = DateTime(day.year, day.month);
    if (_selectedDate == day && _visibleMonth == month) return;
    setState(() {
      _selectedDate = day;
      _visibleMonth = month;
    });
  }
}
