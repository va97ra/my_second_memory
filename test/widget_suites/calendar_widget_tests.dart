part of '../widget_test.dart';

void registerCalendarWidgetTests() {
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
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository([
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
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository([
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
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_EmptyMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
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

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
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
    expect(barRect.left - cellRect.left, closeTo(2.5, 0.1));
    expect(cellRect.right - barRect.right, closeTo(2.5, 0.1));
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

  testWidgets('calendar changes month with horizontal swipes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    String monthLabel(DateTime month) {
      final value = DateFormat('LLLL', 'ru').format(month);
      return '${value[0].toUpperCase()}${value.substring(1)} ${month.year}';
    }

    final swipeArea = find.byKey(
      const ValueKey('calendar_month_swipe_area'),
    );
    expect(find.text(monthLabel(currentMonth)), findsOneWidget);

    await tester.drag(swipeArea, const Offset(-160, 0));
    await tester.pump();
    final incomingPage = find.byKey(
      const ValueKey('calendar_page_incoming'),
    );
    expect(
      find.byKey(const ValueKey('calendar_page_outgoing')),
      findsOneWidget,
    );
    expect(incomingPage, findsOneWidget);
    final incomingStartX =
        tester.widget<Transform>(incomingPage).transform.getTranslation().x;
    await tester.pump(const Duration(milliseconds: 100));
    final incomingMovedX =
        tester.widget<Transform>(incomingPage).transform.getTranslation().x;
    expect(incomingMovedX, lessThan(incomingStartX));
    expect(incomingMovedX, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.text(monthLabel(nextMonth)), findsOneWidget);

    await tester.drag(swipeArea, const Offset(160, 0));
    await tester.pumpAndSettle();
    expect(find.text(monthLabel(currentMonth)), findsOneWidget);
  });

  testWidgets('calendar changes year with animated vertical swipes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextYear = DateTime(now.year + 1, now.month);

    final swipeArea = find.byKey(
      const ValueKey('calendar_month_swipe_area'),
    );
    await tester.drag(swipeArea, const Offset(0, -180));
    await tester.pump();
    final incomingPage = find.byKey(
      const ValueKey('calendar_page_incoming'),
    );
    expect(
      find.byKey(const ValueKey('calendar_page_outgoing')),
      findsOneWidget,
    );
    expect(incomingPage, findsOneWidget);
    final incomingStartY =
        tester.widget<Transform>(incomingPage).transform.getTranslation().y;
    await tester.pump(const Duration(milliseconds: 100));
    final incomingMovedY =
        tester.widget<Transform>(incomingPage).transform.getTranslation().y;
    expect(incomingMovedY, lessThan(incomingStartY));
    expect(incomingMovedY, greaterThan(0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calendar_month_label')))
          .data,
      contains('${nextYear.year}'),
    );

    await tester.drag(swipeArea, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calendar_month_label')))
          .data,
      contains('${currentMonth.year}'),
    );
  });

  testWidgets('calendar chat bubble opens the full screen editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
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

  testWidgets('calendar fills portrait and scrolls only in short landscape',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    expect(
      find.byKey(const ValueKey('calendar_landscape_scroll')),
      findsNothing,
    );
    final gridBottom = tester
        .getBottomRight(find.byKey(const ValueKey('calendar_month_grid')))
        .dy;
    final hintTop =
        tester.getTopLeft(find.byKey(const ValueKey('calendar_hint'))).dy;
    expect(hintTop - gridBottom, closeTo(7, 0.1));

    await tester.binding.setSurfaceSize(const Size(900, 430));
    await tester.pumpAndSettle();
    final calendarScrollView =
        find.byKey(const ValueKey('calendar_landscape_scroll'));
    expect(
      tester.widget<CustomScrollView>(calendarScrollView).physics,
      isA<ClampingScrollPhysics>(),
    );
    final scrollable = find.descendant(
      of: calendarScrollView,
      matching: find.byType(Scrollable),
    );
    final positionBefore =
        tester.state<ScrollableState>(scrollable.first).position.pixels;
    await tester.drag(calendarScrollView, const Offset(0, -140));
    await tester.pumpAndSettle();
    final positionAfter =
        tester.state<ScrollableState>(scrollable.first).position.pixels;
    expect(positionAfter, greaterThan(positionBefore));

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar_landscape_scroll')),
      findsNothing,
    );
  });

  testWidgets('calendar day card can be completed and archived',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FeedMemoryRepository();
    final now = DateTime.now();

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'calendar');
    await tester.tap(find.text('${now.day}').first);
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_card_today-plan')))
          .height,
      108,
    );

    await tester.tap(
      find.byKey(const ValueKey('memory_card_done_today-plan')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'today-plan')
          .isDone,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('memory_card_archive_today-plan')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'today-plan')
          .isArchived,
      isTrue,
    );
    expect(find.text('План на сегодня'), findsOneWidget);
  });
}
