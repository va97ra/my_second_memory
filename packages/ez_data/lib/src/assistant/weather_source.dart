import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import 'online_fetch.dart';

/// Погода для Джарвиса: город — геопоиском Open-Meteo, прогноз — MET
/// Norway (api.met.no, CC BY 4.0), запасной — Open-Meteo. У владельца на МТС
/// прогноз Open-Meteo не открывается, поэтому первым идёт MET.
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца.
class WeatherSource {
  WeatherSource(this._fetch);

  final OnlineFetch _fetch;

  /// Погода в [place] на [day] (null — сегодня, вместе с погодой сейчас).
  Future<Map<String, Object?>> weather(
    String place,
    DateTime? day,
    DateTime now,
  ) async {
    final geo = await _fetch.json(Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {'name': place, 'count': '1', 'language': 'ru', 'format': 'json'},
    ));
    final results = (geo is Map ? geo['results'] : null) as List?;
    if (results == null || results.isEmpty) {
      throw OnlineException('Не нашёл город «$place»');
    }
    final found = results.first as Map;
    final name =
        [found['name'], found['admin1']].whereType<String>().toSet().join(', ');
    final latitude = (found['latitude'] as num).toDouble();
    final longitude = (found['longitude'] as num).toDouble();
    final zone = found['timezone'] as String? ?? 'Europe/Moscow';
    final target = DateTime((day ?? now).year, (day ?? now).month,
        (day ?? now).day);
    final today = target.year == now.year &&
        target.month == now.month &&
        target.day == now.day;

    Map<String, Object?> forecast;
    try {
      forecast =
          await _metNo(latitude, longitude, zone, target, includeNow: today);
    } on OnlineException {
      forecast =
          await _openMeteo(latitude, longitude, target, includeNow: today);
    }
    return {'place': name, ...forecast};
  }

  /// Почасовой ряд MET сводится в день по местному времени города.
  Future<Map<String, Object?>> _metNo(
    double latitude,
    double longitude,
    String zone,
    DateTime day, {
    required bool includeNow,
  }) async {
    final data = await _fetch.json(Uri.https(
      'api.met.no',
      '/weatherapi/locationforecast/2.0/compact',
      {
        'lat': latitude.toStringAsFixed(4),
        'lon': longitude.toStringAsFixed(4),
      },
    )) as Map;
    final series =
        ((data['properties'] as Map)['timeseries'] as List).cast<Map>();
    final location = _location(zone);
    var minimum = double.infinity;
    var maximum = -double.infinity;
    var rain = 0.0;
    var wind = 0.0;
    String? symbol;
    var symbolDistance = 99;
    for (final entry in series) {
      final at = tz.TZDateTime.from(
          DateTime.parse(entry['time'] as String), location);
      if (at.year != day.year || at.month != day.month || at.day != day.day) {
        continue;
      }
      final details = entry['data'] as Map;
      final instant = (details['instant'] as Map)['details'] as Map;
      final temperature = (instant['air_temperature'] as num).toDouble();
      if (temperature < minimum) minimum = temperature;
      if (temperature > maximum) maximum = temperature;
      final speed = (instant['wind_speed'] as num?)?.toDouble() ?? 0;
      if (speed > wind) wind = speed;
      final next =
          (details['next_1_hours'] ?? details['next_6_hours']) as Map?;
      rain += ((next?['details'] as Map?)?['precipitation_amount'] as num?)
              ?.toDouble() ??
          0;
      // Погода «за день» — та, что около 13:00.
      final code = (next?['summary'] as Map?)?['symbol_code'] as String?;
      final distance = (at.hour - 13).abs();
      if (code != null && distance < symbolDistance) {
        symbol = code;
        symbolDistance = distance;
      }
    }
    if (minimum == double.infinity) {
      throw const OnlineException('Прогноз есть только на ближайшие 9 дней');
    }
    final result = <String, Object?>{
      'source': 'MET Norway',
      'date': _isoDate(day),
      'condition': metCondition(symbol ?? ''),
      'temp_min_c': minimum.round(),
      'temp_max_c': maximum.round(),
      'precipitation_mm': double.parse(rain.toStringAsFixed(1)),
      'wind_max_ms': wind.round(),
    };
    if (includeNow && series.isNotEmpty) {
      final first = series.first['data'] as Map;
      result['now_temp_c'] =
          (((first['instant'] as Map)['details'] as Map)['air_temperature']
                  as num)
              .round();
      final code = ((first['next_1_hours'] as Map?)?['summary']
          as Map?)?['symbol_code'] as String?;
      if (code != null) result['now_condition'] = metCondition(code);
    }
    return result;
  }

  Future<Map<String, Object?>> _openMeteo(
    double latitude,
    double longitude,
    DateTime day, {
    required bool includeNow,
  }) async {
    final data = await _fetch.json(Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current': 'temperature_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max,wind_speed_10m_max',
      'timezone': 'auto',
      'forecast_days': '16',
    })) as Map;
    final daily = data['daily'] as Map;
    final dates = (daily['time'] as List).cast<String>();
    final index = dates.indexOf(_isoDate(day));
    if (index < 0) {
      throw OnlineException(
          'Прогноз есть только на ближайшие ${dates.length} дней');
    }
    num at(String field) => (daily[field] as List)[index] as num? ?? 0;
    final result = <String, Object?>{
      'source': 'Open-Meteo',
      'date': _isoDate(day),
      'condition': wmoCondition(at('weather_code').toInt()),
      'temp_min_c': at('temperature_2m_min').round(),
      'temp_max_c': at('temperature_2m_max').round(),
      'rain_chance_percent': at('precipitation_probability_max').round(),
      'wind_max_ms': (at('wind_speed_10m_max') / 3.6).round(),
    };
    final current = data['current'] as Map?;
    if (includeNow && current != null) {
      result['now_temp_c'] = (current['temperature_2m'] as num).round();
      result['now_condition'] =
          wmoCondition((current['weather_code'] as num).toInt());
    }
    return result;
  }

  static bool _zonesReady = false;

  static tz.Location _location(String name) {
    if (!_zonesReady) {
      timezone_data.initializeTimeZones();
      _zonesReady = true;
    }
    // Неизвестный пояс — не повод отказать в погоде: сутки считаются по
    // Москве, ошибка в сводке — не больше нескольких часов.
    return tz.timeZoneDatabase.locations[name] ??
        tz.getLocation('Europe/Moscow');
  }

  /// Код погоды MET («lightrain», «partlycloudy_day») — по-русски.
  static String metCondition(String symbol) {
    final base = symbol.split('_').first;
    final thunder = base.contains('thunder');
    final text = switch (base.replaceAll('andthunder', '')) {
      'clearsky' => 'ясно',
      'fair' => 'малооблачно',
      'partlycloudy' => 'переменная облачность',
      'cloudy' => 'пасмурно',
      'fog' => 'туман',
      'lightrain' => 'небольшой дождь',
      'rain' => 'дождь',
      'heavyrain' => 'сильный дождь',
      'lightrainshowers' => 'небольшой ливень',
      'rainshowers' => 'ливень',
      'heavyrainshowers' => 'сильный ливень',
      'lightsleet' ||
      'sleet' ||
      'lightsleetshowers' ||
      'sleetshowers' =>
        'мокрый снег',
      'heavysleet' || 'heavysleetshowers' => 'сильный мокрый снег',
      'lightsnow' || 'lightsnowshowers' => 'небольшой снег',
      'snow' || 'snowshowers' => 'снег',
      'heavysnow' || 'heavysnowshowers' => 'сильный снег',
      _ => thunder ? '' : 'без осадков',
    };
    if (!thunder) return text;
    return text.isEmpty ? 'гроза' : '$text, гроза';
  }

  /// Код погоды WMO (Open-Meteo) — по-русски.
  static String wmoCondition(int code) => switch (code) {
        0 => 'ясно',
        1 => 'преимущественно ясно',
        2 => 'переменная облачность',
        3 => 'пасмурно',
        45 || 48 => 'туман',
        51 || 53 || 55 => 'морось',
        56 || 57 => 'ледяная морось',
        61 => 'небольшой дождь',
        63 => 'дождь',
        65 => 'сильный дождь',
        66 || 67 => 'ледяной дождь',
        71 => 'небольшой снег',
        73 => 'снег',
        75 => 'сильный снег',
        77 => 'снежная крупа',
        80 || 81 => 'ливень',
        82 => 'сильный ливень',
        85 || 86 => 'снегопад',
        95 => 'гроза',
        96 || 99 => 'гроза с градом',
        _ => 'без осадков',
      };

  static String _isoDate(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
