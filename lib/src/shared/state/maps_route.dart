import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapsRouteProvider = Provider<MapsRoute>((ref) => const MapsRoute());

/// Маршрут в картах телефона (`PhoneActions.kt`): «Яндекс Карты», а без них
/// — Google Maps. Одна дорога на всё приложение: её прокладывает и Джарвис
/// («как доехать»), и кнопка «Маршрут» у записи с адресом.
class MapsRoute {
  const MapsRoute();

  static const _channel = MethodChannel('ezhednevnik_v2/phone');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Открыть маршрут до [to]. Название открывшихся карт или null — карт на
  /// телефоне нет.
  Future<String?> open(String to) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<String>('route', {'to': to});
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
