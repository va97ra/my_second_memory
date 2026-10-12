import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Посмотри на календарь», «что здесь»: Джарвис смотрит на страницу.
void main() {
  // Среда, 7 октября 2099.
  final now = DateTime(2099, 10, 7, 14);
  JarvisCommand? parse(String phrase) =>
      const JarvisCommandParser().parse(phrase, now);

  JarvisPlace? looked(String phrase) {
    final command = parse(phrase);
    return command is LookAtPage ? command.place : null;
  }

  test('названная страница', () {
    expect(looked('посмотри на календарь'), JarvisPlace.calendar);
    expect(looked('глянь в финансы'), JarvisPlace.finance);
    expect(looked('что в финансах'), JarvisPlace.finance);
    expect(looked('загляни в записки'), JarvisPlace.notes);
    expect(looked('что в ленте'), JarvisPlace.feed);
    expect(looked('посмотри архив'), JarvisPlace.archive);
    expect(looked('прочитай графики смен'), JarvisPlace.shifts);
  });

  test('та страница, что на экране', () {
    for (final phrase in [
      'что здесь',
      'что тут написано',
      'что на экране',
      'прочитай',
      'что ты видишь',
      'расскажи что тут',
      'посмотри',
    ]) {
      final command = parse(phrase);
      expect(command, isA<LookAtPage>(), reason: phrase);
      expect((command as LookAtPage).place, isNull, reason: phrase);
    }
  });

  test('календарь на день — это день', () {
    final command = parse('посмотри календарь на пятницу') as LookAtPage;
    expect(command.place, JarvisPlace.day);
    expect(command.date, DateTime(2099, 10, 9));
  });

  test('чужие фразы «посмотри» не забирает', () {
    expect(parse('посмотри погоду'), isNot(isA<LookAtPage>()));
    expect(parse('что у меня в пятницу'), isA<AskAgenda>());
    expect(parse('что в памяти'), isA<CalculatorCommand>());
    expect(parse('открой календарь'), isA<OpenPlace>());
  });

  test('ответы', () {
    expect(JarvisReplies.lookArchive(0, null), 'Архив пуст.');
    expect(JarvisReplies.lookArchive(3, 'Врач'),
        'В архиве 3 записи. Последней убрана «Врач».');
    expect(JarvisReplies.lookAccounts, contains('не читаю'));
    expect(SmallTalk.agrees('Да, давай'), isTrue);
    expect(SmallTalk.agrees('да давай'), isTrue);
    expect(SmallTalk.agrees('Конечно!'), isTrue);
  });
}
