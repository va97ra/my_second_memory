import 'spoken_moments.dart';
import 'task_phrase.dart';

/// Карточка дела — таблица строками в тексте записи:
///
/// ```text
/// Что: Врач
/// Сколько: 30 минут
/// Куда: улица Ленина, 5
/// Что сделать: взять паспорт и полис
/// Срочность: срочно
/// ```
///
/// Когда — это день и время самой записи, а конец — её «до»: на шкале дня
/// дело стоит отрезком. Простое дело без подробностей — просто название.
/// Решение владельца 11 октября 2026: «чтобы он карточку делал… таблицу:
/// какое дело, куда доехать, что сделать, срочность».
String taskCard(ParsedTask task) {
  final rows = <String>[
    if (task.durationMinutes case final minutes?)
      '$cardLength ${spokenDuration(minutes)}',
    if (task.address case final address?) '$cardPlace $address',
    if (task.details case final details?) '$cardDetails $details',
    if (task.urgent) '$cardUrgency срочно',
  ];
  if (rows.isEmpty) return task.title;
  return ['$cardWhat ${task.title}', ...rows].join('\n');
}

const cardWhat = 'Что:';
const cardLength = 'Сколько:';
const cardPlace = 'Куда:';
const cardDetails = 'Что сделать:';
const cardUrgency = 'Срочность:';
