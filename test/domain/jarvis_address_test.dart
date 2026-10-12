import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Адрес в деле и дорога к нему; пометка «срочно».
void main() {
  final now = DateTime(2026, 10, 11, 10);
  const parser = JarvisCommandParser();

  ParsedTask task(String phrase) {
    final command = parser.parse(phrase, now);
    expect(command, isA<CreateTasks>(), reason: phrase);
    return (command! as CreateTasks).tasks.single;
  }

  test('адрес — отдельно от названия, в любом виде', () {
    final doctor = task('запиши завтра в 10 врач на Ленина 5');
    expect(doctor.title, 'Врач');
    expect(doctor.address, 'Ленина, 5');
    expect(doctor.minutes, 600);
    expect(task('запиши завтра стоматолог на улице Баумана дом 10 корпус 2')
        .address, 'улица Баумана, 10 корпус 2');
    expect(task('запиши в пятницу в 12 встреча по адресу Тверская 12').address,
        'Тверская 12');
    expect(task('запиши завтра в 9 собеседование проспект мира 101').address,
        'проспект Мира, 101');
  });

  test('время и «на неделе 3 раза» — не адрес', () {
    expect(task('запиши завтра на 10 часов врач').address, isNull);
    expect(addressIn('бегать на неделе 3 раза'), isNull);
  });

  test('«как доехать» — дорога; метро Москвы — по станциям', () {
    expect((parser.parse('как доехать до врача', now)! as RouteTo).to, 'врача');
    expect((parser.parse('проложи маршрут на Ленина 5', now)! as RouteTo).to,
        'ленина 5');
    expect((parser.parse('как доехать', now)! as RouteTo).to, '');
    expect(parser.parse('как доехать от Сокола до Театральной', now),
        isA<AskMetroRoute>());
  });

  test('адрес записи читается обратно из её текста', () {
    final item = MemoryItem(
      id: '1',
      type: MemoryType.note,
      title: 'Врач',
      body: 'Что: Врач\nКуда: Ленина, 5',
      memoryDate: DateTime(2026, 10, 12),
      createdAt: now,
      updatedAt: now,
    );
    expect(recordAddress(item), 'Ленина, 5');
    expect(JarvisReplies.created([item], now),
        contains('Скажите «как доехать» — проложу маршрут.'));
  });

  test('«срочно» — пометка важности, а не название', () {
    final urgent = task('запиши срочно завтра в 10 сдать отчёт');
    expect(urgent.urgent, isTrue);
    expect(urgent.title, 'Сдать отчёт');
  });
}
