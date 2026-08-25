import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('calendar header holds its bands at ${scale}x text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        testProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              FakeShiftScheduleRepository([
                ShiftSchedule(
                  id: 'factory',
                  organizationName: 'СВ Консалтинг',
                  colorValue: 0xFF2563EB,
                  startDate: DateTime.now(),
                  workDays: 5,
                  restDays: 2,
                ),
              ]),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'calendar');

      // The band never spills: pumping would have thrown on an overflow.
      final header = tester.getRect(
        find.byKey(const ValueKey('calendar_header_card')),
      );
      expect(header.height % notebookPageLineHeight, closeTo(0, 0.01));
      expect(
        find.byKey(const ValueKey('calendar_shift_legend')),
        findsOneWidget,
      );
    });
  }

  testWidgets('calendar header wears the same bands as the feed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository([
              ShiftSchedule(
                id: 'factory',
                organizationName: 'Завод',
                colorValue: 0xFF2563EB,
                startDate: DateTime.now(),
                workDays: 5,
                restDays: 2,
              ),
            ]),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    final header = tester.getRect(
      find.byKey(const ValueKey('calendar_header_card')),
    );
    expect(
      (header.top - notebookPageLineTop) % notebookPageLineHeight,
      closeTo(0, 0.01),
    );
    expect(header.height % notebookPageLineHeight, closeTo(0, 0.01));

    // Title, month navigation and the shift legend all live in the header.
    expect(find.text('Календарь'), findsWidgets);
    expect(find.byKey(const ValueKey('calendar_month_label')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar_today')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar_shift_legend')),
      findsOneWidget,
    );
  });

  testWidgets('empty calendar day stays clean without an empty-state card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(EmptyMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    final todayCell = find.text('${today.day}').first;
    await tester.ensureVisible(todayCell);
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    expect(find.text('На этот день пока ничего нет'), findsNothing);
    expect(find.text('За этот день пока ничего нет'), findsNothing);
    expect(
      find.byKey(const ValueKey('calendar_day_add_record')),
      findsOneWidget,
    );
  });

  testWidgets('calendar date opens day and add opens editor on selected date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    expect(find.byTooltip('Сегодня'), findsOneWidget);
    expect(find.text('09:30 План на сегодня'), findsOneWidget);
    final eventBar = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('calendar_event_bar_today-plan')),
    );
    expect(
      (eventBar.decoration as BoxDecoration).color,
      const Color(0xFF7A5AF8),
    );
    final eventDecoration = eventBar.decoration as BoxDecoration;
    expect(eventDecoration.borderRadius, BorderRadius.zero);
    expect((eventDecoration.border! as Border).top.width, 0.75);
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final cellRect = tester.getRect(
      find.byKey(ValueKey('calendar_day_$todayKey')),
    );
    final barRect = tester.getRect(
      find.byKey(const ValueKey('calendar_event_bar_today-plan')),
    );
    // Полоса записи упирается в обводку ячейки, какой бы толщины та ни была.
    final cellDecoration = tester
        .widget<AnimatedContainer>(
          find
              .descendant(
                of: find.byKey(ValueKey('calendar_day_$todayKey')),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        )
        .decoration! as BoxDecoration;
    final cellBorder = (cellDecoration.border! as Border).top.width;
    expect(barRect.left - cellRect.left, closeTo(cellBorder, 0.1));
    expect(cellRect.right - barRect.right, closeTo(cellBorder, 0.1));
    expect(
      tester.widget<Text>(find.text('09:30 План на сегодня')).style?.fontSize,
      7.5,
    );

    final firstDay = DateTime(today.year, today.month);
    final leadingDays = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final visibleCellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    final firstVisible = firstDay.subtract(Duration(days: leadingDays));
    final omittedNextRowDate =
        firstVisible.add(Duration(days: visibleCellCount));
    final omittedDateKey = '${omittedNextRowDate.year}-'
        '${omittedNextRowDate.month.toString().padLeft(2, '0')}-'
        '${omittedNextRowDate.day.toString().padLeft(2, '0')}';
    expect(
      find.byKey(ValueKey('calendar_day_$omittedDateKey')),
      findsNothing,
    );

    final todayCell = find.text('${today.day}').first;
    await tester.ensureVisible(todayCell);
    await tester.pumpAndSettle();
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Архивная запись'), findsOneWidget);
    expect(find.text('Архив'), findsOneWidget);
    expect(find.text('Добавить запись'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar_day_add_record')),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Сообщение'), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
    expect(find.byIcon(Icons.attach_file), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calendar_day_add_record')));
    await tester.pumpAndSettle();

    expect(find.text('Новая запись'), findsOneWidget);
    expect(
      find.text(DateFormat('d MMM y', 'ru').format(today)),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Запись'),
      'Новая запись из календаря',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Редактировать запись'), findsOneWidget);
    expect(find.text('Новая запись из календаря'), findsOneWidget);
    final savedCloud = tester.widget<Icon>(
      find.byKey(const ValueKey('memory_autosave_saved')),
    );
    expect(savedCloud.color, const Color(0xFF168653));
    expect(
      repository.savedItems.any(
        (item) =>
            item.title == 'Новая запись из календаря' &&
            item.body == 'Новая запись из календаря' &&
            item.memoryDate == today,
      ),
      isTrue,
    );
  });

  testWidgets('calendar chat bubble opens the full screen editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('План на сегодня'));
    await tester.pumpAndSettle();

    expect(find.text('Редактировать запись'), findsOneWidget);
    expect(find.text('Запись'), findsOneWidget);
    expect(find.text('Название'), findsNothing);
  });
}
