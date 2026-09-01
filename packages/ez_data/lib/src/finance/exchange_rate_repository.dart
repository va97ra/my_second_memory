import 'dart:convert';

import 'package:ez_domain/ez_domain.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exchange_rate_source.dart';

/// Последние известные курсы и поход за свежими.
///
/// Курсы — это кэш чужих публичных данных, а не данные человека. Поэтому они
/// лежат в `SharedPreferences`, а не в базе: в резервную копию они не входят,
/// в синхронизацию не входят и формат ни того ни другого не поднимают.
/// Потерять их не страшно — они догоняются одним запросом.
class ExchangeRateRepository {
  ExchangeRateRepository({required this.source, this.preferences});

  static const storageKey = 'finance_exchange_rates_v1';

  final ExchangeRateSource source;
  final SharedPreferences? preferences;

  Future<SharedPreferences> get _prefs async =>
      preferences ?? await SharedPreferences.getInstance();

  /// Что лежит сейчас. `null` — не загружали ни разу.
  Future<ExchangeRates?> readCached() async {
    final raw = (await _prefs).getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return ExchangeRates.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      // Кэш испорчен или писан прошлой раскладкой: он не данные человека,
      // поэтому его просто нет.
      return null;
    }
  }

  Future<void> write(ExchangeRates rates) async {
    await (await _prefs).setString(storageKey, jsonEncode(rates.toJson()));
  }

  /// Курсы для показа: кэш, а если он пуст или устарел — поход в сеть.
  ///
  /// Отказ сети не ошибка экрана: если в кэше что-то есть, возвращается оно.
  /// Пусто и сеть молчит — возвращается `null`, и экран говорит об этом сам.
  ///
  /// `force` пропускает кэш и идёт к источнику всегда: так работает кнопка
  /// «синхронизировать». Отказ сети и здесь оставляет прежние курсы.
  Future<ExchangeRates?> load({DateTime? now, bool force = false}) async {
    final cached = await readCached();
    if (!force && cached != null && !_isStale(cached, now ?? DateTime.now())) {
      return cached;
    }
    try {
      final fresh = await source.fetch();
      await write(fresh);
      return fresh;
    } catch (_) {
      return cached;
    }
  }

  /// Курс считается устаревшим со следующего календарного дня: ЦБ публикует
  /// его раз в сутки, и дёргать источник чаще незачем.
  bool _isStale(ExchangeRates rates, DateTime now) {
    final rateDay = DateTime(rates.date.year, rates.date.month, rates.date.day);
    final today = DateTime(now.year, now.month, now.day);
    return rateDay.isBefore(today);
  }
}
