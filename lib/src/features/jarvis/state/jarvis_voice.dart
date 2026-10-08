import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Голос Джарвиса: синтез речи, установленный в телефоне, без сети.
///
/// Голос мужской, тон чуть ниже обычного, темп на 30 % быстрее — так
/// владелец выбрал его в MemoryVoice. Если мужского голоса в телефоне нет,
/// говорит русский голос по умолчанию.
class JarvisVoice {
  JarvisVoice([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  Future<void>? _ready;

  /// Мужские русские голоса Google в порядке предпочтения.
  static const _preferredVoices = ['ru-ru-x-rud-local', 'ru-ru-x-ruf-local'];
  static const _pitch = 0.85;
  static const _rate = 0.585;

  /// Говорит и ждёт конца фразы.
  Future<void> speak(String text) async {
    await (_ready ??= _prepare());
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<void> _prepare() async {
    await _tts.setLanguage('ru-RU');
    await _tts.awaitSpeakCompletion(true);
    final voices = (await _tts.getVoices as List?)?.cast<Map>() ?? const [];
    final names = {for (final voice in voices) '${voice['name']}'};
    for (final name in _preferredVoices) {
      if (names.contains(name)) {
        await _tts.setVoice({'name': name, 'locale': 'ru-RU'});
        break;
      }
    }
    await _tts.setPitch(_pitch);
    await _tts.setSpeechRate(_rate);
  }
}

final jarvisVoiceProvider = Provider<JarvisVoice>((ref) {
  final voice = JarvisVoice();
  ref.onDispose(voice.stop);
  return voice;
});
