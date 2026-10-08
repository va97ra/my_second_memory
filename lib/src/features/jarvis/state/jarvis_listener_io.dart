import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../../platform/windows/windows_audio_input.dart';
import 'jarvis_listener.dart';

JarvisListener? createJarvisListener() => OfflineJarvisListener();

/// Распознавание на устройстве: sherpa-onnx и потоковая модель Vosk small
/// ru (Zipformer2, Apache 2.0). Модель лежит в `assets/speech/vosk-ru` и при
/// первом запуске один раз копируется в память приложения — движок читает
/// файлы, а не ресурсы сборки.
///
/// Перенесено из MemoryVoice, где проверено на телефоне владельца; числа
/// пауз подобраны там же.
class OfflineJarvisListener implements JarvisListener {
  OfflineJarvisListener({
    AudioRecorder? recorder,
    WindowsAudioInput audioInput = const WindowsAudioInput(),
  })  : _recorder = recorder ?? AudioRecorder(),
        _audioInput = audioInput;

  static const _assetDir = 'assets/speech/vosk-ru';
  static const _modelVersion = 'vosk-ru-0.54';
  static const _files = [
    'encoder.int8.onnx',
    'decoder.int8.onnx',
    'joiner.int8.onnx',
    'tokens.txt',
  ];
  static const _sampleRate = 16000;

  /// Дольше одной фразы не слушаем.
  static const _maxDuration = Duration(seconds: 30);

  final AudioRecorder _recorder;
  final WindowsAudioInput _audioInput;
  sherpa.OnlineRecognizer? _recognizer;
  Future<sherpa.OnlineRecognizer>? _starting;

  sherpa.OnlineStream? _stream;
  StreamSubscription<Uint8List>? _audio;
  Completer<String>? _completer;
  Timer? _maxTimer;
  String _last = '';
  int? _oddByte;

  @override
  Future<String> listen({void Function(String text)? onPartial}) async {
    if (!await _recorder.hasPermission()) {
      throw const JarvisListenerFailure(
          'Разрешите приложению микрофон в настройках телефона.');
    }
    final recognizer = await (_starting ??= _start());
    await cancel();
    // Микрофон один: пока слушаем просьбу, имя не ждём.
    await stopContinuous();
    final stream = recognizer.createStream();
    final completer = Completer<String>();
    _stream = stream;
    _completer = completer;
    _last = '';
    _oddByte = null;

    final Stream<Uint8List> audio;
    try {
      audio = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        noiseSuppress: true,
        autoGain: true,
        device: await _audioInput.inputDeviceFor(_recorder),
      ));
    } on Object {
      _release();
      throw const JarvisListenerFailure(
          'Микрофон не включился — возможно, его занимает другое приложение.');
    }

    _audio = audio.listen(
      (bytes) {
        if (!identical(_completer, completer)) return;
        final samples = _toFloat32(bytes);
        if (samples.isEmpty) return;
        stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
        while (recognizer.isReady(stream)) {
          recognizer.decode(stream);
        }
        final text = recognizer.getResult(stream).text.trim();
        if (text != _last) {
          _last = text;
          onPartial?.call(text);
        }
        if (recognizer.isEndpoint(stream)) _finish(completer);
      },
      // Микрофон оборвался — отдаём то, что успели расслышать.
      onError: (Object _) => _finish(completer),
    );
    _maxTimer = Timer(_maxDuration, () => _finish(completer));
    return completer.future;
  }

  @override
  Future<void> stop() async {
    final completer = _completer;
    if (completer != null) await _finish(completer);
  }

  @override
  Future<void> cancel() async {
    final completer = _completer;
    _completer = null;
    _release();
    await _stopRecorder();
    if (completer != null && !completer.isCompleted) completer.complete('');
  }

  StreamSubscription<Uint8List>? _waitAudio;
  sherpa.OnlineStream? _waitStream;

  @override
  bool get continuous => _waitAudio != null;

  @override
  Future<bool> startContinuous({
    required void Function(String text) onPhrase,
    void Function(String text)? onPartial,
  }) async {
    if (_waitAudio != null) return true;
    // Идёт обычное слушание — оно главнее.
    if (_completer != null) return false;
    if (!await _recorder.hasPermission(request: false)) return false;
    final recognizer = await (_starting ??= _start());
    final stream = recognizer.createStream();
    final Stream<Uint8List> audio;
    try {
      audio = await _recorder.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        noiseSuppress: true,
        autoGain: true,
        device: await _audioInput.inputDeviceFor(_recorder),
      ));
    } on Object {
      // Микрофон занят другим приложением — имя подождёт следующей попытки.
      stream.free();
      return false;
    }
    _waitStream = stream;
    _oddByte = null;
    var last = '';
    _waitAudio = audio.listen((bytes) {
      if (!identical(_waitStream, stream)) return;
      final samples = _toFloat32(bytes);
      if (samples.isEmpty) return;
      stream.acceptWaveform(samples: samples, sampleRate: _sampleRate);
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
      final text = recognizer.getResult(stream).text.trim();
      if (text != last) {
        last = text;
        onPartial?.call(text);
      }
      // Фраза кончилась — отдаём её и слушаем дальше с чистого листа.
      if (recognizer.isEndpoint(stream)) {
        recognizer.reset(stream);
        last = '';
        if (text.isNotEmpty) onPhrase(text);
      }
    });
    return true;
  }

  @override
  Future<void> stopContinuous() async {
    final audio = _waitAudio;
    final stream = _waitStream;
    if (audio == null) return;
    _waitAudio = null;
    _waitStream = null;
    await audio.cancel();
    stream?.free();
    await _stopRecorder();
  }

  @override
  void dispose() {
    unawaited(stopContinuous());
    unawaited(cancel());
    _recognizer?.free();
    _recognizer = null;
  }

  Future<sherpa.OnlineRecognizer> _start() async {
    final dir = await _unpackModel();
    sherpa.initBindings();
    final recognizer = sherpa.OnlineRecognizer(sherpa.OnlineRecognizerConfig(
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: p.join(dir, 'encoder.int8.onnx'),
          decoder: p.join(dir, 'decoder.int8.onnx'),
          joiner: p.join(dir, 'joiner.int8.onnx'),
        ),
        tokens: p.join(dir, 'tokens.txt'),
        numThreads: 2,
        debug: false,
      ),
      decodingMethod: 'modified_beam_search',
      maxActivePaths: 4,
      enableEndpoint: true,
      // Ничего не сказали 2,4 с — «не расслышал».
      rule1MinTrailingSilence: 2.4,
      // Договорили и молчат 2,2 с — фраза закончена. С 1,5 с обрывало
      // задумавшегося посреди фразы: «завтра… в два… к врачу».
      rule2MinTrailingSilence: 2.2,
      rule3MinUtteranceLength: 30,
    ));
    _recognizer = recognizer;
    return recognizer;
  }

  /// Дослушать остаток, выдать итог и освободить микрофон.
  Future<void> _finish(Completer<String> completer) async {
    if (completer.isCompleted || !identical(_completer, completer)) return;
    // Конец фразы и таймер могут прийти разом: завершает первый.
    _completer = null;
    final recognizer = _recognizer;
    final stream = _stream;
    var text = _last;
    if (recognizer != null && stream != null) {
      // Полсекунды тишины в конце — модель «дожимает» последнее слово.
      stream.acceptWaveform(
          samples: Float32List(_sampleRate ~/ 2), sampleRate: _sampleRate);
      stream.inputFinished();
      while (recognizer.isReady(stream)) {
        recognizer.decode(stream);
      }
      text = recognizer.getResult(stream).text.trim();
    }
    _release();
    await _stopRecorder();
    completer.complete(text);
  }

  void _release() {
    _maxTimer?.cancel();
    _maxTimer = null;
    unawaited(_audio?.cancel());
    _audio = null;
    _stream?.free();
    _stream = null;
  }

  Future<void> _stopRecorder() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  /// Копирует модель из ресурсов сборки в память приложения — один раз на
  /// версию модели.
  Future<String> _unpackModel() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'speech', _modelVersion));
    await dir.create(recursive: true);
    for (final name in _files) {
      final file = File(p.join(dir.path, name));
      final data = await rootBundle.load('$_assetDir/$name');
      if (await file.exists() && await file.length() == data.lengthInBytes) {
        continue;
      }
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await partial.rename(file.path);
    }
    return dir.path;
  }

  /// PCM 16 бит little-endian → числа от -1 до 1. Нечётный байт куска
  /// переносится в следующий: звук приходит кусками произвольной длины.
  Float32List _toFloat32(Uint8List bytes) {
    var data = bytes;
    final carried = _oddByte;
    if (carried != null) {
      data = Uint8List(bytes.length + 1)
        ..[0] = carried
        ..setRange(1, bytes.length + 1, bytes);
      _oddByte = null;
    }
    final even = data.length & ~1;
    if (even != data.length) _oddByte = data[data.length - 1];
    final view = ByteData.sublistView(data, 0, even);
    final samples = Float32List(even ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = view.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }
}
