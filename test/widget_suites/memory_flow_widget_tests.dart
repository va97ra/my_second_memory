part of '../widget_test.dart';

void registerMemoryFlowWidgetTests() {
  testWidgets('accounts tab opens accounts without requiring pin',
      (tester) async {
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
}
