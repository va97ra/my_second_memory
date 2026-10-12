import '../memory/memory_item.dart';
import 'jarvis_command.dart';
import 'phrase_scan.dart';
import 'russian_words.dart';

/// Адрес во фразе: «на улице Ленина, дом 5», «по адресу Тверская 12
/// корпус 2», «проспект Мира 101», «на Баумана 10».
///
/// Голос пишет строчными, поэтому улица узнаётся по слову «улица»,
/// «проспект» и подобным или по «на <название> <номер дома>» — а не по
/// заглавной букве. Время и даты разбор вынимает раньше: «в 10» номером
/// дома не станет.
String? takeAddress(PhraseScan scan) {
  for (final pattern in [_byAddress, _street, _bare]) {
    for (final match in pattern.allMatches(scan.work)) {
      final name = _group(match, 'name');
      if (name != null && _notStreet.hasMatch(name)) continue;
      scan.takeMatch(match);
      return _format(match);
    }
  }
  return null;
}

/// «Как доехать до врача», «проложи маршрут на Ленина 5», «маршрут до
/// дома». Метро Москвы узнаётся раньше: там станции и пересадки.
JarvisCommand? routeCommand(String work) {
  final match = _route.firstMatch(work);
  if (match == null) return null;
  return RouteTo((match.namedGroup('to') ?? '').trim());
}

/// Адрес в тексте, если он там есть.
String? addressIn(String text) => takeAddress(PhraseScan(text));

/// Адрес записи: Джарвис кладёт его в карточку строкой «Куда: …» (раньше —
/// «Адрес: …»).
String? recordAddress(MemoryItem item) {
  final line = _addressLine.firstMatch(item.plainBody);
  if (line != null) return line.group(1)!.trim();
  return addressIn('${item.title} ${item.plainBody}');
}


/// Группа совпадения; null — её нет в этом шаблоне или она не совпала.
String? _group(RegExpMatch match, String name) =>
    match.groupNames.contains(name) ? match.namedGroup(name) : null;

String _format(RegExpMatch match) {
  final whole = _group(match, 'whole');
  if (whole != null) return _titleWords(whole.trim());
  final kind = _group(match, 'kind');
  final name = _titleWords(_group(match, 'name')!.trim());
  final house = _group(match, 'house')?.replaceAll(RegExp(r'\s+'), ' ').trim();
  final street = kind == null ? name : '${_kindName(kind)} $name';
  return house == null || house.isEmpty ? street : '$street, $house';
}

String _kindName(String kind) => switch (kind) {
      final k when k.startsWith('ул') => 'улица',
      final k when k.startsWith('пр') => 'проспект',
      final k when k.startsWith('пер') => 'переулок',
      final k when k.startsWith('бул') => 'бульвар',
      final k when k.startsWith('шос') => 'шоссе',
      final k when k.startsWith('пл') => 'площадь',
      final k when k.startsWith('наб') => 'набережная',
      final k when k.startsWith('мкр') || k.startsWith('мик') => 'микрорайон',
      _ => kind,
    };

String _titleWords(String text) => text
    .split(' ')
    .map((word) => word.isEmpty || RegExp(r'^\d').hasMatch(word)
        ? word
        : capitalizeFirst(word))
    .join(' ');

const _house = '(?<house>\\d{1,4}[а-я]?(?:\\s*(?:/|к|корп|корпус|с|стр'
    '|строение)\\.?\\s*\\d{1,3})?)';

final _byAddress =
    phrasePattern('$wordStartпо\\s+адресу[\\s:]+(?<whole>[^,.;!?]+)');

final _street = phrasePattern('(?:$wordStart(?:на|в|во|по)\\s+)?'
    '(?<kind>улиц[аеуы]|ул\\.?|проспект[аеу]?|пр-т|переул[ко]к[аеу]?|пер\\.?'
    '|бульвар[аеу]?|шоссе|площад[иь]|набережн[а-я]{2}|проезд[аеу]?'
    '|микрорайон[аеу]?|мкр\\.?)\\s+(?<name>[а-я0-9-]+'
    '(?:\\s+(?!(?:дом|корпус|строение)$wordEnd)[а-я-]{3,})?)'
    '(?:[\\s,]+(?:дом\\s+|д\\.?\\s*)?$_house)?$wordEnd');

/// «На Ленина 5» — без слова «улица», но с номером дома сразу за названием.
final _bare = phrasePattern('$wordStartна\\s+(?<name>[а-я-]{3,}(?:\\s+[а-я-]{3,})?)'
    '[\\s,]+(?:дом\\s+|д\\.?\\s*)?$_house'
    '(?!\\s*(?::|час|утра|вечера|дня|ночи|минут|числа|раз|человек|руб|штук))'
    '$wordEnd');

/// После «на» с номером бывает и не улица: «на неделе 3 раза», «на работе
/// 2 часа», «на завтра 5 дел».
final _notStreet = phrasePattern('^(?:сегодня|завтра|послезавтра|неделе|неделю'
    '|работе|работу|час|часа|этаже|этаж|месяц|месяце|выходных|понедельник'
    '|вторник|среду|четверг|пятницу|субботу|воскресенье)');

final _route = phrasePattern('^(?:как\\s+(?:мне\\s+)?(?:доехать|добраться'
    '|проехать|попасть|дойти)|проложи(?:те)?\\s+(?:маршрут|дорогу)'
    '|построй\\s+маршрут|маршрут|поехали|отвези\\s+меня)'
    '(?:\\s+(?:до|к|ко|в|во|на))?(?:\\s+(?<to>.+))?\$');

final _addressLine = RegExp(r'^(?:Куда|Адрес):\s*(.+)$', multiLine: true);
