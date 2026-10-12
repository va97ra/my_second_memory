import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_listener.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_talk_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_voice.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Микрофон, который слышит заданные фразы по очереди, а дальше — тишину.
/// Помнит, сколько каждый раз ждали начала речи.
class _FakeListener implements JarvisListener {
  _FakeListener(List<String> phrases) : _phrases = [...phrases];

  final List<String> _phrases;
  final patience = <Duration?>[];

  @override
  Future<String> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  }) async {
    this.patience.add(patience);
    final heard = _phrases.isEmpty ? '' : _phrases.removeAt(0);
    onPartial?.call(heard);
    return heard;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}

  @override
  bool get continuous => false;

  @override
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  }) async =>
      false;

  @override
  Future<void> stopContinuous() async {}

  @override
  void dispose() {}
}

/// Голос без звука: в тестах синтеза речи нет.
class _SilentVoice extends JarvisVoice {
  final said = <String>[];

  @override
  Future<void> speak(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

void main() {
  // Голос создаёт канал к синтезу речи — ему нужна обвязка Flutter.
  TestWidgetsFlutterBinding.ensureInitialized();
  useTestEnvironment();

  ProviderContainer start(_FakeListener mic, _SilentVoice voice,
      {Duration? brainTakes}) {
    final container = ProviderContainer(overrides: [
      if (brainTakes != null) ...[
        // Нейросеть думает [brainTakes] и отказывает: ключа нет.
        jarvisControllerProvider.overrideWith((ref) => JarvisController(
              ref.watch(jarvisExecutorProvider),
              brain: () async {
                await Future<void>.delayed(brainTakes);
                return null;
              },
            )),
        jarvisTalkProvider.overrideWith((ref) => JarvisTalkController(
              listener: mic,
              voice: voice,
              jarvis: ref.watch(jarvisControllerProvider.notifier),
              conversation: () => ref.read(jarvisControllerProvider),
              thinkingPause: const Duration(milliseconds: 20),
            )),
      ],
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      jarvisListenerProvider.overrideWithValue(mic),
      jarvisVoiceProvider.overrideWithValue(voice),
    ]);
    addTearDown(container.dispose);
    // Разговор живёт, пока его кто-то слушает, — как лист на экране.
    container.listen(jarvisTalkProvider, (_, __) {});
    return container;
  }

  test('тишина — «не расслышал», а написанное текстом это убирает', () async {
    final c = start(_FakeListener(const []), _SilentVoice());
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(c.read(jarvisTalkProvider).problem, startsWith('Не расслышал'));
    c.read(jarvisTalkProvider.notifier).forgetProblem();
    expect(c.read(jarvisTalkProvider).problem, isNull);
  });

  test('сказанное уходит Джарвису, ответ звучит вслух', () async {
    final voice = _SilentVoice();
    final c = start(_FakeListener(const ['открой календарь']), voice);
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(voice.said, ['Открываю календарь, сэр.']);
    expect(c.read(jarvisTalkProvider).listening, isFalse);
  });

  test('после ответа слушает продолжение без имени; промолчали — не ошибка',
      () async {
    final voice = _SilentVoice();
    final mic = _FakeListener(const ['открой календарь', 'открой финансы']);
    final c = start(mic, voice);
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(voice.said, ['Открываю календарь, сэр.', 'Открываю финансы, сэр.']);
    // Первую просьбу слушают как обычно, продолжения — терпеливо.
    expect(mic.patience,
        [null, const Duration(seconds: 12), const Duration(seconds: 12)]);
    final talk = c.read(jarvisTalkProvider);
    expect(talk.listening, isFalse, reason: 'промолчали — строка исчезла');
    expect(talk.problem, isNull, reason: 'молчание после ответа — не ошибка');
  });

  test('думает дольше паузы — «Секунду, сэр», и ответ её не обрывает',
      () async {
    final voice = _SilentVoice();
    final c = start(_FakeListener(const ['почему небо голубое']), voice,
        brainTakes: const Duration(milliseconds: 80));
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(voice.said, hasLength(2));
    expect(voice.said.first, 'Секунду, сэр.');
  });

  test('«спасибо» заканчивает разговор', () async {
    final mic = _FakeListener(const ['открой календарь', 'спасибо']);
    final c = start(mic, _SilentVoice());
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(mic.patience, hasLength(2));
    expect(c.read(jarvisTalkProvider).listening, isFalse);
  });
}
