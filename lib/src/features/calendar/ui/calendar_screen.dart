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
import '../state/calendar_view.dart';
import 'calendar_page_turning.dart';
import 'calendar_zoom_handling.dart';
import 'widgets/calendar_header.dart';
import 'widgets/calendar_loading_view.dart';
import 'widgets/calendar_month_pages.dart';
import 'widgets/calendar_year_geometry.dart';
import 'widgets/calendar_zoom_transition.dart';

/// Календарь: страница месяца, которую листают стрелками и пальцем, а щипком
/// сводят к году.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin, CalendarPageTurning, CalendarZoomHandling {
  @override
  CalendarView view = CalendarView(month: DateTime.now());

  @override
  void dispose() {
    disposePageTurn();
    disposeZoom();
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
        // прокручивается — и с месяцем, и с годом: раскладка не меняется
        // посреди щипка.
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
        visibleMonth: view.month,
        showsYear: view.showsYear,
        locale: locale,
        schedules: schedules,
        onToday: view.showsYear ? openTodayMonth : goToToday,
        onChangeMonth: changeMonth,
      );

  Widget _panel(String locale, {required bool scrolls}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = CalendarYearGeometry(constraints.biggest);
        final zooming = zoomMonth;
        return PageSwipeArea(
          key: const ValueKey('calendar_month_swipe_area'),
          onHorizontalSwipe: changeMonth,
          // В прокручиваемом ландшафте вертикальный жест принадлежит прокрутке.
          onVerticalSwipe: scrolls ? null : changeYear,
          onPinchUpdate: (scale) => pinchUpdate(scale, geometry),
          onPinchEnd: pinchEnd,
          child: zooming == null
              ? _pages(locale, view.month, showsYear: view.showsYear)
              : CalendarZoomTransition(
                  zoom: zoom,
                  month: zooming.month,
                  monthPage: _pages(locale, zooming, showsYear: false),
                  yearPage: _pages(locale, view.month, showsYear: true),
                ),
        );
      },
    );
  }

  /// Страница месяца или года. Уходящая страница есть только у листания:
  /// у перехода масштаба свои две страницы.
  Widget _pages(String locale, DateTime month, {required bool showsYear}) {
    return CalendarMonthPages(
      locale: locale,
      visibleMonth: month,
      outgoingMonth: isZooming ? null : outgoingMonth,
      animation: pageTurn,
      axis: turnAxis,
      direction: turnDirection,
      showsYear: showsYear,
      onSelectDate: _openDay,
      onOpenMonth: openMonth,
    );
  }

  Future<void> _openDay(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    final location =
        '/calendar/day?date=${DateFormat('yyyy-MM-dd').format(day)}';
    final month = CalendarView(month: day);

    // Плитка успевает вернуться на место: переворот снимает страницу в картинку,
    // и нажатый день остался бы на снимке сжатым.
    await Future<void>.delayed(PressPulse.duration);
    if (!mounted) return;

    // На Windows день открывается поверх календаря, поэтому месяц
    // переносится уже после возвращения.
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.windows) {
      await context.pageTurnPush(location);
      if (mounted && view != month) setState(() => view = month);
      return;
    }
    if (view != month) setState(() => view = month);
    await context.pageTurnGo(location);
  }
}
