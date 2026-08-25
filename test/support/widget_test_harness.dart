import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';

/// Общая обстановка виджет-тестов: форматы дат и пустые настройки.
///
/// Без обращения к SharedPreferences в тестовой среде загрузка повторов
/// повисает, и экраны, которые её дожидаются, показывают вечный индикатор
/// вместо содержимого.
void useTestEnvironment() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ru');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
}

const pixelImageDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

/// The app opens on the calendar, so a test that wants another tab says so.
/// Tapping by key rather than by label keeps this unambiguous: the open
/// screen's own header carries the same word as its navigation entry.
Future<void> openTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('bottom_$tab')));
  await tester.pumpAndSettle();
}

Widget testProviderScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      localStorageScopeFactoryProvider.overrideWithValue(
        TestLocalStorageScope.new,
      ),
      ...overrides,
    ],
    child: child,
  );
}

class TestLocalStorageScope implements LocalStorageScope {
  @override
  final memoryRepository = const LocalMemoryRepository();

  @override
  final recurrenceRepository = const LocalRecurrenceRepository();

  @override
  final recurrenceExceptionRepository =
      const LocalRecurrenceExceptionRepository();

  @override
  SecureEntityBackend? get secureEntityBackend => null;

  @override
  Future<void> close() async {}
}

class UnlockedSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => false;
}

abstract class TestMemoryRepository implements MemoryRepository {
  @override
  Future<void> upsert(MemoryItem item) async {
    final items = await loadAll();
    await replaceAll([
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ]);
  }

  @override
  Future<void> upsertAll(List<MemoryItem> items) async {
    for (final item in items) {
      await upsert(item);
    }
  }

  @override
  Future<void> delete(String id) async {
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> close() async {}
}

class EmptyMemoryRepository extends TestMemoryRepository {
  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadAll() async => savedItems;

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    savedItems = List.of(items);
  }
}

class FeedMemoryRepository extends TestMemoryRepository {
  FeedMemoryRepository();

  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadAll() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));
    final oldDay = today.subtract(const Duration(days: 5));

    return [
      MemoryItem(
        id: 'today-plan',
        type: MemoryType.event,
        title: 'План на сегодня',
        body: 'Подготовить задачи на день',
        timeMinutes: 9 * 60 + 30,
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'undated-daughter-card',
        type: MemoryType.note,
        title: 'Карта дочери',
        body: 'Данные, которые нужны под рукой',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        isUndated: true,
      ),
      MemoryItem(
        id: 'today-project',
        type: MemoryType.project,
        title: 'Ежедневник V2',
        body: 'Ежедневник V2',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'yesterday-note',
        type: MemoryType.note,
        title: 'Вчерашняя заметка',
        memoryDate: yesterday,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'day-before-note',
        type: MemoryType.note,
        title: 'Позавчерашняя заметка',
        memoryDate: dayBeforeYesterday,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'old-note',
        type: MemoryType.note,
        title: 'Старая активная запись',
        memoryDate: oldDay,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'archived-note',
        type: MemoryType.note,
        title: 'Архивная запись',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        status: MemoryStatus.archived,
      ),
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    savedItems = items;
  }
}

class FakeShiftScheduleRepository implements ShiftScheduleRepository {
  FakeShiftScheduleRepository([this.initialSchedules = const []]);

  final List<ShiftSchedule> initialSchedules;
  List<ShiftSchedule> savedSchedules = const [];

  @override
  Future<List<ShiftSchedule>> loadSchedules() async {
    return initialSchedules;
  }

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    savedSchedules = schedules;
  }
}
