import 'russian_words.dart';

/// Название дела из того, что осталось от фразы после дня и времени: без
/// «напомни», «надо», висящих предлогов и «часов» от «утром часов в 10».
String cleanTaskTitle(String text) {
  var title = compactPhrase(text);
  title = title.replaceAll(_please, ' ');
  String previous;
  do {
    previous = title;
    title = title.replaceFirst(RegExp(r'^[\s,.;:!?—–-]+'), '');
    title = title.replaceFirst(_leadingFillers, '');
    title = title.replaceFirst(RegExp(r'[\s,.;:!?—–-]+$'), '');
    title = title.replaceFirst(_danglingPreposition, '');
    title = title.replaceFirst(_danglingApproximation, '');
  } while (title != previous);
  title = title
      .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return capitalizeFirst(title);
}

const _fillers =
    'напомните|напомни|напомнить|запиши|запишите|запомни|учти|имей\\s+в\\s+виду'
    '|мне|нам|надо\\s+бы'
    '|надо|нужно|необходимо|не\\s+забыть|не\\s+забудь|что|чтобы|и|а|ну|так'
    '|вот|слушай|слушайте|короче|значит|кстати|в\\s+общем|пожалуй|давай|бы'
    '|где-то|где\\s+то|примерно|джарвис|сэр';

/// Без вводных слов в начале: «надо бы», «короче», «Джарвис».
String withoutLeadingFillers(String text) {
  var work = text.trim();
  String previous;
  do {
    previous = work;
    work = work.replaceFirst(_leadingFillers, '').trim();
  } while (work != previous);
  return work;
}

/// Без вводных слов с обоих краёв: «на такси, учти» → «на такси».
String withoutEdgeFillers(String text) {
  var work = text.trim();
  String previous;
  do {
    previous = work;
    work = work
        .replaceFirst(_leadingFillers, '')
        .replaceFirst(_trailingFillers, '')
        .replaceAll(RegExp(r'^[\s,.;:!?—–-]+|[\s,.;:!?—–-]+$'), '');
  } while (work != previous);
  return work;
}

final _please = RegExp('$wordStart(?:пожалуйста)$wordEnd',
    caseSensitive: false, unicode: true);

final _leadingFillers =
    RegExp('^(?:$_fillers)$wordEnd', caseSensitive: false, unicode: true);

final _trailingFillers =
    RegExp('$wordStart(?:$_fillers)\$', caseSensitive: false, unicode: true);

final _danglingPreposition = RegExp('$wordStart(?:в|во|на|к|до|и|а|с)\$',
    caseSensitive: false, unicode: true);

final _danglingApproximation = RegExp(
    '$wordStart(?:часов|часиков|часа|примерно|около|где-то|где\\s+то)\$',
    caseSensitive: false,
    unicode: true);
