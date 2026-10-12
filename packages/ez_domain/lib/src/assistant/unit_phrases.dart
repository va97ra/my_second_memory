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
///
/// Переводит конвертер Ежедневника, а Джарвис его заполняет: «а в метрах?»,
/// «а если 10?», «поменяй местами» продолжают то, что на нём.
JarvisCommand? unitCommand(String work) {
  final text = replaceNumberWords(work.replaceAll(_onConverter, ' ')).trim();
  if (_swap.hasMatch(text)) return const ConverterCommand(ConverterMove.swap);
  final mentions = _mentions(text);
  if (mentions.length < 2) return _continued(text, mentions);
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

/// «А в метрах?», «переведи в метры», «а если 10?», «а 10 футов?» —
/// продолжение того, что на конвертере. Число — только после «а»: «в 3
/// часа» и «на 10 минут» — не конвертер.
JarvisCommand? _continued(String text, List<_Mention> mentions) {
  if (!_onlyUnitsAndNumbers(text, mentions)) return null;
  final unit = mentions.isEmpty ? null : mentions.single.word;
  final number = _number.firstMatch(text);
  if (number == null) {
    if (unit == null || !_into.hasMatch(text)) return null;
    return ConverterCommand(ConverterMove.retarget,
        unit: unit.unitId, category: unit.category);
  }
  if (!_and.hasMatch(text)) return null;
  return ConverterCommand(
    ConverterMove.revalue,
    value: double.parse(number.group(0)!.replaceAll(',', '.')),
    unit: unit?.unitId,
    category: unit?.category,
  );
}

/// Ответ вслух тем, что показал конвертер: «3 дюйма — это 7,62
/// сантиметра.» [result] — его ответ.
String unitReply(ConvertUnits command, double result) {
  final from = _nameOf(command.fromUnit, command.category, command.value);
  final to = _nameOf(command.toUnit, command.category, result);
  return '${_rounded(command.value)} $from — это ${_rounded(result)} $to.';
}

/// На конвертере другая величина, чем названная единица.
const converterMismatch = 'На конвертере сейчас другая величина. Скажите '
    'перевод целиком — например, «сколько граммов в 2 фунтах».';

/// Единица словом по числу; единица без русского названия — обозначением,
/// как на конвертере.
String _nameOf(String unitId, UnitCategory category, double value) {
  for (final word in unitWords) {
    if (word.unitId == unitId && word.category == category) {
      return word.nameFor(value);
    }
  }
  return UnitConverter.unitOrNull(category, unitId)?.symbol ?? unitId;
}

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
    '|подскажи|а|равно|равен|равна|содержится|одном|одной|одних|если'
    '|для|теперь|покажи)$wordEnd');

/// «На конвертере» — лишние слова: переводит всегда он.
final _onConverter = phrasePattern('\\s*(?:на|в)\\s+конвертер[а-я]*$wordEnd');

/// «А в метрах?» — во что переводить.
final _into = phrasePattern('$wordStart(?:в|во)$wordEnd');

/// «А если 10?» — продолжение начинается с «а».
final _and = phrasePattern('^а$wordEnd');

final _swap = phrasePattern('^(?:поменяй(?:\\s+их)?\\s+местами|наоборот'
    '|переведи\\s+обратно)\$');
