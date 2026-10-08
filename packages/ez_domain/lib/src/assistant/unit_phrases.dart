import '../tools/unit_converter.dart';
import 'calculation_phrases.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'unit_words.dart';

/// Перевод величин: «сколько сантиметров в 3 дюймах», «переведи 5
/// километров в мили», «30 градусов Цельсия в Фаренгейты», «сколько метров
/// в миле».
///
/// Единица сразу после числа — та, из которой переводят; вторая — в которую.
/// Без числа переводят одну единицу: «сколько сантиметров в дюйме».
JarvisCommand? unitCommand(String work) {
  final text = replaceNumberWords(work);
  final mentions = _mentions(text);
  if (mentions.length != 2) return null;
  final first = mentions.first;
  final second = mentions.last;
  if (first.word.category != second.word.category) return null;
  if (first.word.unitId == second.word.unitId) return null;

  final number = _number.firstMatch(text);
  final double value;
  final _Mention from;
  if (number == null) {
    // «сколько сантиметров в дюйме» — переводится то, что после «в».
    if (!_question.hasMatch(text)) return null;
    value = 1;
    from = second;
  } else {
    value = double.parse(number.group(0)!.replaceAll(',', '.'));
    final gapToFirst = first.start - number.end;
    final gapToSecond = second.start - number.end;
    from = gapToFirst >= 0 && gapToFirst <= 2
        ? first
        : gapToSecond >= 0 && gapToSecond <= 2
            ? second
            : first;
  }
  final to = identical(from, first) ? second : first;
  if (!_onlyUnitsAndNumbers(text, mentions)) return null;
  return ConvertUnits(
    value: value,
    category: from.word.category,
    fromUnit: from.word.unitId,
    toUnit: to.word.unitId,
  );
}

/// Ответ вслух: «3 дюйма — это 7,62 сантиметра.»
String unitReply(ConvertUnits command) {
  final from = _wordFor(command.fromUnit, command.category);
  final to = _wordFor(command.toUnit, command.category);
  final result = UnitConverter.convert(
    category: command.category,
    fromUnitId: command.fromUnit,
    toUnitId: command.toUnit,
    value: command.value,
  );
  final shown = _rounded(result);
  return '${_rounded(command.value)} ${from.nameFor(command.value)} — это '
      '$shown ${to.nameFor(result)}.';
}

UnitWord _wordFor(String unitId, UnitCategory category) => unitWords
    .firstWhere((word) => word.unitId == unitId && word.category == category);

/// До четырёх знаков после запятой: «7,62», «0,3048», «1609,344».
String _rounded(double value) {
  final fixed =
      value.abs() >= 1000 ? value.toStringAsFixed(1) : value.toStringAsFixed(4);
  final trimmed = fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
  return spokenNumber(trimmed);
}

class _Mention {
  const _Mention(this.word, this.start, this.end);

  final UnitWord word;
  final int start;
  final int end;
}

/// Названные единицы по порядку. Составное название занимает своё место, и
/// простое внутри него второй раз не находится.
List<_Mention> _mentions(String text) {
  final taken = List.filled(text.length, false);
  final found = <_Mention>[];
  for (final word in unitWords) {
    final pattern = _patterns[word]!;
    for (final match in pattern.allMatches(text)) {
      if (taken.sublist(match.start, match.end).any((used) => used)) continue;
      for (var i = match.start; i < match.end; i++) {
        taken[i] = true;
      }
      found.add(_Mention(word, match.start, match.end));
    }
  }
  return found..sort((left, right) => left.start.compareTo(right.start));
}

/// Во фразе нет ничего, кроме чисел, единиц и служебных слов: иначе «в 3
/// часа встреча на 2 км» стала бы переводом величин.
bool _onlyUnitsAndNumbers(String text, List<_Mention> mentions) {
  final chars = text.split('');
  for (final mention in mentions) {
    for (var i = mention.start; i < mention.end; i++) {
      chars[i] = ' ';
    }
  }
  final rest = chars
      .join()
      .replaceAll(_number, ' ')
      .replaceAll(_service, ' ')
      .replaceAll(RegExp(r'[\s,.?!]+'), '');
  return rest.isEmpty;
}

final _patterns = {
  for (final word in unitWords)
    word: phrasePattern('$wordStart(?:${word.stems})$wordEnd'),
};

final _number = RegExp(r'\d+(?:[.,]\d+)?');

final _question = phrasePattern('^(?:сколько|скажи|подскажи)$wordEnd');

final _service = phrasePattern('$wordStart(?:сколько|будет|это|в|во|на'
    '|переведи|перевести|пересчитай|конвертируй|по|из|получится|скажи'
    '|подскажи|а|равно|равен|равна|содержится|одном|одной|одних)$wordEnd');
