import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/calendar/calendar.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_month_data.dart';
import 'package:ezhednevnik_v2/src/features/calendar/state/calendar_today_provider.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_day_cell.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/widgets/calendar_mini_month.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final swipeArea = find.byKey(const ValueKey('calendar_month_swipe_area'));

  String monthLabel(DateTime month) {
    final value = DateFormat('LLLL', 'ru').format(month);
    return '${value[0].toUpperCase()}${value.substring(1)} ${month.year}';
  }

  Finder miniMonth(int year, int month) =>
      find.byKey(ValueKey('calendar_mini_month_${year}_$month'));

  Future<void> openCalendar(
    WidgetTester tester, {
    Size? size,
    List<Override> overrides = const [],
  }) async {
    await tester.binding.setSurfaceSize(size ?? const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          ...overrides,
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository([
              ShiftSchedule(
                id: 'factory',
                organizationName: 'Завод',
                colorValue: 0xFF2563EB,
                startDate: today,
                workDays: 5,
                restDays: 2,
                vacations: [
                  ShiftVacation(
                    id: 'factory-vacation',
                    startDate: today,
                    durationDays: 1,
                  ),
                ],
              ),
            ]),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
  }

  /// Щипок двумя пальцами по странице: [spread] — во сколько раз меняется
  /// расстояние между пальцами. Один палец стоит, другой едет: так щиплют
  /// чаще, чем строго навстречу.
  Future<void> pinch(WidgetTester tester, double spread) async {
    // В низком ландшафте страница прокручивается и видна не вся: щиплют
    // видимую часть, над нижней панелью.
    final panelTop =
        tester.getRect(find.byKey(const ValueKey('bottom_calendar'))).top;
    final area = tester.getRect(swipeArea);
    final center = Offset(
      area.center.dx,
      (area.top + (area.bottom < panelTop ? area.bottom : panelTop)) / 2,
    );
    const half = 100.0;
    final still = await tester.startGesture(
      center - const Offset(half, 0),
      pointer: 1,
    );
    await tester.pump(const Duration(milliseconds: 16));
    final moving = await tester.startGesture(
      center + const Offset(half, 0),
      pointer: 2,
    );
    final travel = Offset(half * 2 * (spread - 1), 0);
    for (var step = 0; step < 10; step++) {
      await moving.moveBy(travel / 10);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await moving.up();
    await still.up();
    await tester.pumpAndSettle();
  }

  testWidgets('щипок внутрь показывает двенадцать месяцев года',
      (tester) async {
    await openCalendar(tester);
    await pinch(tester, 0.5);

    for (var month = 1; month <= 12; month++) {
      expect(miniMonth(today.year, month), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('calendar_year_label')), findsOneWidget);
    expect(find.text('${today.year}'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_month_grid')), findsNothing);
  });

  testWidgets('слабый щипок возвращает месяц на место', (tester) async {
    await openCalendar(tester);
    await pinch(tester, 0.85);

    expect(find.text(monthLabel(DateTime(today.year, today.month))),
        findsOneWidget);
    expect(miniMonth(today.year, 1), findsNothing);
  });

  testWidgets('нажатие на маленький месяц открывает его', (tester) async {
    await openCalendar(tester);
    await pinch(tester, 0.5);
    final target = today.month == 3 ? 4 : 3;

    await tester.tap(miniMonth(today.year, target));
    await tester.pumpAndSettle();

    expect(find.text(monthLabel(DateTime(today.year, target))), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_month_grid')), findsOneWidget);
    expect(miniMonth(today.year, target), findsNothing);
  });

  testWidgets(
      'на годовом виде смахивание листает годы, а щипок наружу '
      'открывает сегодняшний месяц', (tester) async {
    await openCalendar(tester);
    await pinch(tester, 0.5);

    await tester.drag(swipeArea, const Offset(-160, 0));
    await tester.pumpAndSettle();
    expect(miniMonth(today.year + 1, 1), findsOneWidget);
    expect(find.text('${today.year + 1}'), findsOneWidget);

    await pinch(tester, 2);
    expect(find.text(monthLabel(DateTime(today.year, today.month))),
        findsOneWidget);
  });

  testWidgets('кнопка «сегодня» на годовом виде открывает сегодняшний месяц',
      (tester) async {
    await openCalendar(tester);
    await pinch(tester, 0.5);
    await tester.tap(find.byKey(const ValueKey('calendar_next_month')));
    await tester.pumpAndSettle();
    expect(find.text('${today.year + 1}'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar_today')));
    await tester.pumpAndSettle();
    expect(find.text(monthLabel(DateTime(today.year, today.month))),
        findsOneWidget);
  });

  testWidgets('два пальца на днях не открывают день', (tester) async {
    await openCalendar(tester);
    final key = calendarDateStringKey(today);
    final cell = tester.getCenter(find.byKey(ValueKey('calendar_day_$key')));
    final neighbour = today.day == 1
        ? today.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 1));
    final other = tester.getCenter(
      find.byKey(ValueKey('calendar_day_${calendarDateStringKey(neighbour)}')),
    );

    final first = await tester.startGesture(cell, pointer: 1);
    await tester.pump(const Duration(milliseconds: 30));
    final second = await tester.startGesture(other, pointer: 2);
    await tester.pump(const Duration(milliseconds: 30));
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDayScreen), findsNothing);
    expect(find.byKey(const ValueKey('calendar_month_grid')), findsOneWidget);
  });

  testWidgets('миниатюра показывает дни теми же данными, что большой месяц',
      (tester) async {
    await openCalendar(tester);
    final month = DateTime(today.year, today.month);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CalendarScreen)),
    );
    final big = container.read(calendarMonthDataProvider(month));
    final todayCell = big.cellFor(today);
    expect(todayCell.items, isNotEmpty);
    expect(todayCell.shifts.single.isVacationWorkday(today), isTrue);

    await pinch(tester, 0.5);
    final mini = tester.widget<CalendarMiniMonth>(
      miniMonth(today.year, today.month),
    );
    for (final day in big.days.where((day) => day.month == month.month)) {
      expect(mini.data.cellFor(day), big.cellFor(day), reason: '$day');
    }
    expect(mini.today, today);
  });

  testWidgets(
      'сегодняшний день отмечен по часам календаря, а не по времени '
      'перерисовки', (tester) async {
    // Часы календаря уже перешли на соседний день, а месяц не перерисовывался.
    final next = today.day == 1
        ? today.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 1));
    await openCalendar(
      tester,
      overrides: [calendarTodayProvider.overrideWithValue(next)],
    );

    bool marked(DateTime day) => tester
        .widget<CalendarDayCell>(find.descendant(
          of: find
              .byKey(ValueKey('calendar_day_${calendarDateStringKey(day)}')),
          matching: find.byType(CalendarDayCell),
        ))
        .isToday;
    expect(marked(next), isTrue);
    expect(marked(today), isFalse);
  });

  for (final size in const [Size(360, 740), Size(740, 360)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('годовой вид раскладывается: $size, шрифт $scale',
          (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openCalendar(tester, size: size);
        await pinch(tester, 0.5);

        expect(tester.takeException(), isNull);
        final page = tester.getRect(swipeArea);
        for (var month = 1; month <= 12; month++) {
          final rect = tester.getRect(miniMonth(today.year, month));
          expect(page.contains(rect.topLeft), isTrue, reason: '$month');
          expect(rect.width, greaterThan(50), reason: '$month');
          expect(rect.height, greaterThan(50), reason: '$month');
        }
      });
    }
  }
}
