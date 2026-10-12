import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/app/app.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/memory_items.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/navigation/app_router.dart';
import 'package:ezhednevnik_v2/src/shared/state/maps_route.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Карты телефона: запоминают, куда просили проложить дорогу.
class _Maps extends MapsRoute {
  final asked = <String>[];

  @override
  Future<String?> open(String to) async {
    asked.add(to);
    return 'Яндекс Карты';
  }
}

/// «Маршрут» у записи с адресом: одно нажатие — дорога в картах телефона
/// (просьба владельца 12 октября 2026).
void main() {
  useTestEnvironment();

  Future<ProviderContainer> openRecord(
      WidgetTester tester, _Maps maps, MemoryItem record) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testProviderScope(
      overrides: [
        securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
        memoryRepositoryProvider
            .overrideWithValue(const LocalMemoryRepository()),
        notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
        mapsRouteProvider.overrideWithValue(maps),
      ],
      child: const EzhednevnikV2App(),
    ));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(EzhednevnikV2App)));
    await container.read(memoryItemsControllerProvider.notifier).add(record);
    container.read(appRouterProvider).push('/memory/item/${record.id}');
    await tester.pumpAndSettle();
    return container;
  }

  MemoryItem record(String id, String body) {
    final day = DateTime(2099, 10, 8);
    return MemoryItem(
      id: id,
      type: MemoryType.task,
      title: 'Врач',
      body: body,
      memoryDate: day,
      timeMinutes: 10 * 60,
      createdAt: day,
      updatedAt: day,
    );
  }

  testWidgets('у записи с адресом — «Маршрут» в шапке', (tester) async {
    final maps = _Maps();
    await openRecord(
        tester, maps, record('doctor', 'Куда: улица Ленина, 5\nВзять полис'));
    await tester.tap(find.byKey(const ValueKey('memory_route')));
    await tester.pumpAndSettle();
    expect(maps.asked, ['улица Ленина, 5']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('без адреса кнопки нет', (tester) async {
    await openRecord(tester, _Maps(), record('call', 'Позвонить маме'));
    expect(find.byKey(const ValueKey('memory_type_picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('memory_route')), findsNothing);
  });
}
