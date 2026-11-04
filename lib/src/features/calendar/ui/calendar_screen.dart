import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import '../../shift_schedules/shift_schedules.dart';
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
  late final AnimationController _pageController;
  DateTime? _outgoingMonth;
  Axis _transitionAxis = Axis.horizontal;
  int _transitionDirection = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
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
    final schedules = ref.watch(shiftSchedulesControllerProvider);
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
        final panel = _panel(locale, scrolls: needsScroll);
        final header = _header(locale, schedules);

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

  Widget _panel(String locale, {required bool scrolls}) {
    return PageSwipeArea(
      key: const ValueKey('calendar_month_swipe_area'),
      onHorizontalSwipe: _changeMonth,
      // В прокручиваемом ландшафте вертикальный жест принадлежит прокрутке.
      onVerticalSwipe: scrolls ? null : _changeYear,
      child: CalendarMonthPages(
        locale: locale,
        visibleMonth: _visibleMonth,
        outgoingMonth: _outgoingMonth,
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
    final targetMonth = DateTime(now.year, now.month);
    if (targetMonth == _visibleMonth) return;

    _startTransition(
      targetMonth,
      axis: Axis.horizontal,
      direction: targetMonth.isAfter(_visibleMonth) ? 1 : -1,
    );
  }

  void _startTransition(
    DateTime targetMonth, {
    required Axis axis,
    required int direction,
  }) {
    if (_pageController.isAnimating || targetMonth == _visibleMonth) return;

    final outgoingMonth = _visibleMonth;
    setState(() {
      _outgoingMonth = outgoingMonth;
      _visibleMonth = targetMonth;
      _transitionAxis = axis;
      _transitionDirection = direction;
    });

    _pageController.forward(from: 0).whenComplete(() {
      if (!mounted || _outgoingMonth != outgoingMonth) return;
      setState(() => _outgoingMonth = null);
      _pageController.value = 0;
    });
  }

  Future<void> _openDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final location =
        '/calendar/day?date=${DateFormat('yyyy-MM-dd').format(day)}';
    final month = DateTime(day.year, day.month);

    // Плитка успевает вернуться на место: переворот снимает страницу в картинку,
    // и нажатый день остался бы на снимке сжатым.
    await Future<void>.delayed(PressPulse.duration);
    if (!mounted) return;

    // На Windows день открывается поверх календаря, поэтому месяц
    // переносится уже после возвращения.
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.windows) {
      await context.pageTurnPush(location);
      if (mounted && _visibleMonth != month) {
        setState(() => _visibleMonth = month);
      }
      return;
    }
    if (_visibleMonth != month) setState(() => _visibleMonth = month);
    await context.pageTurnGo(location);
  }
}
