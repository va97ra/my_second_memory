import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/app.dart';
import 'package:my_second_memory/src/features/memory_items/data/memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_status.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:my_second_memory/src/features/memory_items/state/memory_items_controller.dart';
import 'package:my_second_memory/src/features/security/data/security_service.dart';
import 'package:my_second_memory/src/features/security/state/security_provider.dart';

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
    const pixel =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
        'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

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
        imagePaths: const [pixel, pixel, pixel],
      ),
    ];
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    savedItems = items;
  }
}

void main() {
  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Лента дня'), findsWidgets);
    expect(find.text('Лента'), findsOneWidget);
    expect(find.text('Календарь'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Люди'), findsNothing);
    expect(find.text('Проекты'), findsNothing);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Моя вторая память'), findsWidgets);
    expect(find.text('Это было вчера'), findsOneWidget);
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(find.text('Это было позавчера'), findsOneWidget);
    expect(find.text('Позавчерашняя заметка'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
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
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Только сегодня'), findsOneWidget);
    expect(find.text('Это было вчера'), findsNothing);
    expect(find.text('Это было позавчера'), findsNothing);
    expect(find.text('Записей нет'), findsNothing);
  });

  testWidgets('feed card can be completed and opened for editing',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _FeedMemoryRepository();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = today.day == 15 ? 16 : 15;
    final targetDate = DateTime(today.year, today.month, targetDay);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(repository),
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

    expect(find.text('Редактировать запись'), findsOneWidget);
    expect(find.text('Выполнено'), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month), findsNothing);
    expect(find.textContaining('Дата:'), findsNothing);
    await tester.tap(find.text('Событие'));
    await tester.pumpAndSettle();
    expect(find.text('Голос'), findsNothing);
    expect(find.text('Человек'), findsNothing);
    expect(find.text('Привычка'), findsNothing);
    await tester.drag(find.byType(ListView).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Покупка'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Запись'),
      'Обновлённый план из первых строк записи',
    );
    await tester.tap(find.byKey(const ValueKey('memory_date_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$targetDay').last);
    await tester.pumpAndSettle();
    final okRu = find.text('ОК');
    if (okRu.evaluate().isNotEmpty) {
      await tester.tap(okRu);
    } else {
      await tester.tap(find.text('OK'));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    final saved = repository.savedItems.firstWhere(
      (item) => item.id == 'today-plan',
    );
    expect(saved.title, 'Обновлённый план из первых строк записи');
    expect(saved.body, 'Обновлённый план из первых строк записи');
    expect(saved.type, MemoryType.purchase);
    expect(saved.memoryDate, targetDate);
    expect(saved.status, MemoryStatus.done);
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
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Длинная запись'));
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

  testWidgets('calendar date opens day chat and sends text on selected date',
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
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.attach_file), findsNothing);
    await tester.enterText(
        find.widgetWithText(TextField, 'Сообщение'), 'Фото дня');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Фото дня'), findsOneWidget);
    expect(
      repository.savedItems.any(
        (item) => item.title == 'Фото дня' && item.memoryDate == today,
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
}
