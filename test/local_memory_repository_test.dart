import 'package:flutter_test/flutter_test.dart';
import 'package:my_second_memory/src/features/memory_items/data/local_memory_repository.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_item.dart';
import 'package:my_second_memory/src/features/memory_items/domain/memory_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('empty storage does not create starter records', () async {
    SharedPreferences.setMockInitialValues({});

    const repository = LocalMemoryRepository();
    final items = await repository.loadItems();

    expect(items, isEmpty);
  });

  test('saved records are restored from local storage', () async {
    SharedPreferences.setMockInitialValues({});

    const repository = LocalMemoryRepository();
    final date = DateTime(2026, 7, 3);
    final item = MemoryItem(
      id: 'real-note',
      type: MemoryType.note,
      title: 'Моя запись',
      body: 'Личная информация',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
      imagePaths: const ['/local/photo.jpg'],
    );

    await repository.saveItems([item]);

    final restored = await repository.loadItems();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'real-note');
    expect(restored.single.body, 'Личная информация');
    expect(restored.single.imagePaths, ['/local/photo.jpg']);
  });
}
