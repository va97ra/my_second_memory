part of '../widget_test.dart';

void registerHomeFeedWidgetTests() {
  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final oldDay = today.subtract(const Duration(days: 5));

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

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.darkTheme?.scaffoldBackgroundColor,
      Colors.transparent,
    );
    expect(
      app.theme?.scaffoldBackgroundColor,
      Colors.transparent,
    );
    final cardShape = app.theme?.cardTheme.shape as RoundedRectangleBorder;
    final dialogShape = app.theme?.dialogTheme.shape as RoundedRectangleBorder;
    final bottomSheetShape =
        app.theme?.bottomSheetTheme.shape as RoundedRectangleBorder;
    expect(cardShape.borderRadius, BorderRadius.circular(8));
    expect(dialogShape.borderRadius, BorderRadius.circular(8));
    expect(
      bottomSheetShape.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(8)),
    );
    expect(find.text('Лента дня'), findsWidgets);
    expect(find.text('Лента'), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Аккаунты'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Люди'), findsNothing);
    expect(find.text('Проекты'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Подготовить задачи на день'), findsOneWidget);
    expect(find.text('Ежедневник V2'), findsWidgets);
    expect(
      find.byKey(const ValueKey('memory_card_body_today-project')),
      findsNothing,
    );
    expect(
      find.text(
        'Сегодня · ${DateFormat('d MMMM', 'ru').format(today)}',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Вчера · ${DateFormat('d MMMM', 'ru').format(yesterday)} · 1 запись',
      ),
      findsOneWidget,
    );
    expect(find.text('Вчерашняя заметка'), findsNothing);
    expect(find.text('Позавчерашняя заметка'), findsNothing);
    await tester.tap(
      find.byKey(ValueKey(
        'feed_day_divider_${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(ValueKey(
        'feed_day_divider_${oldDay.year}-${oldDay.month.toString().padLeft(2, '0')}-${oldDay.day.toString().padLeft(2, '0')}',
      )),
      220,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('feed_dated_scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        '${DateFormat('d MMMM y', 'ru').format(oldDay)} · 1 запись',
      ),
      findsOneWidget,
    );
    expect(find.text('Старая активная запись'), findsNothing);
    await tester.tap(
      find.byKey(ValueKey(
        'feed_day_divider_${oldDay.year}-${oldDay.month.toString().padLeft(2, '0')}-${oldDay.day.toString().padLeft(2, '0')}',
      )),
    );
    await tester.pumpAndSettle();
    expect(find.text('Старая активная запись'), findsOneWidget);
    expect(find.text('Архивная запись'), findsNothing);
    expect(find.text(DateFormat.MMM('ru').format(today)), findsNothing);
    expect(find.byIcon(Icons.delete_rounded), findsNothing);
    expect(find.byIcon(Icons.task_alt_rounded), findsWidgets);
    expect(find.byIcon(Icons.archive_rounded), findsWidgets);

    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
  });

  testWidgets('past feed day collapses into the old divider and expands',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String dateKey(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

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

    final yesterdayDivider =
        find.byKey(ValueKey('feed_day_divider_${dateKey(yesterday)}'));
    await tester.scrollUntilVisible(
      yesterdayDivider,
      100,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('feed_dated_scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(yesterdayDivider, findsOneWidget);
    expect(find.textContaining('1 запись'), findsWidgets);
    expect(find.text('Вчерашняя заметка'), findsNothing);
    await tester.tap(yesterdayDivider);
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    await tester.tap(yesterdayDivider);
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsNothing);
  });

  testWidgets('feed keeps panels and notes static while future days reveal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(
            _FutureFeedMemoryRepository(),
          ),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String dayKey(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final notesDivider = find.byKey(const ValueKey('feed_notes_divider'));
    final todayDivider =
        find.byKey(ValueKey('feed_day_divider_${dayKey(today)}'));
    final closestFutureDivider = find.byKey(
      ValueKey(
        'feed_day_divider_${dayKey(today.add(const Duration(days: 1)))}',
      ),
    );
    expect(notesDivider, findsOneWidget);
    expect(todayDivider, findsOneWidget);
    expect(
      tester.getTopLeft(todayDivider).dy,
      closeTo(tester.getBottomLeft(notesDivider).dy, 1),
    );
    expect(find.text('Фокус сегодня'), findsOneWidget);

    final datedScroll = find.byKey(const ValueKey('feed_dated_scroll'));
    final informers = find.byKey(const ValueKey('feed_recurring_informers'));
    final scrollView = tester.widget<CustomScrollView>(datedScroll);
    final controller = scrollView.controller!;
    final initialOffset = controller.offset;
    expect(initialOffset, greaterThan(0));
    final notesTop = tester.getTopLeft(notesDivider).dy;
    final informersTop = tester.getTopLeft(informers).dy;

    await tester.drag(
      datedScroll,
      const Offset(0, 220),
    );
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(initialOffset));
    expect(tester.getTopLeft(notesDivider).dy, closeTo(notesTop, 1));
    expect(tester.getTopLeft(informers).dy, closeTo(informersTop, 1));
    expect(
      tester.getTopLeft(closestFutureDivider).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(notesDivider).dy - 1),
    );

    final manualOffset = controller.offset;
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, closeTo(manualOffset, 0.1));

    controller.jumpTo(initialOffset);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(todayDivider).dy,
      closeTo(tester.getBottomLeft(notesDivider).dy, 1),
    );

    await tester.drag(datedScroll, const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(initialOffset));
    await tester.tap(find.text('Аккаунты').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лента').last);
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(initialOffset, 0.1));
    expect(
      tester.getTopLeft(todayDivider).dy,
      closeTo(tester.getBottomLeft(notesDivider).dy, 1),
    );

    await tester.tap(notesDivider);
    await tester.pumpAndSettle();
    expect(find.text('Постоянная записка'), findsOneWidget);
    await tester.tap(notesDivider);
    await tester.pumpAndSettle();
    expect(find.text('Постоянная записка'), findsNothing);
    expect(
      tester.getTopLeft(todayDivider).dy,
      closeTo(tester.getBottomLeft(notesDivider).dy, 1),
    );
  });

  testWidgets(
      'undated notes have their own collapsible feed section and editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FeedMemoryRepository();

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

    final divider = find.byKey(const ValueKey('feed_notes_divider'));
    expect(find.text('Записки · 1'), findsOneWidget);
    expect(find.text('Карта дочери'), findsNothing);
    expect(
      tester.getCenter(find.text('Записки · 1')).dx,
      closeTo(tester.getCenter(divider).dx, 0.1),
    );
    final leftLine = find.descendant(
      of: divider,
      matching: find.byKey(const ValueKey('labeled_divider_left_line')),
    );
    final rightLine = find.descendant(
      of: divider,
      matching: find.byKey(const ValueKey('labeled_divider_right_line')),
    );
    expect(tester.getSize(leftLine).width, tester.getSize(rightLine).width);

    await tester.tap(divider);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
    await tester.tap(divider);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    expect(find.text('Новая записка'), findsOneWidget);
    expect(find.byKey(const ValueKey('memory_type_picker')), findsNothing);
    expect(find.byKey(const ValueKey('memory_date_picker')), findsNothing);
    expect(find.byKey(const ValueKey('memory_time_picker')), findsNothing);
    expect(find.byKey(const ValueKey('record_editor_panel')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('record_editor_text')),
      'Важные данные',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.savedItems.any((item) => item.isUndated), isTrue);
  });

  testWidgets('undated note archives and restores through memory archive',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FeedMemoryRepository();

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
    final notesDivider = find.byKey(const ValueKey('feed_notes_divider'));
    await tester.tap(notesDivider);
    await tester.pumpAndSettle();
    final noteArchive = find.byKey(
      const ValueKey('memory_card_archive_undated-daughter-card'),
    );
    await tester.tap(noteArchive);
    await tester.pumpAndSettle();
    expect(find.text('Записки · 0'), findsOneWidget);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Архив памяти'));
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('memory_card_archive_undated-daughter-card'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

    await tester.tap(find.text('Лента').last);
    await tester.pumpAndSettle();
    final restoredDivider = find.byKey(const ValueKey('feed_notes_divider'));
    expect(find.text('Записки · 1'), findsOneWidget);
    expect(find.text('Карта дочери'), findsNothing);
    await tester.tap(restoredDivider);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
  });

  testWidgets('hides empty previous day sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(
            _TodayOnlyMemoryRepository(),
          ),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Только сегодня'), findsOneWidget);
    expect(find.text('Записей нет'), findsNothing);
  });

  testWidgets('holiday detail shows category and historical description',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HolidayDetailScreen(date: DateTime(2026, 8, 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('День ВДВ'), findsOneWidget);
    expect(find.text('Воинский праздник'), findsOneWidget);
    expect(find.textContaining('2 августа 1930 года'), findsOneWidget);
    expect(find.text('День железнодорожника'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed card can be completed and opened read-only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();

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
    expect(
      find.byKey(const ValueKey('memory_card_type_today-plan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('memory_card_content_today-plan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('memory_card_actions_today-plan')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_card_today-plan')))
          .height,
      76,
    );
    expect(
      find.byKey(const ValueKey('memory_card_title_today-plan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('memory_card_body_today-plan')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('memory_card_title_today-plan')),
          )
          .maxLines,
      1,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('memory_card_body_today-plan')),
          )
          .maxLines,
      2,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('memory_card_done_today-plan'))),
      const Size.square(36),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('memory_card_archive_today-plan')),
      ),
      const Size.square(36),
    );
    await tester.tap(
      find.byKey(const ValueKey('memory_card_done_today-plan')),
    );
    await tester.pumpAndSettle();

    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Выполнено'), findsOneWidget);
    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'today-plan')
          .status,
      MemoryStatus.done,
    );

    await tester.tap(find.text('План на сегодня'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_readonly_view')), findsOneWidget);
    expect(find.text('Редактировать запись'), findsNothing);
    expect(find.byIcon(Icons.save_rounded), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Запись'), findsNothing);
    expect(find.text('Тип записи'), findsNothing);
  });

  testWidgets('feed card can be archived from the feed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _TodayOnlyMemoryRepository();

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
    expect(find.text('Только сегодня'), findsOneWidget);

    await tester.tap(find.byTooltip('Скрыть в архив'));
    await tester.pumpAndSettle();

    expect(find.text('Только сегодня'), findsNothing);
    expect(repository.savedItems.single.status, MemoryStatus.archived);
  });

  testWidgets('dense feed card shows image and voice as compact icons',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final now = DateTime.now();

    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MemoryItemCard(
              item: MemoryItem(
                id: 'dense-media',
                type: MemoryType.note,
                title: 'Поездка',
                body: 'Фотография и голосовая заметка',
                memoryDate: now,
                createdAt: now,
                updatedAt: now,
                imagePaths: const [_pixelImageDataUrl],
                audioPath: 'voice-test.m4a',
                audioDurationSeconds: 15,
              ),
              showDate: false,
              compact: true,
              denseFeedLayout: true,
              onOpen: () {},
              onToggleDone: () {},
              onArchive: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_card_dense-media')))
          .height,
      152,
    );
    expect(
      find.byKey(const ValueKey('feed_image_$_pixelImageDataUrl')),
      findsNothing,
    );
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byIcon(Icons.image_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed filter shows selected record type only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
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
    expect(find.text('Все записи'), findsOneWidget);

    await tester.tap(find.text('Все записи'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проект').last);
    await tester.pumpAndSettle();

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('Ежедневник V2'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
    expect(find.text('Вчерашняя заметка'), findsNothing);

    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лента'));
    await tester.pumpAndSettle();

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
  });
}
