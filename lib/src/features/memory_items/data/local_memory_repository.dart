import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/memory_item.dart';
import 'memory_repository.dart';

class LocalMemoryRepository implements MemoryRepository {
  const LocalMemoryRepository();

  static const _storageKey = 'memory_items_v1';

  @override
  Future<List<MemoryItem>> loadAll() async {
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
      await replaceAll(userItems);
    }

    return userItems;
  }

  @override
  Future<void> upsert(MemoryItem item) async {
    final items = await loadAll();
    await replaceAll([
      for (final existing in items)
        if (existing.id == item.id) item else existing,
      if (!items.any((existing) => existing.id == item.id)) item,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  @override
  Future<void> close() async {}

  bool _isStarterItem(MemoryItem item) {
    return item.id == 'starter-event' ||
        item.id == 'starter-project' ||
        item.id == 'starter-person';
  }
}
