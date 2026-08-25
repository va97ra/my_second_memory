import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Переключатель настройки, который помнит себя между запусками.
///
/// До того как значение прочитано с диска, действует [initial]: экран уже
/// строится, а чтение асинхронное.
class BoolSettingController extends StateNotifier<bool> {
  BoolSettingController({required this.storageKey, required bool initial})
      : super(initial) {
    _load(initial);
  }

  final String storageKey;

  Future<void> _load(bool fallback) async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(storageKey) ?? fallback;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await (await SharedPreferences.getInstance()).setBool(storageKey, enabled);
  }
}

/// Провайдер настройки-переключателя: ключ хранения и значение по умолчанию.
StateNotifierProvider<BoolSettingController, bool> boolSettingProvider({
  required String storageKey,
  required bool initial,
}) {
  return StateNotifierProvider<BoolSettingController, bool>(
    (ref) => BoolSettingController(storageKey: storageKey, initial: initial),
  );
}
