import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/memory_item.dart';
import 'memory_repository.dart';

class LocalMemoryRepository implements MemoryRepository {
  const LocalMemoryRepository();

  static const _storageKey = 'memory_items_v1';

  @override
  Future<List<MemoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final items = decoded.map((entry) {
      return MemoryItem.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
    final userItems = [
      for (final item in items)
        if (!_isStarterItem(item)) item,
    ];

    if (userItems.length != items.length) {
      await saveItems(userItems);
    }

    return userItems;
  }

  @override
  Future<void> saveItems(List<MemoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  bool _isStarterItem(MemoryItem item) {
    return item.id == 'starter-event' ||
        item.id == 'starter-project' ||
        item.id == 'starter-person';
  }
}
