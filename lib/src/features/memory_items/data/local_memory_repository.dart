import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/memory_item.dart';
import '../domain/memory_type.dart';
import 'memory_repository.dart';

class LocalMemoryRepository implements MemoryRepository {
  const LocalMemoryRepository();

  static const _storageKey = 'memory_items_v1';

  @override
  Future<List<MemoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return _starterItems();
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    if (decoded.isEmpty) {
      return _starterItems();
    }

    return decoded.map((entry) {
      return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  List<MemoryItem> _starterItems() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      MemoryItem(
        id: 'starter-event',
        type: MemoryType.event,
        title: 'План на сегодня',
        body: 'События, задачи, люди и проекты с сегодняшней датой появляются здесь.',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        priority: 2,
      ),
      MemoryItem(
        id: 'starter-project',
        type: MemoryType.project,
        title: 'Моя вторая память',
        body: 'Проект с датой на сегодня попадает и в проекты, и в главную ленту.',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
        priority: 1,
      ),
      MemoryItem(
        id: 'starter-person',
        type: MemoryType.person,
        title: 'Важный человек',
        body: 'Контакты и люди тоже участвуют в ленте, если у них стоит сегодняшняя дата.',
        memoryDate: today,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
