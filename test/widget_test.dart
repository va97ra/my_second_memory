import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ezhednevnik_v2/src/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/data/memory_repository.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_item.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_status.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/domain/memory_type.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/ui/widgets/memory_item_card.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme_controller.dart';
import 'package:ezhednevnik_v2/src/core/theme/app_theme_style.dart';
import 'package:ezhednevnik_v2/src/features/security/data/app_cipher.dart';
import 'package:ezhednevnik_v2/src/features/security/data/security_service.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/data/shift_schedule_repository.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/domain/shift_schedule.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';

const _pixelImageDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

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

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ru');
  });

  testWidgets('three-column card fits text photo and voice on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 7, 10, 12, 30);
    final item = MemoryItem(
      id: 'media-card',
      type: MemoryType.note,
      title: 'Запись с фотографией и голосом',
      body: 'Запись с фотографией и голосом',
      audioPath: 'voice.m4a',
      audioDurationSeconds: 42,
      imagePaths: const [_pixelImageDataUrl],
      memoryDate: DateTime(2026, 7, 10),
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: MemoryItemCard(
              item: item,
              showDate: false,
              onOpen: () {},
              onToggleDone: () {},
              onArchive: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_card_type_media-card')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('memory_card_content_media-card')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('memory_card_actions_media-card')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first launch requires pin setup', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_FreshSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Создайте PIN для защиты данных'), findsOneWidget);
    expect(find.text('Создать PIN'), findsOneWidget);
    expect(find.text('Лента дня'), findsNothing);
  });

  testWidgets('secure storage timeout shows a retry screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_HangingSecurityService()),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(
      find.text('Не удалось запустить защищённое хранилище'),
      findsOneWidget,
    );
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Лента дня'), findsNothing);
  });

  testWidgets('biometric unlock hides pin until fallback is requested',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(
            _BiometricFailsSecurityService(),
          ),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
          shiftScheduleRepositoryProvider.overrideWithValue(
            _FakeShiftScheduleRepository(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Войти по PIN'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PIN'), findsNothing);

    await tester.tap(find.text('Войти по PIN'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'PIN'), findsOneWidget);
  });

  testWidgets('pin field is cleared after a failed unlock attempt',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(
            _PinRejectingSecurityService(),
          ),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final pinField = find.widgetWithText(TextField, 'PIN');
    tester.widget<TextField>(pinField).controller?.text = '1234';
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Неверный PIN'), findsOneWidget);
    expect(tester.widget<TextField>(pinField).controller?.text, isEmpty);
  });

  testWidgets('startup submits one pin check even after a repeated tap',
      (tester) async {
    final security = _CountingPinSecurityService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(security),
        ],
        child: const EzhednevnikV2App(),
      ),
    );
    await tester.pumpAndSettle();

    final pinField = find.widgetWithText(TextField, 'PIN');
    expect(pinField, findsOneWidget);
    await tester.enterText(pinField, '1234');
    final unlockButton = find.widgetWithText(FilledButton, 'Открыть');
    await tester.tap(unlockButton);
    await tester.tap(unlockButton);

    expect(security.unlockAttempts, 1);
    security.unlockCompleter.complete(null);
    await tester.pumpAndSettle();
  });

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
      find.text(
        'Вчера · ${DateFormat('d MMMM', 'ru').format(yesterday)}',
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey(
          'feed_day_count_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
        )),
        matching: find.text('2 записи'),
      ),
      findsOneWidget,
    );
    expect(find.text('Вчерашняя заметка'), findsOneWidget);
    expect(find.text('Позавчерашняя заметка'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Старая активная запись'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        DateFormat('d MMMM y', 'ru').format(oldDay),
      ),
      findsOneWidget,
    );
    expect(find.text('Старая активная запись'), findsOneWidget);
    expect(find.text('Архивная запись'), findsNothing);
    expect(find.text(DateFormat.MMM('ru').format(today)), findsNothing);
    expect(find.byIcon(Icons.delete_rounded), findsNothing);
    expect(find.byIcon(Icons.task_alt_rounded), findsWidgets);
    expect(find.byIcon(Icons.archive_rounded), findsWidgets);

    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
  });

  testWidgets('feed day header stays pinned and shows localized counts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    String dateKey(DateTime value) =>
        '${value.year}-${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

    await tester.pumpWidget(
      ProviderScope(
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

    final todayHeader =
        find.byKey(ValueKey('feed_day_header_${dateKey(today)}'));
    final yesterdayCount =
        find.byKey(ValueKey('feed_day_count_${dateKey(yesterday)}'));
    expect(todayHeader, findsOneWidget);
    final scrollView = find.byType(CustomScrollView).first;
    final outerScrollable = find
        .descendant(of: scrollView, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(outerScrollable).position;
    final initialHeaderTop = tester.getTopLeft(todayHeader).dy;
    final pinnedOffset = (initialHeaderTop + 8).clamp(
      0.0,
      position.maxScrollExtent - 24,
    );
    position.jumpTo(pinnedOffset);
    await tester.pumpAndSettle();
    final pinnedTop = tester.getTopLeft(todayHeader).dy;
    position.jumpTo(pinnedOffset + 16);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(todayHeader).dy, closeTo(pinnedTop, 0.5));
    await tester.scrollUntilVisible(
      yesterdayCount,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: yesterdayCount,
        matching: find.text('1 запись'),
      ),
      findsOneWidget,
    );
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
        child: const EzhednevnikV2App(),
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
      96,
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
      tester.getSize(find.byKey(const ValueKey('memory_card_done_today-plan'))),
      const Size.square(48),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('memory_card_archive_today-plan')),
      ),
      const Size.square(48),
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
      ProviderScope(
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

  testWidgets('dense feed card keeps image and voice at large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 520));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final now = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
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
      176,
    );
    expect(find.byKey(const ValueKey('feed_image_$_pixelImageDataUrl')),
        findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed filter shows selected record type only', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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

  testWidgets('accounts tab opens accounts without requiring pin',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
    await tester.tap(find.text('Аккаунты'));
    await tester.pumpAndSettle();

    expect(find.text('Аккаунтов пока нет'), findsOneWidget);
    expect(find.text('Добавить аккаунт'), findsWidgets);
    expect(
      find.text('Для хранения аккаунтов сначала включите PIN'),
      findsNothing,
    );

    await tester.tap(find.text('Добавить аккаунт').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    final noteField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Заметка'),
    );
    expect(noteField.minLines, 4);
    expect(noteField.maxLines, 6);
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
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();
    final chatText = find.text('Длинная запись').first;
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
    expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('memory_time_picker')));
    await tester.pumpAndSettle();
    expect(find.text('Время и напоминание'), findsOneWidget);
    expect(find.text('Звуковое уведомление'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('memory_reminder_done')));
    await tester.pumpAndSettle();
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
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Длинная запись'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_readonly_view')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_readonly_panel')))
          .height,
      greaterThan(590),
    );
    expect(
        find.byKey(const ValueKey('memory_readonly_content')), findsOneWidget);
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
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
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
    expect(barRect.left - cellRect.left, closeTo(2, 0.1));
    expect(cellRect.right - barRect.right, closeTo(2, 0.1));
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
      ProviderScope(
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
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    String monthLabel(DateTime month) {
      final value = DateFormat('LLLL', 'ru').format(month);
      return '${value[0].toUpperCase()}${value.substring(1)}';
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
      ProviderScope(
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
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();

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
          .widget<Text>(find.byKey(const ValueKey('calendar_year_label')))
          .data,
      '${nextYear.year}',
    );

    await tester.drag(swipeArea, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calendar_year_label')))
          .data,
      '${currentMonth.year}',
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
        child: const EzhednevnikV2App(),
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

  testWidgets('calendar fills portrait and scrolls only in short landscape',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
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
      ProviderScope(
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
    await tester.tap(find.text('Календарь'));
    await tester.pumpAndSettle();
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
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Графики смен'));
    await tester.pumpAndSettle();

    expect(find.text('Графики смен'), findsWidgets);
    expect(find.text('Графиков пока нет'), findsOneWidget);

    await tester.tap(find.text('Добавить график').last);
    await tester.pumpAndSettle();

    expect(find.text('5/2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('сутки/трое'), findsOneWidget);
    expect(find.text('7/7'), findsNothing);
    expect(find.text('14/14'), findsNothing);
    expect(find.byKey(const ValueKey('shift_color_hue')), findsOneWidget);
    expect(find.byKey(const ValueKey('shift_color_tone')), findsOneWidget);
    expect(find.byKey(const ValueKey('shift_color_preview')), findsOneWidget);
    expect(find.text('Будильник 1'), findsOneWidget);
    expect(find.textContaining('Будильник 2'), findsNothing);
    await tester.tap(find.text('сутки/трое'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Будильник 2'), findsOneWidget);
    expect(find.text('Рабочих дней'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Организация'),
      'Завод',
    );
    await tester.tap(find.text('2/2'));
    await tester.pumpAndSettle();
    final hueTrack = find.byKey(const ValueKey('shift_color_hue'));
    final toneTrack = find.byKey(const ValueKey('shift_color_tone'));
    final hueRect = tester.getRect(hueTrack);
    final toneRect = tester.getRect(toneTrack);
    await tester.tapAt(Offset(
      hueRect.left + hueRect.width * 0.72,
      hueRect.center.dy,
    ));
    await tester.tapAt(Offset(
      toneRect.left + toneRect.width * 0.38,
      toneRect.center.dy,
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    expect(find.text('Количество календарных дней'), findsOneWidget);
    expect(find.byKey(const ValueKey('vacation_end_date_preview')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shift_vacations_empty')), findsNothing);

    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    expect(
      find.text('Этот период пересекается с другим отпуском'),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();

    final removeVacation = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('remove_shift_vacation_'),
    );
    await tester.ensureVisible(removeVacation);
    await tester.pumpAndSettle();
    await tester.tap(removeVacation);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shift_vacations_empty')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add_shift_vacation')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save_shift_vacation')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Сохранить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(shiftRepository.savedSchedules, hasLength(1));
    expect(shiftRepository.savedSchedules.single.organizationName, 'Завод');
    expect(shiftRepository.savedSchedules.single.workDays, 2);
    expect(shiftRepository.savedSchedules.single.restDays, 2);
    expect(
      shiftRepository.savedSchedules.single.colorValue,
      isNot(const Color(0xFF2F7DD1).toARGB32()),
    );
    expect(shiftRepository.savedSchedules.single.vacations, hasLength(1));
    expect(shiftRepository.savedSchedules.single.vacations.single.durationDays,
        14);
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
        child: const EzhednevnikV2App(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Архив памяти'));
    await tester.pumpAndSettle();

    expect(find.text('Архив памяти'), findsWidgets);
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

    await tester.tap(find.text('Лента').last);
    await tester.pumpAndSettle();

    expect(find.text('Архивная запись'), findsOneWidget);
  });

  testWidgets('settings opens backup screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
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
    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Резервная копия'));
    await tester.pumpAndSettle();

    expect(find.text('Сохранить резервную копию'), findsOneWidget);
    expect(find.text('Архив будет сохранён в папку Загрузки.'), findsOneWidget);
    expect(find.text('Восстановить из копии'), findsOneWidget);

    await tester.tap(find.text('Сохранить резервную копию'));
    await tester.pumpAndSettle();
    final password = find.byKey(const ValueKey('backup_password'));
    final confirmation =
        find.byKey(const ValueKey('backup_password_confirmation'));
    expect(password, findsOneWidget);
    expect(confirmation, findsOneWidget);
    await tester.enterText(password, 'correct-password');
    await tester.enterText(confirmation, 'mistyped-password');
    await tester.tap(find.byKey(const ValueKey('backup_password_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    expect(confirmation, findsOneWidget);
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();
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
        vacations: [
          ShiftVacation(
            id: 'factory-vacation',
            startDate: today,
            durationDays: 1,
          ),
        ],
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
        child: const EzhednevnikV2App(),
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
    final factorySegment = find.descendant(
      of: cell,
      matching: find.byKey(const ValueKey('shift_segment_factory')),
    );
    expect(factorySegment, findsOneWidget);
    final factoryFill = find.descendant(
      of: factorySegment,
      matching: find.byType(ColoredBox),
    );
    expect(factoryFill, findsOneWidget);
    expect(
      tester.widget<ColoredBox>(factoryFill).color,
      const Color(0xFF2563EB),
    );
    expect(
      find.descendant(
        of: factorySegment,
        matching: find.byKey(
          ValueKey('vacation_ribbon_factory_$dayKey'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('vacation_ribbon_watch_$dayKey')),
      findsNothing,
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

    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.textContaining('Завод'), findsOneWidget);
    expect(find.textContaining('Вахта'), findsOneWidget);
  });

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('dense feed adapts at ${width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(find.byKey(const ValueKey('memory_card_today-plan')))
            .height,
        closeTo(103.2, 0.1),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('memory_card_done_today-plan')),
        ),
        const Size.square(48),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('dense feed supports ${scale}x text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('memory_card_today-plan'));
      if (card.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          card,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }
      final expectedHeight = scale <= 1.3
          ? 96 + ((scale - 1).clamp(0.0, 0.3) * 24)
          : 103.2 + (((scale - 1.3) / 0.7).clamp(0.0, 1.0) * 72.8);
      expect(
        tester.getSize(card).height,
        closeTo(expectedHeight, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final style in AppThemeStyle.values) {
    testWidgets('dense feed renders in ${style.name} theme', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
            appThemeControllerProvider.overrideWith(
              (ref) => AppThemeController(
                initialStyle: style,
                loadOnStart: false,
              ),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('memory_card_today-plan')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('vacation editor stays reachable at ${width.toInt()} px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityServiceProvider
                .overrideWithValue(_UnlockedSecurityService()),
            memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
            shiftScheduleRepositoryProvider.overrideWithValue(
              _FakeShiftScheduleRepository(),
            ),
          ],
          child: const EzhednevnikV2App(),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Настройки').last);
      await tester.pumpAndSettle();
      final shiftSchedules = find.text('Графики смен');
      await tester.ensureVisible(shiftSchedules);
      await tester.pumpAndSettle();
      await tester.tap(shiftSchedules);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Добавить график').last);
      await tester.pumpAndSettle();

      final addVacation = find.byKey(const ValueKey('add_shift_vacation'));
      await tester.ensureVisible(addVacation);
      await tester.pumpAndSettle();
      expect(tester.getSize(addVacation).height, 48);
      await tester.tap(addVacation);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vacation_start_date')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vacation_duration_days')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
