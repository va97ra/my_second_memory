import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_listener.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_wake_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Микрофон-подделка: помнит, слушает ли, и даёт «сказать» фразу.
class _FakeMic implements JarvisListener {
  void Function(String text)? phrase;
  void Function(String text)? partial;
  int starts = 0;

  @override
  bool continuous = false;

  @override
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  }) async {
    continuous = true;
    starts++;
    phrase = onPhrase;
    partial = onPartial;
    return true;
  }

  @override
  Future<void> stopContinuous() async => continuous = false;

  @override
  Future<String> listen({void Function(String text)? onPartial}) async => '';

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  void dispose() {}
}

void main() {
  late _FakeMic mic;
  late JarvisWakeController wake;
  var enabled = true;
  var busy = false;
  final calls = <String>[];

  setUp(() {
    mic = _FakeMic();
    enabled = true;
    busy = false;
    calls.clear();
    wake = JarvisWakeController(
      listener: mic,
      enabled: () => enabled,
      busy: () => busy,
      tick: const Duration(milliseconds: 10),
      nameOnlyPause: const Duration(milliseconds: 30),
      conversationWindow: const Duration(milliseconds: 150),
    );
    wake.addListener((call) {
      if (call != null) calls.add(call.command);
    }, fireImmediately: false);
    addTearDown(wake.dispose);
  });

  Future<void> settle([int ms = 40]) =>
      Future<void>.delayed(Duration(milliseconds: ms));

  test('открытое приложение ждёт имя, свёрнутое — нет', () async {
    wake.setForeground(true);
    await settle();
    expect(mic.continuous, isTrue);
    wake.setForeground(false);
    await settle();
    expect(mic.continuous, isFalse);
  });

  test('имя с просьбой — вызов с просьбой, обычная речь — ничего', () async {
    wake.setForeground(true);
    await settle();
    mic.phrase!('что у меня завтра');
    expect(calls, isEmpty);
    mic.phrase!('джералд открой календарь');
    expect(calls, ['открой календарь']);
    expect(mic.continuous, isFalse, reason: 'микрофон отдан листу');
  });

  test('только имя и пауза — отзывается, не дожидаясь конца фразы', () async {
    wake.setForeground(true);
    await settle();
    mic.partial!('джарвис');
    await settle(60);
    expect(calls, ['']);
  });

  test('пока Джарвис говорит или выключен в настройках — не слушает', () async {
    wake.setForeground(true);
    await settle();
    busy = true;
    await settle();
    expect(mic.continuous, isFalse);
    busy = false;
    enabled = false;
    await settle();
    expect(mic.continuous, isFalse);
    enabled = true;
    await settle(1100);
    expect(mic.continuous, isTrue);
  });

  test('после ответа можно продолжить без имени, потом — снова по имени',
      () async {
    wake.setForeground(true);
    await settle();
    wake.continueConversation();
    await settle();
    mic.phrase!('а послезавтра');
    expect(calls, ['а послезавтра']);
    // Секунда тишины после вызова, затем окно закрывается без новых слов.
    await settle(1100);
    await settle(200);
    mic.phrase!('что у меня завтра');
    expect(calls, ['а послезавтра'], reason: 'окно разговора закрылось');
  });
}
