import 'calculation_phrases.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import '../language/russian_plural.dart';

/// Валюта, названная словами.
class CurrencyWord {
  const CurrencyWord(this.code, this.stems,
      {required this.one, required this.few, required this.many});

  final String code;
  final String stems;
  final String one;
  final String few;
  final String many;

  String nameFor(double value) {
    if (value != value.roundToDouble()) return few;
    return russianPlural(value.toInt(), one, few, many);
  }
}

/// Названия валют. Составные — раньше простых: «белорусский рубль» не рубль.
const currencyWords = [
  CurrencyWord('BYN', 'белорусск[а-я]*\\s+рубл[а-я]*',
      one: 'белорусский рубль',
      few: 'белорусских рубля',
      many: 'белорусских рублей'),
  CurrencyWord('CAD', 'канадск[а-я]*\\s+доллар[а-я]*',
      one: 'канадский доллар',
      few: 'канадских доллара',
      many: 'канадских долларов'),
  CurrencyWord('AUD', 'австралийск[а-я]*\\s+доллар[а-я]*',
      one: 'австралийский доллар',
      few: 'австралийских доллара',
      many: 'австралийских долларов'),
  CurrencyWord(
      'GBP', 'фунт[а-я]*\\s+стерлинг[а-я]*|британск[а-я]*\\s+фунт[а-я]*',
      one: 'фунт стерлингов',
      few: 'фунта стерлингов',
      many: 'фунтов стерлингов'),
  CurrencyWord('CZK', 'чешск[а-я]*\\s+крон[а-я]*',
      one: 'чешская крона', few: 'чешские кроны', many: 'чешских крон'),
  CurrencyWord('USD', 'доллар[а-я]*|бакс[а-я]*',
      one: 'доллар', few: 'доллара', many: 'долларов'),
  CurrencyWord('EUR', 'евро', one: 'евро', few: 'евро', many: 'евро'),
  CurrencyWord('CNY', 'юан[а-я]*', one: 'юань', few: 'юаня', many: 'юаней'),
  CurrencyWord('RUB', 'рубл[а-я]*|руб',
      one: 'рубль', few: 'рубля', many: 'рублей'),
  CurrencyWord('JPY', '[иий]ен[аыу]?', one: 'иена', few: 'иены', many: 'иен'),
  CurrencyWord('KZT', 'тенге', one: 'тенге', few: 'тенге', many: 'тенге'),
  CurrencyWord('AMD', 'драм(?:а|ов|ы)?',
      one: 'драм', few: 'драма', many: 'драмов'),
  CurrencyWord('GEL', 'лари', one: 'лари', few: 'лари', many: 'лари'),
  CurrencyWord('TRY', 'лир[аыу]?', one: 'лира', few: 'лиры', many: 'лир'),
  CurrencyWord('AED', 'дирхам[а-я]*',
      one: 'дирхам', few: 'дирхама', many: 'дирхамов'),
  CurrencyWord('INR', 'рупи[а-я]*', one: 'рупия', few: 'рупии', many: 'рупий'),
  CurrencyWord('CHF', 'франк[а-я]*',
      one: 'франк', few: 'франка', many: 'франков'),
  CurrencyWord('PLN', 'злот[а-я]*',
      one: 'злотый', few: 'злотых', many: 'злотых'),
  CurrencyWord('THB', 'бат(?:а|ов|ы)?', one: 'бат', few: 'бата', many: 'батов'),
];

/// Курс и пересчёт: «курс доллара», «сколько 100 долларов в рублях»,
/// «переведи 5000 рублей в евро», «сколько рублей в 50 юанях».
JarvisCommand? currencyCommand(String work) {
  final text = replaceNumberWords(work);
  final mentions = currencyMentions(text);
  if (mentions.isEmpty) return null;

  final rate = _rate.hasMatch(text);
  final number = _number.firstMatch(text);
  if (rate && mentions.length == 1 && number == null) {
    final code = mentions.single.$1.code;
    return code == 'RUB'
        ? null
        : ConvertCurrency(amount: 1, from: code, to: 'RUB');
  }
  if (mentions.length > 2 || number == null && !rate) return null;
  if (!_asksConversion.hasMatch(text) && !rate) return null;

  final amount = number == null
      ? 1.0
      : double.parse(number.group(0)!.replaceAll(',', '.'));
  final first = mentions.first;
  final second = mentions.length == 2 ? mentions.last : null;
  // Валюта сразу после числа — та, из которой считают.
  final afterNumber = number == null
      ? (second ?? first)
      : mentions.firstWhere(
          (mention) => mention.$2 >= number.end && mention.$2 - number.end <= 2,
          orElse: () => first,
        );
  final other = second == null
      ? null
      : identical(afterNumber, first)
          ? second
          : first;
  final from = afterNumber.$1.code;
  final to = other?.$1.code ?? (from == 'RUB' ? null : 'RUB');
  if (to == null || to == from) return null;
  return ConvertCurrency(amount: amount, from: from, to: to);
}

/// Ответ вслух: «По курсу ЦБ на 8 октября 100 долларов — это 9450,5 рубля.»
/// [ratesDate] — день, на который опубликован курс.
String currencyReply(
  ConvertCurrency command, {
  required double result,
  required DateTime ratesDate,
  required DateTime now,
}) {
  final from = currencyWordOf(command.from);
  final to = currencyWordOf(command.to);
  final day = ratesDate.year == now.year &&
          ratesDate.month == now.month &&
          ratesDate.day == now.day
      ? 'на сегодня'
      : 'на ${ratesDate.day} ${monthsGenitive[ratesDate.month - 1]}';
  final amount = _money(command.amount);
  final shown = _money(result);
  return 'По курсу ЦБ $day ${amount.text} ${from.nameFor(amount.value)} — '
      'это ${shown.text} ${to.nameFor(shown.value)}.';
}

/// Деньги — до копеек: «9450,5», «1».
({String text, double value}) _money(double value) {
  final rounded = (value * 100).round() / 100;
  final text = rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return (text: spokenNumber(text), value: rounded);
}

/// Названные валюты по порядку: слово и начало его в тексте.
List<(CurrencyWord, int)> currencyMentions(String text) {
  final taken = List.filled(text.length, false);
  final found = <(CurrencyWord, int)>[];
  for (final word in currencyWords) {
    for (final match in _patterns[word]!.allMatches(text)) {
      if (taken.sublist(match.start, match.end).any((used) => used)) continue;
      for (var i = match.start; i < match.end; i++) {
        taken[i] = true;
      }
      found.add((word, match.start));
    }
  }
  return found..sort((left, right) => left.$2.compareTo(right.$2));
}

CurrencyWord currencyWordOf(String code) =>
    currencyWords.firstWhere((word) => word.code == code);

final _patterns = {
  for (final word in currencyWords)
    word: phrasePattern('$wordStart(?:${word.stems})$wordEnd'),
};

final _number = RegExp(r'\d+(?:[.,]\d+)?');

final _rate = phrasePattern('$wordStartкурс[а-я]*$wordEnd');

final _asksConversion = phrasePattern('^(?:сколько|переведи|пересчитай'
    '|конвертируй|почем|скажи)$wordEnd|$wordStart(?:в|во)\\s+[а-я]+\\s*\\??\$'
    '|это\\s+сколько');
