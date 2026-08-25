import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('empty storage does not create starter records', () async {
    SharedPreferences.setMockInitialValues({});

    const repository = LocalMemoryRepository();
    final items = await repository.loadAll();

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

    await repository.upsert(item);

    final restored = await repository.loadAll();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'real-note');
    expect(restored.single.body, 'Личная информация');
    expect(restored.single.imagePaths, ['/local/photo.jpg']);
  });

  test('old starter records are removed from persisted storage', () async {
    final date = DateTime(2026, 7, 3);
    final starter = MemoryItem(
      id: 'starter-event',
      type: MemoryType.event,
      title: 'План на сегодня',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    final realItem = MemoryItem(
      id: 'real-note',
      type: MemoryType.note,
      title: 'Настоящая запись',
      memoryDate: date,
      createdAt: date,
      updatedAt: date,
    );
    SharedPreferences.setMockInitialValues({
      'memory_items_v1': jsonEncode([
        starter.toJson(),
        realItem.toJson(),
      ]),
    });

    const repository = LocalMemoryRepository();
    final restored = await repository.loadAll();

    expect(restored, hasLength(1));
    expect(restored.single.id, 'real-note');
  });
}
