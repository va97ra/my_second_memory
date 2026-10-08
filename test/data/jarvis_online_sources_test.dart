import 'dart:convert';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Справки Джарвиса из сети на заготовленных ответах. Образцы ответов —
/// из MemoryVoice, где источники проверены на телефоне владельца.
void main() {
  final now = DateTime(2026, 10, 7, 14);

  http.Response json(Object body) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );

  String rss(List<(String, String)> items) => '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0"><channel><title>X</title>
${items.map((item) => '<item><title>${item.$1}</title><pubDate>${item.$2}</pubDate></item>').join('\n')}
</channel></rss>''';

  /// Почасовой прогноз MET: 7–9 октября по Москве, каждые 3 часа; 8-го
  /// днём дождь, от 13 до 18 градусов.
  Map<String, Object?> metSample() {
    final series = <Map<String, Object?>>[];
    for (var hour = 0; hour < 72; hour += 3) {
      final utc = DateTime.utc(2026, 10, 6, 21).add(Duration(hours: hour));
      final local = utc.add(const Duration(hours: 3));
      final eighth = local.day == 8;
      series.add({
        'time': utc.toIso8601String(),
        'data': {
          'instant': {
            'details': {
              'air_temperature': eighth ? 13.0 + local.hour / 4.6 : 15.0,
              'wind_speed': eighth ? 6.0 : 3.0,
            },
          },
          'next_1_hours': {
            'summary': {
              'symbol_code':
                  eighth && local.hour >= 9 ? 'rain' : 'partlycloudy_day',
            },
            'details': {'precipitation_amount': eighth ? 1.5 : 0.0},
          },
        },
      });
    }
    return {
      'properties': {'timeseries': series},
    };
  }

  OnlineFetch net({Set<String> broken = const {}}) => OnlineFetch(
        client: MockClient((request) async {
          final url = request.url;
          if (broken.contains(url.host)) throw http.ClientException('нет сети');
          switch (url.host) {
            case 'geocoding-api.open-meteo.com':
              if (url.queryParameters['name'] == 'Нигдебург') {
                return json({'generationtime_ms': 1});
              }
              return json({
                'results': [
                  {
                    'name': 'Сочи',
                    'admin1': 'Краснодарский край',
                    'latitude': 43.6,
                    'longitude': 39.7,
                    'timezone': 'Europe/Moscow',
                  },
                ],
              });
            case 'api.met.no':
              return json(metSample());
            case 'api.open-meteo.com':
              return json({
                'current': {
                  'temperature_2m': 19.1,
                  'weather_code': 1,
                  'wind_speed_10m': 7.2,
                },
                'daily': {
                  'time': ['2026-10-07', '2026-10-08'],
                  'weather_code': [1, 63],
                  'temperature_2m_max': [21.4, 18.6],
                  'temperature_2m_min': [14.2, 13.5],
                  'precipitation_probability_max': [5, 80],
                  'wind_speed_10m_max': [10.8, 18.0],
                },
              });
            case 'ru.wikipedia.org':
              if (url.path == '/w/api.php') {
                return json({
                  'query': {
                    'search': [
                      {'title': 'Тесла, Никола'},
                    ],
                  },
                });
              }
              return json({
                'title': 'Тесла, Никола',
                'extract': 'Никола Тесла — изобретатель в области '
                    'электротехники и радиотехники.',
              });
            case 'tass.ru':
              return http.Response.bytes(
                  utf8.encode(rss([
                    ('Сборная России сыграет в Минске',
                        'Wed, 07 Oct 2026 16:50:52 +0300'),
                    ('В Москве открылся новый парк',
                        'Wed, 07 Oct 2026 15:00:00 +0300'),
                  ])),
                  200);
            case 'ria.ru':
              return http.Response.bytes(
                  utf8.encode(rss([
                    ('Курс доллара снизился', 'Wed, 07 Oct 2026 16:55:00 +0300'),
                  ])),
                  200);
            case 'lenta.ru':
              return http.Response.bytes(utf8.encode('<html>сломан'), 200);
          }
          return http.Response('нет', 404);
        }),
      );

  group('погода', () {
    test('на завтра — по MET Norway', () async {
      final weather =
          await WeatherSource(net()).weather('Сочи', DateTime(2026, 10, 8), now);
      expect(weather['source'], 'MET Norway');
      expect(weather['place'], 'Сочи, Краснодарский край');
      expect(weather['date'], '2026-10-08');
      expect(weather['condition'], 'дождь');
      expect(weather['temp_min_c'], 13);
      expect(weather['temp_max_c'], 18);
      expect(weather.containsKey('now_temp_c'), isFalse,
          reason: 'погода «сейчас» — только для сегодня');
    });

    test('MET недоступен — запасной Open-Meteo', () async {
      final weather = await WeatherSource(net(broken: {'api.met.no'}))
          .weather('Сочи', null, now);
      expect(weather['source'], 'Open-Meteo');
      expect(weather['condition'], 'преимущественно ясно');
      expect(weather['now_temp_c'], 19);
    });

    test('неизвестный город — понятная причина', () async {
      expect(
        () => WeatherSource(net()).weather('Нигдебург', null, now),
        throwsA(isA<OnlineException>().having(
            (error) => error.message, 'message', contains('Нигдебург'))),
      );
    });
  });

  group('Википедия', () {
    test('краткая справка', () async {
      final page = await WikipediaSource(net()).lookup('Тесла');
      expect(page['title'], 'Тесла, Никола');
      expect(page['summary'], startsWith('Никола Тесла'));
    });

    test('закрыта оператором — совет ответить по памяти', () async {
      expect(
        () => WikipediaSource(net(broken: {'ru.wikipedia.org'})).lookup('Тесла'),
        throwsA(isA<OnlineException>().having(
            (error) => error.message, 'message', contains('по памяти'))),
      );
    });
  });

  group('новости', () {
    test('свежие первыми, сломанная лента не мешает', () async {
      final news = await NewsSource(net()).headlines();
      final titles = [
        for (final item in news['news'] as List) (item as Map)['title'],
      ];
      expect(titles.first, 'Курс доллара снизился');
      expect(titles, hasLength(3));
    });

    test('по теме — только про неё, в любом падеже', () async {
      final news = await NewsSource(net()).headlines(topic: 'Москва');
      expect((news['news'] as List).single,
          {'title': 'В Москве открылся новый парк', 'source': 'ТАСС'});
    });

    test('молчат все ленты — нет интернета', () async {
      expect(
        () => NewsSource(net(broken: {'tass.ru', 'ria.ru', 'lenta.ru'}))
            .headlines(),
        throwsA(isA<OnlineException>()),
      );
    });
  });
}
