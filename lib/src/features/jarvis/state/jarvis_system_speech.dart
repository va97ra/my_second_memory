import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Распознавание речи телефона (Google, `SystemSpeech.kt`).
///
/// Просьбу оно слушает точнее своего: лучше слышит имена, улицы и адреса.
/// Имя «Джарвис» ждёт его офлайновая часть — только на телефоне, без сети:
/// она поднимается за доли секунды, а своя модель грузится секунды, и всё
/// это время имени не слышно. Решение владельца 11 октября 2026: «если в
/// телефоне уже есть — берём», «как зашёл — секунда максимум, и слышит».
class JarvisSystemSpeech {
  JarvisSystemSpeech() {
    if (supported) _channel.setMethodCallHandler(_onCall);
  }

  static const _channel = MethodChannel('ezhednevnik_v2/speech');

  void Function(String text)? _onPartial;
  bool? _available;
  bool? _wakeAvailable;

  void Function(String text)? _wakePhrase;
  void Function(String text)? _wakePartial;
  void Function()? _wakeFailed;

  /// Ждёт имя прямо сейчас.
  bool waking = false;

  /// Слушает прямо сейчас.
  bool active = false;

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'partial':
        _onPartial?.call('${call.arguments}');
      case 'wakePartial':
        if (waking) _wakePartial?.call('${call.arguments}');
      case 'wakePhrase':
        if (waking) _wakePhrase?.call('${call.arguments}');
      case 'wakeFailed':
        waking = false;
        _wakeAvailable = false;
        _wakeFailed?.call();
    }
    return null;
  }

  /// Есть ли офлайновое распознавание, чтобы ждать имя.
  Future<bool> wakeAvailable() async {
    if (!supported) return false;
    try {
      return _wakeAvailable ??=
          await _channel.invokeMethod<bool>('wakeAvailable') ?? false;
    } on MissingPluginException {
      return _wakeAvailable = false;
    }
  }

  /// Ждать имя: каждая фраза — в [onPhrase], текст по ходу — в [onPartial].
  /// Не вышло — [onFailed], и больше этим способом не ждать.
  Future<void> startWake({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
    void Function()? onFailed,
  }) async {
    _wakePhrase = onPhrase;
    _wakePartial = onPartial;
    _wakeFailed = onFailed;
    waking = true;
    await _channel.invokeMethod<bool>('startWake');
  }

  Future<void> stopWake() async {
    if (!waking) return;
    waking = false;
    await _channel.invokeMethod<void>('stopWake');
  }

  /// Есть ли в телефоне системное распознавание. Спрашивается один раз.
  Future<bool> available() async {
    if (!supported) return false;
    try {
      return _available ??=
          await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return _available = false;
    }
  }

  /// Одна фраза. Пустая строка — промолчали; null — системное
  /// распознавание сейчас недоступно (нет сети, занято), слушать своим.
  /// [patience] — сколько ждать начала речи; без него — сколько решит
  /// телефон (`SystemSpeech.kt`).
  Future<String?> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  }) async {
    _onPartial = onPartial;
    active = true;
    try {
      return await _channel.invokeMethod<String>(
        'listen',
        {'patience': patience?.inMilliseconds},
      );
    } on PlatformException {
      return null;
    } finally {
      active = false;
      _onPartial = null;
    }
  }

  Future<void> stop() => _channel.invokeMethod<void>('stop');

  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}
