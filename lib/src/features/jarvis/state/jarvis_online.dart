import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final jarvisOnlineProvider = Provider<JarvisOnline>((ref) {
  final online = JarvisOnline();
  ref.onDispose(online.close);
  return online;
});

/// Справки из интернета для нейросети Джарвиса: погода, Википедия, новости.
///
/// Отказ сети — не поломка: нейросеть получает его словами и пересказывает
/// или отвечает по памяти. Город для погоды запоминается: «какая завтра
/// погода» без города — про тот, что владелец называл раньше.
class JarvisOnline {
  JarvisOnline({OnlineFetch? fetch}) : _fetch = fetch ?? OnlineFetch() {
    _weather = WeatherSource(_fetch);
    _wikipedia = WikipediaSource(_fetch);
    _news = NewsSource(_fetch);
  }

  final OnlineFetch _fetch;
  late final WeatherSource _weather;
  late final WikipediaSource _wikipedia;
  late final NewsSource _news;

  static const _cityKey = 'jarvis_weather_city_v1';

  Future<Object?> weather({
    String? place,
    DateTime? day,
    required DateTime now,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final named = place?.trim() ?? '';
    final city = named.isNotEmpty ? named : preferences.getString(_cityKey);
    if (city == null) {
      return {'error': 'Город не известен. Спроси владельца, где он.'};
    }
    return _answer(() async {
      final weather = await _weather.weather(city, day, now);
      if (named.isNotEmpty) await preferences.setString(_cityKey, named);
      return weather;
    });
  }

  Future<Object?> lookup(String query) =>
      _answer(() => _wikipedia.lookup(query));

  Future<Object?> news(String? topic) =>
      _answer(() => _news.headlines(topic: topic));

  void close() => _fetch.close();

  static Future<Object?> _answer(
    Future<Map<String, Object?>> Function() ask,
  ) async {
    try {
      return await ask();
    } on OnlineException catch (failure) {
      return {'error': failure.message};
    }
  }
}
