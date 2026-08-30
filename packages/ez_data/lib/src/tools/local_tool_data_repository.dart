import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tool_data_repository.dart';

class LocalToolDataRepository implements ToolDataRepository {
  const LocalToolDataRepository({this.preferences});

  static const storageKey = 'tool_data_v1';
  final SharedPreferences? preferences;

  @override
  Future<ToolDataSnapshot> load() async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const ToolDataSnapshot();
    return ToolDataSnapshot.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
  }

  @override
  Future<void> replaceAll(ToolDataSnapshot snapshot) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(snapshot.toJson()));
  }
}
