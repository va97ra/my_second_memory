import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository(source: CbrExchangeRateSource());
});

/// Курсы для конвертера. `null` в значении — курсов нет вовсе: ни в кэше, ни
/// из сети. Это не ошибка, а состояние, о котором экран говорит человеку.
final exchangeRatesProvider =
    AsyncNotifierProvider<ExchangeRatesController, ExchangeRates?>(
  ExchangeRatesController.new,
);

class ExchangeRatesController extends AsyncNotifier<ExchangeRates?> {
  @override
  Future<ExchangeRates?> build() =>
      ref.watch(exchangeRateRepositoryProvider).load(force: false);

  /// Сходить к источнику, не спрашивая кэш.
  ///
  /// Обычная загрузка бережёт чужой сервер: курс ЦБ меняется раз в сутки, и
  /// сегодняшний кэш она считает свежим. Но кэш мог приехать до публикации, и
  /// тогда человеку нужен способ сказать «сходи ещё раз» — не удаляя данные и
  /// не переустанавливая приложение.
  Future<void> syncWithSource() async {
    final repository = ref.read(exchangeRateRepositoryProvider);
    // Прежние курсы остаются на экране, пока едут новые: загрузка поверх
    // данных сохраняет их, и конвертер не становится пустым из-за нажатия
    // на «обновить».
    state = const AsyncLoading();
    final rates = await AsyncValue.guard(() => repository.load(force: true));
    if (ref.mounted) state = rates;
  }
}
