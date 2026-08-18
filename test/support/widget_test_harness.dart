part of '../widget_test.dart';

Widget testProviderScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      localStorageScopeFactoryProvider.overrideWithValue(
        _TestLocalStorageScope.new,
      ),
      ...overrides,
    ],
    child: child,
  );
}

class _TestLocalStorageScope implements LocalStorageScope {
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

class _UnlockedSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => false;
}

class _FreshSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => false;

  @override
  Future<bool> hasPin() async => false;
}

class _BiometricFailsSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => true;

  @override
  Future<AppCipher?> unlockWithBiometrics() async => null;
}

class _PinRejectingSecurityService extends SecurityService {
  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<AppCipher?> unlockWithPin(String pin) async => null;
}

class _CountingPinSecurityService extends SecurityService {
  final unlockCompleter = Completer<AppCipher?>();
  int unlockAttempts = 0;

  @override
  Future<bool> setupCompleted() async => true;

  @override
  Future<bool> hasPin() async => true;

  @override
  Future<bool> biometricsEnabled() async => false;

  @override
  Future<AppCipher?> unlockWithPin(String pin) {
    unlockAttempts++;
    return unlockCompleter.future;
  }
}

class _HangingSecurityService extends SecurityService {
  @override
  Future<bool> hasPin() => Completer<bool>().future;
}

abstract class _TestMemoryRepository implements MemoryRepository {
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

class _FeedMemoryRepository extends _TestMemoryRepository {
  _FeedMemoryRepository();

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

class _TodayOnlyMemoryRepository extends _TestMemoryRepository {
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

class _FutureFeedMemoryRepository extends _TestMemoryRepository {
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

class _RichEditorMemoryRepository extends _TestMemoryRepository {
  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadAll() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      MemoryItem(
        id: 'rich-editor',
        type: MemoryType.note,
        title: 'Длинная запись',
        body: List.filled(18, 'Длинная строка записи для проверки прокрутки')
            .join('\n'),
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        imagePaths: const [
          _pixelImageDataUrl,
          _pixelImageDataUrl,
          _pixelImageDataUrl,
        ],
      ),
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    savedItems = items;
  }
}

class _FakeShiftScheduleRepository implements ShiftScheduleRepository {
  _FakeShiftScheduleRepository([this.initialSchedules = const []]);

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
