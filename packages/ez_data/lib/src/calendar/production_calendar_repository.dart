import 'dart:convert';
import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'production_calendar_source.dart';

class CachedProductionYear {
  const CachedProductionYear(this.data, this.checkedAt);
  final ProductionYear data;
  final DateTime checkedAt;
  bool isFresh(DateTime now) =>
      !checkedAt.isAfter(now) &&
      now.difference(checkedAt) < const Duration(hours: 24);
}

/// Public reference data: excluded from backups and personal-data sync.
class ProductionCalendarRepository {
  ProductionCalendarRepository({required this.source, this.preferences});
  final ProductionCalendarSource source;
  final SharedPreferences? preferences;
  final _pending = <int, Future<CachedProductionYear>>{};
  static String storageKey(int year) => 'production_ru_five_day_v1_$year';
  Future<SharedPreferences> get _prefs async =>
      preferences ?? await SharedPreferences.getInstance();

  Future<CachedProductionYear?> readCached(int year) async {
    try {
      final raw = (await _prefs).getString(storageKey(year));
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedProductionYear(
          parseProductionYear(year, json['days'] as String),
          DateTime.parse(json['checkedAt'] as String));
    } catch (_) {
      return null;
    }
  }

  Future<CachedProductionYear> refresh(int year, {DateTime? now}) =>
      _pending[year] ??= _fetch(year, now ?? DateTime.now()).whenComplete(() {
        _pending.remove(year);
      });

  Future<CachedProductionYear> _fetch(int year, DateTime now) async {
    final raw = await source.fetch(year);
    final data = parseProductionYear(year, raw);
    final saved = await (await _prefs).setString(
        storageKey(year),
        jsonEncode({
          'days': raw,
          'checkedAt': now.toUtc().toIso8601String(),
        }));
    if (!saved) throw StateError('Could not persist production calendar');
    return CachedProductionYear(data, now);
  }
}
