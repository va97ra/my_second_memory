import 'dart:async';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productionCalendarRepositoryProvider = Provider((ref) {
  final source = IsDayOffSource();
  ref.onDispose(source.close);
  return ProductionCalendarRepository(source: source);
});

final productionCalendarProvider = StateNotifierProvider.autoDispose
    .family<ProductionCalendarController, ProductionCalendarState, int>(
        (ref, year) {
  return ProductionCalendarController(
      ref.watch(productionCalendarRepositoryProvider), year);
});

class ProductionCalendarState {
  const ProductionCalendarState(
      {this.cached, this.loading = false, this.failed = false});
  final CachedProductionYear? cached;
  final bool loading;
  final bool failed;
  ProductionCalendar get calendar => ProductionCalendar(yearData: cached?.data);
}

class ProductionCalendarController
    extends StateNotifier<ProductionCalendarState> {
  ProductionCalendarController(this.repository, this.year)
      : super(const ProductionCalendarState(loading: true)) {
    _load();
    // A calendar left open overnight still refreshes. Fresh data avoids HTTP.
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _load());
  }
  final ProductionCalendarRepository repository;
  final int year;
  Timer? _timer;
  bool _busy = false;

  Future<void> refresh() => _load(force: true);

  Future<void> _load({bool force = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final cached = state.cached ?? await repository.readCached(year);
      if (!mounted) return;
      final fresh = !force && cached != null && cached.isFresh(DateTime.now());
      state = ProductionCalendarState(cached: cached, loading: !fresh);
      if (fresh) return;
      try {
        final updated = await repository.refresh(year);
        if (mounted) state = ProductionCalendarState(cached: updated);
      } catch (_) {
        if (mounted) {
          state = ProductionCalendarState(cached: cached, failed: true);
        }
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
