import 'task_phrase.dart';

/// Карточка дела — таблица строками в тексте записи:
///
/// ```text
/// Куда: улица Ленина, 5
/// Что сделать: взять паспорт и полис
/// Срочность: срочно
/// ```
///
/// Что за дело — название самой записи, когда — её день и время, сколько —
/// её «до»: на шкале дня дело стоит отрезком нужной длины. Повторять это в
/// тексте незачем (владелец, 12 октября 2026: «сколько час — это уже по
/// табличке понятно»). Дело без подробностей — просто название.
/// Решение владельца 11 октября 2026: «чтобы он карточку делал… таблицу:
/// какое дело, куда доехать, что сделать, срочность».
String taskCard(ParsedTask task) {
  final rows = <String>[
    if (task.address case final address?) '$cardPlace $address',
    if (task.details case final details?) '$cardDetails $details',
    if (task.urgent) '$cardUrgency срочно',
  ];
  return rows.isEmpty ? task.title : rows.join('\n');
}

const cardPlace = 'Куда:';
const cardDetails = 'Что сделать:';
const cardUrgency = 'Срочность:';
