import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('undated notes have their own notebook tab and editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FeedMemoryRepository();

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

    expect(find.text('Карта дочери'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed_previous_period')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('feed_section_day')));
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('bottom_add_note')));
    await tester.pumpAndSettle();
    expect(find.text('Новая записка'), findsOneWidget);
    // Вид есть и у записки, он виден в ленте — значит и кнопка ей нужна.
    expect(find.byKey(const ValueKey('memory_type_picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('record_editor_panel')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('record_editor_text')),
      'Важные данные',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.savedItems.any((item) => item.isUndated), isTrue);
  });

  testWidgets('undated note archives and restores through memory archive',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FeedMemoryRepository();

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
    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();
    final noteArchive = find.byKey(
      const ValueKey('memory_card_archive_undated-daughter-card'),
    );
    await tester.tap(noteArchive);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

    await tester.tap(find.text('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Архив памяти'));
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('memory_card_archive_undated-daughter-card'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsNothing);

    await tester.tap(find.text('Лента').last);
    await tester.pumpAndSettle();
    expect(find.text('Карта дочери'), findsOneWidget);
  });
}
