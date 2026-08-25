import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/recurrence/recurrence.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('day tab holds recurring records and filters open their period',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      testProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(
            _FutureFeedMemoryRepository(),
          ),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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
          securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
          memoryRepositoryProvider
              .overrideWithValue(_FixedMemoryRepository([origin])),
          shiftScheduleRepositoryProvider.overrideWithValue(
            FakeShiftScheduleRepository(),
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

class _FutureFeedMemoryRepository extends TestMemoryRepository {
  @override
  Future<List<MemoryItem>> loadAll() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      MemoryItem(
        id: 'future-feed-undated',
        type: MemoryType.note,
        title: 'Постоянная записка',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        isUndated: true,
      ),
      for (var offset = 1; offset <= 10; offset++)
        MemoryItem(
          id: 'future-$offset',
          type: MemoryType.note,
          title: 'Будущая запись $offset',
          memoryDate: today.add(Duration(days: offset)),
          createdAt: now,
          updatedAt: now,
        ),
      MemoryItem(
        id: 'today-focus',
        type: MemoryType.note,
        title: 'Фокус сегодня',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'monthly-informer',
        type: MemoryType.payment,
        title: 'Ежемесячный информер',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        repeatRule: RecurrenceFrequency.monthly.name,
        seriesId: 'monthly-series',
      ),
      MemoryItem(
        id: 'yearly-informer',
        type: MemoryType.birthday,
        title: 'Ежегодный информер',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        repeatRule: RecurrenceFrequency.yearly.name,
        seriesId: 'yearly-series',
      ),
      MemoryItem(
        id: 'past-after-focus',
        type: MemoryType.note,
        title: 'Прошлая запись',
        memoryDate: today.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {}
}

class _FixedMemoryRepository extends TestMemoryRepository {
  _FixedMemoryRepository(this._items);

  final List<MemoryItem> _items;
  List<MemoryItem> saved = const [];

  @override
  Future<List<MemoryItem>> loadAll() async => _items;

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    saved = items;
  }
}

class _FixedRecurrenceRepository implements RecurrenceRepository {
  _FixedRecurrenceRepository(this._series);

  final List<RecurrenceSeries> _series;

  @override
  Future<List<RecurrenceSeries>> loadAll() async => _series;

  @override
  Future<void> upsert(RecurrenceSeries series) async {}

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {}

  @override
  Future<void> close() async {}
}

class _RecordingExceptionRepository implements RecurrenceExceptionRepository {
  final List<RecurrenceOccurrenceException> saved = [];

  @override
  Future<List<RecurrenceOccurrenceException>> loadAll() async => saved;

  @override
  Future<void> upsert(RecurrenceOccurrenceException exception) async {
    saved.add(exception);
  }

  @override
  Future<void> upsertAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    saved.addAll(exceptions);
  }

  @override
  Future<RecurrenceOccurrenceException> skip(
    String seriesId,
    DateTime occurrenceDate,
  ) async {
    final exception = RecurrenceOccurrenceException(
      id: recurrenceExceptionId(seriesId, occurrenceDate),
      seriesId: seriesId,
      occurrenceDate: occurrenceDate,
      kind: RecurrenceOccurrenceExceptionKind.skipped,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    saved.add(exception);
    return exception;
  }

  @override
  Future<void> delete(String seriesId, DateTime occurrenceDate) async {}

  @override
  Future<void> deleteSeries(String seriesId) async {}

  @override
  Future<void> replaceAll(
    List<RecurrenceOccurrenceException> exceptions,
  ) async {
    saved
      ..clear()
      ..addAll(exceptions);
  }

  @override
  Future<void> close() async {}
}
