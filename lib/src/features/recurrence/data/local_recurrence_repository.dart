import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recurrence_series.dart';
import 'recurrence_repository.dart';

class LocalRecurrenceRepository implements RecurrenceRepository {
  const LocalRecurrenceRepository();

  static const storageKey = 'recurrence_series_v1';

  @override
  Future<List<RecurrenceSeries>> loadAll() async {
    final raw = (await SharedPreferences.getInstance()).getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    return (jsonDecode(raw) as List<dynamic>).map((entry) {
      return RecurrenceSeries.fromJson(
        Map<String, Object?>.from(entry as Map),
      );
    }).toList();
  }

  @override
  Future<void> upsert(RecurrenceSeries series) async {
    final all = await loadAll();
    await replaceAll([
      for (final item in all)
        if (item.id == series.id) series else item,
      if (!all.any((item) => item.id == series.id)) series,
    ]);
  }

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {
    if (series.isEmpty) return;
    final byId = {
      for (final item in await loadAll()) item.id: item,
      for (final item in series) item.id: item,
    };
    await replaceAll(byId.values.toList());
  }

  @override
  Future<void> delete(String id) async {
    await replaceAll([
      for (final item in await loadAll())
        if (item.id != id) item,
    ]);
  }

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    await (await SharedPreferences.getInstance()).setString(
      storageKey,
      jsonEncode(series.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> close() async {}
}
