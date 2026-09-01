import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Пройденные темы обучения.
///
/// Прогресс лежит на устройстве и между устройствами не синхронизируется:
/// для облака нужна своя сущность и миграция, а её применяет владелец. Пока
/// этого нет, честнее хранить локально, чем обещать синхронизацию.
final learningProgressProvider =
    StateNotifierProvider<LearningProgressController, Set<String>>((ref) {
  return LearningProgressController()..load();
});

class LearningProgressController extends StateNotifier<Set<String>> {
  LearningProgressController() : super(const {});

  static const _storageKey = 'electrician_learning_passed_v1';

  Future<void> load() async {
    final saved =
        (await SharedPreferences.getInstance()).getStringList(_storageKey);
    if (saved != null) state = saved.toSet();
  }

  /// Тема считается пройденной после верного ответа на все вопросы.
  Future<void> markPassed(String topicId) async {
    if (state.contains(topicId)) return;
    state = {...state, topicId};
    await _save();
  }

  Future<void> reset() async {
    state = const {};
    await _save();
  }

  Future<void> _save() async =>
      (await SharedPreferences.getInstance()).setStringList(
        _storageKey,
        state.toList(),
      );
}
