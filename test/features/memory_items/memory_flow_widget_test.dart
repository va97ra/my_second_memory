import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('accounts tab opens accounts without requiring pin',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
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
    await openTab(tester, 'accounts');

    expect(find.text('Аккаунтов пока нет'), findsNothing);
    expect(find.byKey(const ValueKey('accounts_add')), findsOneWidget);
    expect(
      find.text('Для хранения аккаунтов сначала включите PIN'),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('accounts_add')));
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
    await openTab(tester, 'calendar');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await tester.tap(find.byKey(ValueKey('calendar_day_$dayKey')));
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

    // Экран открыт внутри оболочки, поэтому обе панели остаются на месте.
    // Даже на высоте 560 px лист записи сохраняет полезную рабочую область.
    expect(panelSize.height, greaterThan(230));
    // Поле ввода остаётся не меньше трёх строк; на ещё более низком экране
    // редактор переключается в свой компактный режим.
    expect(textSize.height, greaterThan(88));
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

  testWidgets('note editor uses the full space above the keyboard',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    tester.view.viewInsets = FakeViewPadding(
      bottom: 360 * tester.view.devicePixelRatio,
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);

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
    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();

    final panel = tester.getRect(
      find.byKey(const ValueKey('record_editor_panel')),
    );
    final field = tester.getRect(
      find.byKey(const ValueKey('record_editor_text')),
    );

    expect(panel.height, greaterThan(300));
    expect(field.height, greaterThan(210));
    expect(panel.bottom, lessThanOrEqualTo(900 - 360));
  });

  testWidgets('deleting a record leaves no empty page behind', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 720));
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

    // Лента -> просмотр -> редактор: под редактором в стеке остаётся экран
    // просмотра той же записи.
    await tester.tap(find.text('План на сегодня'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('memory_editor_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();

    // Возврат не должен упереться в страницу удалённой записи.
    expect(find.text('Запись не найдена'), findsNothing);
    expect(find.byKey(const ValueKey('memory_readonly_view')), findsNothing);
    expect(find.text('План на сегодня'), findsNothing);
    expect(find.byKey(const ValueKey('feed_section_day')), findsWidgets);
  });

  testWidgets('readonly image opens fullscreen viewer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _RichEditorMemoryRepository();

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
    await tester.tap(find.text('Длинная запись'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memory_readonly_view')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('memory_readonly_panel')))
          .height,
      // Обе панели оболочки остаются видимыми и на вложенной странице.
      greaterThan(530),
    );
    expect(
        find.byKey(const ValueKey('memory_readonly_content')), findsOneWidget);
    final image =
        find.byKey(const ValueKey('readonly_image_$pixelImageDataUrl')).first;
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
}

class _RichEditorMemoryRepository extends TestMemoryRepository {
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
          pixelImageDataUrl,
          pixelImageDataUrl,
          pixelImageDataUrl,
        ],
      ),
    ];
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    savedItems = items;
  }
}
