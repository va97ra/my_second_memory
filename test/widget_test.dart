import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/app.dart';
import 'package:my_second_memory/src/features/memory_items/data/memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:my_second_memory/src/features/memory_items/state/memory_items_controller.dart';
import 'package:my_second_memory/src/features/security/data/security_service.dart';
import 'package:my_second_memory/src/features/security/state/security_provider.dart';

class _UnlockedSecurityService extends SecurityService {
  @override
  Future<bool> hasPin() async => false;
}

class _FeedMemoryRepository implements MemoryRepository {
  @override
  Future<List<MemoryItem>> loadItems() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
    ];
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {}
}

void main() {
  testWidgets('shows the home feed when app is unlocked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          securityServiceProvider.overrideWithValue(_UnlockedSecurityService()),
          memoryRepositoryProvider.overrideWithValue(_FeedMemoryRepository()),
        ],
        child: const MySecondMemoryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('План на сегодня'), findsOneWidget);
    expect(find.text('Моя вторая память'), findsWidgets);
  });
}
