import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ezhednevnik_v2/src/features/calendar/ui/holiday_detail_screen.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('empty day feed shows only the notebook sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    await openTab(tester, 'feed');

    expect(find.text('На этот день пока ничего нет'), findsNothing);
    expect(find.byKey(const ValueKey('feed_dated_scroll')), findsOneWidget);
  });

  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FeedMemoryRepository();

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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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

  testWidgets('hides empty previous day sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(
            _TodayOnlyMemoryRepository(),
          ),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
}

class _TodayOnlyMemoryRepository extends TestMemoryRepository {
  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadAll() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      MemoryItem(
        id: 'today-only',
        type: MemoryType.note,
        title: '',
        body: 'Только сегодня',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    savedItems = items;
  }
}
