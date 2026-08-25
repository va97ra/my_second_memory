part of '../widget_test.dart';

void registerHomeFeedWidgetTests() {
  testWidgets('empty day feed shows only the notebook sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    await openTab(tester, 'feed');

    expect(find.text('На этот день пока ничего нет'), findsNothing);
    expect(find.byKey(const ValueKey('feed_dated_scroll')), findsOneWidget);
  });

  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
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
    await openTab(tester, 'feed');

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
    expect(find.byKey(const ValueKey('feed_section_day')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed_section_month')), findsNothing);
    expect(find.byKey(const ValueKey('feed_section_year')), findsNothing);
    expect(find.byKey(const ValueKey('feed_section_notes')), findsOneWidget);
    expect(find.text('Вчерашняя заметка'), findsNothing);
    expect(find.text('Позавчерашняя заметка'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_previous_period')));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(find.byIcon(Icons.delete_rounded), findsNothing);
    expect(find.byIcon(Icons.task_alt_rounded), findsWidgets);
    expect(find.byIcon(Icons.archive_rounded), findsWidgets);
    // Повторы за месяц достаются фильтром, а не отдельной закладкой.
    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Каждый месяц').last);
    await tester.pumpAndSettle();
    expect(find.text('Старая активная запись'), findsNothing);
    expect(find.text('Архивная запись'), findsNothing);

    await openTab(tester, 'calendar');
  });

  testWidgets('period arrows turn to the exact adjacent day', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
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
    await openTab(tester, 'feed');

    expect(find.text('Вчерашняя заметка'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_previous_period')));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(
      find.textContaining(DateFormat('d MMMM', 'ru').format(yesterday)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('feed_next_period')));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
  });

  testWidgets('today button returns the feed to the current date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
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
    await openTab(tester, 'feed');

    final today = find.byKey(const ValueKey('feed_today'));
    expect(today, findsOneWidget);
    // Nothing to return to while today is already on screen.
    expect(tester.widget<IconButton>(today).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('feed_previous_period')));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(tester.widget<IconButton>(today).onPressed, isNotNull);

    await tester.tap(today);
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(tester.widget<IconButton>(today).onPressed, isNull);
  });

  testWidgets('feed header takes whole ruled rows and starts on a line',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
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
    await openTab(tester, 'feed');

    final header = tester.getRect(
      find.byKey(const ValueKey('feed_header_card')),
    );
    final offsetFromLine =
        (header.top - notebookPageLineTop) % notebookPageLineHeight;
    expect(offsetFromLine, closeTo(0, 0.01));
    expect(header.height % notebookPageLineHeight, closeTo(0, 0.01));
  });

  testWidgets('feed page turns to the previous and next day on a swipe',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
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
    await openTab(tester, 'feed');

    final swipeArea = find.byKey(const ValueKey('feed_period_swipe_area'));
    expect(swipeArea, findsOneWidget);

    expect(find.text('Вчерашняя заметка'), findsNothing);
    await tester.drag(swipeArea, const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsOneWidget);

    await tester.drag(swipeArea, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(find.text('Вчерашняя заметка'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
  });

  testWidgets('notes tab has no page to turn', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
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
    await openTab(tester, 'feed');

    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('feed_period_swipe_area')),
      findsNothing,
    );
  });

  testWidgets('day tab holds recurring records and filters open their period',
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
    await openTab(tester, 'feed');

    expect(find.text('Постоянная записка'), findsNothing);
    for (final section in ['day', 'notes']) {
      final tab = find.byKey(ValueKey('feed_section_$section'));
      expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
    }
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('notebook_feed_sheet')),
    );
    final dayTabRect = tester.getRect(
      find.byKey(const ValueKey('feed_section_day')),
    );
    expect(sheetRect.right, closeTo(356, 0.1));
    expect(dayTabRect.top, greaterThanOrEqualTo(sheetRect.bottom - 12));
    expect(dayTabRect.bottom, greaterThan(sheetRect.bottom + 40));

    // Закладка задаёт день, а не разновидность записи: повтор, выпавший на
    // сегодня, стоит рядом с обычными записями.
    expect(find.text('Лента дня'), findsOneWidget);
    expect(find.text('Фокус сегодня'), findsOneWidget);
    expect(find.text('Ежемесячный информер'), findsOneWidget);
    expect(find.text('Ежегодный информер'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Каждый месяц').last);
    await tester.pumpAndSettle();
    expect(find.text('Ежемесячный информер'), findsOneWidget);
    expect(find.text('Ежегодный информер'), findsNothing);
    expect(find.text('Фокус сегодня'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Каждый год').last);
    await tester.pumpAndSettle();
    expect(find.text('Ежемесячный информер'), findsNothing);
    expect(find.text('Ежегодный информер'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    expect(find.text('Записки'), findsWidgets);
    expect(find.text('Постоянная записка'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed_previous_period')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('feed_section_day')));
    await tester.pumpAndSettle();
    expect(find.text('Постоянная записка'), findsNothing);
  });

  testWidgets('undated notes have their own notebook tab and editor',
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
    await openTab(tester, 'feed');

    expect(find.text('Карта дочери'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed_previous_period')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_section_day')));
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
    await openTab(tester, 'feed');
    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    final noteArchive = find.byKey(
      const ValueKey('memory_card_archive_undated-daughter-card'),
    );
    await tester.tap(noteArchive);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

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
    await openTab(tester, 'feed');
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
    await openTab(tester, 'feed');
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
    await openTab(tester, 'feed');

    await tester.tap(find.byKey(const ValueKey('feed_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Проект').last);
    await tester.pumpAndSettle();

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('Ежедневник V2'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
    expect(find.text('Вчерашняя заметка'), findsNothing);

    await openTab(tester, 'calendar');
    await openTab(tester, 'feed');

    expect(find.text('Проект'), findsWidgets);
    expect(find.text('План на сегодня'), findsNothing);
  });

  testWidgets('feed marks a projected occurrence done through its series',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(today.year, today.month - 1, today.day);
    final origin = MemoryItem(
      id: 'origin',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: start,
      createdAt: start,
      updatedAt: start,
      repeatRule: RecurrenceFrequency.monthly.name,
      seriesId: 'series',
    );
    final exceptions = _RecordingExceptionRepository();

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider
              .overrideWithValue(_FixedMemoryRepository([origin])),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
          recurrenceRepositoryProvider.overrideWithValue(
            _FixedRecurrenceRepository([
              RecurrenceSeries(
                id: 'series',
                frequency: RecurrenceFrequency.monthly,
                template: origin,
                startDate: start,
                originItemId: origin.id,
                createdAt: start,
                updatedAt: start,
              ),
            ]),
          ),
          recurrenceExceptionRepositoryProvider.overrideWithValue(exceptions),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await openTab(tester, 'feed');

    // Сегодняшнее вхождение спроецировано: сохранённой строки у него нет.
    expect(find.text('Подписка'), findsOneWidget);
    final done = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('memory_card_done_'),
    );
    await tester.tap(done);
    await tester.pumpAndSettle();

    // Отметка вхождения живёт в серии, а не в строке записей.
    expect(exceptions.saved, hasLength(1));
    expect(exceptions.saved.single.item?.isDone, isTrue);
  });
}
