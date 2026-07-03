import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:my_second_memory/src/app.dart';
import 'package:my_second_memory/src/features/memory_items/data/memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_status.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:my_second_memory/src/features/memory_items/state/memory_items_controller.dart';
import 'package:my_second_memory/src/features/security/data/security_service.dart';
import 'package:my_second_memory/src/features/security/state/security_provider.dart';
import 'package:my_second_memory/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:my_second_memory/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:my_second_memory/src/features/shift_schedules/state/shift_schedules_controller.dart';

const _pixelImageDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

class _UnlockedSecurityService extends SecurityService {
  @override
  Future<bool> hasPin() async => false;
}

class _FeedMemoryRepository implements MemoryRepository {
  _FeedMemoryRepository();

  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadItems() async {
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
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
      MemoryItem(
        id: 'today-project',
        type: MemoryType.project,
        title: 'Моя вторая память',
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
  Future<void> saveItems(List<MemoryItem> items) async {
    savedItems = items;
  }
}

class _TodayOnlyMemoryRepository implements MemoryRepository {
  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadItems() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      MemoryItem(
        id: 'today-only',
        type: MemoryType.note,
        title: 'Только сегодня',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    savedItems = items;
  }
}

class _RichEditorMemoryRepository implements MemoryRepository {
  List<MemoryItem> savedItems = const [];

  @override
  Future<List<MemoryItem>> loadItems() async {
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
  Future<void> saveItems(List<MemoryItem> items) async {
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

void main() {
  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final oldDay = today.subtract(const Duration(days: 5));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFFF7ECDB));
    expect(find.text('Лента дня'), findsWidgets);
    expect(find.text('Лента'), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Люди'), findsNothing);
    expect(find.text('Проекты'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Моя вторая память'), findsWidgets);
    expect(find.text(DateFormat.yMMMMd('ru').format(today)), findsOneWidget);
    expect(
      find.text(DateFormat.yMMMMd('ru').format(yesterday)),
      findsOneWidget,
    );
    expect(find.text(DateFormat.yMMMMd('ru').format(oldDay)), findsOneWidget);
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(find.text('Позавчерашняя заметка'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Старая активная запись'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Старая активная запись'), findsOneWidget);
    expect(find.text('Архивная запись'), findsNothing);
    expect(find.text(DateFormat.MMM('ru').format(today)), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
    expect(find.byIcon(Icons.archive_outlined), findsWidgets);
  });

  testWidgets('hides empty previous day sections', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(
            _TodayOnlyMemoryRepository(),
          ),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Только сегодня'), findsOneWidget);
    expect(find.text('Записей нет'), findsNothing);
  });

  testWidgets('feed card can be completed and opened read-only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Отметить выполненным').first);
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
    expect(find.byIcon(Icons.save_outlined), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.widgetWithText(TextFormField, 'Запись'), findsNothing);
    expect(find.text('Тип записи'), findsNothing);
  });

  testWidgets('feed card can be archived from the feed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _TodayOnlyMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Только сегодня'), findsOneWidget);

    await tester.tap(find.byTooltip('Скрыть в архив'));
    await tester.pumpAndSettle();

    expect(find.text('Только сегодня'), findsNothing);
    expect(repository.savedItems.single.status, MemoryStatus.archived);
  });

  testWidgets('editor keeps record field large with long text and images',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RichEditorMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();
    final chatText = find.textContaining('Длинная строка').first;
    await tester.ensureVisible(chatText);
    await tester.pumpAndSettle();
    await tester.tap(chatText);
    await tester.pumpAndSettle();

    final panelSize =
        tester.getSize(find.byKey(const ValueKey('record_editor_panel')));
    final textSize =
        tester.getSize(find.byKey(const ValueKey('record_editor_text')));

    expect(panelSize.height, greaterThan(290));
    expect(textSize.height, greaterThan(120));
    expect(find.byKey(const ValueKey('record_editor_images')), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });

  testWidgets('readonly image opens fullscreen viewer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RichEditorMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Длинная запись'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_readonly_view')), findsOneWidget);
    final image =
        find.byKey(const ValueKey('readonly_image_$_pixelImageDataUrl')).first;
    await tester.ensureVisible(image);
    await tester.pumpAndSettle();
    await tester.tap(image);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_image_viewer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('memory_image_viewer_image')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('memory_image_viewer_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('memory_image_viewer')), findsNothing);
  });

  testWidgets('calendar date opens day and add opens editor on selected date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    expect(find.text('Сегодня'), findsOneWidget);

    final todayCell = find.text('${today.day}').first;
    await tester.ensureVisible(todayCell);
    await tester.pumpAndSettle();
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
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
      find.textContaining(DateFormat.yMMMd('ru').format(today)),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Запись'),
      'Новая запись из календаря',
    );
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Редактировать запись'), findsOneWidget);
    expect(find.text('Новая запись из календаря'), findsOneWidget);
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

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('План на сегодня'));
    await tester.pumpAndSettle();

    expect(find.text('Редактировать запись'), findsOneWidget);
    expect(find.text('Запись'), findsOneWidget);
    expect(find.text('Название'), findsNothing);
  });

  testWidgets('settings opens shift schedules and saves preset',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final memoryRepository = _FeedMemoryRepository();
    final shiftRepository = _FakeShiftScheduleRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          shiftScheduleRepositoryProvider.overrideWithValue(shiftRepository),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Графики смен'));
    await tester.pumpAndSettle();

    expect(find.text('Графики смен'), findsWidgets);
    expect(find.text('Графиков пока нет'), findsOneWidget);

    await tester.tap(find.text('Добавить график'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Организация'),
      'Завод',
    );
    await tester.tap(find.text('2/2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(shiftRepository.savedSchedules, hasLength(1));
    expect(shiftRepository.savedSchedules.single.organizationName, 'Завод');
    expect(shiftRepository.savedSchedules.single.workDays, 2);
    expect(shiftRepository.savedSchedules.single.restDays, 2);
  });

  testWidgets('settings opens memory archive and restores item to feed',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('База памяти'));
    await tester.pumpAndSettle();

    expect(find.text('База памяти'), findsWidgets);
    expect(find.text('Архивная запись'), findsOneWidget);
    expect(find.text('План на сегодня'), findsNothing);

    await tester.tap(find.byTooltip('Вернуть в ленту'));
    await tester.pumpAndSettle();

    expect(
      repository.savedItems
          .firstWhere((item) => item.id == 'archived-note')
          .status,
      MemoryStatus.active,
    );
    expect(find.text('Архивная запись'), findsNothing);

    await tester.tap(find.text('Лента'));
    await tester.pumpAndSettle();

    expect(find.text('Архивная запись'), findsOneWidget);
  });

  testWidgets('calendar shows shift colors and opens selected day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final memoryRepository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final secondWorkDay = today.add(const Duration(days: 1));
    final secondWorkDayKey =
        '${secondWorkDay.year}-${secondWorkDay.month.toString().padLeft(2, '0')}-'
        '${secondWorkDay.day.toString().padLeft(2, '0')}';
    final shiftRepository = _FakeShiftScheduleRepository([
      ShiftSchedule(
        id: 'factory',
        organizationName: 'Завод',
        colorValue: 0xFF2563EB,
        startDate: today,
        workDays: 5,
        restDays: 2,
      ),
      ShiftSchedule(
        id: 'watch',
        organizationName: 'Вахта',
        colorValue: 0xFF16A34A,
        startDate: today,
        workDays: 1,
        restDays: 3,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(memoryRepository),
          shiftScheduleRepositoryProvider.overrideWithValue(shiftRepository),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey('calendar_day_$dayKey'));
    expect(cell, findsOneWidget);
    expect(
      find.descendant(
        of: cell,
        matching: find.byKey(ValueKey('shift_fill_$dayKey')),
      ),
      findsOneWidget,
    );

    final secondWorkCell =
        find.byKey(ValueKey('calendar_day_$secondWorkDayKey'));
    expect(secondWorkCell, findsOneWidget);
    expect(
      find.descendant(
        of: secondWorkCell,
        matching: find.byKey(ValueKey('shift_fill_$secondWorkDayKey')),
      ),
      findsOneWidget,
    );

    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.textContaining('Завод'), findsOneWidget);
    expect(find.textContaining('Вахта'), findsOneWidget);
  });
}
