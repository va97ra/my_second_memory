import 'package:ezhednevnik_v2/src/app/local_storage_scope_provider.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_listener.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_talk_controller.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_voice.dart';
import 'package:ezhednevnik_v2/src/features/security/security.dart';
import 'package:ezhednevnik_v2/src/shared/state/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_items_test_support.dart';
import '../../support/widget_test_harness.dart';

/// Микрофон, который каждый раз слышит заданное.
class _FakeListener implements JarvisListener {
  _FakeListener(this.heard);

  final String heard;

  @override
  Future<String> listen({void Function(String text)? onPartial}) async {
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

  ProviderContainer start(String heard, _SilentVoice voice) {
    final container = ProviderContainer(overrides: [
      localStorageScopeFactoryProvider
          .overrideWithValue(TestLocalStorageScope.new),
      securityServiceProvider.overrideWithValue(UnlockedSecurityService()),
      notificationServiceProvider.overrideWithValue(FakeReminderScheduler()),
      jarvisListenerProvider.overrideWithValue(_FakeListener(heard)),
      jarvisVoiceProvider.overrideWithValue(voice),
    ]);
    addTearDown(container.dispose);
    // Разговор живёт, пока его кто-то слушает, — как лист на экране.
    container.listen(jarvisTalkProvider, (_, __) {});
    return container;
  }

  test('тишина — «не расслышал», а написанное текстом это убирает', () async {
    final c = start('', _SilentVoice());
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(c.read(jarvisTalkProvider).problem, startsWith('Не расслышал'));
    c.read(jarvisTalkProvider.notifier).forgetProblem();
    expect(c.read(jarvisTalkProvider).problem, isNull);
  });

  test('сказанное уходит Джарвису, ответ звучит вслух', () async {
    final voice = _SilentVoice();
    final c = start('открой календарь', voice);
    await c.read(jarvisTalkProvider.notifier).listen();
    expect(voice.said, ['Открываю календарь, сэр.']);
    expect(c.read(jarvisTalkProvider).listening, isFalse);
  });
}
