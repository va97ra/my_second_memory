import '../finance/finance_entry.dart';
import '../language/russian_plural.dart';
import '../recurrence/recurrence_dates.dart';
import 'currency_phrases.dart';
import 'jarvis_command.dart';
import 'russian_numbers.dart';
import 'russian_words.dart';
import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Прошлое: «что я делал 15 апреля», «чем занимался в прошлом месяце»,
/// «когда пришла зарплата», «какие расходы были вчера», «сколько ушло на
/// такси в сентябре».
///
/// Деньги — только из журнала финансов Ежедневника: туда их записывают
/// голосом или Джарвис из уведомлений банков. В приложения банков он не
/// ходит.
JarvisCommand? historyCommand(String work, DateTime now) {
  if (_moneyWord.hasMatch(work)) return _financeHistory(work, now);
  final unfinished = _unfinished.hasMatch(work);
  if (!unfinished && !_didWhat.hasMatch(work)) return null;
  final today = dateOnly(now);
  // «Что я не доделал» без периода — за последний месяц, до вчера.
  final period = pastPeriod(work, now) ??
      (unfinished
          ? (
              from: DateTime(today.year, today.month - 1, today.day),
              to: DateTime(today.year, today.month, today.day - 1),
              label: 'за последний месяц',
            )
          : null);
  if (period == null) return null;
  return AskHistory(
    from: period.from,
    to: period.to,
    label: period.label,
    unfinished: unfinished,
    important: asksImportant(work),
  );
}

/// «Самое важное», «главное», «срочное», «по приоритету».
bool asksImportant(String work) => _important.hasMatch(work);

final _important = phrasePattern('$wordStart(?:важн[а-я]*|главн[а-я]*'
    '|срочн[а-я]*|приоритет[а-я]*)');

final _unfinished = phrasePattern('$wordStart(?:не\\s+(?:закончил[а]?|доделал[а]?'
    '|сделал[а]?|выполнил[а]?|успел[а]?|отметил[а]?)|несделанн[а-я]*'
    '|невыполненн[а-я]*|незаконченн[а-я]*|осталось\\s+(?:сделать|несделанным))');

typedef PastPeriod = ({DateTime from, DateTime to, String label});

/// Период в прошлом, названный во фразе; null — не назван. День, который
/// разбор дат кладёт в будущее («15 апреля» в октябре), здесь — прошедший.
PastPeriod? pastPeriod(String work, DateTime now) {
  final today = dateOnly(now);
  DateTime day(int offset) => DateTime(today.year, today.month, today.day + offset);
  PastPeriod month(int back, String label) {
    final first = DateTime(today.year, today.month - back);
    final last = DateTime(first.year, first.month + 1, 0);
    return (from: first, to: last.isAfter(today) ? today : last, label: label);
  }

  if (_lastMonth.hasMatch(work)) return month(1, 'в прошлом месяце');
  if (_thisMonth.hasMatch(work)) return month(0, 'в этом месяце');
  final monday = day(1 - today.weekday);
  if (_lastWeek.hasMatch(work)) {
    return (
      from: DateTime(monday.year, monday.month, monday.day - 7),
      to: DateTime(monday.year, monday.month, monday.day - 1),
      label: 'на прошлой неделе',
    );
  }
  if (_thisWeek.hasMatch(work)) {
    return (from: monday, to: today, label: 'на этой неделе');
  }
  final span = _span.firstMatch(work);
  if (span != null) {
    final unit = span.namedGroup('u')!;
    final count = _count(span.namedGroup('n'), unit);
    final from = switch (unit) {
      final u when u.startsWith('нед') => day(-7 * count),
      final u when u.startsWith('дн') || u.startsWith('ден') => day(-count),
      final u when u.startsWith('год') || u.startsWith('лет') =>
        DateTime(today.year - count, today.month, today.day),
      _ => DateTime(today.year, today.month - count, today.day),
    };
    return (from: from, to: today, label: 'за ${span.group(0)!.substring(3)}');
  }
  final ago = _ago.firstMatch(work);
  if (ago != null) {
    final unit = ago.namedGroup('u')!;
    final count = _count(ago.namedGroup('n'), unit);
    final said = ago.group(0)!;
    if (unit.startsWith('дн') || unit.startsWith('ден')) {
      final that = day(-count);
      return (from: that, to: that, label: '$said, ${spokenDate(that, now)}');
    }
    if (unit.startsWith('нед')) {
      final start = day(-7 * count - today.weekday + 1);
      return (
        from: start,
        to: DateTime(start.year, start.month, start.day + 6),
        label: said,
      );
    }
    if (unit.startsWith('год') || unit.startsWith('лет')) {
      final that = DateTime(today.year - count, today.month, today.day);
      return (from: that, to: that, label: '$said, ${spokenDate(that, now)}');
    }
    return month(count, said);
  }
  for (var i = 0; i < 12; i++) {
    final named = phrasePattern('$wordStart(?:в\\s+)?(?:${monthsPrepositional[i]}'
        '|${monthsNominative[i]})$wordEnd(?!\\s+\\d)');
    if (named.hasMatch(work) && !_dayAndMonth.hasMatch(work)) {
      final back = (today.month - (i + 1) + 12) % 12;
      return month(back, 'в ${monthsPrepositional[i]}');
    }
  }
  var date = const TaskPhraseParser().parseAnswer(work, now).date;
  if (date == null) return null;
  if (date.isAfter(today)) {
    final ahead = daysBetween(today, date);
    date = _weekdayWord.hasMatch(work) && ahead <= 7
        ? DateTime(date.year, date.month, date.day - 7)
        : ahead <= 31
            ? DateTime(date.year, date.month - 1, date.day)
            : DateTime(date.year - 1, date.month, date.day);
  }
  return (from: date, to: date, label: spokenDay(date, now));
}

int _count(String? raw, String unit) {
  if (unit == 'полгода' || raw == 'пол') return 6;
  if (raw == null) return 1;
  return int.tryParse(raw) ?? numberFromWords(raw) ?? 1;
}

JarvisCommand? _financeHistory(String work, DateTime now) {
  final asksWhen = _when.hasMatch(work);
  final asksList = _listQuestion.hasMatch(work);
  final asksSum = _sumQuestion.hasMatch(work);
  if (!asksWhen && !asksList && !asksSum) return null;
  final kind = _incomeWord.hasMatch(work)
      ? FinanceEntryKind.income
      : _expenseWord.hasMatch(work)
          ? FinanceEntryKind.expense
          : null;
  final what = _whatOf(work);
  final period = pastPeriod(work, now);
  // «Сколько я потратил в сентябре» без «на что» — итог месяца
  // (`financeCommand`): он отвечает в валюте журнала.
  if (asksSum && !asksWhen && !asksList && what.isEmpty) return null;
  final today = dateOnly(now);
  final fallback = asksWhen
      ? (
          from: DateTime(today.year - 1, today.month, today.day),
          to: today,
          label: 'за год',
        )
      : (
          from: DateTime(today.year, today.month),
          to: today,
          label: 'в этом месяце',
        );
  final chosen = period ?? fallback;
  return AskFinanceHistory(
    from: chosen.from,
    to: chosen.to,
    label: chosen.label,
    kind: kind,
    what: what,
    asksWhen: asksWhen,
  );
}

/// О чём спросили: всё, что осталось от фразы без вопроса, глаголов и
/// периода. «Когда пришла зарплата в прошлом месяце» → «зарплата».
String _whatOf(String work) {
  var rest = work;
  for (final pattern in [
    _lastMonth, _thisMonth, _lastWeek, _thisWeek, _span, _ago, _dayAndMonth,
    _monthName, _service, _moneyVerb, _questionWord,
  ]) {
    rest = rest.replaceAll(pattern, ' ');
  }
  rest = rest.replaceAll(RegExp(r'\d+'), ' ').replaceAll(RegExp(r'[?!.,]'), ' ');
  rest = compactPhrase(rest).replaceFirst(_leadingPreposition, '').trim();
  return _generic.hasMatch(rest) ? '' : rest;
}

/// Ответ о прошлом журнала финансов. [entries] — весь журнал; отбирается
/// здесь: период, вид и «про что».
String financeHistoryReply(
  AskFinanceHistory command,
  List<FinanceEntry> entries,
  DateTime now,
) {
  final what = searchStems(command.what);
  final found = [
    for (final entry in entries)
      if (!entry.occurredOn.isBefore(command.from) &&
          !dateOnly(entry.occurredOn).isAfter(command.to) &&
          (command.kind == null || entry.kind == command.kind) &&
          (what.isEmpty || _sameWords(entry.category, what)))
        entry,
  ]..sort((left, right) => right.occurredOn.compareTo(left.occurredOn));
  final label = command.label;
  final subject = command.what.isEmpty
      ? (command.kind == FinanceEntryKind.income ? 'доходы' : 'расходы')
      : '«${command.what}»';
  if (found.isEmpty) {
    return 'Не нашёл в финансах ${command.what.isEmpty ? subject : subject} '
        '$label.';
  }
  if (command.asksWhen) {
    final shown = found.take(5).map((entry) =>
        '${spokenDate(entry.occurredOn, now)} — ${spokenMoney(_value(entry), entry.currencyCode)}');
    return '${capitalizeFirst(command.what.isEmpty ? subject : command.what)}: '
        '${shown.join('; ')}${found.length > 5 ? '; и ещё ${found.length - 5}' : ''}.';
  }
  if (command.what.isNotEmpty) {
    final times = found.length;
    return '${capitalizeFirst(command.what)} $label — ${_totals(found)}, '
        '$times ${russianPlural(times, 'раз', 'раза', 'раз')}.';
  }
  final parts = <String>[];
  for (final kind in FinanceEntryKind.values) {
    final ofKind = [for (final entry in found) if (entry.kind == kind) entry];
    if (ofKind.isEmpty) continue;
    final name = kind == FinanceEntryKind.expense ? 'расходы' : 'доходы';
    parts.add('$name — ${_totals(ofKind)}: ${_byCategory(ofKind)}');
  }
  return '${capitalizeFirst(label)} ${parts.join('. ')}.';
}

double _value(FinanceEntry entry) => double.tryParse(entry.amount) ?? 0;

bool _sameWords(String category, List<String> what) {
  final known = searchStems(category);
  return what.every((stem) =>
      known.any((word) => word.startsWith(stem) || stem.startsWith(word)));
}

/// «45 000 рублей», «45 000 рублей и 100 долларов».
String _totals(List<FinanceEntry> entries) {
  final sums = <String, double>{};
  for (final entry in entries) {
    sums[entry.currencyCode] = (sums[entry.currencyCode] ?? 0) + _value(entry);
  }
  return joinWithAnd([
    for (final MapEntry(key: code, value: sum) in sums.entries) spokenMoney(sum, code),
  ]);
}

/// Крупнейшие категории: «продукты — 12 000 рублей, такси — 6 000 рублей».
String _byCategory(List<FinanceEntry> entries) {
  final sums = <(String, String), double>{};
  for (final entry in entries) {
    final key = (entry.category, entry.currencyCode);
    sums[key] = (sums[key] ?? 0) + _value(entry);
  }
  final top = sums.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  final shown = [
    for (final MapEntry(key: (category, code), value: sum) in top.take(5))
      '${lowerFirst(category)} — ${spokenMoney(sum, code)}',
  ];
  final more = top.length > 5 ? ' и ещё ${top.length - 5}' : '';
  return '${shown.join(', ')}$more';
}

const monthsPrepositional = [
  'январе', 'феврале', 'марте', 'апреле', 'мае', 'июне', 'июле', 'августе',
  'сентябре', 'октябре', 'ноябре', 'декабре',
];

final _didWhat = phrasePattern('$wordStart(?:что\\s+(?:я\\s+)?(?:делал[а]?'
    '|было|планировал[а]?)|что\\s+у\\s+меня\\s+было|чем\\s+(?:я\\s+)?'
    '(?:занимал(?:ся|ась)|был[а]?\\s+занят[а]?)|какие\\s+(?:у\\s+меня\\s+)?'
    '(?:дела|записи|планы)\\s+(?:у\\s+меня\\s+)?были|где\\s+я\\s+был[а]?)$wordEnd');

final _moneyWord = phrasePattern('$wordStart(?:расход[а-я]*|трат[а-я]*'
    '|потратил[а-я]*|ушло|доход[а-я]*|поступлени[а-я]*|зарплат[а-я]*'
    '|пришл[аио]|поступил[аио]?|получил[а-я]*|заплатил[а-я]*|платил[а-я]*'
    '|оплатил[а-я]*|покупк[а-я]*|купил[а-я]*|аванс[а-я]*|деньг[а-я]*)$wordEnd');

final _incomeWord = phrasePattern('$wordStart(?:доход[а-я]*|поступлени[а-я]*'
    '|зарплат[а-я]*|пришл[аио]|поступил[аио]?|получил[а-я]*|аванс[а-я]*)$wordEnd');

final _expenseWord = phrasePattern('$wordStart(?:расход[а-я]*|трат[а-я]*'
    '|потратил[а-я]*|ушло|заплатил[а-я]*|платил[а-я]*|оплатил[а-я]*'
    '|покупк[а-я]*|купил[а-я]*)$wordEnd');

final _when = phrasePattern('^(?:а\\s+)?когда$wordEnd');
final _listQuestion = phrasePattern('^(?:а\\s+)?(?:какие|что\\s+за|покажи'
    '|расскажи|перечисли|на\\s+что|что\\s+я)$wordEnd');
final _sumQuestion = phrasePattern('^(?:а\\s+)?сколько$wordEnd');

final _lastMonth = phrasePattern('$wordStart(?:в\\s+|за\\s+)?прошл[а-я]*\\s+месяц[а-я]*');
final _thisMonth = phrasePattern('$wordStart(?:в\\s+|за\\s+)?(?:этом|этот|текущ[а-я]*)\\s+месяц[а-я]*');
final _lastWeek = phrasePattern('$wordStart(?:на\\s+|за\\s+)?прошл[а-я]*\\s+недел[а-я]*');
final _thisWeek = phrasePattern('$wordStart(?:на\\s+|за\\s+)?(?:этой|эту)\\s+недел[а-я]*');
final _span = phrasePattern('$wordStartза\\s+(?:(?<n>\\d+|[а-я]+)\\s+)?'
    '(?<u>полгода|дн[а-я]*|день|недел[а-я]*|месяц[а-я]*|год[а-я]*|лет)$wordEnd');
final _ago = phrasePattern('$wordStart(?:(?<n>\\d+|[а-я]+)\\s+)?'
    '(?<u>полгода|дн[а-я]*|день|недел[а-я]*|неделю|месяц[а-я]*|год[а-я]*|лет)'
    '\\s+назад$wordEnd');
final _dayAndMonth = phrasePattern('\\d{1,2}\\s+(?:январ|феврал|март|апрел'
    '|ма[яй]|июн|июл|август|сентябр|октябр|ноябр|декабр)[а-я]*'
    '|\\d{1,2}(?:-?го)?\\s+числа');
final _monthName = phrasePattern('$wordStart(?:в\\s+)?(?:январ|феврал|март|апрел'
    '|ма[яйе]|июн|июл|август|сентябр|октябр|ноябр|декабр)[а-я]*$wordEnd');
final _weekdayWord = phrasePattern('$wordStart(?:понедельник|вторник|сред[уа]'
    '|четверг|пятниц[уа]|суббот[уа]|воскресень[ея])$wordEnd');

final _service = phrasePattern('$wordStart(?:я|мне|меня|у|был[аио]?|были|есть'
    '|больше\\s+всего|чаще\\s+всего|меньше\\s+всего|больше|чаще|в\\s+основном'
    '|последний\\s+раз|в\\s+последний\\s+раз|вообще|всего|вчера|позавчера'
    '|сегодня|ли|мой|моя|мои|за|раз|число|числа)$wordEnd');
final _moneyVerb = phrasePattern('$wordStart(?:потратил[а-я]*|тратил[а-я]*'
    '|ушло'
    '|пришл[аио]|поступил[аио]?|получил[а-я]*|заплатил[а-я]*|платил[а-я]*'
    '|оплатил[а-я]*|купил[а-я]*)$wordEnd');
final _questionWord = phrasePattern('^(?:а\\s+)?(?:когда|какие|какой|сколько'
    '|что\\s+за|покажи|расскажи|перечисли|на\\s+что|что)$wordEnd');
final _leadingPreposition = phrasePattern('^(?:на|в|во|от|по|с)$wordEnd\\s*');

/// «Расходы», «траты», «деньги» — это не «про что», а про всё.
final _generic = phrasePattern('^(?:расход[а-я]*|трат[а-я]*|доход[а-я]*'
    '|поступлени[а-я]*|покупк[а-я]*|деньг[а-я]*|были|было)?\$');
