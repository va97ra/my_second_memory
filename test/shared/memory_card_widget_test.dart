import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/shared/ui/memory_card/memory_card_type_rail.dart';
import 'package:ezhednevnik_v2/src/shared/ui/memory_card/memory_item_card.dart';
import 'package:ezhednevnik_v2/src/shared/ui/memory_card/memory_item_presentation.dart';
import '../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

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
      voiceNotes: const [
        VoiceNote(reference: 'voice.m4a', durationSeconds: 42),
      ],
      imagePaths: const [pixelImageDataUrl],
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

  testWidgets('done record turns grey while waiting work keeps its colour',
      (tester) async {
    final now = DateTime(2026, 10, 1, 9);
    MemoryItem task(String id, MemoryStatus status) => MemoryItem(
          id: id,
          type: MemoryType.task,
          title: 'Замена счётчика $id',
          body: '',
          status: status,
          memoryDate: DateTime(2026, 10, 1),
          createdAt: now,
          updatedAt: now,
        );

    await tester.pumpWidget(
      testProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                for (final item in [
                  task('done', MemoryStatus.done),
                  task('waiting', MemoryStatus.active),
                ])
                  MemoryItemCard(
                    item: item,
                    showDate: false,
                    compact: true,
                    denseFeedLayout: true,
                    onOpen: () {},
                    onToggleDone: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color railOf(String id) => tester
        .widget<MemoryCardTypeRail>(
            find.byKey(ValueKey('memory_card_type_$id')))
        .color;
    Color? titleOf(String id) {
      // Название — с оформлением текста, его цвет — в стиле самого текста.
      final text =
          tester.widget<Text>(find.byKey(ValueKey('memory_card_title_$id')));
      return (text.style ?? text.textSpan?.style)?.color;
    }

    expect(railOf('done'), memoryDoneColor);
    expect(railOf('waiting'), memoryTypeColor(MemoryType.task));
    expect(titleOf('done'), isNot(titleOf('waiting')));
    expect(tester.takeException(), isNull);
  });

  // Серый занят «выполненным»: вид записи, окрашенный в серое, читался бы
  // сделанным, ещё не начавшись. Так было с документом.
  test('no record type is grey', () {
    for (final type in MemoryType.values) {
      final saturation = HSLColor.fromColor(memoryTypeColor(type)).saturation;
      expect(saturation, greaterThan(0.4), reason: '$type');
    }
  });
}
