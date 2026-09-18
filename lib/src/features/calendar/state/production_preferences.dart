import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductionPreferences {
  const ProductionPreferences(
      {this.highlight = true,
      this.weekNumbers = true,
      this.showProgress = true,
      this.includeToday = false});
  final bool highlight;
  final bool weekNumbers;
  final bool showProgress;
  final bool includeToday;

  ProductionPreferences copyWith(
          {bool? highlight,
          bool? weekNumbers,
          bool? showProgress,
          bool? includeToday}) =>
      ProductionPreferences(
          highlight: highlight ?? this.highlight,
          weekNumbers: weekNumbers ?? this.weekNumbers,
          showProgress: showProgress ?? this.showProgress,
          includeToday: includeToday ?? this.includeToday);
}

final productionPreferencesProvider = StateNotifierProvider<
    ProductionPreferencesController,
    ProductionPreferences>((ref) => ProductionPreferencesController());

class ProductionPreferencesController
    extends StateNotifier<ProductionPreferences> {
  ProductionPreferencesController() : super(const ProductionPreferences()) {
    _load();
  }
  static const storageKey = 'calendar_production_preferences_v1';
  bool _changed = false;
  Future<void> _writes = Future.value();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || _changed) return;
    try {
      final raw = prefs.getString(storageKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = ProductionPreferences(
          highlight: json['highlight'] as bool? ?? true,
          weekNumbers: json['weekNumbers'] as bool? ?? true,
          showProgress: json['showProgress'] as bool? ?? true,
          includeToday: json['includeToday'] as bool? ?? false);
    } catch (_) {/* Invalid preferences use the defaults. */}
  }

  Future<void> update(
      {bool? highlight,
      bool? weekNumbers,
      bool? showProgress,
      bool? includeToday}) {
    _changed = true;
    state = state.copyWith(
        highlight: highlight,
        weekNumbers: weekNumbers,
        showProgress: showProgress,
        includeToday: includeToday);
    final next = state;
    return _writes = _writes.catchError((_) {}).then((_) async {
      await (await SharedPreferences.getInstance()).setString(
          storageKey,
          jsonEncode({
            'highlight': next.highlight,
            'weekNumbers': next.weekNumbers,
            'showProgress': next.showProgress,
            'includeToday': next.includeToday,
          }));
    });
  }
}
