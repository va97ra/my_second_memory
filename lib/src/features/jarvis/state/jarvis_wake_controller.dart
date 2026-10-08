import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/state/bool_setting_controller.dart';
import 'jarvis_controller.dart';
import 'jarvis_listener.dart';
import 'jarvis_voice.dart';

/// «Отзываться на «Джарвис»» — включено, пока владелец не выключит.
final jarvisWakeEnabledProvider = boolSettingProvider(
  storageKey: 'jarvis_wake_word_v1',
  initial: true,
);

/// Открыт ли лист Джарвиса. Открытый лист сам отвечает на вызовы, закрытый
/// открывают по вызову.
final jarvisSheetOpenProvider = StateProvider<bool>((ref) => false);

/// Джарвиса позвали. [command] — что сказали после имени; пусто — только
/// имя. Каждый вызов — новый объект: два одинаковых вызова подряд оба
/// доходят.
class JarvisWakeCall {
  JarvisWakeCall(this.command);

  final String command;
}

final jarvisWakeProvider =
    StateNotifierProvider<JarvisWakeController, JarvisWakeCall?>((ref) {
  final voice = ref.watch(jarvisVoiceProvider);
  return JarvisWakeController(
    listener: ref.watch(jarvisListenerProvider),
    enabled: () => ref.read(jarvisWakeEnabledProvider),
    busy: () => voice.speaking || ref.read(jarvisControllerProvider).busy,
  );
});

/// Ждёт имя «Джарвис», пока приложение открыто и Джарвис свободен.
///
/// Каждые 0,3 с сверяется с обстановкой: можно слушать — микрофон ждёт имя,
/// Джарвис говорит или думает — микрофон выключен, чтобы не услышать его
/// самого. После ответа ещё [conversationWindow] можно говорить без имени —
/// разговор не обрывается; «спасибо» или «хватит» его заканчивают.
///
/// Перенесено из MemoryVoice; паузы подобраны там на телефоне владельца.
class JarvisWakeController extends StateNotifier<JarvisWakeCall?> {
  JarvisWakeController({
    required JarvisListener? listener,
    required bool Function() enabled,
    required bool Function() busy,
    this.tick = const Duration(milliseconds: 300),
    this.nameOnlyPause = const Duration(milliseconds: 900),
    this.conversationWindow = const Duration(seconds: 12),
  })  : _listener = listener,
        _enabled = enabled,
        _busy = busy,
        super(null);

  final JarvisListener? _listener;
  final bool Function() _enabled;
  final bool Function() _busy;
  final Duration tick;

  /// Сказали только имя и замолчали — не ждём конца фразы, отзываемся.
  final Duration nameOnlyPause;

  /// После ответа Джарвиса столько ждём продолжения без имени.
  final Duration conversationWindow;

  Timer? _ticker;
  Timer? _nameOnly;
  bool _foreground = false;
  bool _switching = false;
  DateTime? _quietUntil;
  bool _conversation = false;
  DateTime? _windowUntil;

  /// Приложение на экране или свёрнуто. Свёрнутое имя не слушает.
  void setForeground(bool foreground) {
    _foreground = foreground;
    // Слушать нечем (веб) — и проверять нечего.
    if (foreground && _listener != null) {
      _ticker ??= Timer.periodic(tick, (_) => unawaited(check()));
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
    unawaited(check());
  }

  /// Джарвис ответил — ждать продолжения без имени. Окно отсчитывается,
  /// когда он договорит и микрофон снова слушает.
  void continueConversation() {
    _conversation = true;
    _windowUntil = null;
  }

  void endConversation() {
    _conversation = false;
    _windowUntil = null;
  }

  bool get _inConversation {
    final until = _windowUntil;
    return _conversation && (until == null || DateTime.now().isBefore(until));
  }

  /// Включить или выключить микрофон по обстановке.
  Future<void> check() async {
    final listener = _listener;
    if (listener == null || _switching) return;
    final until = _windowUntil;
    if (_conversation && until != null && !DateTime.now().isBefore(until)) {
      endConversation();
    }
    final quiet = _quietUntil?.isAfter(DateTime.now()) ?? false;
    final want = _foreground && _enabled() && !_busy() && !quiet;
    if (want == listener.continuous) {
      if (want && _conversation && _windowUntil == null) {
        _windowUntil = DateTime.now().add(conversationWindow);
      }
      return;
    }
    _switching = true;
    try {
      if (want) {
        final started = await listener.startContinuous(
          onPhrase: _heard,
          onPartial: _partial,
        );
        if (started && _conversation && _windowUntil == null) {
          _windowUntil = DateTime.now().add(conversationWindow);
        }
      } else {
        _nameOnly?.cancel();
        await listener.stopContinuous();
      }
    } finally {
      _switching = false;
    }
  }

  void _partial(String text) {
    _nameOnly?.cancel();
    if (WakeWord.commandAfter(text) == '') {
      _nameOnly = Timer(nameOnlyPause, () => _wake(''));
    }
    // Начал говорить к концу окна — дослушать фразу.
    final until = _windowUntil;
    if (_inConversation && text.isNotEmpty && until != null) {
      final atLeast = DateTime.now().add(const Duration(seconds: 4));
      if (until.isBefore(atLeast)) _windowUntil = atLeast;
    }
  }

  void _heard(String text) {
    _nameOnly?.cancel();
    final command = WakeWord.commandAfter(text);
    if (command != null) {
      _wake(command);
    } else if (_inConversation) {
      // В разговоре имя не нужно.
      if (WakeWord.endsConversation(text)) endConversation();
      _wake(text);
    }
  }

  void _wake(String command) {
    _nameOnly?.cancel();
    _windowUntil = null;
    // Пока Джарвис начинает отвечать, «занят» становится не сразу — секунду
    // не слушаем.
    _quietUntil = DateTime.now().add(const Duration(seconds: 1));
    unawaited(_listener?.stopContinuous());
    if (mounted) state = JarvisWakeCall(command);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _nameOnly?.cancel();
    unawaited(_listener?.stopContinuous());
    super.dispose();
  }
}
