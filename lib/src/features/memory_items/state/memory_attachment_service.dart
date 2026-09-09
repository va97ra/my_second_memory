import 'dart:convert';

import 'package:image_picker/image_picker.dart' show XFile;
import 'package:ez_data/ez_data.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../../../platform/windows/windows_audio_input.dart';

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
  MemoryAttachmentService({
    AppCipher? Function()? atRest,
    MediaStorage? storage,
    AudioRecorder? recorder,
    WindowsAudioInput audioInput = const WindowsAudioInput(),
  })  : _audioInput = audioInput,
        _atRest = atRest ?? _noCipher,
        _storage = storage ?? MediaStorage(),
        _recorder = recorder ?? AudioRecorder();

  /// Ключ местного шифрования вложений. Спрашивается в момент обращения, а не
  /// запоминается: замок могли открыть уже после того, как экран построился.
  /// Null означает, что PIN не задан и файлы лежат открытыми.
  final AppCipher? Function() _atRest;

  static AppCipher? _noCipher() => null;

  final WindowsAudioInput _audioInput;

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
    return _storage.saveImage(file, _atRest());
  }

  /// Начинает запись голоса. Возвращает false, если разрешение не дано:
  /// молча ничего не записывать честнее, чем делать вид, что пишем.
  Future<bool> startVoice() async {
    if (!await _recorder.hasPermission()) return false;
    final path = await _storage.createVoicePath();
    await _recorder.start(
      RecordConfig(device: await _defaultInputDevice()),
      path: path,
    );
    _recordingStartedAt = DateTime.now();
    return true;
  }

  /// Микрофон, выбранный в параметрах звука Windows.
  ///
  /// Null — устройство назвать не удалось; тогда его выбирает система, как и
  /// раньше. На телефоне это всегда так: там микрофон один.
  Future<InputDevice?> _defaultInputDevice() async {
    final id = await _audioInput.defaultCaptureDeviceId();
    if (id == null) return null;
    for (final device in await _recorder.listInputDevices()) {
      if (device.id == id) return device;
    }
    return null;
  }

  /// Останавливает запись. Null означает, что записывать было нечего.
  Future<VoiceRecording?> stopVoice() async {
    final startedAt = _recordingStartedAt;
    _recordingStartedAt = null;
    final path = await _recorder.stop();
    if (path == null) return null;
    final reference = MediaStorage.referenceFor(path);
    await _storage.protectRecording(reference, _atRest());
    return VoiceRecording(
      // В записи живёт имя файла, а не путь: путь свой у каждого устройства.
      path: reference,
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
