import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../platform/windows/windows_audio_input.dart';
import 'jarvis_listener.dart';
import 'jarvis_speech_worker.dart';
import 'jarvis_system_speech.dart';

JarvisListener? createJarvisListener() => OfflineJarvisListener();

/// Распознавание на устройстве: sherpa-onnx и потоковая модель Vosk small
/// ru (Zipformer2, Apache 2.0). Модель лежит в `assets/speech/vosk-ru` и
/// один раз копируется в память приложения — движок читает файлы, а не
/// ресурсы сборки. Расшифровка идёт в своём потоке ([SpeechWorker]).
///
/// Микрофон один на две работы: ждать имя и слушать просьбу. Включают и
/// выключают его строго по очереди — иначе две работы одновременно
/// запускали запись, и одна из них молча оставалась без звука.
///
/// Где в телефоне есть распознавание Google, имя ждёт его офлайновая часть,
/// а просьбу слушает оно же ([JarvisSystemSpeech]); своё — запасное.
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца; числа
/// пауз подобраны там же.
class OfflineJarvisListener implements JarvisListener {
  OfflineJarvisListener({
    AudioRecorder? recorder,
    WindowsAudioInput audioInput = const WindowsAudioInput(),
    JarvisSystemSpeech? system,
  })  : _recorder = recorder ?? AudioRecorder(),
        _audioInput = audioInput,
        _system = system ?? JarvisSystemSpeech();

  static const _assetDir = 'assets/speech/vosk-ru';
  static const _modelVersion = 'vosk-ru-0.54';
  static const _files = [
    'encoder.int8.onnx',
    'decoder.int8.onnx',
    'joiner.int8.onnx',
    'tokens.txt',
  ];

  /// Модель распакована целиком: файл появляется последним.
  static const _unpacked = '.unpacked';

  /// Дольше одной фразы не слушаем.
  static const _maxDuration = Duration(seconds: 30);

  final AudioRecorder _recorder;
  final WindowsAudioInput _audioInput;

  /// Просьбу слушает распознавание телефона, если оно есть и доступно.
  final JarvisSystemSpeech _system;

  Future<SpeechWorker>? _worker;
  StreamSubscription<SpeechHeard>? _heard;
  _Session? _session;
  var _sessions = 0;
  Future<void> _mic = Future.value();

  @override
  bool get continuous => (_session?.continuous ?? false) || _system.waking;

  @override
  Future<String> listen({
    void Function(String text)? onPartial,
    Duration? patience,
  }) async {
    if (!await _recorder.hasPermission()) {
      throw const JarvisListenerFailure(
          'Разрешите приложению микрофон в настройках телефона.');
    }
    if (await _system.available()) {
      // Микрофон один: своё ожидание имени уступает его телефону. Занят он
      // с этой минуты — иначе ожидание имени успело бы включиться снова,
      // пока своё выключается.
      _system.active = true;
      await _system.stopWake();
      await _exclusive(() => _close(_session));
      final heard =
          await _system.listen(onPartial: onPartial, patience: patience);
      if (heard != null) return heard;
      // Системное сейчас недоступно (нет сети, занято) — слушаем своим.
    }
    final SpeechWorker worker;
    try {
      worker = await _ready();
    } on Object {
      throw const JarvisListenerFailure(
          'Распознавание речи не запустилось на этом телефоне.');
    }
    final session = await _exclusive(() async {
      // Микрофон один: пока слушаем просьбу, имя не ждём.
      await _close(_session);
      return _open(worker,
          continuous: false, patience: patience, onPartial: onPartial);
    });
    if (session == null) {
      throw const JarvisListenerFailure(
          'Микрофон не включился — возможно, его занимает другое приложение.');
    }
    return session.result.future;
  }

  @override
  Future<void> stop() async {
    if (_system.active) return _system.stop();
    return _stopOwn();
  }

  Future<void> _stopOwn() => _exclusive(() async {
        final session = _session;
        if (session != null && !session.continuous) await _finish(session);
      });

  @override
  Future<void> cancel() async {
    if (_system.active) return _system.cancel();
    return _cancelOwn();
  }

  Future<void> _cancelOwn() => _exclusive(() async {
        final session = _session;
        if (session != null && !session.continuous) await _close(session);
      });

  @override
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  }) async {
    // Слушают просьбу — своим или телефоном: имя подождёт.
    if (_session != null || _system.waking) return continuous;
    if (_system.active) return false;
    if (!await _recorder.hasPermission(request: false)) return false;
    // Имя ждёт офлайновое распознавание телефона: оно готово через доли
    // секунды. Своя модель грузится, только если его нет или оно отказало.
    if (await _system.wakeAvailable()) {
      if (_system.active) return false;
      await _system.startWake(onPhrase: onPhrase, onPartial: onPartial);
      return true;
    }
    final SpeechWorker worker;
    try {
      worker = await _ready();
    } on Object {
      return false;
    }
    return _exclusive(() async {
      // Пока ждали очереди, могли начать слушать просьбу — она главнее.
      if (_session != null) return continuous;
      if (_system.active) return false;
      final session = await _open(worker,
          continuous: true, onPartial: onPartial, onPhrase: onPhrase);
      return session != null;
    });
  }

  @override
  Future<void> stopContinuous() async {
    await _system.stopWake();
    await _stopOwnContinuous();
  }

  Future<void> _stopOwnContinuous() => _exclusive(() async {
        final session = _session;
        if (session != null && session.continuous) await _close(session);
      });

  @override
  void dispose() {
    unawaited(_exclusive(() async {
      await _close(_session);
      await _heard?.cancel();
      final worker = _worker;
      _worker = null;
      if (worker != null) (await worker).dispose();
    }));
  }

  /// Включения и выключения микрофона — по одному, в порядке вызова.
  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _mic.then((_) => action());
    _mic = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Поток распознавания поднимается один раз; не поднялся — каждая
  /// следующая попытка получает тот же отказ, а не грузит модель заново.
  Future<SpeechWorker> _ready() => _worker ??= () async {
        final worker = await SpeechWorker.spawn(await _unpackModel());
        _heard = worker.heard.listen(_onHeard);
        return worker;
      }();

  Future<_Session?> _open(
    SpeechWorker worker, {
    required bool continuous,
    Duration? patience,
    void Function(String text)? onPartial,
    void Function(String text)? onPhrase,
  }) async {
    final id = ++_sessions;
    // Терпеливое слушание — как ожидание имени: молчание распознаватель не
    // считает концом фразы, итог — первая сказанная фраза.
    worker.open(id, continuous: continuous || patience != null);
    final Stream<Uint8List> audio;
    try {
      audio = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        // Режим микрофона для распознавания речи: без автоусиления и
        // шумоподавления. Они подстраиваются под тишину и искажают первое
        // слово после неё — как раз имя, которым зовут. Этим же режимом
        // пишет звук официальная обвязка Vosk для Android.
        noiseSuppress: false,
        autoGain: false,
        androidConfig: const AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
        ),
        // Чужие звуки запись не прерывают, и сама она чужим не мешает. По
        // умолчанию любое уведомление ставило её на паузу, и та уже не
        // снималась: приложение считало, что слушает, а звука не было. Да
        // ещё и музыка останавливалась, пока Джарвис ждал имя.
        audioInterruption: AudioInterruptionMode.none,
        device: await _audioInput.inputDeviceFor(_recorder),
      ));
    } on Object {
      worker.close(id);
      return null;
    }
    final session = _Session(id, worker,
        continuous: continuous,
        patient: patience != null,
        onPartial: onPartial,
        onPhrase: onPhrase);
    _session = session;
    session.audio = audio.listen(
      (bytes) => worker.feed(id, bytes),
      // Микрофон оборвался — отдаём то, что успели расслышать, а ожидание
      // имени выключаем: оболочка включит его заново.
      onError: (Object _) => _ended(session),
      onDone: () => _ended(session),
    );
    if (!continuous) session.limit = Timer(_maxDuration, () => _ended(session));
    if (patience != null) {
      // Заговорили — дослушиваем, сколько бы ни шло; промолчали — тишина.
      session.patience = Timer(patience, () {
        if (!session.spoke) unawaited(_exclusive(() => _close(session)));
      });
    }
    return session;
  }

  void _onHeard(SpeechHeard heard) {
    final session = _session;
    if (session == null || heard.session != session.id) return;
    switch (heard.kind) {
      case SpeechHeardKind.partial:
        if (heard.text.isNotEmpty) session.spoke = true;
        session.onPartial?.call(heard.text);
      case SpeechHeardKind.endpoint:
        if (session.continuous) {
          session.onPhrase?.call(heard.text);
        } else {
          if (session.patient) session.phrase = heard.text;
          _ended(session);
        }
      case SpeechHeardKind.done:
        break;
    }
  }

  /// Фраза кончилась, вышло время или оборвался звук.
  void _ended(_Session session) => unawaited(_exclusive(
      () => session.continuous ? _close(session) : _finish(session)));

  /// Дослушать просьбу, выдать итог и освободить микрофон.
  Future<void> _finish(_Session session) async {
    if (!identical(_session, session)) return;
    _session = null;
    await session.stopFeeding();
    // У терпеливого слушания распознаватель после фразы уже начал с чистого
    // листа: итог — сама фраза.
    final phrase = session.phrase;
    final String text;
    if (phrase != null) {
      session.worker.close(session.id);
      text = phrase;
    } else {
      text = await session.worker.finish(session.id);
    }
    await _stopRecorder();
    session.complete(text);
  }

  /// Выключить микрофон без итога.
  Future<void> _close(_Session? session) async {
    if (session == null || !identical(_session, session)) return;
    _session = null;
    await session.stopFeeding();
    session.worker.close(session.id);
    await _stopRecorder();
    session.complete('');
  }

  Future<void> _stopRecorder() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  /// Копирует модель из ресурсов сборки в память приложения — один раз на
  /// версию модели. Распакованную не трогает: чтение 27 МБ ресурсов на
  /// каждом запуске задерживало старт приложения.
  Future<String> _unpackModel() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'speech', _modelVersion));
    final done = File(p.join(dir.path, _unpacked));
    if (await done.exists()) return dir.path;
    await dir.create(recursive: true);
    for (final name in _files) {
      final data = await rootBundle.load('$_assetDir/$name');
      final partial = File(p.join(dir.path, '$name.part'));
      await partial.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await partial.rename(p.join(dir.path, name));
    }
    await done.writeAsString(_modelVersion, flush: true);
    return dir.path;
  }
}

/// Одно включение микрофона: ожидание имени или одна просьба.
class _Session {
  _Session(
    this.id,
    this.worker, {
    required this.continuous,
    this.patient = false,
    this.onPartial,
    this.onPhrase,
  });

  final int id;
  final SpeechWorker worker;
  final bool continuous;

  /// Продолжение разговора: молчание — не конец, итог — первая фраза.
  final bool patient;

  /// Терпеливое слушание: начали ли говорить и что сказали.
  bool spoke = false;
  String? phrase;
  Timer? patience;
  final void Function(String text)? onPartial;
  final void Function(String text)? onPhrase;

  /// Итог просьбы; у ожидания имени — всегда пусто.
  final result = Completer<String>();
  StreamSubscription<Uint8List>? audio;
  Timer? limit;

  Future<void> stopFeeding() async {
    limit?.cancel();
    patience?.cancel();
    await audio?.cancel();
  }

  void complete(String text) {
    if (!result.isCompleted) result.complete(text);
  }
}
