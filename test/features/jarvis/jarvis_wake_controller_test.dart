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
  Future<String> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  }) async =>
      '';

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

  test('повтор того же имени не отодвигает паузу', () async {
    // Распознавание телефона повторяет один и тот же кусок по нескольку раз
    // в секунду — каждый повтор заново заводил паузу, и она не наступала.
    wake.setForeground(true);
    await settle();
    // Выключенный микрофон кусков не присылает — как и настоящий.
    for (var i = 0; i < 8 && mic.continuous; i++) {
      mic.partial!('Джарвис');
      await settle(10);
    }
    expect(calls, ['']);
  });

  test('имя, слитое в записи со следующим словом, — всё равно зов', () async {
    // С телефона владельца, 12 октября 2026: по ходу — «Джарвис», в конце
    // фразы — «джарвисцию как». Имя прозвучало, Джарвис откликается.
    wake.setForeground(true);
    await settle();
    mic.partial!('Джарвис под');
    mic.partial!('джарвисцию');
    mic.phrase!('джарвисцию как');
    expect(calls, ['']);
    mic.phrase!('обезболивающее смотрите как');
    expect(calls, [''], reason: 'чужая речь после зова — не зов');
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

  test('без имени фраза — не вызов: продолжение слушает лист, а не здесь',
      () async {
    wake.setForeground(true);
    await settle();
    mic.phrase!('а послезавтра');
    expect(calls, isEmpty);
    mic.phrase!('джарвис что у меня завтра');
    expect(calls, ['что у меня завтра']);
  });
}
