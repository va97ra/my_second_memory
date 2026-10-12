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
/// самого. Продолжение разговора без имени слушает лист Джарвиса
/// (`JarvisTalkController`), а не этот контроллер: так лист видит, что
/// микрофон слушает, и показывает это.
///
/// Перенесено из MemoryVoice; паузы подобраны там на телефоне владельца.
class JarvisWakeController extends StateNotifier<JarvisWakeCall?> {
  JarvisWakeController({
    required JarvisListener? listener,
    required bool Function() enabled,
    required bool Function() busy,
    this.tick = const Duration(milliseconds: 300),
    this.nameOnlyPause = const Duration(milliseconds: 900),
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

  Timer? _ticker;
  Timer? _nameOnly;

  /// В этой фразе по ходу уже прозвучало имя первым словом.
  bool _named = false;
  String? _lastPartial;
  bool _foreground = false;
  bool _switching = false;
  DateTime? _quietUntil;

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

  /// Включить или выключить микрофон по обстановке.
  Future<void> check() async {
    final listener = _listener;
    if (listener == null || _switching) return;
    final quiet = _quietUntil?.isAfter(DateTime.now()) ?? false;
    final want = _foreground && _enabled() && !_busy() && !quiet;
    if (want == listener.continuous) return;
    _switching = true;
    try {
      if (want) {
        await listener.startContinuous(
          onPhrase: _heard,
          onPartial: _partial,
        );
      } else {
        _nameOnly?.cancel();
        _forgetPhrase();
        await listener.stopContinuous();
      }
    } finally {
      _switching = false;
    }
  }

  void _partial(String text) {
    final command = WakeWord.commandAfter(text);
    if (command != null) _named = true;
    // Распознавание телефона повторяет тот же кусок по нескольку раз в
    // секунду: пауза отсчитывается от перемены текста, а не от повтора.
    if (text == _lastPartial) return;
    _lastPartial = text;
    _nameOnly?.cancel();
    if (command == '') {
      _nameOnly = Timer(nameOnlyPause, () => _wake(''));
    }
  }

  void _heard(String text) {
    _nameOnly?.cancel();
    final named = _named;
    _forgetPhrase();
    final command = WakeWord.commandAfter(text);
    if (command != null) {
      _wake(command);
    } else if (named) {
      // По ходу фразы имя было первым словом, а в конце распознавание
      // слило его со следующим («джарвисцию»). Звали — Джарвис откликается
      // и слушает просьбу заново.
      _wake('');
    }
  }

  /// Фраза кончилась: следующая начинается с чистого листа.
  void _forgetPhrase() {
    _named = false;
    _lastPartial = null;
  }

  void _wake(String command) {
    _nameOnly?.cancel();
    _forgetPhrase();
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
