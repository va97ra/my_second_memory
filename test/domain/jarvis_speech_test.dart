import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Как Джарвис говорит: время словами, рассказ о дне, обращение и разбор
/// ответа на уточняющий вопрос.
void main() {
  // Среда, 7 октября 2026, 14:00.
  final now = DateTime(2026, 10, 7, 14);

  MemoryItem item(String title,
      {int? minutes, DateTime? date, bool done = false}) {
    final day = date ?? DateTime(2026, 10, 8);
    return MemoryItem(
      id: title,
      type: MemoryType.note,
      title: title,
      memoryDate: day,
      createdAt: now,
      updatedAt: now,
      timeMinutes: minutes,
      status: done ? MemoryStatus.done : MemoryStatus.active,
    );
  }

  test('время словами', () {
    expect(spokenClock(14 * 60), '2 часа дня');
    expect(spokenClock(9 * 60), '9 часов утра');
    expect(spokenClock(19 * 60 + 30), '7:30 вечера');
    expect(spokenClock(12 * 60), 'полдень');
    expect(spokenClock(0), 'полночь');
    expect(spokenClock(21 * 60), '9 часов вечера');
    expect(spokenClock(13 * 60), '1 час дня');
    expect(spokenDay(DateTime(2026, 10, 8), now), 'завтра');
    expect(spokenDay(DateTime(2026, 10, 15), now), '15 октября');
    expect(spokenDay(DateTime(2027, 1, 3), now), '3 января 2027 года');
    expect(spokenDuration(90), '1 час 30 минут');
    expect(spokenDuration(60), 'час');
  });

  group('рассказ о дне', () {
    test('завтра — по порядку времени, без выполненного', () {
      final text = AgendaSpeech.day(
        [
          item('Позвонить маме', minutes: 18 * 60),
          item('Встреча с Иваном', minutes: 14 * 60),
          item('Купить хлеб'),
          item('Сделано уже', minutes: 10 * 60, done: true),
        ],
        day: DateTime(2026, 10, 8),
        now: now,
        label: 'завтра',
        address: 'сэр',
      );
      expect(
        text,
        'Сэр, на завтра 3 дела. Первое — в 2 часа дня: встреча с Иваном. '
        'Затем в 6 часов вечера — позвонить маме. Также без точного '
        'времени: купить хлеб.',
      );
    });

    test('сегодня — ближайшее первым, прошедшее отдельно', () {
      final today = DateTime(2026, 10, 7);
      final text = AgendaSpeech.day(
        [
          item('Планёрка', minutes: 10 * 60, date: today),
          item('Стоматолог', minutes: 16 * 60, date: today),
          item('Ужин', minutes: 19 * 60, date: today),
        ],
        day: today,
        now: now,
        label: 'сегодня',
      );
      expect(text, startsWith('На сегодня 3 дела. Ближайшее — в 4 часа дня'));
      expect(
          text,
          endsWith('Уже прошло, но не отмечено: в 10 часов утра — '
              'планёрка.'));
    });

    test('одно дело и пустой день', () {
      expect(
        AgendaSpeech.day([item('Врач', minutes: 600)],
            day: DateTime(2026, 10, 8), now: now, label: 'завтра'),
        'На завтра одно дело: в 10 часов утра — врач.',
      );
      expect(
        AgendaSpeech.day(const [],
            day: DateTime(2026, 10, 8),
            now: now,
            label: 'в пятницу',
            address: 'сэр'),
        'Сэр, в пятницу дел нет.',
      );
    });

    test('день рождения — отдельно от дел', () {
      expect(
        AgendaSpeech.day(
          [item('Врач', minutes: 600), item('День рождения мамы')],
          day: DateTime(2026, 10, 8),
          now: now,
          label: 'завтра',
        ),
        'На завтра одно дело: в 10 часов утра — врач. '
        'Ещё в этот день: день рождения мамы.',
      );
      expect(
        AgendaSpeech.day([item('День рождения мамы')],
            day: DateTime(2026, 10, 8), now: now, label: 'завтра'),
        'На завтра дел нет. Ещё в этот день: день рождения мамы.',
      );
    });

    test('несколько дней — по дням, а не одной кучей', () {
      expect(
        AgendaSpeech.range([
          item('Уборка', date: DateTime(2026, 10, 11)),
          item('Дача', minutes: 600, date: DateTime(2026, 10, 10)),
          item('Гости', minutes: 15 * 60, date: DateTime(2026, 10, 10)),
        ], now: now, label: 'На выходных'),
        'На выходных 3 дела. '
        '10 октября: в 10 часов утра — дача, в 3 часа дня — гости. '
        '11 октября: уборка.',
      );
    });
  });

  test('обращение дворецкого', () {
    const butler = ButlerPersona('сэр');
    expect(butler.apply('Записал: врач — завтра в 10 часов утра.'),
        'Записал, сэр: врач — завтра в 10 часов утра.');
    expect(butler.apply('Не нашёл такой записи. Скажите иначе.'),
        'Не нашёл такой записи, сэр. Скажите иначе.');
    expect(butler.apply('Сэр, на завтра дел нет.'), 'Сэр, на завтра дел нет.');
    expect(const ButlerPersona('').apply('Готово.'), 'Готово.');
    expect(butler.apply('Что вы хотите? Скажите: «запиши …».'),
        'Что вы хотите, сэр? Скажите: «запиши …».');
  });

  group('ответ на уточнение', () {
    final tomorrow = DateTime(2026, 10, 8);

    test('время и день — ответ', () {
      final answer = readClarification('в 10', now, forDate: tomorrow);
      expect(answer, isA<ClarificationAnswer>());
      expect((answer as ClarificationAnswer).answer.minutes, 600);
      expect(readClarification('весь день', now, forDate: tomorrow),
          isA<ClarificationAnswer>());
    });

    test('«не надо» — отмена, «нет, в 10» — ответ', () {
      expect(readClarification('не надо', now), isA<ClarificationCancel>());
      expect(readClarification('нет', now), isA<ClarificationCancel>());
      expect(readClarification('нет, в 10', now, forDate: tomorrow),
          isA<ClarificationAnswer>());
    });

    test('новая просьба с «завтра» внутри — не ответ', () {
      expect(readClarification('какие у меня дела на завтра', now),
          isA<ClarificationNewRequest>());
      expect(readClarification('открой календарь', now),
          isA<ClarificationNewRequest>());
    });
  });

  test('нейросети дни недели даны готовыми, а не на высчитывание', () {
    // 8 октября 2026 — четверг; нейросеть однажды назвала его «четверг,
    // 6 октября», высчитав день недели сама.
    final text = jarvisBrainInstructions(DateTime(2026, 10, 8, 18, 54));
    expect(text, contains('Сейчас: четверг, 8 октября 2026 года, 18:54.'));
    expect(text, contains('- 2026-10-05 — понедельник, 5 октября (прошёл)'));
    expect(text, contains('- 2026-10-08 — четверг, 8 октября (сегодня)'));
    expect(text, contains('- 2026-10-09 — пятница, 9 октября (завтра)'));
    expect(text, contains('- 2026-10-18 — воскресенье, 18 октября'));
    expect(
        text,
        contains('Эта неделя — с понедельника 5 октября по воскресенье '
            '11 октября'));
  });

  test('подробный рассказ нейросети читается целиком', () {
    // Решение 11 октября 2026: рассказ и новости — до семи-восьми
    // предложений. По-русски это больше 700 знаков, на которых ответ
    // раньше обрывался.
    final story = List.filled(
            8,
            'Сэр, это одно из восьми длинных предложений подробного '
            'рассказа о сегодняшних новостях и погоде в Казани.')
        .join(' ');
    expect(story.length, greaterThan(700));
    expect(cleanBrainReply(story), story);
  });

  test('ответ, оборванный лимитом токенов, кончается целым предложением', () {
    expect(
        cleanBrainReply(
            'Сэр, курс вырос на 2.5 рубля. Аналитики ждут, что к пятнице он',
            cut: true),
        'Сэр, курс вырос на 2.5 рубля.');
    expect(cleanBrainReply('Сэр, аналитики ждут, что к пятнице', cut: true),
        'Сэр, аналитики ждут, что к пятнице…');
  });
}
