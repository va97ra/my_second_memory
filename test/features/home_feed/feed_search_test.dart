import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_layout_provider.dart';
import 'package:ezhednevnik_v2/src/features/home_feed/state/feed_providers.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_items_controller.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  testWidgets('search finds work across all dates and leaves with the button',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    MemoryItem item(String id, String title, DateTime day,
            {String body = '', MemoryStatus status = MemoryStatus.active}) =>
        MemoryItem(
            id: id,
            type: MemoryType.task,
            title: title,
            body: body,
            memoryDate: day,
            status: status,
            createdAt: today,
            updatedAt: today);
    final repo = EmptyMemoryRepository()
      ..savedItems = [
        item('meter', 'Замена счётчика', DateTime(2026, 3, 2),
            body: 'ул. Ленина, 5', status: MemoryStatus.done),
        item('fence', 'Покраска забора', today),
        item('socket', 'Замена розетки', DateTime(2026, 5, 7)),
        item('tap', 'Замена крана', DateTime(2026, 4, 1),
            status: MemoryStatus.archived),
      ];
    await tester.pumpWidget(testProviderScope(overrides: [
      memoryRepositoryProvider.overrideWithValue(repo),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService())
    ], child: const EzhednevnikV2App()));
    await tester.pumpAndSettle();
    await openTab(tester, 'feed');

    final button = find.byKey(const ValueKey('feed_search'));
    final c = ProviderScope.containerOf(tester.element(button));
    expect(find.byKey(const ValueKey('feed_search_field')), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('feed_search_field'));
    expect(field, findsOneWidget);
    // Строку открыли, чтобы набрать запрос: клавиатура уже у неё.
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
    expect(find.byKey(const ValueKey('feed_pick_date')), findsNothing);

    // «ё» в записи и «е» в запросе — одна буква; адрес ищется в тексте.
    await tester.enterText(field, 'счетчик ленина');
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, ['meter']);
    expect(find.text('Замена счётчика'), findsOneWidget);

    // Архивное не находится: архив скрывает запись из ленты.
    await tester.enterText(field, 'замена');
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, ['meter', 'socket']);

    await tester.enterText(field, 'гагарина');
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, isEmpty);
    expect(find.text('Записи не найдены'), findsOneWidget);

    // Стёртый запрос ничего не ищет: под строкой снова открытый день, а не
    // прошлые находки.
    await tester.tap(find.byKey(const ValueKey('feed_search_clear')));
    await tester.pumpAndSettle();
    expect(c.read(feedLayoutProvider).itemIds, ['fence']);
    expect(find.text('Замена счётчика'), findsNothing);
    expect(find.text('Записи не найдены'), findsNothing);
    expect(find.byKey(const ValueKey('feed_search_clear')), findsNothing);

    await tester.enterText(field, 'забор');
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('feed_search_field')), findsNothing);
    expect(c.read(feedViewProvider).searchQuery, isEmpty);
    expect(c.read(feedLayoutProvider).itemIds, ['fence']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes tab searches notes and keeps the query between tabs',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    MemoryItem item(String id, String title, {bool undated = false}) =>
        MemoryItem(
            id: id,
            type: MemoryType.note,
            title: title,
            body: '',
            memoryDate: today,
            isUndated: undated,
            createdAt: today,
            updatedAt: today);
    final repo = EmptyMemoryRepository()
      ..savedItems = [
        item('wifi', 'Пароль от вайфая на даче', undated: true),
        item('sizes', 'Размеры окон', undated: true),
        item('dated', 'Пароль от домофона'),
      ];
    await tester.pumpWidget(testProviderScope(overrides: [
      memoryRepositoryProvider.overrideWithValue(repo),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService())
    ], child: const EzhednevnikV2App()));
    await tester.pumpAndSettle();
    await openTab(tester, 'feed');
    await tester.tap(find.byKey(const ValueKey('feed_section_notes')));
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('feed_search'));
    final c = ProviderScope.containerOf(tester.element(button));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Поиск по запискам'), findsOneWidget);

    final field = find.byKey(const ValueKey('feed_search_field'));
    await tester.enterText(field, 'пароль');
    await tester.pumpAndSettle();
    // Записка с датой — не записка: на закладке записок её нет и в поиске.
    expect(c.read(feedLayoutProvider).itemIds, ['wifi']);
    expect(find.text('Пароль от вайфая на даче'), findsOneWidget);

    // Тот же запрос на дне ищет среди записей всех дат.
    await tester.tap(find.byKey(const ValueKey('feed_section_day')));
    await tester.pumpAndSettle();
    expect(c.read(feedViewProvider).searchQuery, 'пароль');
    expect(c.read(feedLayoutProvider).itemIds, ['dated']);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('feed_search_field')))
          .controller
          ?.text,
      'пароль',
    );
    expect(tester.takeException(), isNull);
  });
}
