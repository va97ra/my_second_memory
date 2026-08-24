import 'dart:convert';

import 'package:image_picker/image_picker.dart' show XFile;
import 'package:ez_data/ez_data.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Записанная голосовая заметка.
class VoiceRecording {
  const VoiceRecording({required this.path, required this.durationSeconds});

  final String path;
  final int durationSeconds;
}

/// Вложения записи: фотографии и голос.
///
/// Сервис знает, что делать с выбранным файлом, но не знает, как его
/// выбирают: диалог с камерой и галереей остаётся экрану, потому что это
/// разговор с человеком, а не работа с данными.
class MemoryAttachmentService {
  MemoryAttachmentService({MediaStorage? storage, AudioRecorder? recorder})
      : _storage = storage ?? MediaStorage(),
        _recorder = recorder ?? AudioRecorder();

  final MediaStorage _storage;
  final AudioRecorder _recorder;

  DateTime? _recordingStartedAt;

  bool get isRecording => _recordingStartedAt != null;

  /// Кладёт снимок туда, где запись сможет его найти.
  ///
  /// В вебе файловой системы нет, поэтому изображение остаётся при записи
  /// целиком, строкой data-URL; на остальных платформах хранится файл.
  Future<String> importImage(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final mimeType = file.mimeType ?? mimeTypeForName(file.name);
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
    return _storage.saveImage(file);
  }

  /// Начинает запись голоса. Возвращает false, если разрешение не дано:
  /// молча ничего не записывать честнее, чем делать вид, что пишем.
  Future<bool> startVoice() async {
    if (!await _recorder.hasPermission()) return false;
    final path = await _storage.createVoicePath();
    await _recorder.start(const RecordConfig(), path: path);
    _recordingStartedAt = DateTime.now();
    return true;
  }

  /// Останавливает запись. Null означает, что записывать было нечего.
  Future<VoiceRecording?> stopVoice() async {
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final path = await _recorder.stop();
    if (path == null) return null;
    return VoiceRecording(
      path: path,
      durationSeconds:
          startedAt == null ? 0 : DateTime.now().difference(startedAt).inSeconds,
    );
  }

  void dispose() => _recorder.dispose();

  /// Тип изображения по имени файла — на случай, если сам файл его не назвал.
  static String mimeTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
