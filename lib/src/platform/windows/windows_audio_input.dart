import 'package:flutter/services.dart';

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
}
