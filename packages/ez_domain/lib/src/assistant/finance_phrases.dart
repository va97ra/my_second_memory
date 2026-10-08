import '../finance/finance_entry.dart';
import '../recurrence/recurrence_dates.dart';
import 'currency_phrases.dart';
import 'date_phrases.dart';
import 'jarvis_command.dart';
import 'moment_hits.dart';
import 'phrase_scan.dart';
import 'time_phrases.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';

/// Деньги голосом: «потратил 500 на продукты», «купил хлеб за 80», «расход
/// 1200 такси», «получил зарплату 50 тысяч», «вчера заплатил за интернет
/// 600» — и вопросы: «сколько я потратил в этом месяце», «какой доход в
/// сентябре».
JarvisCommand? financeCommand(String work, DateTime now) {
  final question = _financeQuestion(work, now);
  if (question != null) return question;

  final FinanceEntryKind kind;
  if (_expenseVerb.hasMatch(work)) {
    kind = FinanceEntryKind.expense;
  } else if (_incomeVerb.hasMatch(work)) {
    kind = FinanceEntryKind.income;
  } else {
    return null;
  }

  // День и время вынимаются первыми: «вчера» — не категория, а «в 5» и
  // «15 октября» — не суммы.
  final scan = PhraseScan(work);
  final hits = MomentHits();
  collectDates(scan, hits, now);
  collectTimes(scan, hits);
  final date = hits.dates.isEmpty ? dateOnly(now) : hits.dates.first;
  var text = replaceNumberWords(scan.work);

  // «купил 2 хлеба за 80» — сумма та, что после «за».
  final paid = _paidFor.firstMatch(text);
  final amountMatch = paid ?? _amount.firstMatch(text);
  if (amountMatch == null) return null;
  final raw = paid == null ? amountMatch.group(0)! : paid.namedGroup('n')!;
  final amount = raw.replaceAll(' ', '').replaceAll(',', '.');
  if ((double.tryParse(amount) ?? 0) <= 0) return null;
  text = text.replaceRange(amountMatch.start, amountMatch.end, ' ');

  final currencies = currencyMentions(text);
  final currency = currencies.isEmpty ? null : currencies.first.$1.code;
  for (final word in currencyWords) {
    text = text.replaceAll(
        phrasePattern('$wordStart(?:${word.stems})$wordEnd'), ' ');
  }
  final category = _category(text);
  return AddFinanceEntry(
    kind: kind,
    amount: amount,
    date: date,
    currency: currency,
    category: category.isEmpty ? _defaultCategory(kind) : category,
  );
}

/// Ответ на вопрос о деньгах: «В октябре расходы — 12 300 рублей.»
String financeReply(
  AskFinance command, {
  required String total,
  required String currency,
  required DateTime now,
}) {
  final month = command.month;
  final period = month.year == now.year && month.month == now.month
      ? 'В этом месяце'
      : 'В ${_monthsPrepositional[month.month - 1]}'
          '${month.year == now.year ? '' : ' ${month.year} года'}';
  final what = command.kind == FinanceEntryKind.expense ? 'расходы' : 'доходы';
  final value = double.tryParse(total) ?? 0;
  if (value == 0) {
    return '$period $what не записаны.';
  }
  final name = currencyWords.any((word) => word.code == currency)
      ? currencyWordOf(currency).nameFor(value)
      : currency;
  return '$period $what — ${total.replaceAll('.', ',')} $name.';
}

String _defaultCategory(FinanceEntryKind kind) =>
    kind == FinanceEntryKind.expense ? 'Прочее' : 'Доход';

/// Категория из того, что осталось: «на продукты» → «Продукты».
String _category(String text) {
  var rest = text.replaceAll(_expenseVerb, ' ').replaceAll(_incomeVerb, ' ');
  rest = rest.replaceAll(_serviceWords, ' ');
  rest = compactPhrase(rest.replaceAll(RegExp(r'[,.!?:;]'), ' '));
  rest = rest
      .replaceFirst(_leadingPreposition, '')
      .replaceFirst(_trailingPreposition, '')
      .trim();
  return capitalizeFirst(rest);
}

AskFinance? _financeQuestion(String work, DateTime now) {
  if (!_asks.hasMatch(work)) return null;
  final FinanceEntryKind kind;
  if (_spentQuestion.hasMatch(work)) {
    kind = FinanceEntryKind.expense;
  } else if (_earnedQuestion.hasMatch(work)) {
    kind = FinanceEntryKind.income;
  } else {
    return null;
  }
  return AskFinance(kind: kind, month: _monthOf(work, now));
}

DateTime _monthOf(String work, DateTime now) {
  if (_lastMonth.hasMatch(work)) return DateTime(now.year, now.month - 1);
  for (var i = 0; i < 12; i++) {
    final named = phrasePattern(
        '$wordStart(?:${_monthsPrepositional[i]}|${monthsNominative[i]})$wordEnd');
    if (named.hasMatch(work)) {
      final month = i + 1;
      // Названный месяц — прошедший: о будущих тратах не спрашивают.
      return DateTime(month > now.month ? now.year - 1 : now.year, month);
    }
  }
  return DateTime(now.year, now.month);
}

const _monthsPrepositional = [
  'январе',
  'феврале',
  'марте',
  'апреле',
  'мае',
  'июне',
  'июле',
  'августе',
  'сентябре',
  'октябре',
  'ноябре',
  'декабре',
];

final _expenseVerb = phrasePattern('$wordStart(?:потратил[а-я]*|истратил[а-я]*'
    '|заплатил[а-я]*|оплатил[а-я]*|отдал[а-я]*|купил[а-я]*|расход|трат[аы]'
    '|списали|списание)$wordEnd');

final _incomeVerb = phrasePattern('$wordStart(?:получил[а-я]*|заработал[а-я]*'
    '|доход|поступлени[ея]|приход|пришл[оаи]|поступил[оаи]?|начислили'
    '|перевели\\s+мне)$wordEnd');

final _amount = RegExp(r'\d+(?: \d{3})*(?:[.,]\d+)?');

final _paidFor =
    phrasePattern('$wordStartза\\s+(?<n>\\d+(?: \\d{3})*(?:[.,]\\d+)?)');

final _serviceWords = phrasePattern('$wordStart(?:я|мне|запиши|записать'
    '|добавь|всего|сегодня|сумму|сумма|в\\s+размере|примерно|около)$wordEnd');

final _leadingPreposition = phrasePattern('^(?:на|за|в|во|от|с|по)$wordEnd');

final _trailingPreposition =
    phrasePattern('$wordStart(?:на|за|в|во|от|с|по)\$');

final _asks = phrasePattern('^(?:сколько|какой|какие|какая|каков[а-я]*'
    '|покажи|скажи|расскажи)$wordEnd');

final _spentQuestion =
    phrasePattern('$wordStart(?:потратил[а-я]*|расход[а-я]*|трат[а-я]*'
        '|истратил[а-я]*|ушло)$wordEnd');

final _earnedQuestion = phrasePattern('$wordStart(?:заработал[а-я]*'
    '|доход[а-я]*|получил[а-я]*|пришло|поступлени[а-я]*)$wordEnd');

final _lastMonth = phrasePattern('прошл[а-я]*\\s+месяц');
