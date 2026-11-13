import 'dart:async';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productionCalendarRepositoryProvider = Provider((ref) {
  final source = IsDayOffSource();
  ref.onDispose(source.close);
  return ProductionCalendarRepository(source: source);
});

final productionCalendarProvider = NotifierProvider.autoDispose
    .family<ProductionCalendarController, ProductionCalendarState, int>(
  ProductionCalendarController.new,
);

class ProductionCalendarState {
  const ProductionCalendarState(
      {this.cached, this.loading = false, this.failed = false});
  final CachedProductionYear? cached;
  final bool loading;
  final bool failed;
  ProductionCalendar get calendar => ProductionCalendar(yearData: cached?.data);
}

class ProductionCalendarController extends Notifier<ProductionCalendarState> {
  ProductionCalendarController(this.year);

  final int year;
  late final ProductionCalendarRepository _repository;
  bool _busy = false;

  @override
  ProductionCalendarState build() {
    _repository = ref.watch(productionCalendarRepositoryProvider);
    // A calendar left open overnight still refreshes. Fresh data avoids HTTP.
    final timer = Timer.periodic(const Duration(hours: 1), (_) => _load());
    ref.onDispose(timer.cancel);
    _load();
    return const ProductionCalendarState(loading: true);
  }

  Future<void> refresh() => _load(force: true);

  Future<void> _load({bool force = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      // До первой записи состояния в нём ничего нет: build ещё не вернул.
      final cached = stateOrNull?.cached ?? await _repository.readCached(year);
      if (!ref.mounted) return;
      final fresh = !force && cached != null && cached.isFresh(DateTime.now());
      state = ProductionCalendarState(cached: cached, loading: !fresh);
      if (fresh) return;
      try {
        final updated = await _repository.refresh(year);
        if (ref.mounted) state = ProductionCalendarState(cached: updated);
      } catch (_) {
        if (ref.mounted) {
          state = ProductionCalendarState(cached: cached, failed: true);
        }
      }
    } finally {
      _busy = false;
    }
  }
}
