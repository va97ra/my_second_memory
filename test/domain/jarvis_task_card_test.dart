import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Подробная карточка дела: длительность из фразы, вопросы по очереди,
/// ответы и таблица в тексте записи (просьба владельца 11 октября 2026).
void main() {
  final now = DateTime(2026, 10, 11, 10);
  const parser = TaskPhraseParser();

  test('длительность из фразы', () {
    expect(parser.parse('завтра в 12 на полчаса врач', now).task.durationMinutes,
        30);
    expect(parser.parse('завтра врач минут на 20 в 12', now).task.durationMinutes,
        20);
    final range = parser.parse('завтра с 12 до 13 совещание', now).task;
    expect(range.minutes, 12 * 60);
    expect(range.durationMinutes, 60);
    expect(range.title, 'Совещание');
    expect(parser.parse('завтра на 2 часа дня врач', now).task.durationMinutes,
        isNull, reason: '«на 2 часа дня» — время, а не длительность');
  });

  test('вопросы карточки — по очереди, сказанное не спрашивается', () {
    var task = parser.parse('завтра в 12 врач', now).task;
    expect(task.needFor(detailed: false), isNull);
    expect(task.needFor(detailed: true), TaskNeed.duration);
    task = task.copyWith(durationMinutes: 30);
    expect(task.needFor(detailed: true), TaskNeed.place);
    final told =
        parser.parse('завтра в 12 на полчаса врач на Ленина 5 срочно', now).task;
    expect(told.needFor(detailed: true), TaskNeed.details,
        reason: 'длительность, место и срочность уже сказаны');
    expect(parser.parse('завтра врач', now).task.needFor(detailed: true),
        TaskNeed.time, reason: 'без времени — сначала время');
  });

  test('ответы: длительность, место, что сделать, срочность, пропуск', () {
    final task = parser.parse('завтра в 12 врач', now).task;
    ParsedTask answer(TaskNeed need, String said) =>
        (readDetail(task, need, said, now) as ClarificationDetail).task;
    expect(answer(TaskNeed.duration, 'полчаса').durationMinutes, 30);
    expect(answer(TaskNeed.duration, 'до часу дня').durationMinutes, 60);
    expect(answer(TaskNeed.place, 'на Ленина 5').address, 'Ленина, 5');
    expect(answer(TaskNeed.place, 'в поликлинику').address, 'В поликлинику');
    expect(answer(TaskNeed.details, 'взять паспорт и полис').details,
        'Взять паспорт и полис');
    expect(answer(TaskNeed.urgency, 'да').urgent, isTrue);
    final skipped = answer(TaskNeed.place, 'никуда');
    expect(skipped.address, isNull);
    expect(skipped.asked, contains(TaskNeed.place));
    expect(readDetail(task, TaskNeed.duration, 'не надо', now),
        isA<ClarificationCancel>());
    expect(readDetail(task, TaskNeed.details, 'какие дела на завтра', now),
        isA<ClarificationNewRequest>());
  });

  test('таблица в тексте записи', () {
    final task = parser
        .parse('завтра в 12 врач', now)
        .task
        .copyWith(
          durationMinutes: 30,
          address: 'улица Ленина, 5',
          details: 'Взять паспорт',
          urgent: true,
        );
    expect(
        taskCard(task),
        'Что: Врач\n'
        'Сколько: 30 минут\n'
        'Куда: улица Ленина, 5\n'
        'Что сделать: Взять паспорт\n'
        'Срочность: срочно');
    expect(taskCard(parser.parse('завтра в 12 врач', now).task), 'Врач',
        reason: 'без подробностей — просто название');
  });
}
