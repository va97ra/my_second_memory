import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shift_schedule.dart';
import 'shift_schedule_repository.dart';

class LocalShiftScheduleRepository implements ShiftScheduleRepository {
  const LocalShiftScheduleRepository();

  static const _storageKey = 'shift_schedules_v1';

  @override
  Future<List<ShiftSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((entry) {
      return ShiftSchedule.fromJson(Map<String, Object?>.from(entry as Map));
    }).toList();
  }

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
