import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Переключатель настройки, который помнит себя между запусками.
///
/// До того как значение прочитано с диска, действует [initial]: экран уже
/// строится, а чтение асинхронное.
class BoolSettingController extends Notifier<bool> {
  BoolSettingController({required this.storageKey, required this.initial});

  final String storageKey;
  final bool initial;

  @override
  bool build() {
    _load();
    return initial;
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (ref.mounted) state = preferences.getBool(storageKey) ?? initial;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await (await SharedPreferences.getInstance()).setBool(storageKey, enabled);
  }
}

/// Провайдер настройки-переключателя: ключ хранения и значение по умолчанию.
NotifierProvider<BoolSettingController, bool> boolSettingProvider({
  required String storageKey,
  required bool initial,
}) {
  return NotifierProvider<BoolSettingController, bool>(
    () => BoolSettingController(storageKey: storageKey, initial: initial),
  );
}
