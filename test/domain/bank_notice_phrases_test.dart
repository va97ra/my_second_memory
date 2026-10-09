import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Уведомления банков в том виде, в каком их показывают приложения банков
/// и SMS от «900». Номера карт и суммы вымышленные.
void main() {
  final at = DateTime(2026, 10, 9, 15, 42);

  AddFinanceEntry? parse(String text, {String title = ''}) =>
      bankNoticeEntry(title: title, text: text, at: at, source: 'Банк');

  void expectEntry(
    AddFinanceEntry? entry, {
    required FinanceEntryKind kind,
    required String amount,
    required String category,
    String currency = 'RUB',
  }) {
    expect(entry, isNotNull);
    expect(entry!.kind, kind);
    expect(entry.amount, amount);
    expect(entry.currency, currency);
    expect(entry.category, category);
    expect(entry.date, DateTime(2026, 10, 9));
    expect(entry.source, 'Банк');
  }

  group('расход', () {
    test('SMS от 900: покупка с балансом после', () {
      expectEntry(parse('MIR-1234 15:42 Покупка 350р SPAR Баланс: 4590.20р'),
          kind: FinanceEntryKind.expense, amount: '350', category: 'SPAR');
    });

    test('пуш Сбера с разделителями тысяч и копейками', () {
      expectEntry(parse('Покупка 1 250,50 ₽, Пятёрочка. Баланс 12 345,67 ₽'),
          kind: FinanceEntryKind.expense,
          amount: '1250.50',
          category: 'Пятёрочка');
    });

    test('пуш Т-Банка: «на» перед суммой, «Доступно» вместо баланса', () {
      expectEntry(
          parse('Покупка на 350 ₽, Магнит. Доступно 12 000 ₽',
              title: 'Карта *1234'),
          kind: FinanceEntryKind.expense,
          amount: '350',
          category: 'Магнит');
    });

    test('ВТБ: оплата с номером карты перед магазином', () {
      expectEntry(parse('Оплата 500.00р Карта*1234 YANDEX.GO Баланс 1000.00р'),
          kind: FinanceEntryKind.expense, amount: '500', category: 'YANDEX.GO');
    });

    test('Альфа: RUR и «в» перед магазином', () {
      expectEntry(
          parse('Покупка 1 200,00 RUR в MAGNIT. Карта ..1234. '
              'Остаток 5 000,00 RUR'),
          kind: FinanceEntryKind.expense,
          amount: '1200',
          category: 'MAGNIT');
    });

    test('перевод с карты — деньги ушли', () {
      expectEntry(parse('MIR-1234 10:15 Перевод 1000р Баланс: 3000р'),
          kind: FinanceEntryKind.expense, amount: '1000', category: 'Перевод');
    });
  });

  group('доход', () {
    test('входящий перевод со знаком плюс и отправителем', () {
      expectEntry(
          parse('Перевод из Т-Банк +5000р от Иван И. MIR-1234 Баланс: 8000р'),
          kind: FinanceEntryKind.income,
          amount: '5000',
          category: 'Перевод от Иван И.');
    });

    test('зачисление зарплаты', () {
      expectEntry(
          parse('СЧЁТ1234 09:00 Зачисление зарплаты 45 000р Баланс: 50 000р'),
          kind: FinanceEntryKind.income,
          amount: '45000',
          category: 'Зарплата');
    });

    test('пополнение в Т-Банке', () {
      expectEntry(parse('Пополнение на 5 000 ₽, счет RUB. Доступно 17 000 ₽'),
          kind: FinanceEntryKind.income,
          amount: '5000',
          category: 'Пополнение');
    });
  });

  group('не банковское уведомление', () {
    test('реклама магазина со скидкой — без следа счёта', () {
      expect(parse('Скидка 500 ₽ на первую покупку в приложении!'), isNull);
    });

    test('сообщение в чате с суммой', () {
      expect(parse('Скинь мне 500р за пиццу', title: 'Вася'), isNull);
    });

    test('баланс без операции', () {
      expect(parse('Баланс карты *1234: 4 590 ₽'), isNull);
    });
  });
}
