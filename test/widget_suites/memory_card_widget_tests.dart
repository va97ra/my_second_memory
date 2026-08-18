part of '../widget_test.dart';

void registerMemoryCardWidgetTests() {
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
      testProviderScope(
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
}
