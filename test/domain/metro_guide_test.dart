import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Метро Москвы без сети: схема, станции во фразе в любом падеже и маршрут
/// словами. Перенесено из MemoryVoice вместе со схемой.
void main() {
  final guide = MetroGuide.moscow;
  final map = guide.map;
  final now = DateTime(2026, 10, 9, 14);

  Set<int> ids(String name) => {
        for (var i = 0; i < map.stations.length; i++)
          if (map.stations[i].name == name) i,
      };

  String ask(String text) {
    final asked = guide.question(text);
    expect(asked, isNotNull, reason: text);
    return guide.route(asked!.from, asked.to);
  }

  group('схема', () {
    test('у всех станций есть координаты, номера в ветках верные', () {
      for (final station in map.stations) {
        expect(station.hasCoords, isTrue, reason: station.name);
      }
      for (final line in map.lines) {
        for (final branch in line.branches) {
          for (final index in branch) {
            expect(map.stations[index].line, line.id,
                reason: '${line.name}: ${map.stations[index].name}');
          }
        }
      }
    });

    test('с любой станции можно доехать до любой', () {
      final from = ids('Комсомольская');
      for (var i = 0; i < map.stations.length; i++) {
        expect(map.route(from, {i}), isNotNull, reason: map.stations[i].name);
      }
    });
  });

  group('станции во фразе', () {
    List<String> names(String text) =>
        [for (final mention in guide.mentions(text)) mention.name];

    test('в любом падеже', () {
      expect(names('от щёлковской до комсомольской'),
          ['Щёлковская', 'Комсомольская']);
      expect(names('до Парка культуры'), ['Парк культуры']);
      expect(names('с Охотного ряда'), ['Охотный Ряд']);
      expect(names('от Марьиной рощи'), ['Марьина Роща']);
    });

    test('длинное название важнее короткого, похожие не путаются', () {
      expect(names('до Октябрьского поля'), ['Октябрьское поле']);
      expect(names('до Октябрьской'), ['Октябрьская']);
      expect(names('до Хорошёвской'), ['Хорошёвская']);
      expect(names('от Сокола'), ['Сокол']);
    });
  });

  group('маршрут', () {
    test('с пересадкой: Щёлковская → Комсомольская', () {
      final said = ask('как доехать от Щёлковской до Комсомольской');
      expect(said,
          startsWith('От станции «Щёлковская» до станции «Комсомольская»'));
      expect(said, contains('одна пересадка'));
      expect(said, contains('Садитесь на синюю ветку, Арбатско-Покровскую'));
      expect(said, contains('На станции «Курская» пересадка на коричневую'));
    });

    test('«до … от …» — порядок наоборот', () {
      final said = ask('как добраться до Курской от Щёлковской');
      expect(said, startsWith('От станции «Щёлковская» до станции «Курская»'));
      expect(said, contains('без пересадок'));
    });

    test('назвали только, куда ехать, — спрашивает откуда', () {
      expect(ask('как доехать до Курской'), startsWith('Откуда поедете'));
    });

    test('та же станция — уже на месте', () {
      expect(ask('как доехать от Курской до Курской'), contains('уже на месте'));
    });
  });

  group('в разборе фраз', () {
    test('вопрос о дороге — маршрут, а не дело', () {
      final command = const JarvisCommandParser()
          .parse('Джарвис, как доехать от Сокола до Театральной?', now);
      expect(command, isA<AskMetroRoute>());
      final route = command! as AskMetroRoute;
      expect(route.from, 'Сокол');
      expect(route.to, 'Театральная');
    });

    test('«завтра доехать до Курской» без вопроса — дело', () {
      expect(guide.question('завтра доехать до Курской'), isNull);
    });
  });
}
