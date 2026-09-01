import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository(source: CbrExchangeRateSource());
});

/// Курсы для конвертера. `null` в значении — курсов нет вовсе: ни в кэше, ни
/// из сети. Это не ошибка, а состояние, о котором экран говорит человеку.
final exchangeRatesProvider =
    StateNotifierProvider<ExchangeRatesController, AsyncValue<ExchangeRates?>>(
        (ref) {
  return ExchangeRatesController(ref.watch(exchangeRateRepositoryProvider));
});

class ExchangeRatesController
    extends StateNotifier<AsyncValue<ExchangeRates?>> {
  ExchangeRatesController(this._repository)
      : super(const AsyncValue.loading()) {
    _load(force: false);
  }

  final ExchangeRateRepository _repository;

  /// Сходить к источнику, не спрашивая кэш.
  ///
  /// Обычная загрузка бережёт чужой сервер: курс ЦБ меняется раз в сутки, и
  /// сегодняшний кэш она считает свежим. Но кэш мог приехать до публикации, и
  /// тогда человеку нужен способ сказать «сходи ещё раз» — не удаляя данные и
  /// не переустанавливая приложение.
  Future<void> syncWithSource() => _load(force: true);

  Future<void> _load({required bool force}) async {
    // Прежние курсы остаются на экране, пока едут новые: конвертер не должен
    // на секунду становиться пустым из-за нажатия на «обновить».
    state = const AsyncValue<ExchangeRates?>.loading().copyWithPrevious(state);
    try {
      final rates = await _repository.load(force: force);
      if (mounted) state = AsyncValue.data(rates);
    } catch (error, stackTrace) {
      if (mounted) state = AsyncValue.error(error, stackTrace);
    }
  }
}
