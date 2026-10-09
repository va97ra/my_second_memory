import '../finance/finance_entry.dart';
import 'jarvis_command.dart';
import 'russian_words.dart';

/// Уведомление банка о деньгах → запись в финансах.
///
/// Банковское уведомление узнаётся по самому тексту, а не по приложению:
/// названия приложений банков меняются, а SMS от «900» приходят через
/// приложение сообщений. Нужны три признака сразу — операция («покупка»,
/// «зачисление»), сумма с валютой и след счёта: баланс, «доступно»,
/// «остаток» или номер карты. Реклама магазина «скидка 500 ₽ на покупку»
/// счёта не называет и записью не становится.
///
/// [source] — приложение, показавшее уведомление: о нём Джарвис скажет,
/// откуда запись.
AddFinanceEntry? bankNoticeEntry({
  required String title,
  required String text,
  required DateTime at,
  String? source,
}) {
  // Разбор идёт по тексту в нижнем регистре, а название магазина берётся из
  // исходного — с его буквами: «Пятёрочка», «SPAR». Длина у них одна.
  final original = '$title. $text'.replaceAll(_spaces, ' ');
  final whole = normalizePhrase(original);
  if (!_account.hasMatch(whole)) return null;
  // Сумма операции стоит до баланса: всё, что после «Баланс», — остаток.
  final balance = _balance.firstMatch(whole);
  final head = balance == null ? whole : whole.substring(0, balance.start);
  final money = _money.firstMatch(head);
  if (money == null) return null;
  final before = head.substring(0, money.start);
  final operation = _operation.allMatches(before).lastOrNull ??
      _operation.firstMatch(head);
  if (operation == null) return null;
  final word = operation.group(0)!;
  final income = _incomeWord.hasMatch(word) ||
      money.namedGroup('sign') == '+' ||
      (word.startsWith('перевод') && _incoming.hasMatch(head));
  final amount = _amount(money.namedGroup('n')!);
  if (amount == null) return null;
  final after = original.substring(money.end, head.length);
  return AddFinanceEntry(
    kind: income ? FinanceEntryKind.income : FinanceEntryKind.expense,
    amount: amount,
    date: DateTime(at.year, at.month, at.day),
    currency: _currency(money.namedGroup('c')!),
    category: income
        ? _incomeCategory(word, original.substring(0, head.length))
        : _merchant(after, word),
    source: source,
  );
}

/// «1 250,50» → «1250.50»; «45000» → «45000».
String? _amount(String raw) {
  final digits = raw.replaceAll(' ', '').replaceAll(',', '.');
  final value = double.tryParse(digits);
  if (value == null || value <= 0) return null;
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2);
}

String _currency(String marker) => switch (marker) {
      r'$' || 'usd' => 'USD',
      '€' || 'eur' => 'EUR',
      _ => 'RUB',
    };

/// Где купили: «SPAR», «Пятёрочка», «YANDEX.GO» — без номеров карт и
/// служебных слов. Не нашлось — сама операция: «Покупка».
String _merchant(String after, String operation) {
  var rest = after
      .replaceAll(_card, ' ')
      .replaceAll(_time, ' ')
      .replaceFirst(_lead, '')
      .replaceAll(RegExp(r'[\s.,;:]+$'), '')
      .trim();
  final stop = rest.indexOf(RegExp(r'[.;]\s'));
  if (stop > 0) rest = rest.substring(0, stop).trim();
  if (rest.isEmpty || !_anyCase('[а-яёa-z]').hasMatch(rest)) {
    return capitalizeFirst(operation);
  }
  final words = rest.split(' ');
  return capitalizeFirst(words.length > 4 ? words.take(4).join(' ') : rest);
}

/// «Зарплата», «Перевод от Иван И.», «Пополнение». [said] — уведомление до
/// баланса, с исходными буквами.
String _incomeCategory(String operation, String said) {
  final from = _from.firstMatch(said);
  if (operation.startsWith('перевод') && from != null) {
    return 'Перевод от ${_titleCase(from.namedGroup('who')!)}';
  }
  if (_salary.hasMatch(normalizePhrase(said)) ||
      operation.startsWith('зарплат')) {
    return 'Зарплата';
  }
  return capitalizeFirst(operation);
}

String _titleCase(String text) => text
    .split(' ')
    .map((word) => word.isEmpty ? word : capitalizeFirst(word))
    .join(' ');

final _spaces = RegExp(r'[   \s]+');

/// След счёта: без него текст с суммой — не банковское уведомление.
final _account = phrasePattern('$wordStart(?:баланс|доступно|остаток|карта'
    '|карты|картой|счет|счета|счёт|mir|visa|maestro|mastercard)'
    '|\\*\\d{4}|\\.\\.\\d{4}|$wordStart(?:mir|visa|сч[её]т)-?\\d{4}');

final _balance = phrasePattern('$wordStart(?:баланс|доступно|остаток)$wordEnd');

final _money = phrasePattern('(?<sign>[+-])?\\s?(?<n>\\d{1,3}(?: \\d{3})+'
    '(?:[.,]\\d{1,2})?|\\d+(?:[.,]\\d{1,2})?)\\s?(?<c>₽|р\\.?|руб\\.?|rub|rur'
    '|\\\$|usd|€|eur)(?![а-яa-z])');

final _operation = phrasePattern('$wordStart(?:покупка|оплата|списание'
    '|снятие|платеж|платёж|перевод|зачисление|поступление|пополнение'
    '|зарплата|возврат|кэшбэк|кешбэк|входящий\\s+перевод)$wordEnd');

final _incomeWord = phrasePattern('^(?:зачисление|поступление|пополнение'
    '|зарплата|возврат|кэшбэк|кешбэк|входящий\\s+перевод)');

/// «Перевод из Т-Банк», «перевод от Ивана» — деньги пришли.
final _incoming = phrasePattern('$wordStart(?:из|от)$wordEnd');

final _from = _anyCase('$wordStartот\\s+(?<who>[а-яa-z]+(?:\\s+[а-яa-z]\\.?)?)');
final _salary = phrasePattern('$wordStartзарплат');

final _card = _anyCase('(?:$wordStart(?:карта|карты|картой|card|mir|visa'
    '|сч[её]т)[\\s\\-*.]*\\d{4}|\\*\\d{4}|\\.\\.\\d{4})');
final _time = phrasePattern('\\d{1,2}:\\d{2}');
final _lead = _anyCase('^[\\s,.:;—-]*(?:(?:в|на|у)\\s+)?');

/// Для исходного текста с его заглавными буквами.
RegExp _anyCase(String pattern) =>
    RegExp(pattern, unicode: true, caseSensitive: false);
