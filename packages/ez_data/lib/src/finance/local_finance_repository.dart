import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'finance_repository.dart';

class LocalFinanceRepository implements FinanceRepository {
  const LocalFinanceRepository({this.preferences});

  static const storageKey = 'finance_entries_v1';
  final SharedPreferences? preferences;

  @override
  Future<List<FinanceEntry>> loadAll() async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in decoded)
        FinanceEntry.fromJson(Map<String, Object?>.from(item as Map)),
    ];
  }

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }
}
