import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

/// Имя «Джарвис» в услышанном. Написания взяты из MemoryVoice: так модель
/// Vosk записывала голос владельца.
void main() {
  test('как распознавание пишет «Джарвис» — узнаём', () {
    for (final heard in [
      'джарвис',
      'джералд',
      'джентль',
      'джарс',
      'джарлис',
      'жарлис',
      'эйджарвес',
      'эй джарвис',
      'Джарвис!',
      'ну джарвис',
    ]) {
      expect(WakeWord.commandAfter(heard), '', reason: heard);
    }
  });

  test('просьба после имени — с исходным регистром', () {
    expect(WakeWord.commandAfter('джералд что у меня завтра'),
        'что у меня завтра');
    expect(WakeWord.commandAfter('Джарвис, открой Финансы'), 'открой Финансы');
  });

  test('обычная речь — не имя', () {
    for (final heard in [
      'завтра купить хлеб',
      'джентльмен пришёл',
      'жена просила хлеб',
      'позвони джарвису',
      'что у меня завтра',
    ]) {
      expect(WakeWord.commandAfter(heard), isNull, reason: heard);
    }
  });

  test('конец разговора', () {
    expect(WakeWord.endsConversation('спасибо'), isTrue);
    expect(WakeWord.endsConversation('Всё, хватит'), isTrue);
    expect(WakeWord.endsConversation('что у меня завтра'), isFalse);
  });

  test('имя в начале команды отрезается тем же правилом', () {
    final command = const JarvisCommandParser().parse(
        'джералд открой календарь', DateTime(2026, 10, 8));
    expect(command, isA<OpenPlace>());
  });
}
