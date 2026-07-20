import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appHintsProvider = StateNotifierProvider<AppHintsController, bool>(
  (ref) => AppHintsController(),
);

class AppHintsController extends StateNotifier<bool> {
  AppHintsController() : super(true) {
    _load();
  }

  static const storageKey = 'calendar_hints_enabled_v1';

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    state = preferences.getBool(storageKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await (await SharedPreferences.getInstance()).setBool(storageKey, enabled);
  }
}

@Deprecated('Use appHintsProvider')
final calendarHintsProvider = appHintsProvider;

@Deprecated('Use AppHintsController')
typedef CalendarHintsController = AppHintsController;
