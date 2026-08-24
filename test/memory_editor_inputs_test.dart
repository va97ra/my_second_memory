import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Сумма платежа', () {
    test('набирается с пробелами и запятой', () {
      expect(parseAmountMinor('1 200,50'), 120050);
      expect(parseAmountMinor(' 99 '), 9900);
      expect(parseAmountMinor('0'), 0);
    });

    test('не бывает отрицательной и не читается из мусора', () {
      expect(parseAmountMinor('-10'), isNull);
      expect(parseAmountMinor(''), isNull);
      expect(parseAmountMinor('сто рублей'), isNull);
    });

    test('возвращается в поле без лишних копеек', () {
      expect(formatAmount(120050), '1200.50');
      expect(formatAmount(9900), '99');
      expect(formatAmount(null), '');
    });
  });

  group('Название записи по её тексту', () {
    test('пустая запись называется своим видом', () {
      expect(memoryTitleFromRecord('   ', MemoryType.task, 'ru'),
          MemoryType.task.label('ru'));
      expect(memoryTitleFromRecord('', MemoryType.note, 'en'),
          MemoryType.note.label('en'));
    });

    test('перевод строки не попадает в название', () {
      expect(
        memoryTitleFromRecord('Купить хлеб\n  и молоко', MemoryType.task, 'ru'),
        'Купить хлеб и молоко',
      );
    });

    test('длинный текст обрезается многоточием', () {
      final title = memoryTitleFromRecord('а' * 60, MemoryType.note, 'ru');

      expect(title.length, 51);
      expect(title.endsWith('...'), isTrue);
    });
  });

  group('Срок подписки', () {
    final start = DateTime(2026, 1, 10);
    final template = MemoryItem(
      id: 'record',
      type: MemoryType.payment,
      title: 'Подписка',
      memoryDate: start,
      createdAt: start,
      updatedAt: start,
      paymentCategory: 'subscription',
    );
    RecurrenceSeries series({DateTime? end}) => RecurrenceSeries(
          id: 'series',
          frequency: RecurrenceFrequency.monthly,
          template: template,
          startDate: start,
          originItemId: template.id,
          createdAt: start,
          updatedAt: start,
          subscriptionEndDate: end,
        );

    test('считается от вхождения, а не от начала серии', () {
      final subscription = series(end: DateTime(2026, 12, 10));

      expect(
          subscription.subscriptionTermMonthsFrom(DateTime(2026, 1, 10)), 12);
      expect(
          subscription.subscriptionTermMonthsFrom(DateTime(2026, 10, 10)), 3);
    });

    test('вхождение раньше начала серии не удлиняет срок', () {
      final subscription = series(end: DateTime(2026, 12, 10));

      expect(subscription.subscriptionTermMonthsFrom(DateTime(2025, 6, 1)), 12);
    });

    test('истёкший срок остаётся хотя бы месяцем, а без срока его нет', () {
      expect(
        series(end: DateTime(2026, 2, 10))
            .subscriptionTermMonthsFrom(DateTime(2026, 8, 10)),
        1,
      );
      expect(
          series().subscriptionTermMonthsFrom(DateTime(2026, 8, 10)), isNull);
    });
  });
}
