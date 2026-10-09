import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Команды телефону, будильники Ежедневника, голос напоминаний, сводки и
/// реплики Джарвиса — правила без сети.
void main() {
  final now = DateTime(2026, 10, 9, 14, 7);
  const parser = JarvisCommandParser();

  T as<T>(String text) {
    final command = parser.parse(text, now);
    expect(command, isA<T>(), reason: text);
    return command as T;
  }

  group('телефон', () {
    test('фонарик', () {
      expect(as<PhoneTorch>('включи фонарик').on, isTrue);
      expect(as<PhoneTorch>('Джарвис, выключи фонарик').on, isFalse);
    });

    test('будильник в «Часах» — утро, если не сказано «вечера»', () {
      expect(as<PhoneAlarm>('разбуди меня в 6:30').minutes, 6 * 60 + 30);
      expect(as<PhoneAlarm>('поставь будильник на 7').minutes, 7 * 60);
      expect(as<PhoneAlarm>('будильник на 7 вечера').minutes, 19 * 60);
      expect(as<JarvisSay>('поставь будильник').text,
          PhoneReplies.alarmNeedsTime);
    });

    test('таймер', () {
      expect(as<PhoneTimer>('таймер на 10 минут').seconds, 600);
      expect(as<PhoneTimer>('засеки полчаса').seconds, 1800);
      expect(as<PhoneTimer>('таймер на 1 час 20 минут').seconds, 4800);
      expect(as<PhoneTimer>('поставь таймер на 45 секунд').seconds, 45);
      expect(spokenSeconds(4800), '1 час 20 минут');
    });

    test('звонок — только сейчас; с днём или временем — дело', () {
      expect(as<PhoneCall>('позвони маме').who, 'маме');
      expect(parser.parse('позвони маме завтра в 10', now),
          isNot(isA<PhoneCall>()));
    });

    test('сообщение: кому, чем и текст с исходными буквами', () {
      final message = as<PhoneMessage>('напиши Васе в ватсап, что Буду в 7');
      expect(message.who, 'васе');
      expect(message.app, PhoneMessenger.whatsapp);
      expect(message.text, 'Буду в 7');
      expect(as<PhoneMessage>('напиши маме в телегу привет').app,
          PhoneMessenger.telegram);
    });

    test('«напиши поздравление маме» — не сообщение', () {
      expect(parser.parse('напиши поздравление маме', now),
          isNot(isA<PhoneMessage>()));
    });

    test('страницы Ежедневника открываются раньше приложений телефона', () {
      expect(parser.parse('открой календарь', now), isA<OpenPlace>());
      expect(as<PhoneOpenApp>('открой камеру').name, 'камеру');
    });

    test('контакт в любом падеже', () {
      const names = ['Мамонтов Пётр', 'Мама', 'Вася Петров', 'Иван'];
      expect(bestContact('маме', names), 1);
      expect(bestContact('Васе', names), 2);
      expect(bestContact('Ивану', names), 3);
      expect(bestContact('Серёже', names), isNull);
    });
  });

  group('будильники Ежедневника', () {
    test('вопрос узнаётся, просьба поставить — нет', () {
      expect(parser.parse('какие у меня будильники', now), isA<AskAlarms>());
      expect(parser.parse('когда будильник?', now), isA<AskAlarms>());
      expect(parser.parse('поставь будильник на 7', now), isA<PhoneAlarm>());
    });

    test('ответ — ближайшие по порядку', () {
      final reply = alarmsReply([
        (at: DateTime(2026, 10, 12, 7, 30), what: 'Врач'),
        (at: DateTime(2026, 10, 10, 6), what: 'смена, Завод'),
      ], now);
      expect(reply, startsWith('Ближайшие будильники: завтра в 6 часов утра'));
      expect(reply.indexOf('Завод'), lessThan(reply.indexOf('врач')));
      expect(alarmsReply(const [], now), contains('нет'));
    });
  });

  group('голос напоминаний и сводки', () {
    MemoryItem item(String title, {int? minutes, DateTime? day}) => MemoryItem(
          id: title,
          type: MemoryType.task,
          title: title,
          body: '',
          memoryDate: day ?? DateTime(2026, 10, 9),
          timeMinutes: minutes,
          createdAt: now,
          updatedAt: now,
        );

    test('в момент дела, заранее и накануне', () {
      final meeting = item('Встреча с Иваном', minutes: 14 * 60);
      expect(
          AgendaSpeech.reminder(meeting,
              at: DateTime(2026, 10, 9, 14), address: 'сэр'),
          'Сэр, напоминаю: в 2 часа дня — встреча с Иваном.');
      expect(
          AgendaSpeech.reminder(meeting,
              at: DateTime(2026, 10, 9, 13, 30), address: 'сэр'),
          'Сэр, через 30 минут, в 2 часа дня — встреча с Иваном.');
      expect(
          AgendaSpeech.reminder(
              item('Врач', minutes: 10 * 60, day: DateTime(2026, 10, 10)),
              at: DateTime(2026, 10, 9, 20),
              address: 'сэр'),
          'Сэр, напоминаю: завтра в 10 часов утра — врач.');
    });

    test('утром — с приветствием, вечером — на завтра, без дел — молчит', () {
      final morning = AgendaSpeech.briefing(
        [item('Зарядка', minutes: 10 * 60), item('Купить хлеб')],
        day: DateTime(2026, 10, 9),
        at: DateTime(2026, 10, 9, 9),
        address: 'сэр',
      )!;
      expect(morning.title, 'Доброе утро, сэр! На сегодня 2 дела');
      expect(morning.body, startsWith('В 10 часов утра — зарядка.'));
      final evening = AgendaSpeech.briefing(
        [item('Врач', minutes: 10 * 60, day: DateTime(2026, 10, 10))],
        day: DateTime(2026, 10, 10),
        at: DateTime(2026, 10, 9, 20),
        address: 'сэр',
      )!;
      expect(evening.title, 'Сэр, на завтра одно дело');
      expect(
          AgendaSpeech.briefing(const [],
              day: DateTime(2026, 10, 10), at: DateTime(2026, 10, 9, 20)),
          isNull);
    });

    test('за будильником смены', () {
      expect(
          AgendaSpeech.shiftAlarm('Завод', afterNightShift: false, address: 'сэр'),
          'Доброе утро, сэр! Сегодня рабочая смена — Завод.');
    });
  });

  group('реплики Джарвиса', () {
    test('шутка, похвала и «ты тут» — его собственные фразы', () {
      expect(as<JarvisSay>('пошути').text, isIn(SmallTalk.jokes));
      expect(as<JarvisSay>('Джарвис, ты молодец').text, isIn(SmallTalk.praise));
      expect(as<JarvisSay>('ты тут?').text, isIn(SmallTalk.here));
    });

    test('приветствие по времени суток', () {
      expect(SmallTalk.reply('привет', DateTime(2026, 10, 9, 8)),
          isIn(SmallTalk.morning));
      expect(SmallTalk.reply('привет', DateTime(2026, 10, 9, 19)),
          isIn(SmallTalk.evening));
    });

    test('«пошути про это завтра» — уже не реплика', () {
      expect(SmallTalk.reply('пошути про это завтра', now), isNull);
    });
  });
}
