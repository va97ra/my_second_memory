import '../language/russian_plural.dart';
import 'metro_map.dart';
import 'moscow_metro_data.dart';

/// Станция, которую назвал человек: имя и все станции узла на разных линиях.
class StationMention {
  const StationMention(this.name, this.ids, this.start, this.end);

  final String name;
  final Set<int> ids;

  /// Номера слов во фразе: [start, end).
  final int start;
  final int end;
}

/// «Как доехать от Щёлковской до Комсомольской?» → ветки, пересадки и
/// время. Без нейросети и без интернета.
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца.
class MetroGuide {
  MetroGuide(this.map, Map<String, List<String>> aliases) {
    for (var i = 0; i < map.stations.length; i++) {
      final name = map.stations[i].name;
      final names = {
        name,
        ...?aliases[name],
        if (RegExp(r'^(Улица|Бульвар) ', unicode: true).hasMatch(name))
          name.substring(name.indexOf(' ') + 1),
      };
      for (final said in names) {
        final key = _tokens(said).join(' ');
        final entry = _byName.putIfAbsent(key, () => _Name(name, _tokens(said)))
          ..ids.add(i);
        // «Деловой центр» — и другое имя «Выставочной», и своя станция:
        // называем своё.
        if (said == name) entry.display = name;
      }
    }
    _names = _byName.values.toList()
      ..sort((a, b) => b.tokens.length.compareTo(a.tokens.length));
  }

  static final moscow = MetroGuide(MetroMap.moscow, moscowAliases);

  final MetroMap map;
  final _byName = <String, _Name>{};
  late final List<_Name> _names;

  static final _travel = RegExp(
    r'(?<![а-я])(доехать|добраться|доеду|доберусь|доберемся|проехать|ехать'
    r'|едем|маршрут[а-я]*|дорог[аиуе]|попасть)(?![а-я])',
    unicode: true,
  );
  static final _question = RegExp(
    r'(?<![а-я])(как|каким|сколько|подскажи|подскажите|покажи|где'
    r'|маршрут[а-я]*)(?![а-я])',
    unicode: true,
  );
  static const _skip = {'метро', 'станции', 'станция', 'станцию', 'м'};
  static const _fromWords = {'от', 'из', 'с', 'со'};

  static String _norm(String text) => text.toLowerCase().replaceAll('ё', 'е');

  static List<String> _tokens(String text) => _norm(text)
      .split(RegExp(r'[^а-яa-z0-9]+', unicode: true))
      .where((token) => token.isNotEmpty)
      .toList();

  /// Слово из речи подходит к слову названия в любом падеже: «щелковской»
  /// ~ «щелковская».
  static bool _same(String spoken, String word) {
    if (spoken == word) return true;
    if (RegExp(r'\d').hasMatch(word)) return false;
    // «сад» ~ «сада», «ряд» ~ «ряду»: у коротких слов окончание просто
    // добавляется.
    final cut = word.length >= 6 ? 2 : (word.length >= 4 ? 1 : 0);
    final stem = word.substring(0, word.length - cut);
    return spoken.startsWith(stem) && spoken.length <= word.length + 2;
  }

  /// Все станции во фразе по порядку; самое длинное название — первым.
  List<StationMention> mentions(String text) {
    final words = _tokens(text);
    final found = <StationMention>[];
    var i = 0;
    while (i < words.length) {
      _Name? best;
      for (final name in _names) {
        if (i + name.tokens.length > words.length) continue;
        var same = true;
        for (var k = 0; k < name.tokens.length && same; k++) {
          same = _same(words[i + k], name.tokens[k]);
        }
        if (same) {
          best = name;
          break;
        }
      }
      if (best == null) {
        i++;
        continue;
      }
      found.add(
          StationMention(best.display, best.ids, i, i + best.tokens.length));
      i += best.tokens.length;
    }
    return found;
  }

  /// Вопрос о дороге: откуда и куда. null — это не о метро. Пустое
  /// «откуда» — назвали только, куда ехать.
  ({String? from, String to})? question(String text) {
    final said = _norm(text);
    if (!_travel.hasMatch(said)) return null;
    final found = mentions(text);
    final distinct = <StationMention>[];
    for (final mention in found) {
      if (!distinct.any((known) => known.name == mention.name)) {
        distinct.add(mention);
      }
    }
    if (distinct.isEmpty) return null;
    if (distinct.length == 1) {
      if (found.length >= 2) return (from: distinct[0].name, to: distinct[0].name);
      // «Завтра доехать до Курской» без вопроса — это дело, а не маршрут.
      if (!_question.hasMatch(said)) return null;
      return (from: null, to: distinct[0].name);
    }
    var from = distinct[0], to = distinct[1];
    // «До Курской от Щёлковской» — порядок наоборот.
    final words = _tokens(text);
    if (_wordBefore(words, to.start) case final word?
        when _fromWords.contains(word)) {
      if (_wordBefore(words, from.start) == 'до') (from, to) = (to, from);
    }
    return (from: from.name, to: to.name);
  }

  /// Маршрут по названиям станций — словами для экрана и голоса.
  String route(String? from, String to) {
    if (from == null) {
      return 'Откуда поедете до станции «$to»? Скажите, например: '
          '«от Щёлковской до станции $to».';
    }
    final a = _find(from);
    final b = _find(to);
    if (a == null) return 'Не знаю станцию «$from».';
    if (b == null) return 'Не знаю станцию «$to».';
    final aName = map.stations[a.first].name;
    final bName = map.stations[b.first].name;
    if (a.intersection(b).isNotEmpty) {
      return 'Вы уже на месте: это одна и та же станция.';
    }
    final found = map.route(a, b);
    if (found == null) return 'Не нашёл дорогу от «$aName» до «$bName».';
    return describe(found, aName, bName);
  }

  Set<int>? _find(String name) {
    final found = mentions(name);
    return found.isEmpty ? null : found.first.ids;
  }

  static String? _wordBefore(List<String> words, int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (!_skip.contains(words[i])) return words[i];
    }
    return null;
  }

  /// Текст для экрана и голоса.
  static String describe(MetroRoute route, String from, String to) {
    final minutes =
        route.minutes < 15 ? route.minutes : (route.minutes / 5).round() * 5;
    final changes = switch (route.transfers) {
      0 => 'без пересадок',
      1 => 'одна пересадка',
      2 => 'две пересадки',
      3 => 'три пересадки',
      final count =>
        '$count ${russianPlural(count, 'пересадка', 'пересадки', 'пересадок')}',
    };
    final lines = <String>[
      'От станции «$from» до станции «$to» — примерно $minutes '
          '${russianPlural(minutes, 'минута', 'минуты', 'минут')}, $changes.',
    ];
    for (var i = 0; i < route.legs.length; i++) {
      final leg = route.legs[i];
      final line = leg.line.id == '14'
          ? 'МЦК'
          : '${_accusative(leg.line.color)} ветку, ${_accusative(leg.line.name)}';
      final ride = 'в сторону «${leg.toward}», ${_stops(leg.stops)} '
          'до станции «${leg.to.name}».';
      lines.add(i == 0
          ? 'Садитесь на $line, $ride'
          : 'На станции «${leg.from.name}» пересадка на $line, $ride');
    }
    return lines.join('\n');
  }

  static String _stops(int count) => switch (count) {
        1 => 'одна остановка',
        2 => 'две остановки',
        _ =>
          '$count ${russianPlural(count, 'остановка', 'остановки', 'остановок')}',
      };

  /// «синяя» → «синюю», «Большая кольцевая» → «Большую кольцевую».
  static String _accusative(String text) => text.split(' ').map((word) {
        if (word.endsWith('ая')) return '${word.substring(0, word.length - 2)}ую';
        if (word.endsWith('яя')) return '${word.substring(0, word.length - 2)}юю';
        return word;
      }).join(' ');
}

class _Name {
  _Name(this.display, this.tokens);

  String display;
  final List<String> tokens;
  final ids = <int>{};
}
