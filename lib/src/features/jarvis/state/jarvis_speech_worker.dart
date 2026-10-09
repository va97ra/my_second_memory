import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Что расслышал распознаватель за одну сессию микрофона.
enum SpeechHeardKind {
  /// Текст по ходу речи.
  partial,

  /// Человек договорил и замолчал.
  endpoint,

  /// Итог после [SpeechWorker.finish].
  done,
}

typedef SpeechHeard = ({int session, SpeechHeardKind kind, String text});

/// Распознавание речи в своём потоке.
///
/// Модель грузится секунды, а пока Джарвис ждёт имя, расшифровка идёт без
/// остановки. В потоке интерфейса это замораживало запуск приложения и
/// отнимало время у каждого кадра; здесь интерфейс только пересылает звук и
/// получает текст.
///
/// Сессия — одно включение микрофона. Звук и команды доходят до потока по
/// порядку, поэтому итог [finish] учитывает весь звук, посланный до него.
class SpeechWorker {
  SpeechWorker._(this._commands, this._replies, this.heard);

  final SendPort _commands;
  final ReceivePort _replies;

  /// Распознанное по всем сессиям; чья сессия — разбирает получатель.
  final Stream<SpeechHeard> heard;

  /// Поднимает поток и загружает в нём модель из [modelDir]. Бросает
  /// [StateError], если модель не загрузилась.
  static Future<SpeechWorker> spawn(String modelDir) async {
    final replies = ReceivePort();
    final messages = replies.asBroadcastStream();
    final ready = messages.first;
    final isolate = await Isolate.spawn(
      _run,
      (replies.sendPort, modelDir),
      debugName: 'jarvis-speech',
    );
    final first = await ready;
    if (first is! SendPort) {
      isolate.kill();
      replies.close();
      throw StateError('Распознавание речи не запустилось: $first');
    }
    final heard = messages
        .where((message) => message is (int, int, String))
        .map((message) {
      final (session, kind, text) = message as (int, int, String);
      return (
        session: session,
        kind: SpeechHeardKind.values[kind],
        text: text,
      );
    }).asBroadcastStream();
    return SpeechWorker._(first, replies, heard);
  }

  /// Новая сессия; прежняя забывается. [continuous] — после конца фразы
  /// слушать дальше с чистого листа, а не ждать [finish].
  void open(int session, {required bool continuous}) =>
      _commands.send(('open', session, continuous));

  /// Кусок звука: PCM 16 бит, 16 кГц, моно.
  void feed(int session, Uint8List pcm) => _commands
      .send(('audio', session, TransferableTypedData.fromList([pcm])));

  /// Дослушать сессию и отдать итог; сессия закрывается.
  Future<String> finish(int session) {
    final done = heard
        .firstWhere((event) =>
            event.session == session && event.kind == SpeechHeardKind.done)
        .then((event) => event.text);
    _commands.send(('finish', session));
    return done;
  }

  /// Закрыть сессию без итога.
  void close(int session) => _commands.send(('close', session));

  /// Освобождает модель; поток завершается сам, когда закроет свой порт.
  void dispose() {
    _commands.send(('dispose',));
    _replies.close();
  }
}

const _sampleRate = 16000;

sherpa.OnlineRecognizerConfig _config(String dir) =>
    sherpa.OnlineRecognizerConfig(
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
    );

/// Поток распознавания: модель, одна сессия за раз, ответы по порядку.
void _run((SendPort, String) setup) {
  final (reply, dir) = setup;
  final sherpa.OnlineRecognizer recognizer;
  try {
    sherpa.initBindings();
    recognizer = sherpa.OnlineRecognizer(_config(dir));
  } on Object catch (error) {
    reply.send('$error');
    return;
  }
  final inbox = ReceivePort();
  reply.send(inbox.sendPort);

  sherpa.OnlineStream? stream;
  var session = -1;
  var continuous = false;
  var last = '';
  final pcm = _Pcm16();

  void heard(SpeechHeardKind kind, String text) =>
      reply.send((session, kind.index, text));

  void drop() {
    stream?.free();
    stream = null;
  }

  void decode(sherpa.OnlineStream current) {
    while (recognizer.isReady(current)) {
      recognizer.decode(current);
    }
  }

  inbox.listen((message) {
    switch (message) {
      case ('open', final int id, final bool keepListening):
        drop();
        stream = recognizer.createStream();
        session = id;
        continuous = keepListening;
        last = '';
        pcm.reset();
      case ('audio', final int id, final TransferableTypedData data):
        final current = stream;
        if (id != session || current == null) return;
        final samples = pcm.toFloat32(data.materialize().asUint8List());
        if (samples.isEmpty) return;
        current.acceptWaveform(samples: samples, sampleRate: _sampleRate);
        decode(current);
        final text = recognizer.getResult(current).text.trim();
        if (text != last) {
          last = text;
          heard(SpeechHeardKind.partial, text);
        }
        if (!recognizer.isEndpoint(current)) return;
        if (continuous) {
          // Фраза кончилась — отдаём её и слушаем дальше с чистого листа.
          recognizer.reset(current);
          last = '';
          if (text.isNotEmpty) heard(SpeechHeardKind.endpoint, text);
        } else {
          heard(SpeechHeardKind.endpoint, text);
        }
      case ('finish', final int id):
        final current = stream;
        if (id != session || current == null) {
          reply.send((id, SpeechHeardKind.done.index, ''));
          return;
        }
        // Полсекунды тишины в конце — модель «дожимает» последнее слово.
        current.acceptWaveform(
            samples: Float32List(_sampleRate ~/ 2), sampleRate: _sampleRate);
        current.inputFinished();
        decode(current);
        heard(SpeechHeardKind.done, recognizer.getResult(current).text.trim());
        drop();
      case ('close', final int id):
        if (id == session) drop();
      case ('dispose',):
        drop();
        recognizer.free();
        inbox.close();
    }
  });
}

/// PCM 16 бит little-endian → числа от -1 до 1. Нечётный байт куска
/// переносится в следующий: звук приходит кусками произвольной длины.
class _Pcm16 {
  int? _oddByte;

  void reset() => _oddByte = null;

  Float32List toFloat32(Uint8List bytes) {
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
