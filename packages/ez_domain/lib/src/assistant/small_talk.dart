import 'task_phrase.dart';

/// Короткие реплики, которые не дела: «спасибо», «ладно», «привет».
///
/// Без этого «ладно на завтра» становилось делом «Ладно» с вопросом «во
/// сколько?». Дата во фразе реплику делом не делает.
class SmallTalk {
  const SmallTalk._();

  static const _thanks = {
    'спасибо',
    'благодарю',
    'спс',
    'пасиб',
    'пасибо',
    'спасиб',
  };
  static const _hello = {
    'привет',
    'приветик',
    'здравствуй',
    'здравствуйте',
    'здорово',
    'добрый',
    'доброе',
    'доброй',
  };
  static const _bye = {'пока', 'свидания', 'спокойной', 'увидимся'};
  static const _ok = {
    'ладно',
    'хорошо',
    'окей',
    'ок',
    'ok',
    'ага',
    'угу',
    'понял',
    'поняла',
    'понятно',
    'ясно',
    'отлично',
    'супер',
    'класс',
    'договорились',
    'принято',
    'норм',
    'нормально',
    'круто',
    'да',
    'нет',
    'неа',
    'конечно',
  };

  static final _howAreYou = RegExp(
    r'^(?:ну\s+)?как\s+(?:у\s+тебя\s+)?(?:дела|ты|жизнь|поживаешь'
    r'|настроение|сам)[?!.\s]*$',
    unicode: true,
  );

  static final _whoAreYou = RegExp(
    r'^(?:кто\s+ты|ты\s+кто|что\s+ты\s+умеешь|что\s+ты\s+можешь)[?!.\s]*$',
    unicode: true,
  );

  /// Слова-связки и обращения: сами по себе ничего не значат.
  static const _glue = {
    'джарвис',
    'джарвес',
    'джарвиз',
    'джервис',
    'сэр',
    'эй',
    'слушай',
    'ну',
    'так',
    'вот',
    'а',
    'и',
    'тебе',
    'большое',
    'огромное',
    'до',
    'утро',
    'день',
    'вечер',
    'ночи',
    'всё',
    'все',
    'же',
    'уж',
  };

  /// Ответ на короткую реплику или null, если это не она.
  static String? reply(String text, DateTime now) {
    if (_howAreYou.hasMatch(text.trim().toLowerCase())) {
      return 'Всё в порядке, благодарю. Чем могу помочь?';
    }
    if (_whoAreYou.hasMatch(text.trim().toLowerCase())) {
      return 'Я Джарвис, ваш помощник. Веду календарь, записи и финансы — '
          'говорите, что сделать.';
    }
    final title = const TaskPhraseParser().parse(text, now).task.title;
    final words = title
        .toLowerCase()
        .replaceAll('ё', 'е')
        .split(RegExp('[^а-яa-z]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    bool known(String word) =>
        _thanks.contains(word) ||
        _hello.contains(word) ||
        _bye.contains(word) ||
        _ok.contains(word) ||
        _glue.contains(word);
    if (!words.every(known)) return null;
    if (words.any(_thanks.contains)) return 'Всегда рад помочь.';
    if (words.any(_bye.contains)) return 'До связи.';
    if (words.any(_hello.contains)) return 'Здравствуйте. Чем могу помочь?';
    if (words.any(_ok.contains)) return 'Хорошо.';
    return 'Слушаю.';
  }
}
