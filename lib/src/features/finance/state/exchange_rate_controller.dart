import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository(source: CbrExchangeRateSource());
});

/// Курсы для конвертера. `null` в значении — курсов нет вовсе: ни в кэше, ни
/// из сети. Это не ошибка, а состояние, о котором экран говорит человеку.
final exchangeRatesProvider = FutureProvider<ExchangeRates?>((ref) {
  return ref.watch(exchangeRateRepositoryProvider).load();
});
