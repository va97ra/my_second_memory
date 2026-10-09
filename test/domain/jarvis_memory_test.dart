import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Память Джарвиса: «запомни», записки и повторы, прошлое календаря и
/// журнала финансов, важное и подсказки сводок.
void main() {
  final now = DateTime(2026, 10, 9, 14, 7);
  const parser = JarvisCommandParser();

  T as<T>(String text) {
    final command = parser.parse(text, now);
    expect(command, isA<T>(), reason: '$text → $command');
    return command as T;
  }

  MemoryItem item(
    String title, {
    required DateTime day,
    int? minutes,
    MemoryStatus status = MemoryStatus.active,
    DateTime? remindAt,
  }) =>
      MemoryItem(
        id: title,
        type: MemoryType.task,
        title: title,
        memoryDate: day,
        timeMinutes: minutes,
        status: status,
        remindAt: remindAt,
        createdAt: now,
        updatedAt: now,
      );

  FinanceEntry money(String category, String amount, DateTime on,
          {FinanceEntryKind kind = FinanceEntryKind.expense}) =>
      FinanceEntry(
        id: '$category$on$amount',
        kind: kind,
        amount: amount,
        currencyCode: 'RUB',
        category: category,
        occurredOn: on,
        createdAt: now,
        updatedAt: now,
      );

  group('запомни', () {
    test('о себе — в память, дело — в записки или календарь', () {
      expect(as<RememberFact>('запомни, что я живу в Казани').fact,
          'Я живу в Казани');
      expect(as<CreateNote>('запомни купить хлеб').text, 'Купить хлеб');
      expect(parser.parse('запомни что завтра врач', now), isA<CreateTasks>());
      expect(as<ForgetFact>('забудь, что я живу в Казани').query,
          'я живу в Казани');
      expect(parser.parse('что ты обо мне знаешь', now), isA<ListFacts>());
    });

    test('ответ из запомненного по смыслу вопроса', () {
      const facts = ['Мама любит белые розы', 'Я живу в Казани'];
      expect(factFor('что любит мама?', facts), facts.first);
      expect(factFor('где я живу', facts), facts.last);
      expect(factFor('какая завтра погода', facts), isNull);
    });
  });

  group('записки и повторы', () {
    test('«напиши записку» — записка, а не сообщение', () {
      expect(as<CreateNote>('напиши записку купить молоко').text,
          'Купить молоко');
      expect(parser.parse('напиши записку, что ключи у соседа', now),
          isA<CreateNote>());
    });

    test('день рождения — каждый год, подписка — каждый месяц', () {
      final birthday = as<CreateTasks>('запиши день рождения Васи 15 марта');
      expect(birthday.tasks.single.repeat?.kind, PhraseRepeatKind.yearly);
      final subscription = as<CreateTasks>('запиши оплатить подписку 20 числа');
      expect(subscription.tasks.single.repeat?.kind, PhraseRepeatKind.monthly);
      expect(subscription.tasks.single.repeat?.monthDay, 20);
    });
  });

  group('прошлое календаря', () {
    test('день в прошлом, даже если разбор дат кладёт его в будущее', () {
      final day = as<AskHistory>('что я делал 15 апреля');
      expect(day.from, DateTime(2026, 4, 15));
      expect(day.to, DateTime(2026, 4, 15));
      expect(as<AskHistory>('чем я занимался вчера').from, DateTime(2026, 10, 8));
    });

    test('месяц и «не закончил»', () {
      final month = as<AskHistory>('что я не закончил в прошлом месяце');
      expect(month.unfinished, isTrue);
      expect(month.from, DateTime(2026, 9, 1));
      expect(month.to, DateTime(2026, 9, 30));
      final ago = as<AskHistory>('что было полгода назад');
      expect(ago.from, DateTime(2026, 4, 1));
    });

    test('рассказ — со сделанным; несделанное — отдельно', () {
      final items = [
        item('Врач', day: DateTime(2026, 4, 15), minutes: 600,
            status: MemoryStatus.done),
        item('Купить хлеб', day: DateTime(2026, 4, 15)),
      ];
      expect(
          AgendaSpeech.history(items, label: '15 апреля', now: now),
          '15 апреля: в 10 часов утра — врач, сделано; купить хлеб.');
      expect(
          AgendaSpeech.history(items,
              label: 'в прошлом месяце', now: now, unfinished: true),
          'В прошлом месяце не отмечено одно дело: купить хлеб.');
    });
  });

  group('деньги из журнала', () {
    final journal = [
      money('Зарплата', '45000', DateTime(2026, 9, 5),
          kind: FinanceEntryKind.income),
      money('Такси', '400', DateTime(2026, 9, 12)),
      money('Такси', '600', DateTime(2026, 9, 20)),
      money('Пятёрочка', '350', DateTime(2026, 10, 8)),
    ];

    test('когда пришла зарплата', () {
      final command = as<AskFinanceHistory>('когда пришла зарплата в прошлом месяце');
      expect(command.asksWhen, isTrue);
      expect(command.kind, FinanceEntryKind.income);
      expect(command.what, 'зарплата');
      expect(financeHistoryReply(command, journal, now),
          'Зарплата: 5 сентября — 45 000 рублей.');
    });

    test('расходы вчера и на такси за месяц', () {
      final yesterday = as<AskFinanceHistory>('какие расходы были вчера');
      expect(financeHistoryReply(yesterday, journal, now),
          'Вчера расходы — 350 рублей: пятёрочка — 350 рублей.');
      final taxi = as<AskFinanceHistory>('сколько я потратил на такси в сентябре');
      expect(financeHistoryReply(taxi, journal, now),
          'Такси в сентябре — 1 000 рублей, 2 раза.');
    });

    test('итог месяца без «на что» — прежний ответ в валюте журнала', () {
      expect(parser.parse('сколько я потратил в прошлом месяце', now),
          isA<AskFinance>());
    });
  });

  group('важное', () {
    test('«что самое важное завтра» — сначала главное', () {
      expect(as<AskAgenda>('что самое важное завтра').important, isTrue);
      final tomorrow = DateTime(2026, 10, 10);
      expect(
          AgendaSpeech.important([
            item('Купить хлеб', day: tomorrow),
            item('Оплатить интернет', day: tomorrow,
                remindAt: DateTime(2026, 10, 10, 9)),
          ], label: 'завтра', address: 'сэр'),
          'Сэр, самое важное на завтра: оплатить интернет. '
          'Остальное: купить хлеб.');
    });
  });

  group('сводка замечает сама', () {
    test('смена, два дела на одно время, вчерашнее и день рождения', () {
      final today = DateTime(2026, 10, 10);
      final notes = briefingNotes(
        day: today,
        at: now,
        morning: true,
        shifts: ['Завод'],
        dayItems: [
          item('Врач', day: today, minutes: 600),
          item('Встреча', day: today, minutes: 600),
        ],
        overdue: [item('Позвонить маме', day: DateTime(2026, 10, 9))],
        ahead: [item('День рождения Васи', day: DateTime(2026, 10, 13))],
        finance: [money('Пятёрочка', '2300', DateTime(2026, 10, 9))],
        currency: 'RUB',
      );
      expect(notes, [
        'Сегодня смена — Завод.',
        'В 10 часов утра сразу два дела: врач и встреча.',
        'Вчера не отмечено: позвонить маме.',
        'Через 3 дня — день рождения Васи.',
        'Вчера ушло 2 300 рублей.',
      ]);
    });

    test('первого числа — итог месяца и необычные траты', () {
      final notes = briefingNotes(
        day: DateTime(2026, 10, 1),
        at: DateTime(2026, 9, 30, 21),
        morning: true,
        finance: [
          for (final month in [6, 7, 8]) money('Такси', '1000', DateTime(2026, month, 10)),
          money('Такси', '3000', DateTime(2026, 9, 10)),
          money('Зарплата', '50000', DateTime(2026, 9, 5),
              kind: FinanceEntryKind.income),
        ],
        currency: 'RUB',
      );
      expect(notes, contains('В сентябре расходы — 3 000 рублей, доходы — 50 000 рублей.'));
      expect(notes, contains('Такси — вдвое больше обычного.'));
    });

    test('без дел, но со сменой — сводка всё равно приходит', () {
      final briefing = AgendaSpeech.briefing(const [],
          day: DateTime(2026, 10, 10),
          at: DateTime(2026, 10, 9, 20),
          address: 'сэр',
          notes: ['Завтра смена — Завод.'])!;
      expect(briefing.title, 'Сэр, на завтра дел нет');
      expect(briefing.body, 'Завтра смена — Завод.');
    });
  });
}
