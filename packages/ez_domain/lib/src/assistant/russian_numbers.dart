/// Числа, месяцы и дни недели словами — как их произносят.
library;

const _units =
    'одну|одна|один|две|два|три|четыре|пять|шесть|семь|восемь|девять';

/// Количественное число до 59: цифрами или словами («двадцать пять»).
const numberPattern = '(?:\\d{1,2}'
    '|(?:двадцать|тридцать|сорок|пятьдесят)(?:\\s+(?:$_units))?'
    '|одиннадцать|двенадцать|тринадцать|четырнадцать|пятнадцать|шестнадцать'
    '|семнадцать|восемнадцать|девятнадцать|десять|$_units)';

const _ordinalUnits =
    'первого|второго|третьего|четвертого|пятого|шестого|седьмого|восьмого|девятого';

/// Порядковое в родительном падеже: «пятнадцатого», «двадцать первого».
const ordinalPattern = '(?:(?:двадцать|тридцать)\\s+(?:$_ordinalUnits)'
    '|одиннадцатого|двенадцатого|тринадцатого|четырнадцатого|пятнадцатого'
    '|шестнадцатого|семнадцатого|восемнадцатого|девятнадцатого|десятого'
    '|двадцатого|тридцатого|$_ordinalUnits)';

/// Месяцы в родительном падеже — «15 октября».
const monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

/// Месяцы в именительном падеже — «покажи ноябрь».
const monthsNominative = [
  'январь',
  'февраль',
  'март',
  'апрель',
  'май',
  'июнь',
  'июль',
  'август',
  'сентябрь',
  'октябрь',
  'ноябрь',
  'декабрь',
];

final monthsGenitivePattern = monthsGenitive.join('|');

const _numberWords = {
  'один': 1,
  'одну': 1,
  'одна': 1,
  'два': 2,
  'две': 2,
  'пару': 2,
  'три': 3,
  'четыре': 4,
  'пять': 5,
  'шесть': 6,
  'семь': 7,
  'восемь': 8,
  'девять': 9,
  'десять': 10,
  'одиннадцать': 11,
  'двенадцать': 12,
  'тринадцать': 13,
  'четырнадцать': 14,
  'пятнадцать': 15,
  'шестнадцать': 16,
  'семнадцать': 17,
  'восемнадцать': 18,
  'девятнадцать': 19,
  'двадцать': 20,
  'тридцать': 30,
  'сорок': 40,
  'пятьдесят': 50,
};

const _ordinalWords = {
  'первого': 1,
  'второго': 2,
  'третьего': 3,
  'четвертого': 4,
  'пятого': 5,
  'шестого': 6,
  'седьмого': 7,
  'восьмого': 8,
  'девятого': 9,
  'десятого': 10,
  'одиннадцатого': 11,
  'двенадцатого': 12,
  'тринадцатого': 13,
  'четырнадцатого': 14,
  'пятнадцатого': 15,
  'шестнадцатого': 16,
  'семнадцатого': 17,
  'восемнадцатого': 18,
  'девятнадцатого': 19,
  'двадцатого': 20,
  'тридцатого': 30,
  'двадцать': 20,
  'тридцать': 30,
};

/// «15», «пятнадцать», «двадцать пять» → число; не число — null.
int? numberFromWords(String raw) {
  final text = raw.trim();
  final digits = int.tryParse(text);
  if (digits != null) return digits;
  return _sum(text, _numberWords);
}

/// «пятнадцатого», «двадцать первого» → число; иначе null.
int? ordinalFromWords(String raw) => _sum(raw.trim(), _ordinalWords);

int? _sum(String text, Map<String, int> words) {
  var total = 0;
  for (final word in text.split(RegExp(r'\s+'))) {
    final value = words[word];
    if (value == null) return null;
    total += value;
  }
  return total;
}

/// Номер месяца по родительному падежу: «октября» → 10.
int monthFromGenitive(String word) => monthsGenitive.indexOf(word) + 1;

/// Номер дня недели (понедельник — 1) по любой форме слова: «среду»,
/// «пятницам», «воскресенье».
int weekdayFromWord(String word) {
  const stems = ['пон', 'вто', 'сре', 'чет', 'пят', 'суб', 'вос'];
  return stems.indexOf(word.substring(0, 3)) + 1;
}

/// Сумма словами или цифрами: «500», «1500», «1 500», «2,5», «полторы тысячи»,
/// «пять тысяч», «тысяча двести». Не сумма — null.
double? amountFromWords(String raw) {
  final text = raw.trim().replaceAll(RegExp(r'(?<=\d)\s+(?=\d{3}(?!\d))'), '');
  final plain = double.tryParse(text.replaceAll(',', '.'));
  if (plain != null) return plain;
  final thousand = RegExp(
    r'^(?:(?<n>[\d.,]+|[а-я ]+?)\s+)?(?:тысяч[аиу]?|тыс\.?|к)(?:\s+(?<rest>.+))?$',
    unicode: true,
  ).firstMatch(text);
  if (thousand != null) {
    final head = thousand.namedGroup('n');
    final multiplier = head == null ? 1.0 : _smallAmount(head);
    if (multiplier == null) return null;
    final restRaw = thousand.namedGroup('rest');
    final rest = restRaw == null ? 0.0 : _smallAmount(restRaw);
    if (rest == null) return null;
    return multiplier * 1000 + rest;
  }
  return _smallAmount(text);
}

/// Одно слово числа: «двадцать», «пятьсот», «тысяч», «полтора».
final _numberWordPattern = [
  ..._numberWords.keys,
  ..._hundreds.keys,
  'тысяча',
  'тысячи',
  'тысячу',
  'тысяч',
  'полтора',
  'полторы',
].join('|');

/// Цепочка слов-чисел подряд: «сто двадцать пять», «пять тысяч двести».
final amountWordsPattern =
    '(?:$_numberWordPattern)(?:\\s+(?:$_numberWordPattern))*';

final _amountWords = RegExp(
  '(?<![а-я])$amountWordsPattern(?![а-я])',
  unicode: true,
);

/// Числа словами заменены цифрами: «двадцать пять на четыре» → «25 на 4».
/// Цепочка, которую не удалось сложить в число, остаётся как была.
String replaceNumberWords(String text) =>
    text.replaceAllMapped(_amountWords, (match) {
      final value = amountFromWords(match.group(0)!);
      if (value == null) return match.group(0)!;
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    });

double? _smallAmount(String raw) {
  final text = raw.trim();
  final plain = double.tryParse(text.replaceAll(',', '.'));
  if (plain != null) return plain;
  if (text == 'полторы' || text == 'полтора') return 1.5;
  var total = 0;
  for (final word in text.split(RegExp(r'\s+'))) {
    final value = _hundreds[word] ?? _numberWords[word];
    if (value == null) return null;
    total += value;
  }
  return total.toDouble();
}

const _hundreds = {
  'сто': 100,
  'двести': 200,
  'триста': 300,
  'четыреста': 400,
  'пятьсот': 500,
  'шестьсот': 600,
  'семьсот': 700,
  'восемьсот': 800,
  'девятьсот': 900,
  'шестьдесят': 60,
  'семьдесят': 70,
  'восемьдесят': 80,
  'девяносто': 90,
};
