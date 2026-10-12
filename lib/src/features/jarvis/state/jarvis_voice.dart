import 'package:ez_domain/ez_domain.dart' show JarvisTone;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Голос Джарвиса: синтез речи, установленный в телефоне, без сети. Каким
/// голосом говорить — [JarvisTone].
class JarvisVoice {
  JarvisVoice([FlutterTts? tts]) : _given = tts;

  final FlutterTts? _given;

  /// Синтез речи подключается к первой реплике, а не при запуске: связь с
  /// движком речи занимала основной поток на полсекунды с лишним, пока
  /// приложение открывалось.
  late final FlutterTts _tts = _given ?? FlutterTts();
  Future<void>? _ready;

  var _speaking = 0;

  /// Говорит прямо сейчас. Пока говорит, имя не слушают: микрофон услышал
  /// бы самого Джарвиса.
  bool get speaking => _speaking > 0;

  /// Говорит и ждёт конца фразы.
  Future<void> speak(String text) async {
    _speaking++;
    try {
      await (_ready ??= _prepare());
      await _tts.stop();
      await _tts.speak(text);
    } finally {
      _speaking--;
    }
  }

  Future<void> stop() async {
    // Ни разу не говорил — и останавливать нечего: не будить движок речи.
    if (_ready == null) return;
    await _tts.stop();
  }

  Future<void> _prepare() async {
    await _tts.setLanguage('ru-RU');
    await _tts.awaitSpeakCompletion(true);
    final voices = (await _tts.getVoices as List?)?.cast<Map>() ?? const [];
    final names = {for (final voice in voices) '${voice['name']}'};
    for (final name in JarvisTone.voices) {
      if (names.contains(name)) {
        await _tts.setVoice({'name': name, 'locale': 'ru-RU'});
        break;
      }
    }
    await _tts.setPitch(JarvisTone.pitch);
    await _tts.setSpeechRate(JarvisTone.rate);
  }
}

final jarvisVoiceProvider = Provider<JarvisVoice>((ref) {
  final voice = JarvisVoice();
  ref.onDispose(voice.stop);
  return voice;
});
