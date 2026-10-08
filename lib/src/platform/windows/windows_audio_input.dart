import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Микрофон, выбранный в параметрах звука Windows.
///
/// Плагин записи такого не отдаёт, а без явного указания устройства Media
/// Foundation берёт *коммуникационное* устройство — в Windows это отдельная
/// настройка, и на машине с несколькими входами она указывает на другой
/// микрофон. Поэтому оболочка приложения спрашивает систему напрямую.
///
/// Null означает «спросить не удалось» или «платформа не Windows»: тогда
/// выбор остаётся за системой, как и был.
class WindowsAudioInput {
  const WindowsAudioInput();

  static const _channel = MethodChannel('ezhednevnik/audio_input');

  Future<String?> defaultCaptureDeviceId() async {
    try {
      return await _channel.invokeMethod<String>('defaultCaptureDeviceId');
    } on MissingPluginException {
      // Канал есть только у Windows-сборки.
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Устройство записи для [recorder]: микрофон, выбранный в Windows.
  ///
  /// Null — устройство назвать не удалось; тогда его выбирает система, как и
  /// раньше. На телефоне это всегда так: там микрофон один. Этим пользуются
  /// все, кто пишет звук: голосовые заметки и Джарвис.
  Future<InputDevice?> inputDeviceFor(AudioRecorder recorder) async {
    final id = await defaultCaptureDeviceId();
    if (id == null) return null;
    for (final device in await recorder.listInputDevices()) {
      if (device.id == id) return device;
    }
    return null;
  }
}
