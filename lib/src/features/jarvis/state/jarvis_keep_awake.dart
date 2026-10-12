import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jarvisKeepAwakeProvider =
    Provider<JarvisKeepAwake>((ref) => const JarvisKeepAwake());

/// Экран телефона, пока открыт лист Джарвиса (`MainActivity.kt`).
///
/// Экран владельца гаснет через 15 секунд, а Джарвис дольше: ждёт
/// нейросеть и ещё 12 секунд — продолжения разговора. На погасшем экране
/// Android не даёт микрофон, и разговор обрывался на полуслове. Пока лист
/// открыт, экран не гаснет; закрыли — гаснет как обычно (решение владельца
/// 12 октября 2026).
class JarvisKeepAwake {
  const JarvisKeepAwake();

  static const _channel = MethodChannel('ezhednevnik_v2/screen');

  Future<void> keepOn(bool on) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
